module fc_unit
(
	input clk, rst_n,
	input fc_en,
	output reg fc_done,
	// from bus 
	input [width-1:0] data,
	output reg [27:0] addr,
	input link_write,
	input link_read,
	// waddr
	output awuser_ap,
	output awuser_id,
	output [3:0] awlen,
	input awready,
	input awvalid,
	// wdata
	output [width/8-1:0] wstrb,
	input wready,
	input [3:0] wuser_id,
	input wuser_last,
	// raddr
	input arready,
	output [3:0] aruser_id,
	output [3:0] arlen,
	output aruser_ap,
	input rvalid,
	input rlast,
	input [3:0] rid
);

fc_ctrl #
(
	.data_init_addr(data_init_addr),
	.weight_init_addr(weight_init_addr),
	.bias_init_addr(bias_init_addr),
) u_fc_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.NcNrc_initAddr(NcNrc_initAddr),
	.NcNrc_initAddrEn(NcNrc_initAddrEn),
	.NrcNc_initAddrRq(NrcNc_initAddrRq),
	.NrcNc_dataType(NrcNc_dataType),
	.NrcNc_rd_end(NrcNc_rd_end),
	.NcNwc_initAddr(NcNwc_initAddr),
	.NcNwc_initAddrEn(NcNwc_initAddrEn),
	.NwcNc_done(NwcNc_done),
	.fc_en(fc_en),
	.fc_done(fc_done)
);

fc_rd_ctrl #
(
	.batch_size(batch_size),
	.feature_size(feature_size),
	.bias_size(bias_size),
	.word_len(word_len)
) u_fc_rd_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.NrcFc_data(NrcFc_data),
	.NrcFc_weight(NrcFc_weight),
	.NrcFc_bias(NrcFc_bias),
	.NrcFc_data_valid(NrcFc_data_valid),
	.NrcFc_bias_valid(NrcFc_bias_valid),
	.NrcFc_weight_valid(NrcFc_weight_valid),
	.NrcBus_arlen(NrcBus_arlen),
	.NrcBus_araddr(NrcBus_araddr),
	.NrcBus_arvalid(NrcBus_arvalid),
	.NrcBus_aruserap(NrcBus_aruserap),
	.NrcBus_aruserid(NrcBus_aruserid),
	.BusNrc_rid(BusNrc_rid),
	.BusNrc_rdata(BusNrc_rdata),
	.BusNrc_rlast(BusNrc_rlast),
	.BusNrc_rvalid(BusNrc_rvalid),
	.BusNrc_arready(BusNrc_arready),
	.NcNrc_initAddr(NcNrc_initAddr),
	.NcNrc_initAddrEn(NcNrc_initAddrEn),
	.NrcNc_rd_end(NrcNc_rd_end),
	.NrcNc_dataType(NrcNc_dataType),
	.NrcNc_initAddrRq(NrcNc_initAddrRq),
);

fc_wr_ctrl #
(
	.batch_size(batch_size),
	.bias_size(bias_size),
	.word_len(word_len)
) u_fc_wr_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.FcNwc_result(FcNwc_result),
	.FcNwc_result_en(FcNwc_result_en),
	.BusNwc_wready(BusNwc_wready),
	.BusNwc_wuser_id(BusNwc_wuser_id),
	.BusNwc_wuser_last(BusNwc_wuser_last),
	.BusNwc_awready(BusNwc_awready),
	.NwcBus_awuser_id(NwcBus_awuser_id),
	.NwcBus_awuser_ap(NwcBus_awuser_ap),
	.NwcBus_awlen(NwcBus_awlen),
	.NwcBus_awvalid(NwcBus_awvalid),
	.NwcBus_wdata(NwcBus_wdata),
	.NwcBus_awaddr(NwcBus_awaddr),
	.NwcBus_wstrb(NwcBus_wstrb),
	.NcNwc_initAddr(NcNwc_initAddr),
	.NcNwc_initAddrEn(NcNwc_initAddrEn),
	.NwcNc_done(NwcNc_done)
);

fully_connect #
(
	.batch_size(batch_size),
	.feature_size(feature_size),
	.bias_size(bias_size)
) u_fully_connect
(
	.clk(clk),
	.rst_n(rst_n),
	.data(NrcFc_data),
	.weight(NrcFc_weight),
	.bias(NrcFc_bias),
	.data_en(NrcFc_data_valid),
	.weight_en(NrcFc_weight_valid),
	.bias_en(NrcFc_bias_valid),
	.result(FcNwc_result),
	.result_valid(FcNwc_result_en),
	.bias_rq() // not find 
);

/* TODO :
* 1 link the data, addr and the control wires to the bus * 
* 2 declare the inline wires */

endmodule
