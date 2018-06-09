//synopsys translate off
`timescale 1 ps/1 ps
//synopsys translate on
module onefilter_onepixel #
(parameter channel_num = 64)
(
	input wire [31:0] data[channel_num-1:0], weight[channel_num-1:0],
	input wire [channel_num-1:0] en,
	input wire clk, rst_n,
	output wire [31:0] accout
);
// This is the total num of channels
wire [31:0] tmp_wire[channel_num-1:0], data_w[channel_num-1:0], weight_w[channel_num-1:0];

// Instantial the accumulator by specific channel_num, 
// which accumulates the output of the convolution 
float_acc # (
	.add_num(channel_num)
) facc (
	.din(tmp_wire),
	.clk(clk),
	.rst_n(rst_n),
	.dout(accout)
);

// Generate automaticly the assign block
genvar ens_i;
generate 
	for (ens_i = 0; ens_i < channel_num; ens_i = ens_i + 1) begin : ens
		assign { data_w[ens_i], weight_w[ens_i] } = en[ens_i] ? {data[ens_i], weight[ens_i]} : 64'b0;
	end
endgenerate

// Generate automaticly the float_mul instances
genvar mul_i;
generate 
	for (mul_i = 0; mul_i < channel_num; mul_i = mul_i + 1) begin : multiply
		wire [31:0] y;
		float_mul fm
		(
			.in1(data_w[mul_i]),
			.in2(weight_w[mul_i]),
			.clk(clk),
			.rst_n(rst_n),
			.result(y)
		);
		assign tmp_wire[mul_i] = y;
	end 
endgenerate 

endmodule 