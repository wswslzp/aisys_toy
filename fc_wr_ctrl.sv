module fc_rd_ctrl
(
	// from outside
	input clk, rst_n,
	// from bus
	input awready,
	output reg [3:0] awuserId,
	output reg awuserAp,
	output reg [3:0] awlen,
	output reg awvalid,
	output reg [27:0] awaddr,

	input wready,
	input [3:0] wuserId,
	input wuserLast,
	output reg [31:0] wdata,
	output reg [3:0] wstrb,
