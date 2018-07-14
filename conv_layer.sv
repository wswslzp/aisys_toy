module conv_layer #
(
	parameter window_size = 3,
	parameter channel_size = 8,
	parameter filter_total = 8
)
(
	input wire [window_size-1:0][window_size-1:0][channel_size-1:0][31:0] img_window,
	input wire [filter_total-1:0][window_size-1:0][window_size-1:0][channel_size-1:0][31:0] filters,
	input wire clk, rst_n,
	input wire  en, // when en == 0, all result == 0!
	output wire [filter_total-1:0][31:0] conv_outs,
	output reg conv_outs_valid
);

//wire [kernel_size*channel_size*32-1 : 0] img_window;
//wire [filter_total*kernel_size*channel_size*32-1 : 0] filters;
//wire clk, rst_n;
//wire [filter_total*kernel_size*channel_size-1 : 0] en;
//wire [filter_total*32-1 : 0] conv_outs;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) conv_outs_valid <= 1'b0;
	else if (!conv_outs) conv_outs_valid <= 1'b1;
end 

genvar fi;
generate
	for (fi = 0; fi < filter_total; fi++) begin : filter
//		wire [31:0] y;
//		assign conv_outs[fi] = y;
		onefilter_onewindow # (
			.window_size(window_size),
			.channel_size(channel_size)
		) ofow (
			.img_window(img_window),
			.kernel(filters[fi]),
			.en(en),
			.clk(clk),
			.rst_n(rst_n),
			.conv_out(conv_outs[fi])
		);
	end
endgenerate

endmodule 
