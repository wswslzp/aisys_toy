module fc_wr_ctrl #
(parameter batch_size=1,
	parameter bias_size=10,
	parameter word_len=32)
(
	// from outside
	input clk, rst_n,
	// from fully_connect side
	input FcNwc_result_en,
	input [batch_size-1:0][bias_size-1:0][31:0] FcNwc_result,
	// from bus
	input BusNwc_awready,
	output reg [3:0] NwcBus_awuser_id,
	output reg NwcBus_awuser_ap,
	output reg [3:0] NwcBus_awlen,
	output reg NwcBus_awvalid,
	output reg [27:0] NwcBus_awaddr,

	input BusNwc_wready,
	input [3:0] BusNwc_wuser_id,
	input BusNwc_wuser_last,
	output reg [31:0] NwcBus_wdata,
	output reg [3:0] NwcBus_wstrb,
	// from fc_ctrl 
	input [27:0] NcNwc_initAddr,
	input NcNwc_initAddrEn,
	output reg NwcNc_done
);

localparam AWID = 4'b0110;
localparam RESULT_SIZE = batch_size*bias_size;

reg [27:0] _addr;
reg [batch_size-1:0][bias_size-1:0][31:0] _result;
reg [31:0] cnt;
reg [4:0] wd_cnt;
reg [1:0] state;
reg [1:0] wd_state;
reg write_en;

task write_addr;
	NwcBus_awlen <= 4'h0;
	NwcBus_awaddr <= _addr + cnt * 16 * 32/word_len;
	NwcBus_awvalid <= 1'b1;
	NwcBus_awuser_ap <= 1'b1;
	NwcBus_awuser_id <= AWID;
endtask

task write_data;
	if (BusNwc_wready) write_en <= 1'b1;
	else write_en <= 1'b0;
endtask

always @(posedge clk, negedge rst_n) begin
	if (write_en) begin
		if (wd_cnt != 5'h10) begin
			wd_cnt <= wd_cnt + 1;
			NwcBus_wdata <= _result[batch_size-1][bias_size];
			NwcBus_wstrb <= 4'hf;
			_result <= _result << 32;
		end 
		else begin
			wd_cnt <= 5'b0;
			NwcBus_wstrb <= 0;
			NwcBus_wdata <= 0;
		end 
	end else begin
		wd_cnt <= 0;
		NwcBus_wstrb <= 0;
		NwcBus_wdata <= 0;
	end 
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= 2'b0;
	else begin
		case (state) 
			2'h0: begin
				state <= FcNwc_result_en ? 2'h1 : 2'h0;
				NwcNc_done <= 1'b0;
			end 
			2'h1: begin
				write_addr;
				state <= BusNwc_awready ? 2'h2 : 2'h0;
			end 
			2'h2: begin
				if (cnt != RESULT_SIZE/16+1) begin // With the burst length being 16, cnt should count to RESULT_SIZE/16+1
					cnt <= cnt + 1;
					write_data;
					state <= 2'h2;
				end else begin
					cnt <= 0;
					NwcNc_done <= 1'b1;
					state <= 2'h0;
				end 
			end 
		endcase
	end 
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		_addr <= 0;
	end else if (NcNwc_initAddrEn) _addr <= NcNwc_initAddr;
	else ;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) _result <= 0; 
	else if (FcNwc_result_en) _result <= FcNwc_result;
	else ;
end 

endmodule 
