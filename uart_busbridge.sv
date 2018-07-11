module uart_bridge #
(
	parameter word_len=32)
(
	input clk,
	input rst_n,
	// from uart_ctrl
	input [31:0] UcUb_data_out,// the UbUc_data_in of the uart_ctrl
	output reg [31:0] UbUc_data_in,// the UcUb_data_out of the uart_ctrl
	input UbUc_data_out_en,//UbUc_UbUc_data_out_en of uart_ctrl
	output reg UbUc_UbUc_data_out_en,
	// from bus
	// for write addr
	output reg [27:0] UbBus_awaddr,
	output reg UbBus_awuserap,
	output reg [3:0] UbBus_awuserid,
	output reg [3:0] UbBus_awlen,
	output reg UbBus_awvalid,
	input BusUb_awready,
	// for read addr
	output reg [27:0] UbBus_araddr,
	output reg UbBus_aruserap,
	output reg [3:0] UbBus_aruserid,
	output reg [3:0] UbBus_arlen,
	output reg UbBus_arvalid,
	input BusUb_arready,
	// for write data
	input [3:0] BusUb_wuserid,
	input [3:0] BusUb_wready,
	input BusUb_wlast,
	output reg [31:0] UbBus_wdata,
	output reg [3:0] UbBus_wstrb,
	// for read data
	input [3:0] BusUb_rid,
	input BusUb_rlast,
	input BusUb_rvalid,
	input [31:0] BusUb_rdata,
	// from uart_unit
	input [2:0] UnUb_wr_sel
	input [27:0] UnUb_initAddr,
	input UnUb_initAddrEn
);

localparam AWID = 4'b1011;

reg [3:0] state, nstate;
reg [27:0] _addr;
reg wd_done;
reg [31:0] _data;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) _addr <= 0;
	else if (UnUb_initAddrEn) _addr <= UnUb_initAddr;
	else _addr <= _addr + 32/word_len;//addr plus one unit
end

task write_addr;
	UbBus_awlen <= 4'h1;// every time write one word
	UbBus_awaddr <= _addr;
	UbBus_awvalid <= 1'b1;
	UbBus_awuserap <= 1'b1;
	UbBus_awuserid <= AWID;
endtask

task write_data;
	if (BusUb_wready) write_en <= 1'b1;
	else write_en <= 1'b0;
endtask

always @(posedge clk) begin
	if (write_en) begin
		UbBus_wdata <= _data;
		UbBus_wstrb <= 4'hf;
		wd_done <= 1;
	end else begin
		UbBus_wstrb <= 0;
		wd_done <= 0;
		UbBus_wdata <= 0;
	end 
end 

task read_addr;
	UbBus_aruserid <= ARID;
	UbBus_arlen <= 4'h0;
	UbBus_aruserap <= 1'b1;
	UbBus_araddr <= _addr + 32/word_len;
	UbBus_arvalid <= 1'b1;
endtask

task read_data;
	if (BusUb_rvalid && BusUb_rid == AWID) begin
		UbUc_data_in <= BusUb_rdata;
		UbUc_UbUc_data_out_en <= 1'b1;
	end
endtask 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= 0;
	else state <= nstate;
end 

always @* begin
	case (state) 
		4'h0: begin
			if (rst_n) 
				if (UnUb_wr_sel == 3'b100) nstate = 4'h1;
				else if (UnUb_wr_sel == 3'b010) nstate = 4'h3;
				else nstate = 4'h0;
			else nstate = 4'h0;
		end
		4'h1: nstate = 4'h2;
		4'h2: nstate = wd_done ? 4'h0 : 4'h2;
		4'h3: nstate = 4'h4;
		4'h4: nstate = UbUc_UbUc_data_out_en ? 4'h0 : 4'h4;
	endcase
end

always @(posedge clk) begin
	case (state) 
		4'h0: begin
			if (rst_n && UbUc_data_out_en) begin
				write_en <= 1'b0;
				_data <= UcUb_data_out;
			end
			else if (!rst_n) begin
				_data	<= 0;
			end else ;
		end
		4'h1: 
			write_addr;
		4'h2:
			write_data;
		4'h3: 
			read_addr;
		4'h4: 
			read_data;
	endcase
end

endmodule
