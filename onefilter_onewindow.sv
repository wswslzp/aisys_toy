//synopsys translate off
`timescale 1 ps/1 ps
//synopsys translate on
module onefilter_onewindow #
(
	parameter window_size = 3,
	parameter channel_size = 64
)
(
	input [31:0] img_window[window_size-1:0][window_size-1:0][channel_size-1:0], kernel[window_size-1:0][window_size-1:0][channel_size-1:0],
	input [window_size-1:0][window_size-1:0][channel_size-1:0]en,
	input clk, rst_n,
	output [31:0] conv_out
);
// compute the accumulator tree size, which (2**(i-1), 2**i]
function integer find_add_tree_size(input integer x);
	integer i;
	for (i = 0; i <= x; i = i + 1) begin
		if ((1 << (i-1)) < x && x <= (1 << i))
			find_add_tree_size = i;
	end
endfunction

// the total amount of the channels

localparam add_tree_size = find_add_tree_size(window_size*window_size),
					 add_num = 1 << add_tree_size;

wire [31:0] tmp_pout[window_size*window_size-1:0];
wire [31:0] acc_in[add_num-1:0];

genvar i;
generate
	localparam ks = window_size*window_size;
	for (i = 0; i < add_num; i++) begin : connect_acc
		if (i < ks) assign acc_in[i] = tmp_pout[i];
		else assign acc_in[i] = 32'b0;
	end 
endgenerate

// compute the output by the position
genvar r, c;
generate 
	for (r = 0; r < window_size; r++) begin : ofop_row
		for (c = 0; c < window_size; c++) begin : ofop_col
			onefilter_onepixel #(channel_size) ofop_unit 
			(
				.data(img_window[r][c]),
				.weight(kernel[r][c]),
				.en(en[r][c]),
				.clk(clk),
				.rst_n(rst_n),
				.accout(tmp_pout[r*window_size+c])
			);
		end 
	end 
endgenerate

float_acc #(add_num) facc 
(
	.din(acc_in),
	.clk(clk),
	.rst_n(rst_n),
	.dout(conv_out)
);

endmodule
