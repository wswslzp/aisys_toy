module comp_nx_pt #
(parameter window_size=3)
(
	input clk, rst_n, 
	input [5:0] in_pt_r, in_pt_c, in_img_edge, // image prime point position, and the size of the image
	input [3:0] in_pt_bias,
	input in_en,
	output reg [5:0] out_pt_r, out_pt_c, out_img_edge,
	output reg [3:0] out_pt_bias,
	output reg img_end, // represents that current conv_window is moved to the end of the image;
	output reg out_valid,
	output reg last_pt
);

always @(posedge clk) begin
	if (img_end && in_pt_bias == 8) begin
		last_pt <= 1'b1;
	end else last_pt <= 1'b0;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		{out_pt_r, out_pt_c, out_img_edge, out_pt_bias, img_end} <= 0;
	end else if (in_en) begin
		if (in_pt_bias != 4'h8) begin
			out_pt_r <= in_pt_r;
			out_pt_c <= in_pt_c;
			out_pt_bias <= in_pt_bias + 4'b1;
			out_valid <= 1'b1;
		end else begin
			if (in_pt_c+6'h2 != in_img_edge) begin
				out_pt_r <= in_pt_r;
				out_pt_c <= in_pt_c+window_size;
				out_pt_bias <= 0;
				out_valid <= 1'b1;
			end else begin
				if (in_pt_r+6'h2 == in_img_edge) begin
					img_end <= 1'b1;
					{out_pt_r, out_pt_c, out_pt_bias} <= 0;
					out_img_edge <= in_img_edge-6'h2;
					out_valid <= 1'b1;
				end else begin
					out_pt_r <= in_pt_r+window_size;
					out_pt_c <= 0;
					out_pt_bias <= 0;
					out_valid <= 1'b1;
				end 
			end 
		end 
	end else ;
end 

endmodule
