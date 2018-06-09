module matmul #
(
	parameter left_size = 2,
	parameter middle_size = 3,
	parameter right_size = 4
)
(
	input wire [31:0] in1[left_size-1:0][middle_size-1:0],  
	input wire [31:0] in2[middle_size-1:0][right_size-1:0], 
	input wire clk ,rst_n,                            
	output wire [31:0] result[left_size-1:0][right_size-1:0]
);

wire [31:0] in2_T[right_size-1:0][middle_size-1:0];

generate
	genvar id, jd;
	for (id = 0; id < middle_size; id++) begin : row_t
		for (jd = 0; jd < right_size; jd++) begin : col_t
				assign in2_T[jd][id] = in2[id][jd];
		end 
	end
endgenerate

generate
	genvar i, j;
	for (i = 0; i < left_size; i++) begin : row
		for (j = 0; j < right_size; j++) begin : col
			vecmul #(
				.vsize(middle_size)
			) vm (
				.in1(in1[i]),
				.in2(in2_T[j]),
				.clk(clk),
				.rst_n(rst_n),
				.result(result[i][j])
			);
		end 
	end 
endgenerate

endmodule 
