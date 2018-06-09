module conv_wr_bridge #
(parameter width = 32)
(
	// from system
	input clk, 
	input rst_n,
	// from conv_layer side
	input [31:0] result,
	input result_en, 

	// from the conv_ctrl side
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

reg [31:0] _data;
reg [27:0] _addr;
reg [5:0] _addr_bias;
wire [31:0] _result;
reg [31:0] accout;
wire res_valid; 
reg [3:0] cnt;

seri_acc u_seri_acc
(
	.clk(clk),
	.rst_n(rst_n),
	.data(_data),
	.en(result_en),
	.result(_result),
	.res_valid(res_valid)
);

//always @(posedge clk, negedge rst_n) begin
//	if (!rst_n) begin
//		_data <= 0;
//	end else if (result_en) begin
//		_data <= result;
//	end else ;
//end 

always @(posedge clk) begin
	if (addr_en) begin
		_addr <= addr;
		_addr_bias <= addr_bias;
	end 
	else ;
end 

always @(posedge clk) begin
	if (res_valid) begin
		accout <= _result;
	end else accout <= 0;
end 

always @(posedge clk) begin
	if (addr_en) begin
		addr_rq <= 1'b0;
		if (awready) begin
			awuser_ap <= 1'b1;
			awuser_id <= 4'h2;
			awaddr <= _addr + {22'b0, _addr_bias};
			awlen <= 4'h1;
			awvalid <= 1'b1;
		end 
		else begin 
			awvalid <= 1'b0;
			awuser_ap <= 1'b0;
			awuser_id <= 4'h0;
			awaddr <= 28'h0;
			awlen <= 4'h0;
		end 
	end 
	else begin 
		addr_rq <= 1'b1;
		awvalid <= 1'b0;
		awuser_ap <= 1'b0;
		awuser_id <= 4'h0;
		awaddr <= 28'h0;
		awlen <= 4'h0;
	end 
end 

always @(posedge clk) begin
	if (wready && 4'h2 == wuser_id) begin
		cnt <= 4'h1;
	end else if (cnt < 4'h2) cnt <= cnt + 1;
	else cnt <= 0;
end 

always @(posedge clk) begin
	if (cnt == 4'h2) begin 
		wdata <= accout;
		wstrb <= 4'hf;
	end else begin 
		wdata <= 32'h0;
		wstrb <= 4'h0;
	end 
end 

endmodule
