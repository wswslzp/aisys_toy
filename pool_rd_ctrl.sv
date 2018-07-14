module pool_rd_ctrl #
(parameter channel_size=64,
 parameter window_size=2,
 parameter word_len=32)
(
	input clk, rst_n,
	// from bus 
	input BusPrb_arready, // read addr ready
	input BusPrb_rvalid, 
	input BusPrb_rlast,
	input [3:0] BusPrb_rid,
	input [31:0] BusPrb_rdata,

	output reg PrbBus_arvalid,
	output reg [3:0] PrbBus_arusrid,
	output reg [3:0] PrbBus_arlen,
	output reg PrbBus_aruserap,
	output reg [27:0] PrbBus_araddr,
	// from maxpool
	output reg [channel_size*32-1:0] in1, in2, in3, in4,
	output reg PrbMp_pool_en,
	//from pool_ctrl
	input PcPrb_initAddrEn,
	input [27:0] PcPrb_initAddr,
	output reg PrbPc_imgEnd,  // represent that all pixel of the image is read;
	output reg [27:0] PrbPc_imgEndAddr, // the last pixel's prime(first channel address;
	//output reg last_pt
	output [5:0] ptc, ptr,
	output pt_en
);

wire [27:0] __addr;
wire __addr_valid;
wire [5:0] out_pt_r, out_pt_c;
wire [3:0] out_pt_bias;
reg [5:0] out_img_edge;
wire img_end;
wire last_pt;
reg ca_rst_n, cnp_rst_n;
reg [5:0] in_pt_r, in_pt_c;
reg [3:0] in_pt_bias;
reg [5:0] in_img_edge;
wire [channel_size*32-1:0] pool_in; 
reg in_en;
wire pool_in_valid;
reg [1:0] pool_in_buf_cnt;
reg [4*channel_size*32-1:0] pool_in_buf;
wire out_valid;

assign ptr = out_pt_r;
assign ptc = out_pt_c;
assign pt_en = out_valid;

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

comp_addr #
(
	.window_size(window_size),
	.word_len(word_len)
) u_comp_addr
(
	.initAddr(PcPrb_initAddr),
	.initAddrEn(PcPrb_initAddrEn),
	.ptr(out_pt_r),
	.ptc(out_pt_c),
	.clk(clk),
	.rst_n(ca_rst_n),
	.pt_bias(out_pt_bias),
	.img_edge(out_img_edge),
	.addr(__addr),
	.addr_valid(__addr_valid)
);

pool_rd_bridge 
#(
	.channel_size(channel_size),
	.repeat_time(4),
	.width(32)
) u_pool_rd_bridge
(
	.clk(clk),
	.rst_n(rst_n),
	.rd_addr(__addr),
	.addr_ena(__addr_valid),
	.pool_in(pool_in),
	.in_valid(pool_in_valid),
	.arready(BusPrb_arready),
	.rvalid(BusPrb_rvalid),
	.rlast(BusPrb_rlast),
	.rid(BusPrb_rid),
	.rdata(BusPrb_rdata),
	.arvalid(PrbBus_arvalid),
	.aruser_id(PrbBus_arusrid),
	.aruser_ap(PrbBus_aruserap),
	.araddr(PrbBus_araddr),
	.arlen(PrbBus_arlen)
);

always @(posedge clk) begin
	if (pool_in_valid && pool_in_buf_cnt != 2'b0) begin
		pool_in_buf <= {pool_in_buf[4*channel_size*32-1:3*channel_size*32], pool_in};
		pool_in_buf_cnt <= pool_in_buf_cnt + 1;
		PrbMp_pool_en <= 0;
		{in1, in2, in3, in4} <= 0;
	end else if (pool_in_buf_cnt == 2'b0) begin
		pool_in_buf <= {pool_in_buf[4*channel_size*32-1:3*channel_size*32], pool_in};
		pool_in_buf_cnt <= pool_in_buf_cnt + 1;
		PrbMp_pool_en <= 1;
		{in1, in2, in3, in4} <= pool_in_buf;
	end else ;
end 

always @(posedge clk) begin
	if (last_pt) begin
		PrbPc_imgEnd <= 1'b1;
		PrbPc_imgEndAddr <= __addr;
	end else begin
		PrbPc_imgEnd <= 1'b0;
		PrbPc_imgEndAddr <= 0;
	end 
end

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		{in_pt_bias, in_pt_r, in_pt_c} <=  0;
		cnp_rst_n <= 1'b0;

	end else if (PrbMp_pool_en) begin
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
