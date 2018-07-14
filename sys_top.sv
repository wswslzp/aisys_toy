module pgt180h_aisys
(
	input											clk, rst_n,
	output										system_end,
	input											rxd,
	output										txd,
	output [14:0]							mem_a,
	output [2:0]							mem_ba,
	output										mem_ck, mem_ck_n, mem_cke,
	output [3:0]							mem_dm,
	output										mem_odt, mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n, mem_reset_n,
	inout [31:0]							mem_dq, 
	inout [3:0]								mem_dqs, mem_dqs_n
);

wire [31:0] data;
wire [255:0] ddr_data;
wire [27:0] addr, conv_init_addr;
wire [3:0] awlen, arlen, awuser_id, aruser_id, rid, wuser_id;
wire [7:0] wstrb;
wire arvalid, awvalid, rvalid, wready, arready, awready, awuser_ap, aruser_ap, ddr_init_done, wuser_last, rlast;
wire conv_en, conv_done;
wire pool_en, pool_done;
wire conv_link_read, conv_link_write;
wire pool_link_read, pool_link_write;

assign data = conv_link_read ? ddr_data[31:0] : 32'hzzzz_zzzz;
assign data = pool_link_read ? ddr_data[31:0] : 32'hzzzz_zzzz;

sys_state_ctrl #(16'h1111) 
u_sys_state_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.system_end(system_end),
	.rdone(rdone),
	.wdone(wdone),
	.conv_en(conv_en),
	.conv_done(conv_done),
	.conv_link_read(conv_link_read),
	.conv_link_write(conv_link_write),
	.conv_init_addr(conv_init_addr),
	.conv_init_addr_en(conv_init_addr_en),
	.pool_en(pool_en),
	.pool_done(pool_done),
	.pool_link_read(pool_link_read),
	.pool_link_write(pool_link_write),
	.uart_en(uart_en),
	.uart_wrSel(wr_sel),
	.uart_link_read(uart_link_read),
	.uart_link_write(uart_link_write),
	.fc_en(fc_en),
	.fc_done(fc_done),
	.fc_link_read(fc_link_read),
	.fc_link_write(fc_link_write)
);

conv_unit #
(
	.width(32),
	.window_size(3),
	.channel_size(64),
	.filter_total(64)
) u_conv_unit
(
	.clk(clk),
	.rst_n(rst_n),
	.conv_start(conv_en),
	.conv_end(conv_done),
	.conv_init_addr(conv_init_addr),
	.conv_init_addr_en(conv_init_addr_en),
	.link_write(conv_link_write),
	.link_read(conv_link_read),
	.data(data),
	.addr(addr),
	.arready(arready),
	.rvalid(rvalid),
	.rlast(rlast),
	.rid(rid),
	.arvalid(arvalid),
	.aruser_id(aruser_id),
	.aruser_ap(aruser_ap),
	.arlen(arlen),
	.awuser_ap(awuser_ap),
	.awuser_id(awuser_id),
	.awlen(awlen),
	.awvalid(awvalid),
	.awready(awready),
	.wstrb(wstrb),
	.wready(wready),
	.wuser_id(wuser_id),
	.wuser_last(wuser_last)
);

pool_unit #
(
	.width(32),
	.window_size(3),
	.channel_size(64),
	.filter_total(64)
) u_pool_unit
(
	.clk(clk),
	.rst_n(rst_n),
	.pool_start(pool_en),
	.pool_end(pool_done),
	.link_write(pool_link_write),
	.link_read(pool_link_read),
	.data(data),
	.addr(addr),
	.arready(arready),
	.rvalid(rvalid),
	.rlast(rlast),
	.rid(rid),
	.arvalid(arvalid),
	.aruser_id(aruser_id),
	.aruser_ap(aruser_ap),
	.arlen(arlen),
	.awuser_ap(awuser_ap),
	.awuser_id(awuser_id),
	.awlen(awlen),
	.awvalid(awvalid),
	.awready(awready),
	.wstrb(wstrb),
	.wready(wready),
	.wuser_id(wuser_id),
	.wuser_last(wuser_last)
);

