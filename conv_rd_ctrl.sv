module conv_rd_ctrl #
(parameter channel_size = 64,
 parameter img_size = 64,
 parameter window_size = 3,
 parameter repeat_time = 4, // burst len = 16, channel_size/16=4
 parameter word_len  =32,
 parameter width=32) // 
(
	input clk, rst_n,
	
	// from bus side
	input BusCrb_arready, // read addr ready
	input BusCrb_rvalid, 
	input BusCrb_rlast,
	input [3:0] BusCrb_rid,
	input [31:0] BusCrb_rdata,

	output reg CrbBus_arvalid,
	output reg [3:0] CrbBus_arusrid,
	output reg [3:0] CrbBus_arlen,
	output reg CrbBus_aruserap,
	output reg [27:0] CrbBus_araddr,
	
	// from conv_layer side
	output reg [channel_size*32-1:0] CrbCl_conv_img, CrbCl_conv_flt,
	output wire CrbCl_data_en, // indicate that the data is valid

	// from conv_ctrl side
	input CcCrb_initAddrEn,
	input [27:0] CcCrb_initAddr,
	output reg CrbCc_imgEnd,  // represent that all pixel of the image is read;
	output reg [27:0] CrbCc_imgEndAddr, // the last pixel's prime(first channel address;
	output reg last_pt,
	output [5:0] ptr, ptc,
	output pt_en
);

wire [27:0] __addr;
wire __addr_valid;
wire [5:0] out_pt_r, out_pt_c;
wire [3:0] out_pt_bias;
reg [5:0] out_img_edge;
wire img_end;
reg ca_rst_n, cnp_rst_n;
reg [5:0] in_pt_r, in_pt_c;
reg [3:0] in_pt_bias;
reg [5:0] in_img_edge;
wire [channel_size*32-1:0] conv_in;
reg in_en;
wire out_valid;

assign ptr = out_pt_r;
assign ptc = out_pt_c;
assign pt_en = out_valid;

// send the address computed by comp_addr to the bus/ddr3,
// and repeat reading 4 times data with 16 burst len composing of a pixel data
// with 64 channels;
conv_rd_bridge 
#(
	.channel_size(channel_size),
	.repeat_time(repeat_time),
	.width(width)
) u_conv_rd_bridge
(
	.clk(clk),
	.rst_n(rst_n),
	.rd_addr(__addr),
	.addr_ena(__addr_valid),
	.conv_in(conv_in),
	.in_valid(CrbCl_data_en),
	.arready(BusCrb_arready),
	.rvalid(BusCrb_rvalid),
	.rlast(BusCrb_rlast),
	.rid(BusCrb_rid),
	.rdata(BusCrb_rdata),
	.arvalid(CrbBus_arvalid),
	.aruser_id(CrbBus_arusrid),
	.aruser_ap(CrbBus_aruserap),
	.araddr(CrbBus_araddr),
	.arlen(CrbBus_arlen)
);

// compute the address based on the position of the point got from comp_nx_pt;
// the address is added by the initAddr got from conv_ctrl;
comp_addr #
(
	.window_size(window_size),
	.word_len(word_len)
) u_comp_addr
(
	.initAddr(CcCrb_initAddr),    
	.initAddrEn(CcCrb_initAddrEn),
	.ptr(out_pt_r),
	.ptc(out_pt_c),
	.clk(clk),
	.rst_n(ca_rst_n),
	.pt_bias(out_pt_bias),
	.img_edge(out_img_edge),
	.addr(__addr),
	.addr_valid(__addr_valid)
);

// compute the next point position, and indicate if the input image/filter is
// in the end; 
comp_nx_pt #
(.window_size(window_size)) u_comp_nx_pt
(
	.clk(clk), 
	.rst_n(cnp_rst_n),
	.in_en(in_en),
	.in_pt_r(in_pt_r),
	.in_pt_c(in_pt_c),
	.in_pt_bias(in_pt_bias),
	.in_img_edge(in_img_edge),
	.out_pt_r(out_pt_r),
	.out_pt_c(out_pt_c),
	.out_img_edge(out_img_edge),
	.out_pt_bias(out_pt_bias),
	.out_valid(out_valid),
	.img_end(img_end),
	.last_pt(last_pt)

);

// may change
always @(posedge clk) begin
	if (CrbCl_data_en) begin
		if (CcCrb_initAddr[27] == 0) begin
			CrbCl_conv_img <= conv_in; // image address begin with 0
		end else begin
			CrbCl_conv_flt <= conv_in; // filter address begin with 1
		end 
	end else ;
end 

always @(posedge clk) begin
	if (last_pt) begin
		CrbCc_imgEnd <= 1'b1;
		CrbCc_imgEndAddr <= __addr;
	end else begin
		CrbCc_imgEnd <= 1'b0;
		CrbCc_imgEndAddr <= 0;
	end 
end 

// to compute the position and the addr
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		{in_pt_bias, in_pt_r, in_pt_c} <=  0;
		cnp_rst_n <= 1'b0;

	end else if (CrbCl_data_en) begin
		if (img_end) begin
			cnp_rst_n <= 1'b1;
			{in_pt_bias, in_pt_r, in_pt_c} <=  0;

		end 
		else begin
			in_pt_bias <= out_pt_bias;
			in_pt_r <= out_pt_r;
			in_pt_c <= out_pt_c;
			in_img_edge <= out_img_edge;
			in_en <= 1'b1;
		end 
	end else begin
		cnp_rst_n <= 1'b1;
		in_en <= 1'b0;
	end 
end 
// to sent the read address
always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		ca_rst_n <= 1'b0;
	end else begin
		if (out_valid) begin
			ca_rst_n <= 1'b1;
		end else ca_rst_n <= 1'b0;
	end 
end 
endmodule
