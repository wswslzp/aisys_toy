module seri_acc
(
	input clk, rst_n,
	input [31:0] data,
	input en, // input data enable

	output reg [31:0] result,
	output reg res_valid
);

reg [3:0] cnt;
reg [31:0] _data;
reg [31:0] _result;
wire [31:0] b;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) _data <= 0;
	else _data <= data;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) result <= 0;
	else if (cnt == 4'h9) begin
		result <= _result;
		res_valid <= 1'b1;
	end 
	else result <= 0;
end 

assign b = _result;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) cnt <= 4'h0;
	else begin
		if (cnt == 4'h9) begin
			cnt <= 4'h0;
		end else if (en) begin
			cnt <= cnt + 1;
		end else ;
	end 
end 

add u1
(
	.a(_data),
	.b(b),
	.clk(clk),
	.rst_n(rst_n),
	.out(_result)
);

endmodule 
