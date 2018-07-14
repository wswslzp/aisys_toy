module fc_unit #
(
	parameter batch_size = 10,
	parameter bias_size = 10,
	parameter feature_size = 1024,
	parameter word_len = 32
)
(
	input clk, rst_n,
	input fc_start,
	output reg fc_end,
	// from bus 
	inout [word_len-1:0] data,
	output reg [27:0] addr,
	// control from control machine
	input link_write,
	input link_read,
	// waddr
	output awuser_ap,
	output awuser_id,
	output [3:0] awlen,
	input awready,
	input awvalid,
	// wdata
	output [word_len/8-1:0] wstrb,
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

localparam data_init_addr = 28'b0,
	weight_init_addr = 28'b0,//wait for changing
	bias_init_addr = 28'b0;

// wire declaration
wire [27:0] NcNrc_initAddr, NrcBus_araddr, NwcBus_awaddr, NcNwc_initAddr;
wire [31:0] BusNrc_rdata, NwcBus_wdata;
wire [bias_size-1:0][feature_size-1:0][31:0] NrcFc_data;
wire [feature_size-1:0][bias_size-1:0][31:0] NrcFc_weight;
wire [bias_size-1:0][31:0] NrcFc_bias;
wire [batch_size-1:0][bias_size-1:0][31:0] FcNwc_result;
wire [3:0] BusNrc_rid, BusNwc_wuser_id, NrcBus_arlen, NrcBus_aruserid,NwcBus_awuser_id, NwcBus_awlen, NwcBus_wstrb;
wire [2:0] NrcNc_dataType;
wire NrcNc_initAddrRq, NrcNc_rd_end, BusNrc_rlast, BusNrc_rvalid, BusNrc_arready, NcNrc_initAddrEn, FcNwc_result_en, BusNwc_wready, BusNwc_wuser_last, BusNwc_awready, NcNwc_initAddrEn, NrcFc_data_valid, NrcFc_weight_valid, NrcFc_bias_valid,  NwcNc_done, NrcBus_arvalid, NrcBus_aruserap, NwcBus_awuser_ap, NwcBus_awvalid;


assign BusNwc_wuser_last = link_read ? wuser_last : 1'hz;
assign BusNwc_wuser_id = link_read ? wuser_id : 4'hz;
assign BusNwc_wready = link_read ? wready : 1'hz;
assign BusNwc_awready = link_read ? awready : 1'hz;
assign BusNrc_rid = link_read ? rid : 4'hz;
assign BusNrc_rlast = link_read ? rvalid : 1'hz;
assign BusNrc_arready = link_read ? arready : 1'hz;
assign BusNrc_rvalid = link_read ? rvalid : 1'hz;
assign data = link_write ? NwcBus_wdata : 32'hzzzz_zzzz;
assign wstrb = link_write ? NwcBus_wstrb : 4'hz;
assign arvalid = link_write ? NrcBus_arvalid : 1'hz;
assign aruser_id = link_write ? NrcBus_aruserid : 4'hz;
assign aruser_ap = link_write ? NrcBus_aruserap : 1'hz;
assign arlen = link_write ? NrcBus_arlen : 4'hz;
assign awuser_ap = link_write ? NwcBus_awuser_ap : 1'hz;
assign awuser_id = link_write ? NwcBus_awuser_id : 4'hz;
assign awlen = link_write ? NwcBus_awlen : 4'hz;
assign awvalid = link_write ? NwcBus_awvalid : 1'hz;

always @* begin
	if (link_read && NrcBus_arvalid) addr = NrcBus_araddr;
	else if (link_write && NwcBus_awvalid) addr = NwcBus_awaddr;
	else addr = 28'hzzz_zzzz;
end 

fc_ctrl #
(
	.data_init_addr(data_init_addr),
	.weight_init_addr(weight_init_addr),
	.bias_init_addr(bias_init_addr)
) u_fc_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.NcNrc_initAddr(NcNrc_initAddr), // o28
	.NcNrc_initAddrEn(NcNrc_initAddrEn),//o1
	.NrcNc_initAddrRq(NrcNc_initAddrRq),//i1
	.NrcNc_dataType(NrcNc_dataType),// i3
	.NrcNc_rd_end(NrcNc_rd_end),// i1
	.NcNwc_initAddr(NcNwc_initAddr),// o28
	.NcNwc_initAddrEn(NcNwc_initAddrEn),// o1
	.NwcNc_done(NwcNc_done),// o1
	.fc_en(fc_start),// i1
	.fc_done(fc_done)// o1
);

