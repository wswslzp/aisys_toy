module fully_connect #
(
	parameter batch_size = 1,
	parameter feature_size = 3,
	parameter bias_size = 2
)
(
	input wire [31:0] data[batch_size-1:0][feature_size-1:0],
	input wire [31:0] weight[feature_size-1:0][bias_size-1:0],
	input wire [31:0] bias[bias_size-1:0],
	input wire clk, rst_n, en,
	output wire [31:0] result[batch_size-1:0][bias_size-1:0],
	output reg result_valid
);


localparam weight_rsize = feature_size;
localparam weight_csize = bias_size;
localparam result_size = bias_size;

wire [31:0] mul_res[batch_size-1:0][result_size-1:0];
wire [31:0] bias_en[batch_size-1:0][bias_size-1:0];
wire [31:0] data_en[batch_size-1:0][feature_size-1:0];
wire [31:0] weight_en[weight_rsize-1:0][weight_csize-1:0];
//wire [31:0] bias_en[bias_size-1:0];
reg [31:0] _mul_res[batch_size-1:0][result_size-1:0];
reg _matmul_valid;
//reg [31:0] _result[batch_size-1:0][bias_size-1:0];
wire [31:0] result_tmp[batch_size-1:0][bias_size-1:0];

//assign data_en = en ? data : {(batch_size*feature_size){32'b0}};
//assign weight_en = en ? weight : {(weight_rsize*weight_csize){32'b0}};
//assign bias_en = en ? bias : {(bias_size){32'b0}};
//assign bias_tmp = {(batch_size){bias}};

always @(posedge clk) begin
	if (

generate 
	genvar i,j;
	for (i = 0; i < batch_size; i++)
		for (j = 0; j < feature_size; j++) 
			assign data_en[i][j] = en ? data[i][j] : 32'b0;
	
	for (i = 0; i < weight_rsize; i++) 
		for (j = 0; j < weight_csize; j++) 
			assign weight_en[i][j] = en ? weight[i][j] : 32'b0;
			
	for (i = 0; i < batch_size; i++)
		for (j = 0; j < bias_size; j++)
			assign bias_en[i][j] = en ? bias[j] : 32'b0;
	
endgenerate

matmul #(
	.left_size(batch_size),
	.middle_size(feature_size),
	.right_size(bias_size)
) mm (
	.in1(data_en),
	.in2(weight_en),
	.clk(clk),
	.rst_n(rst_n),
	.result(mul_res)
);

always @(posedge clk) begin
	if (_mul_res != mul_res ) begin
		_mul_res <= mul_res;
		_matmul_valid <= 1;
	end else begin
		_matmul_valid <= 0;
	end 
end 

matadd #(
	.rsize(batch_size),
	.csize(bias_size)
) ma (
	.in1(mul_res),
	.in2(bias_en & _matmul_valid),
	.clk(clk),
	.rst_n(rst_n),
	.result(result_tmp)
);
					
always @(posedge clk) begin
	if (result != result_tmp) begin
		result <= result_tmp;
		result_valid <= 1'b1;
	end else begin
		result_valid <= 1'b0;
	end 
end 

endmodule
