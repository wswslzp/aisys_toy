module maxpooling_4(
   input [31:0] in1,in2,in3,in4,max_out,
	 input clk,rst_n, 
	 output wire valid,
	 input wire en
);

wire valid1, valid2, valid3;
wire [31:0] max_1,max_2;

assign en3 = valid1 & valid2;

maxpooling_2 max1(
    .in1(in1),.in2(in2),.clk(clk),.rst_n(rst_n),
	 .max_out(max_1), .valid(valid1), .en(en)
);

maxpooling_2 max2(
    .in1(in3),.in2(in4),.clk(clk),.rst_n(rst_n),
	 .max_out(max_2), .valid(valid1), .en(en)
);

maxpooling_2 max_final(
    .in1(max_1),.in2(max_2),.clk(clk),.rst_n(rst_n), .en(valid3),
	 .max_out(max_out), .valid(valid)
);

endmodule
