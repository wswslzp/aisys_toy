module uart_interface #
(parameter word_size=64*64*64) // e.g. a 64*64 image with 64 channels
(
	// from system
	input clk, rst_n,
	// from sys_state_ctrl
	input uart_ena,
	input wr_sel,
	input link_write,
	input link_read,
	output rdone, wdone,
	// from bus 
	// read
	input arready,
	output [27:0] araddr,
	output aruserap,
	output [3:0] aruserid,
	output [3:0] arlen,
	output arvalid,
	
	input [3:0] rid,
	input rlast,
	input rvalid,
	input [31:0] rdata,
	// write 
	input awready,
	output [27:0] awaddr,
	output awuserap,
	output [3:0] awuserid,
	output [3:0] awlen,
	output awvalid,

	input wready, 
	input [3:0] wuserid,
	input wlast,
	output [27:0] wdata,
	output wstrb
	// from outside
	input rxd,
	output txd
);

reg [3:0] state, nstate;

uart_ctrl u_uart_ctrl
(
	.clk(clk),
	.rst_n(rst_n),
	.rxd(rxd),
	.txd(txd),
	.ena(uart_ena),
	.

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin 
		state <= 4'h0;
	end else state <= nstate;
end 




endmodule 
	
