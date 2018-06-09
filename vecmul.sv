module vecmul #
(parameter vsize = 4)
(
	input wire [31:0] in1[vsize-1:0], in2[vsize-1:0],
	input wire clk, rst_n,
	output wire [31:0] result
);

function int find_add_tree_size(input int kernel_size);
	int i;
	for (i = 1; i <= kernel_size; i++) begin
		if ((1 << (i-1)) < kernel_size && kernel_size <= (1 << i))
			find_add_tree_size = i;
	end
endfunction

localparam acc_size = (1 << find_add_tree_size(vsize));

wire [31:0] mul_tmp[vsize-1:0];
wire [31:0] acc_in[acc_size-1:0];

generate
	genvar i;
	for (i = 0; i < acc_size; i++) begin : mul_to_acc
		if (i < vsize) assign acc_in[i] = mul_tmp[i];
		else assign acc_in[i] = 32'b0;
	end 
endgenerate

genvar id;
generate
	for (id = 0; id < vsize; id++) begin : mul
		float_mul fm
		(
			.in1(in1[id]),
			.in2(in2[id]),
			.clk(clk),
			.rst_n(rst_n),
			.result(mul_tmp[id])
		);
	end 
endgenerate

float_acc #(
	.add_num(acc_size)
) facc (
	.din(acc_in),
	.clk(clk),
	.rst_n(rst_n),
	.dout(result)
);


endmodule