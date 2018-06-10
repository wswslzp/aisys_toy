module conv_unit #
(parameter width = 32,
 parameter window_size = 3,
 parameter channel_size = 64,
 parameter filter_total = 64)
(
	// from the system 
	input clk, rst_n,
	// from the state control machine
	input conv_start,
	output conv_end,
	input [27:0] conv_init_addr,
	input conv_init_addr_en,
	// control from control machine
	input link_write,
	input link_read,

	// bus side 
	inout [width-1:0] data, // data bus
	output reg [27:0] addr, // addr bus
	// read 
	input arready,
	input rvalid,
	input rlast,
	input [3:0] rid,
	output arvalid,
	output [3:0] aruser_id,
	output [3:0] arlen,
	output aruser_ap,
	//write
	output awuser_ap,
	output [3:0] awuser_id,
	output awlen,
	output awvalid,
	input awready,
	output [width/8-1:0] wstrb,
	input wready,
	input [3:0] wuser_id,
	input wuser_last

);

wire [channel_size-1:0][31:0] CrbCl_conv_img, CrbCl_conv_flt;
wire CrbCl_data_en;
wire [31:0] result, BusCrb_rdata, CwbBus_wdata;
wire result_en;
wire BusCwb_wuserLast, BusCwb_wready, BusCwb_awready, BusCrb_rlast,
	BusCrb_arready, BusCrb_rvalid, CcCrb_initAddrEn, CcCwb_primAddrEn,
	CwbCc_addrRq, pt_en;
wire [3:0] BusCwb_wuserId, BusCrb_rid, CrbBus_arusrid, CwbBus_awuserId,
	CrbBus_arlen, CwbBus_awlen, CwbBus_wstrb;
wire [27:0] CcCwb_primAddr, CrbCc_imgEndAddr, CrbCc_initAddr, CcCrb_initAddr, CrbBus_araddr, 
CwbBus_awaddr; 
wire [5:0]  CcCwb_primAddrBias, CrbCc_ptr, CrbCc_ptc;

assign BusCwb_wuserLast = link_read ? wuser_last : 1'hz;
assign BusCwb_wuserId = link_read ? wuser_id : 4'hz;
assign BusCwb_wready = link_read ? wready : 1'hz;
assign BusCwb_awready = link_read ? awready : 1'hz;
assign BusCrb_rid = link_read ? rid : 4'hz;
assign BusCrb_rlast = link_read ? rvalid : 1'hz;
assign BusCrb_arready = link_read ? arready : 1'hz;
assign BusCrb_rvalid = link_read ? rvalid : 1'hz;
assign data = link_write ? CwbBus_wdata : 32'hzzzz_zzzz;
assign wstrb = link_write ? CwbBus_wstrb : 4'hz;
assign arvalid = link_write ? CrbBus_arvalid : 1'hz;
assign aruser_id = link_write ? CrbBus_arusrid : 4'hz;
assign aruser_ap = link_write ? CrbBus_aruserap : 1'hz;
assign arlen = link_write ? CrbBus_arlen : 4'hz;
assign awuser_ap = link_write ? CwbBus_userAp : 1'hz;
assign awuser_id = link_write ? CwbBus_awuserId : 4'hz;
assign awlen = link_write ? CwbBus_awlen : 4'hz;
assign awvalid = link_write ? CwbBus_awvalid : 1'hz;

always @* begin
	if (link_write) begin
		if (CrbBus_arvalid) addr = CrbBus_araddr;
		else if (CwbBus_awvalid) addr = CwbBus_awaddr;
		else addr = 32'hzzzz_zzzz;
	end else addr = 32'hzzzz_zzzz;
end 

conv_layer #
(
	.window_size(1),
	.channel_size(channel_size),
	.filter_total(1)
) u_conv_layer
(
	.img_window(CrbCl_conv_img),
	.filters(CrbCl_conv_flt),
	.clk(clk),
	.rst_n(rst_n),
	.en(CrbCl_data_en),
	.conv_outs(result),
	.conv_outs_valid(result_en)
);

conv_rd_ctrl #
(
	.channel_size(channel_size),
	.img_size(64),
	.window_size(3),
	.repeat_time(4),
	.word_len(32),
	.width(32) // databus's width
) u_conv_rd_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.BusCrb_arready(BusCrb_arready),
	.BusCrb_rvalid(BusCrb_rvalid),
	.BusCrb_rlast(BusCrb_rlast),
	.BusCrb_rid(BusCrb_rid),
	.BusCrb_rdata(data),
	.CrbBus_arvalid(CrbBus_arvalid),
	.CrbBus_arusrid(CrbBus_arusrid),
	.CrbBus_arlen(CrbBus_arlen),
	.CrbBus_aruserap(CrbBus_aruserap),
	.CrbBus_araddr(CrbBus_araddr),

	.CrbCl_conv_img(CrbCl_conv_img),
	.CrbCl_conv_flt(CrbCl_conv_flt),
	.CrbCl_data_en(CrbCl_data_en),

	.CcCrb_initAddrEn(CrbCc_initAddrEn),
	.CcCrb_initAddr(CrbCc_initAddr),
	.CrbCc_imgEnd(CrbCc_imgEnd),
	.CrbCc_imgEndAddr(CrbCc_imgEndAddr),
	.ptr(CrbCc_ptr),
	.ptc(CrbCc_ptc),
	.pt_en(pt_en),
	
	.last_pt()
);

conv_wr_bridge #(width)
u_conv_wr_bridge
(
	.clk(clk),
	.rst_n(rst_n),
	.result(result),
	.result_en(result_en),

	.addr(CcCwb_primAddr),
	.addr_bias(CcCwb_primAddrBias),
	.addr_en(CcCwb_primAddrEn),
	.addr_rq(CwbCc_addrRq),

	.awaddr(CwbBus_awaddr),
	.awuser_ap(CwbBus_userAp),
	.awuser_id(CwbBus_awuserId),
	.awlen(CwbBus_awlen),
	.awvalid(CwbBus_awvalid),
	.awready(BusCwb_awready),

	.wdata(CwbBus_wdata),
	.wstrb(CwbBus_wstrb),
	.wready(BusCwb_wready),
	.wuser_id(BusCwb_wuserId),
	.wuser_last(BusCwb_wuserLast)
);

conv_ctrl #
(
	.word_len(32),
	.channel_size(channel_size)
) u_conv_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.CrbCc_imgEnd(CrbCc_imgEnd),
	.CrbCc_imgEndAddr(CrbCc_imgEndAddr),
	.CrbCc_initAddrEn(CrbCc_initAddrEn),
	.CrbCc_initAddr(CrbCc_initAddr),
	.conv_init_addr(conv_init_addr),
	.conv_init_addr_en(conv_init_addr_en),

	.conv_start(conv_start),
	.conv_end(conv_end),
	
	.ptr(CrbCc_ptr),
	.ptc(CrbCc_ptc),
	.pt_en(pt_en),
	.CwbCc_addrRq(CwbCc_addrRq),
	.CcCwb_primAddr(CcCwb_primAddr),
	.CcCwb_primAddrEn(CcCwb_primAddrEn),
	.CcCwb_primAddrBias(CcCwb_primAddrBias)
);



endmodule
