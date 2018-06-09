module uart_divfreq # // 25div, 50mbps to 2mbps
(parameter div=25)
(
	input clk_in,
	output reg clk_out,
	input rst_n
);
reg [4:0] cnt1, cnt2; // 2 counter
reg c1, c2;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		cnt1 <= 0;
		cnt2 <= 0;
		c1 <= 0;
		c2 <= 0;
		clk_out <= 0;
	end else ;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) cnt1 <= 5'b0;
	else begin
		if (cnt1 != 5'd24) begin
			cnt1 <= cnt1 + 1;
		end  else begin
			cnt1 <= 5'h0;
		end 
	end 
end 

always @(negedge clk, negedge rst_n) begin
	if (!rst_n) cnt2 <= 5'b0;
	else begin
		if (cnt2 != 5'd24) begin
			cnt2 <= cnt2 + 1;
		end  else begin
			cnt2 <= 5'h0;
		end 
	end 
end 

always @* begin
	c1 = cnt1 < 5'd12 ? 1 : 0;
	c2 = cnt2 < 5'd12 ? 1 : 0;
	clk_out = c1 || c2;
end 

endmodule 
