module fully_connect #
(
	parameter batch_size = 1,
	parameter feature_size = 3,
	parameter bias_size = 2
)
(
	input wire [batch_size-1:0][feature_size-1:0][31:0] data,
	input wire [feature_size-1:0][bias_size-1:0][31:0] weight,
	input wire [bias_size-1:0][31:0] bias,
	input wire clk, rst_n, data_en, weight_en, bias_en,
	output wire [batch_size-1:0][bias_size-1:0][31:0] result,
	output reg result_valid,
	output reg bias_rq
);

localparam weight_rsize = feature_size;
localparam weight_csize = bias_size;
localparam result_size = bias_size;

reg mul_en, add_en;
wire [batch_size-1:0][result_size-1:0][31:0] mul_res;
reg [batch_size-1:0][bias_size-1:0][31:0] _bias;
reg [batch_size-1:0][feature_size-1:0][31:0] _data;
reg [weight_rsize-1:0][weight_csize-1:0][31:0] _weight;
reg [batch_size-1:0][result_size-1:0][31:0] _mul_res;
wire matmul_done, matadd_done;
wire [batch_size-1:0][bias_size-1:0][31:0] result_tmp;

reg [3:0] state, nstate;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) state <= 0;
	else state <= nstate;
end 

always @(*) begin
	case (state) 
		4'h0: nstate = rst_n ? 4'h1 : 4'h0;
		4'h1: nstate = data_en & weight_en ? 4'h2 : 4'h1; // Data and weight were designed to recieve spontaneously instead sequentially;
		4'h2: nstate = 4'h3; // After data and weight has been received, make a request signal to 'fc_rd_ctrl' to ask for 'bias';
		4'h3: nstate = bias_en & matmul_done ? 4'h4 : 4'h3; // When bias input is enable and 'matmul' sends a signal 'matmul_done', the process will go to matrix additon;
		4'h4: nstate = matadd_done ? 4'h1 : 4'h4;
		default: nstate = 4'h0;
	endcase
end

generate 
	genvar i,j;
	for (i = 0; i < batch_size; i++) begin
		for (j = 0; j < feature_size; j++) begin
			always @(posedge clk) begin
				if (state == 4'h1) begin
					if (data_en) begin
						_data[i][j] <= data[i][j];
					end else ;
				end else;
			end 
		end
	end

	for (i = 0; i < weight_rsize; i++) begin
		for (j = 0; j < weight_csize; j++) begin
			always @(posedge clk) begin
				if (state == 4'h1) begin
					if (data_en) begin
						_weight[i][j] <= weight[i][j];
					end else ;
				end else;
			end 
		end
	end
			
	for (i = 0; i < batch_size; i++) begin
		for (j = 0; j < bias_size; j++) begin
			always (posedge clk) begin
				if (state == 4'h3) begin 
					if (bias_en) begin
						_bias[i][j] <= bias[i];
					end else ;
				end else;
			end 
		end
	end

endgenerate

always @(posedge clk) begin
	if (state == 4'h2) begin
		bias_rq <= 1'b1;
		mul_en <= 1'b1;
	end else begin
		bias_rq <= 1'b0;
		mul_en <= 1'b0;
	end 
end 

always @(posedge clk) begin
	if (state == 4'h3 && matmul_done == 1 && bias_en == 1) add_en <= 1'b1;
	else add_en <= 1'b0;
end 

matmul #(
	.left_size(batch_size),
	.middle_size(feature_size),
	.right_size(bias_size)
) mm (
	.in1(_data),
	.in2(_weight),
	.clk(clk),
	.rst_n(rst_n),
	.result(mul_res)
	.en(mul_en),
	.done(matmul_done)
);

always @(posedge clk) begin
	if (matmul_done) begin
		_mul_res <= mul_res;
	end else ;
end 

matadd #(
	.rsize(batch_size),
	.csize(bias_size)
) ma (
	.in1(_mul_res),
	.in2(_bias),
	.en(add_en),
	.clk(clk),
	.rst_n(rst_n),
	.done(matadd_done),
	.result(result_tmp)
);
					
always @(posedge clk) begin
	if (matadd_done) begin
		result <= result_tmp;
		result_valid <= 1'b1;
	end else begin
		result_valid <= 1'b0;
	end 
end 

endmodule
