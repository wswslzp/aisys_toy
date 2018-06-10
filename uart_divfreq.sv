module uart_divfreq  // 25div, 50mbps to 2mbps
(
	input clki,
	input rst_n,
	output reg clko
);

reg [4:0] cnt1, cnt2;
reg c1, c2;


always @(posedge clki, negedge rst_n) begin
	if (!rst_n) begin
		clko <= 0;
		c1 <= 0;
		c2 <= 0;
	end else ;
end 

always @(posedge clki, negedge rst_n) begin
	if (!rst_n) cnt1 <= 5'b0;
	else if (cnt1 == 5'd24) begin
		cnt1 <= 5'b0;
	end else begin
		cnt1 <= cnt1 + 1;
	end 
end 

always @(negedge clki, negedge rst_n) begin
	if (!rst_n) cnt2 <= 5'b0;
	else if (cnt2 == 5'd24) begin
		cnt2 <= 5'b0;
	end else begin
		cnt2 <= cnt2 + 1;
	end 
end 

always @* begin
	c1 = cnt1 < 5'd12 ? 1 : 0;
	c2 = cnt2 < 5'd12 ? 1 : 0;
	clko = c1 || c2;
end 
	

endmodule 