fc_unit u_fc_unit
(
	.clk(clk),
	.rst_n(rst_n),
	.fc_start(fc_start),
	.fc_end(fc_done),
	.data(data),
	.addr(addr),
	.link_write(fc_link_write),
	.link_read(fc_link_read),
	.awuser_ap(awuser_ap),
	.awuser_id(awuser_id),
	.awlen(awlen),
	.awready(awready),
	.awvalid(awvalid),
	.wstrb(wstrb),
	.wready(wready),
	.wuser_id(wuser_id),
	.wuser_last(wuser_last),
	.arready(arready),
	.aruser_id(aruser_id),
	.arlen(arlen),
	.aruser_ap(aruser_ap),
	.rvalid(rvalid),
	.rlast(rlast),
	.rid(rid)
);

uart_unit u_uart_unit
(
	.clk(clk),
	.rst_n(rst_n),
	.uart_en(uart_en),
	.wr_sel(wr_sel),
	.link_write(uart_link_write),
	.link_read(uart_link_read),
	.rdone(rdone),
	.wdone(wdone),
	.data(data),
	.addr(addr),
	.arready(arready),
	.aruserap(aruser_ap),
	.aruserid(aruser_id),
	.arlen(arlen),
	.arvalid(arvalid),
	.rid(rid),
	.rlast(rlast),
	.rvalid(rvalid),
	.awready(awready),
	.awuserap(awuser_ap),
	.awuserid(awuser_id),
	.awlen(awlen),
	.awvalid(awvalid),
	.wready(wready),
	.wuserid(wuser_id),
	.wlast(wuser_last),
	.wstrb(wstrb),
	.rxd(rxd),
	.txd(txd)
);

ddr3 u_ddr3
(
  // .pll_lock(pll_lock),
  .ref_clk(clk),
  .ref_rst_n(rst_n),
  // .ref_clk_bypass(ref_clk_bypass),
  // .free_run_clk(free_run_clk),
  // .core_clk(core_clk),
  .dfi_reset_n(),
  .ddr_init_done(ddr_init_done),
  .update_mask(3'b000),
  .manual_update(1'b0),
  .shift_thresh(7'd3),
  
  .axi_awaddr(addr),
  .axi_awuser_ap(awuser_ap),
  .axi_awuser_id(awuser_id),
  .axi_awlen(awlen),
  .axi_awready(awready),
  .axi_awvalid(awvalid),
  
  .axi_wdata(data),
  .axi_wstrb(wstrb),
  .axi_wready(wready),
  .axi_wusero_id(wuser_id),
  .axi_wusero_last(wuser_last),
  
  .axi_araddr(addr),
  .axi_aruser_ap(aruser_ap),
  .axi_aruser_id(aruser_id),
  .axi_arlen(arlen),
  .axi_arready(arready),
  .axi_arvalid(arvalid),
  
  .axi_rdata(ddr_data),
  .axi_rvalid(rvalid),
  .axi_rid(rid),
  .axi_rlast(rlast),
  
  .apb_clk(),
  .apb_rst_n(),
  .apb_sel(),
  .apb_enable(),
  .apb_addr(),
  .apb_write(),
  .apb_ready(),
  .apb_wdata(),
  .apb_rdata(),
  
  .mem_a(mem_a),
  .mem_ba(mem_ba),
  .mem_ck(mem_ck),
  .mem_ck_n(mem_ck_n),
  .mem_cke(mem_cke),
  .mem_dm(mem_dm),
  .mem_odt(mem_odt),
  .mem_cs_n(mem_cs_n),
  .mem_ras_n(mem_ras_n),
  .mem_cas_n(mem_cas_n),
  .mem_we_n(mem_we_n),
  .mem_reset_n(mem_reset_n),
  .mem_dq(mem_dq),
  .mem_dqs(mem_dqs),
  .mem_dqs_n(mem_dqs_n),

  .dly_mon_pad()
);

endmodule 
