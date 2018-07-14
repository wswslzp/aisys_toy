module pool_unit #
(parameter width = 32,
 parameter window_size = 3,
 parameter channel_size = 64,
 parameter filter_total = 64)
(
	// from the system 
	input clk, rst_n,
	// from the state control machine
	input pool_start,
	output pool_end,
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

//wire [channel_size-1:0][31:0] PrbMp_pool_img, PrbMp_pool_flt;
wire [channel_size*32-1:0] in1, in2, in3, in4, result;
wire PrbMp_pool_en;
wire [31:0] BusPrb_rdata, PwbBus_wdata;
wire result_en;
wire BusPwb_wuserLast, BusPwb_wready, BusPwb_awready, BusPrb_rlast,
	BusPrb_arready, BusPrb_rvalid, PcPrb_initAddrEn, PcPwb_primAddrEn,
	PwbPc_addrRq,PrbPc_pt_en, PrbBus_arvalid, PrbBus_aruserap, PwbBus_userAp, PwbBus_awvalid;
wire [3:0] BusPwb_wuserId, BusPrb_rid, PrbBus_arusrid, PwbBus_awuserId,
	PrbBus_arlen, PwbBus_awlen, PwbBus_wstrb;
wire [27:0] PcPwb_primAddr, PrbPc_imgEndAddr, PcPrb_initAddr, PrbBus_araddr, PwbBus_awaddr; 
wire [5:0]  PcPwb_primAddrBias, PrbPc_ptr,PrbPc_ptc;

assign BusPwb_wuserLast = link_read ? wuser_last : 1'hz;
assign BusPwb_wuserId = link_read ? wuser_id : 4'hz;
assign BusPwb_wready = link_read ? wready : 1'hz;
assign BusPwb_awready = link_read ? awready : 1'hz;
assign BusPrb_rid = link_read ? rid : 4'hz;
assign BusPrb_rlast = link_read ? rvalid : 1'hz;
assign BusPrb_arready = link_read ? arready : 1'hz;
assign BusPrb_rvalid = link_read ? rvalid : 1'hz;
assign data = link_write ? PwbBus_wdata : 32'hzzzz_zzzz;
assign wstrb = link_write ? PwbBus_wstrb : 4'hz;
assign arvalid = link_write ? PrbBus_arvalid : 1'hz;
assign aruser_id = link_write ? PrbBus_arusrid : 4'hz;
assign aruser_ap = link_write ? PrbBus_aruserap : 1'hz;
assign arlen = link_write ? PrbBus_arlen : 4'hz;
assign awuser_ap = link_write ? PwbBus_userAp : 1'hz;
assign awuser_id = link_write ? PwbBus_awuserId : 4'hz;
assign awlen = link_write ? PwbBus_awlen : 4'hz;
assign awvalid = link_write ? PwbBus_awvalid : 1'hz;

always @* begin
	if (link_read && PrbBus_arvalid) addr = PrbBus_araddr;
	else if (link_write && PwbBus_awvalid) addr = PwbBus_awaddr;
	else addr = 28'hzzz_zzzz;
end 

maxpool #
(.channel_size(64))
u_maxpool
(
	.clk(clk),
	.rst_n(rst_n),
	.in1(in1),
	.in2(in2),
	.in3(in3),
	.in4(in4),
	.in_en(PrbMp_pool_en),
	.out(result),
	.valid(result_en)
);

pool_rd_ctrl #
(
	.channel_size(channel_size),
	.window_size(3),
	.word_len(32)
) u_pool_rd_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.BusPrb_arready(BusPrb_arready),
	.BusPrb_rvalid(BusPrb_rvalid),
	.BusPrb_rlast(BusPrb_rlast),
	.BusPrb_rid(BusPrb_rid),
	.BusPrb_rdata(data),
	.PrbBus_arvalid(PrbBus_arvalid),
	.PrbBus_arusrid(PrbBus_arusrid),
	.PrbBus_arlen(PrbBus_arlen),
	.PrbBus_aruserap(PrbBus_aruserap),
	.PrbBus_araddr(PrbBus_araddr),

	.in1(in1), .in2(in2), .in3(in3), .in4(in4),
	.PrbMp_pool_en(PrbMp_pool_en),

	.PcPrb_initAddrEn(PcPrb_initAddrEn),
	.PcPrb_initAddr(PcPrb_initAddr),
	.PrbPc_imgEnd(PrbPc_imgEnd),
	.PrbPc_imgEndAddr(PrbPc_imgEndAddr),
	.ptr(PrbPc_ptr),
	.ptc(PrbPc_ptc),
	.pt_en(PrbPc_pt_en)
	
);

pool_wr_bridge #
(.width(width), .channel_size(channel_size))
u_pool_wr_bridge
(
	.clk(clk),
	.rst_n(rst_n),
	.result(result),
	.result_en(result_en),

	.addr(PcPwb_primAddr),
	.addr_bias(PcPwb_primAddrBias),
	.addr_en(PcPwb_primAddrEn),
	.addr_rq(PwbPc_addrRq),

	.awaddr(PwbBus_awaddr),
	.awuser_ap(PwbBus_userAp),
	.awuser_id(PwbBus_awuserId),
	.awlen(PwbBus_awlen),
	.awvalid(PwbBus_awvalid),
	.awready(BusPwb_awready),

	.wdata(PwbBus_wdata),
	.wstrb(PwbBus_wstrb),
	.wready(BusPwb_wready),
	.wuser_id(BusPwb_wuserId),
	.wuser_last(BusPwb_wuserLast)
);

pool_ctrl #
(
	.word_len(32),
	.channel_size(channel_size)
) u_pool_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.PrbPc_imgEnd(PrbPc_imgEnd),
	.PrbPc_imgEndAddr(PrbPc_imgEndAddr),
	.PcPrb_initAddrEn(PcPrb_initAddrEn),
	.PcPrb_initAddr(PcPrb_initAddr),
	.ptr(PrbPc_ptr),
	.ptc(PrbPc_ptc),
	.pt_en(PrbPc_pt_en),

	.pool_start(pool_start),
	.pool_end(pool_end),
	
	.PwbPc_addrRq(PwbPc_addrRq),
	.PcPwb_primAddr(PcPwb_primAddr),
	.PcPwb_primAddrEn(PcPwb_primAddrEn),
	.PcPwb_primAddrBias(PcPwb_primAddrBias)
);



endmodule
