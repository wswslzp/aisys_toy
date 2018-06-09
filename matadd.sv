module matadd #
(
	parameter rsize = 2,
	parameter csize = 3
)
(
	input wire [31:0] in1[rsize-1:0][csize-1:0], in2[rsize-1:0][csize-1:0],
	input wire clk, rst_n,
	output wire [31:0] result[rsize-1:0][csize-1:0]
);

genvar i, j;
generate
	for (i = 0; i < rsize; i = i + 1) begin	: row 
		for (j = 0; j < csize; j = j + 1) begin : col
			add fa
			(
				.a(in1[i][j]),
				.b(in2[i][j]),
				.clk(clk),
				.rst_n(rst_n),
				.out(result[i][j])
			);
		end 
	end 
endgenerate

endmodule
