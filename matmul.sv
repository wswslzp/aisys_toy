module matmul #
(
	parameter left_size = 2,
	parameter middle_size = 3,
	parameter right_size = 4
)
(
	input wire [left_size-1:0][middle_size-1:0][31:0] in1,  
	input wire [middle_size-1:0][right_size-1:0][31:0] in2, 
	input wire clk ,rst_n,                            
	output wire [left_size-1:0][right_size-1:0][31:0] result
	input en,
	output done
);

reg [left_size-1:0][middle_size-1:0][31:0] _in1, _in2;  
wire [right_size-1:0][middle_size-1:0][31:0] in2_T;
wire [left_size*right_size-1:0] _done;

generate begin
	genvar i, j;
	for(i = 0; i < left_size; i++) begin
		for (j = 0; j < middle_size; j++) begin
			always (posedge clk, negedge rst_n) begin
				if (!rst_n || !en) begin
					_in1[i][j] <= 0;
				end else begin
					_in1[i][j] <= in1[i][j];
				end 
			end 
		end 
	end 
	for(i = 0; i < middle_size; i++) begin
		for(j = 0; j < right_size; j++) begin
			always (posedge clk, negedge rst_n) begin
				if (!rst_n || !en) begin
					_in2[i][j] <= 0;
				end else begin
					_in2[i][j] <= in2[i][j];
				end 
			end 
		end 
	end 
end 
endgenerate

generate
	genvar id, jd;
	for (id = 0; id < middle_size; id++) begin : row_t
		for (jd = 0; jd < right_size; jd++) begin : col_t
				assign in2_T[jd][id] = _in2[id][jd];
		end 
	end
endgenerate

generate begin
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
				.done(_done),
				.en(en)
			);
		end 
	end 
	assign done = &_done; // done only hold on a clock-perior;
end 
endgenerate

endmodule 