always @(posedge clk) begin
	fc_end <= fc_done;
end

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
	.NrcFc_data(NrcFc_data),//o_bas_fs_32
	.NrcFc_weight(NrcFc_weight),//o_fs_bis_32 
	.NrcFc_bias(NrcFc_bias),//o_bis_32 
	.NrcFc_data_valid(NrcFc_data_valid),//o1 
	.NrcFc_bias_valid(NrcFc_bias_valid),//o1 
	.NrcFc_weight_valid(NrcFc_weight_valid),//o1 
	.NrcBus_arlen(NrcBus_arlen),//o4 
	.NrcBus_araddr(NrcBus_araddr),//o28 
	.NrcBus_arvalid(NrcBus_arvalid),//o1 
	.NrcBus_aruserap(NrcBus_aruserap),//o1 
	.NrcBus_aruserid(NrcBus_aruserid),//o4 
	.BusNrc_rid(BusNrc_rid),//i4 
	.BusNrc_rdata(BusNrc_rdata),//i32 
	.BusNrc_rlast(BusNrc_rlast),//i1 
	.BusNrc_rvalid(BusNrc_rvalid),//i1 
	.BusNrc_arready(BusNrc_arready),//i1 
	.NcNrc_initAddr(NcNrc_initAddr),// i28
	.NcNrc_initAddrEn(NcNrc_initAddrEn),//i1 
	.NrcNc_rd_end(NrcNc_rd_end),//o1 
	.NrcNc_dataType(NrcNc_dataType),//o3 
	.NrcNc_initAddrRq(NrcNc_initAddrRq)//o1 
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
	.FcNwc_result(FcNwc_result),//i_bas_bis_32 
	.FcNwc_result_en(FcNwc_result_en),//i1 
	.BusNwc_wready(BusNwc_wready),//i1 
	.BusNwc_wuser_id(BusNwc_wuser_id),//i4 
	.BusNwc_wuser_last(BusNwc_wuser_last),//i1 
	.BusNwc_awready(BusNwc_awready),//i1 
	.NwcBus_awuser_id(NwcBus_awuser_id),//o4 
	.NwcBus_awuser_ap(NwcBus_awuser_ap),//o1 
	.NwcBus_awlen(NwcBus_awlen),//o4 
	.NwcBus_awvalid(NwcBus_awvalid),//o1 
	.NwcBus_wdata(NwcBus_wdata),//o32 
	.NwcBus_awaddr(NwcBus_awaddr),//o28 
	.NwcBus_wstrb(NwcBus_wstrb),//o4 
	.NcNwc_initAddr(NcNwc_initAddr),//i28 
	.NcNwc_initAddrEn(NcNwc_initAddrEn),//i1 
	.NwcNc_done(NwcNc_done)//o1 
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
	.data(NrcFc_data),//i_bas_fs_32 
	.weight(NrcFc_weight),//i_fs_bis_32 
	.bias(NrcFc_bias),//i_bis_32 
	.data_en(NrcFc_data_valid),//i1 
	.weight_en(NrcFc_weight_valid),//i1 
	.bias_en(NrcFc_bias_valid),//i1 
	.result(FcNwc_result),//o_bas_bis_32 
	.result_valid(FcNwc_result_en),//o1 
	.bias_rq() // not find 
);


endmodule
