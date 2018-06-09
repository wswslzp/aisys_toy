module maxpool #
(parameter channel_size=64)
(
	// from the system 
	input clk, rst_n,
	
	// from the pool_rd_bridge
	input [channel_size-1:0][31:0] in1,
	input [channel_size-1:0][31:0] in2,
	input [channel_size-1:0][31:0] in3,
	input [channel_size-1:0][31:0] in4,
	input in_en,

	// from the pool_wr_bridge
	output [channel_size-1:0][31:0] out,
	output  valid
);

reg [channel_size-1:0][31:0] _in1, _in2,  _in3, _in4;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n || !in_en) begin
		_in1 <= 0;
		_in2 <= 0;
		_in3 <= 0;
		_in4 <= 0;
	end else begin
		_in1 <= in1;
		_in2 <= in2;
		_in3 <= in3;
		_in4 <= in4;
	end 
end 


genvar i;
generate 
for (i = 0; i < channel_size; i++) begin : pu
	wire [channel_size-1:0] pu_valid;
	assign valid = pu_valid;
	maxpooling_4 u_maxpool_4
	(
		.en(in_en),
		.in1(_in1[i]),
		.in2(_in2[i]),
		.in3(_in3[i]),
		.in4(_in4[i]),
		.clk(clk),
		.rst_n(rst_n),
		.max_out(out[i]),
		.valid(pu_valid[i])
	);
end 
endgenerate

endmodule
