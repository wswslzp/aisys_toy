module fc_unit
(
	input clk, rst_n,
	input fc_start,
	output reg fc_end,
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



endmodule
