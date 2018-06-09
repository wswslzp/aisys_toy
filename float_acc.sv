module float_acc #(parameter add_num = 4)
(
	input [31:0] din[add_num-1:0],
	input clk, rst_n,
	output wire [31:0] dout
);

reg _dout;

generate 
	if (add_num >= 2) begin : acc 
		wire [31:0] s1, s2;
		float_acc #(.add_num(add_num/2)) u1
		(
			.din(din[add_num/2-1:0]),
			.clk(clk),
			.rst_n(rst_n),
			.dout(s1)
		);
		float_acc #(.add_num(add_num/2)) u2
		(
			.din(din[add_num-1:add_num/2]),
			.clk(clk),
			.rst_n(rst_n),
			.dout(s2)
		);
		add eu
		(
			.a(s1),
			.b(s2),
			.clk(clk),
			.rst_n(rst_n),
			.out(dout)
		);
	end else if (add_num <= 1) begin
		always @(posedge clk, negedge rst_n) begin
			if (!rst_n) _dout <= 'h0;
			else _dout <= din;
		end 
		assign dout = _dout;
	end else begin
		add base
		(
			.a(din[0]),
			.b(din[1]),
			.clk(clk),
			.rst_n(rst_n),
			.out(dout)
		);
	end 
	
endgenerate

endmodule 
