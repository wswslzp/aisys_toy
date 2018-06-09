module pool_wr_bridge #
(parameter width = 32, 
 parameter channel_size=64)
(
	// from system
	input clk, 
	input rst_n,
	// from pool_layer side
	input [channel_size*32-1:0] result,
	input result_en, 

	// from the pool_ctrl side
	input [27:0] addr, // prime point's address
	input [5:0] addr_bias, // equal to the current filter number
	input addr_en, // first result's addr valid
	output reg addr_rq, // request for addr

	// from bus side
	output reg [27:0] awaddr,
	output reg awuser_ap,
	output reg [3:0] awuser_id,
	output reg [3:0] awlen,
	output reg awvalid,
	input awready,

	output reg [width-1:0] wdata,
	output reg [width/8-1:0] wstrb,
	input wready,
	input [3:0] wuser_id,
	input wuser_last
	
);

reg write_start;
reg [1:0] state, nstate, wstate;
reg [2:0] cnt;
reg [4:0] wcnt;
reg [channel_size*32-1:0] _result;
reg [27:0] _addr;

always @(posedge clk, negedge rst_n) begin
	if(!rst_n ) begin
		state <= 2'h0;
	end else state <= nstate;
end 

always @* begin
	case (state) 
		2'h0: nstate = rst_n ? 2'h1 : 0;
		2'h1: nstate = result_en ? 2'h2 : 2'h1;
		2'h2: nstate = addr_en ? 2'h3 : 2'h2;
		2'h3: nstate = cnt==3'h4 ? 2'h0 : 2'h3;
		default: nstate = 2'h0;
	endcase
end

task reset;
	addr_rq = 0;
	awaddr = 0;
	awuser_ap = 0;
	awuser_id = 0;
	awlen = 0;
	awvalid = 0;
	wdata = 0;
	wstrb = 0;
endtask

task write_addr;
	if (!awready) begin
		awaddr = _addr;
		awuser_ap = 1;
		awuser_id = 4'h4;
		awvalid = 1;
		awlen = 4'h0;
	end else begin
		awvalid = 0;
		awlen = 0;
		awaddr = _addr;
		awuser_ap = 1;
		awuser_id = 4'h4;
	end 
endtask

task write_data;
	case (wstate) 
		2'h0: begin
			if (wready) begin
				wcnt <= 0;
				wstate <= 2'h1;
			end else ;
		end 
		2'h1: begin
			if (wcnt == 5'h2) begin
				wcnt <= 5'h0;
				wstate <= 2'h2;
				write_start <= 1;
			end else begin
				wcnt <= wcnt  +1;
				wstate <= 2'h1;
				write_start <= 0;
			end 
		end 
		2'h2: begin
			if (wcnt != 5'h10) begin
				wcnt <= wcnt + 1;
				wdata <= _result[31:0];
				_result <= {_result[channel_size*32-1:(channel_size-1)*32], 32'b0};
				wstate <= 2'h2;
			end else begin
				wstate <= 2'h0;
				write_start <= 1'b0;
			end 
		end
	endcase
endtask

always @* begin
	case (state) 
		2'h0: begin
		end 
		2'h1: begin
			if (result_en) begin
				addr_rq = 1;
			end else addr_rq = 0;
		end 
		2'h2: begin
			if (addr_en) begin
				write_addr;
			end else begin
				awlen = 0;
				awuser_ap = 0;
				awuser_id = 0;
				awaddr = 0;
				awvalid = 0;
			end 
		end 
		2'h3: begin
		end
	endcase
end

always @(posedge clk) begin 
	case (state) 
		2'h1: begin
			if (result_en) begin
				_result <= result;
			end else ;
		end 
		2'h2: begin
			if (addr_en) begin
				_addr <= addr;
				cnt <= 0;
			end else ;
		end 
		2'h3: begin
			if (cnt != 4) begin
				if (write_start==1 || cnt == 0) begin
					write_data;
				end else if (cnt != 4) begin
					cnt <= cnt + 1;
					_addr <= _addr + 28'h000_0010;
				end else if (cnt == 4) begin
					cnt <= 0;
				end else ;
			end 
		end
	endcase
end

endmodule
