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
	output wire [31:0] result[batch_size-1:0][bias_size-1:0]
);


localparam weight_rsize = feature_size;
localparam weight_csize = bias_size;
localparam result_size = bias_size;

wire [31:0] res_tmp[batch_size-1:0][result_size-1:0];
wire [31:0] bias_en[batch_size-1:0][bias_size-1:0];
wire [31:0] data_en[batch_size-1:0][feature_size-1:0];
wire [31:0] weight_en[weight_rsize-1:0][weight_csize-1:0];
//wire [31:0] bias_en[bias_size-1:0];

//assign data_en = en ? data : {(batch_size*feature_size){32'b0}};
//assign weight_en = en ? weight : {(weight_rsize*weight_csize){32'b0}};
//assign bias_en = en ? bias : {(bias_size){32'b0}};
//assign bias_tmp = {(batch_size){bias}};

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
	.result(res_tmp)
);

matadd #(
	.rsize(batch_size),
	.csize(bias_size)
) ma (
	.in1(res_tmp),
	.in2(bias_en),
	.clk(clk),
	.rst_n(rst_n),
	.result(result)
);
					

endmodule