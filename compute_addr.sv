module comp_addr #
(parameter window_size = 3, // the window's scale, e.g. 3x3
 parameter word_len    = 32) // the ddr3's word length e.g. 32bit
(
	input [27:0] initAddr,
	input initAddrEn,
	input [5:0] ptr, ptc,
	input [3:0] pt_bias,
	input [5:0] img_edge,
	input clk, rst_n,
	output reg [27:0] addr,
	output reg addr_valid
);

reg [1:0] bias_m, bias_d;

generate 
if (window_size == 2) begin
	always @* begin
		bias_m = bias % 2;
		bias_d = bias / 2;
	end 
end
endgenerate

generate 
if (window_size == 3) begin
	// lookup table for x mod 3
	always @* begin
		case (pt_bias)
			4'h0, 4'h3, 4'h6: bias_m = 2'h0;
			4'h1, 4'h4, 4'h7: bias_m = 2'h1;
			4'h2, 4'h5, 4'h8: bias_m = 2'h2;
			default: bias_m = 2'h0;
		endcase
	end

	// lookup table for x div 3
	always @* begin
		case (pt_bias)
			4'h0, 4'h1, 4'h2: bias_d = 2'h0;
			4'h3, 4'h4, 4'h5: bias_d = 2'h1;
			4'h6, 4'h7, 4'h8: bias_d = 2'h2;
			default: bias_d = 2'h2;
		endcase
	end 
end
endgenerate

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		addr <= 0;
		addr_valid <= 0;
	end else if (initAddrEn) begin
		addr <= initAddr + ((ptr + bias_d) * (img_edge+1) + (ptc + bias_m)) * 64*32/word_len; 
		addr_valid <= 1;
	end else begin
		addr <= addr + ((ptr + bias_d) * (img_edge+1) + (ptc + bias_m)) * 64*32/word_len; 
		addr_valid <= 1;
	end 
end 

endmodule
