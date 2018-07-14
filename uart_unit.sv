module uart_unit #
(parameter kernel_scale=10,
 parameter weight_scale=10,
 parameter bias_scale=10,
 parameter image_scale=10,
 parameter word_len=32) // e.g. a 64*64 image with 64 channels
(
	// from system
	input clk, rst_n,
	// from sys_state_ctrl
	input uart_en,
	input [2:0] UnUc_wr_sel,
	input link_write,
	input link_read,
	output reg rdone, wdone,
	// from bus 
	inout [31:0] data,
	output reg [27:0] addr,
	// read
	input arready,
	//output [27:0] araddr,
	output reg aruserap,
	output reg [3:0] aruserid,
	output reg [3:0] arlen,
	output reg arvalid,
	
	input [3:0] rid,
	input rlast,
	input rvalid,
	//input [31:0] rdata,
	// write 
	input awready,
	//output [27:0] awaddr,
	output reg awuserap,
	output reg [3:0] awuserid,
	output reg [3:0] awlen,
	output reg awvalid,

	input wready, 
	input [3:0] wuserid,
	input wlast,
	//output [27:0] wdata,
	output reg wstrb,
	// from outside
	input rxd,
	output reg txd
);

reg clki;
reg [3:0] state, nstate;
wire [32:0] UbUc_data_in, BusUb_rdata, UcUb_data_out, UbBus_wdata;
wire [27:0] UnUb_initAddr, UbBus_awaddr, UbBus_araddr;
wire [3:0] BusUb_wuserid, BusUb_wready, BusUb_rid, UbBus_awuserid, UbBus_awlen, UbBus_aruserid, UbBus_arlen, UbBus_wstrb;
wire UckUc_clk_bps, UckUc_clk_smp, UckUc_txd_ena, UckUc_rxd_ena, UbUc_data_in_en, BusUb_awready, BusUb_arready, BusUb_wlast, BusUb_rlast, BusUb_rvalid, UnUb_initAddrEn, UcUb_data_out_en, UcUn_txd_valid, UcUn_rxd_ready, UbBus_awuserap, UbBus_awvalid, UbBus_aruserap, UbBus_arvalid; 

assign BusUb_wlast = link_read ? wlast : 1'hz;
assign BusUb_wuserid = link_read ? wuserid : 4'hz;
assign BusUb_wready = link_read ? wready : 1'hz;
assign BusUb_awready = link_read ? awready : 1'hz;
assign BusUb_rid = link_read ? rid : 4'hz;
assign BusUb_rlast = link_read ? rvalid : 1'hz;
assign BusUb_arready = link_read ? arready : 1'hz;
assign BusUb_rvalid = link_read ? rvalid : 1'hz;
assign data = link_write ? UbBus_wdata : 32'hzzzz_zzzz;
assign wstrb = link_write ? UbBus_wstrb : 4'hz;
assign arvalid = link_write ? UbBus_arvalid : 1'hz;
assign aruser_id = link_write ? UbBus_aruserid : 4'hz;
assign aruser_ap = link_write ? UbBus_aruserap : 1'hz;
assign arlen = link_write ? UbBus_arlen : 4'hz;
assign awuserap = link_write ? UbBus_awuserap : 1'hz;
assign awuserid = link_write ? UbBus_awuserid : 4'hz;
assign awlen = link_write ? UbBus_awlen : 4'hz;
assign awvalid = link_write ? UbBus_awvalid : 1'hz;

always @* begin
	if (link_read && UbBus_arvalid) addr = UbBus_araddr;
	else if (link_write && UbBus_awvalid) addr = UbBus_awaddr;
	else addr = 28'hzzz_zzzz;
end

// uart_ena control the clock
always @* begin
	clki = uart_en ? clk : 1'b0;
end

uart_ctrl u_uart_ctrl
(
	.clk(clki),// 
	.rst_n(rst_n),//
	.rxd(rxd),//
	.txd(txd),//
	.UckUc_clk_bps(UckUc_clk_bps),//i1
	.UckUc_clk_smp(UckUc_clk_smp),//i1
	.UckUc_txd_ena(UckUc_txd_ena),//i1
	.UckUc_rxd_ena(UckUc_rxd_ena),//i1
	.UbUc_data_in(UbUc_data_in),//i32
	.UcUb_data_out(UcUb_data_out),//o32
	.UcUb_data_out_en(UcUb_data_out_en),//o1
	.UbUc_data_in_en(UbUc_data_in_en),//i1
	.UnUc_wr_sel(UnUc_wr_sel),//i3
	.UcUn_txd_valid(UcUn_txd_valid),//o1
	.UcUn_rxd_ready(UcUn_rxd_ready)//o1
);

uart_clkgen u_uart_clk_gen
(
	.clki(clki),//
	.rst_n(rst_n),//
	.UckUc_clk_bps(UckUc_clk_bps),//o1
	.UckUc_clk_smp(UckUc_clk_smp),//o1
	.UckUc_txd_ena(UckUc_txd_ena),//o1
	.UckUc_rxd_ena(UckUc_rxd_ena)//o1
);

uart_bridge u_uart_bridge
(
	.clk(clki),//
	.rst_n(rst_n),//
	.UbUc_data_in(UbUc_data_in),//i32
	.UcUb_data_out(UcUb_data_out),//o32
	.UbUc_data_in_en(UbUc_data_in_en),//i1
	.UcUb_data_out_en(UcUb_data_out_en),//o1
	.UbBus_awaddr(UbBus_awaddr),//o28
	.UbBus_awuserap(UbBus_awuserap),//o1
	.UbBus_awuserid(UbBus_awuserid),//o4
	.UbBus_awlen(UbBus_awlen),//o4
	.UbBus_awvalid(UbBus_awvalid),//o1
	.BusUb_awready(BusUb_awready),//i1
	.UbBus_araddr(UbBus_araddr),//o28
	.UbBus_aruserap(UbBus_aruserap),//o1
	.UbBus_aruserid(UbBus_aruserid),//o4
	.UbBus_arlen(UbBus_arlen),//o4
	.UbBus_arvalid(UbBus_arvalid),//o1
	.BusUb_arready(BusUb_arready),//i1
	.BusUb_wuserid(BusUb_wuserid),//i4
	.BusUb_wready(BusUb_wready),//i4
	.BusUb_wlast(BusUb_wlast),//i1
	.UbBus_wdata(UbBus_wdata),//o32
	.UbBus_wstrb(UbBus_wstrb),//o4
	.BusUb_rid(BusUb_rid),//i4
	.BusUb_rlast(BusUb_rlast),//i1
	.BusUb_rvalid(BusUb_rvalid),//i1
	.BusUb_rdata(BusUb_rdata),//i32
	.UnUc_wr_sel(UnUc_wr_sel),//i1
	.UnUb_initAddr(UnUb_initAddr),//i28
	.UnUb_initAddrEn(UnUb_initAddrEn)//i1
);

// TODO : IO complete flag;
//reg cnt
//always @(posedge clk, negedge rst_n) begin
//	if (!rst_n) 


endmodule 
	
