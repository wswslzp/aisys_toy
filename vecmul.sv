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
	genvar i;
	for (i = 0; i < vsize; i++) begin
		always @(posedge clk, negedge rst_n) begin
			if (!rst_n) begin
				_in1[i] <= 0;
				_in2[i] <= 0;
			end else if (!en) begin
				_in1[i] <= 0;
				_in2[i] <= 0;
			end else begin
				_in1[i] <= in1[i];
				_in2[i] <= in2[i];
			end 
		end
	end
endgenerate
			
generate
	genvar i;
	for (i = 0; i < acc_size; i++) begin : mul_to_acc
		if (i < vsize) assign acc_in[i] = mul_tmp[i];
		else assign acc_in[i] = 32'b0;
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
