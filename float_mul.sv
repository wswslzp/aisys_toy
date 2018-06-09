//synopsys translate off
`timescale 1 ps/1 ps
//synopsys translate on
module float_mul
(
	input [31:0] in1, in2,
	input clk, rst_n,	
	output [31:0] result,
	output reg valid
);

wire [31:0] in1, in2;
wire [31:0] result;
wire sgn1, sgn2;
wire [7:0] exp1, exp2;
wire [22:0] mat1, mat2;
wire [47:0] product_tmp;
wire [23:0] m1, m2;
wire [22:0] mat3;

reg sgn3;
reg [7:0] exp3;

reg [47:0] product;

//synopsys translate off
initial begin
	sgn3 = 1'b0;
	exp3 = 8'b0;
	product = 48'b0;
end 
//synopsys translate on

assign {sgn1, exp1, mat1} = in1;
assign {sgn2, exp2, mat2} = in2;
//assign result = {sgn3, exp3, mat3};
assign m1 = {1'b1, mat1};
assign m2 = {1'b1, mat2};
assign result = { sgn3, exp3, mat3 };
assign mat3 = product[22] ? {product[45:24], 1'b1}
								  : product[45:23];

//mul24 mul1
//(
//	.dataa(m1),
//	.datab(m2),
//	.clk(clk),
//	.rst_n(rst_n),
//	.result(product_tmp)
//);
mul24 u_mul24
(
	.CE(1'b1),
	.RST(~rst_n),
	.CLK(clk),
	.A(m1),
	.B(m2),
	.P(product_tmp)
);

always @ (posedge clk)
begin
	if (rst_n)
		sgn3 <= sgn1 ^ sgn2;
	else
		sgn3 <= 1'b0;
end

always @ (posedge clk)
begin
	if (rst_n)
	begin
		if ( product_tmp[47] )
			exp3 <= exp1 + exp2 - 8'd126;
		else
			exp3 <= exp1 + exp2 - 8'd127;
	end
	else 
		exp3 <= 8'b0;		
end

always @ (posedge clk)
begin
	if ( product_tmp[47] )
		product <= product_tmp >> 1;
	else
	begin
		product <= product_tmp;
	end
end

//always @ (*)
//begin 
//	if ( product[22] )
//		mat3 = {product[45:24], 1'b1};
//	else 
//		mat3 = product[45:23];
//end



endmodule 		
