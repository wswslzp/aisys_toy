module vecmul #
(parameter vsize = 4)
(
	input wire [vsize-1:0][31:0] in1, in2,
	input wire clk, rst_n,
	output reg [31:0] result,
	output reg done,
	input en
);

function int find_add_tree_size(input int kernel_size);
	int i;
	for (i = 1; i <= kernel_size; i++) begin
		if ((1 << (i-1)) < kernel_size && kernel_size <= (1 << i))
			find_add_tree_size = i;
	end
endfunction

localparam acc_size = (1 << find_add_tree_size(vsize));

reg [vsize-1:0][31:0] _in1, _in2;
wire [vsize-1:0][31:0] mul_tmp;
wire [acc_size-1:0][31:0] acc_in;
wire [31:0] acc_out;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		result <= 0;
	end else if (result != acc_out) begin
		result <= acc_out;
		done <= 1'b1; // done only hold on a clock-perior;
	end else done <= 1'b0;
end 

generate
	genvar j;
	for (j = 0; j < vsize; j++) begin
		always @(posedge clk, negedge rst_n) begin
			if (!rst_n) begin
				_in1[j] <= 0;
				_in2[j] <= 0;
			end else if (!en) begin
				_in1[j] <= 0;
				_in2[j] <= 0;
			end else begin
				_in1[j] <= in1[j];
				_in2[j] <= in2[j];
			end 
		end
	end
endgenerate
			
generate
	genvar k;
	for (k = 0; k < acc_size; k++) begin : mul_to_acc
		if (k < vsize) assign acc_in[k] = mul_tmp[k];
		else assign acc_in[k] = 32'b0;
	end 
endgenerate

generate
	genvar id;
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
	.dout(acc_out)
);


endmodule
