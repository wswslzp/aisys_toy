module maxpooling_2(
  input in1,in2,clk,rst_n,en, 
	output reg [31:0] max_out,
	output reg valid
);

wire [31:0] in1,in2;
wire [31:0] max_out;
wire sgn1,sgn2;
wire [7:0] exp1,exp2;
wire [22:0] mat1,mat2;
reg [31:0] max;
reg [1:0] flag;

assign {sgn1, exp1, mat1} = in1;
assign {sgn2, exp2, mat2} = in2;


always @( posedge clk, negedge rst_n) begin
  if(!rst_n || !en) flag <= 0;
	else begin
	  if( sgn1 != sgn2 ) begin
			if( sgn1 != 0 ) flag <= 2'b10;
			else flag <= 2'b01;
		end else begin//sgn1 ==sgn2
			if( sgn1 ) begin
				if( exp1 > exp2 ) flag <= 2'b10;
				else if( exp1 < exp2 ) flag <= 2'b01;
				else begin
				  if( mat1 >= mat2) flag <= 2'b10;
					else flag <= 2'b01;
				end
			end else begin
				if( exp1 > exp2 ) flag <= 2'b01;
				else if( exp1 < exp2 ) flag <= 2'b10;
				else begin
					if( mat1 >= mat2 ) flag <= 2'b01;
				  else flag <= 2'b10;
				end
			end
		end
	end
end						      
						  
always @( posedge clk ) begin
	if (flag == 2'b01) begin
		valid <= 1'b1;
		max <= in2;
	end else if (flag == 2'b10) begin
		max <= in1;
		valid <= 1'b1;
	end else valid <= 1'b0;
end 
	//if (flag == 2'b01) begin
	//	valid <= 1;
	//  max <= in2;
	//end 
	//else if( flag == 2'b10 ) begin
	//  max <= in1;
	//	valid <= 1;
	//else begin
	////  max <= 0;//错误
	////	valid <= 0;
	//
	//end 

assign max_out = max;

endmodule						  
						  
