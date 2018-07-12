module matadd #
(
	parameter rsize = 2,
	parameter csize = 3
)
(
	input wire [rsize-1:0][csize-1:0][31:0] in1, in2,
	input wire clk, rst_n,
	output reg [rsize-1:0][csize-1:0][31:0] result,
	input en,
	output reg done
);

reg [rsize-1:0][csize-1:0][31:0] _in1, _in2;
reg [rsize-1:0][csize-1:0] _done;
wire [rsize-1:0][csize-1:0][31:0] _result;

always @(*) begin
	done = &_done;
end 

generate begin
	genvar i, j;
	for (i = 0; i < rsize; i++ ) begin
		for (j = 0; j < csize; j ++ ) begin
			always @(posedge clk, negedge rst_n) begin
				if (!rst_n || !en) begin 
					_in1[i][j] <= 0;
					_in2[i][j] <= 0;
				end 
				else begin 
					_in1[i][j] <= in1[i][j];
					_in2[i][j] <= in2[i][j];
				end 
			end 
			
			always @(posedge clk) begin
				if (_result[i][j] != result[i][j]) begin
					result[i][j] <= _result[i][j];
					_done[i][j] <= 1'b1;
				end else begin
					_done[i][j] <= 1'b0;
				end 
			end

			add fa
			(
				.a(in1[i][j]),
				.b(in2[i][j]),
				.clk(clk),
				.rst_n(rst_n),
				.out(_result[i][j])
			);
		end 
	end 
end 
endgenerate

endmodule
