module fc_wr_ctrl
(
	// from outside
	input clk, rst_n,
	// from fully_connect side
	input FcNwc_result_en,
	input [batch_size-1:0][bias_size-1:0][31:0] FcNwc_result,
	// from bus
	input BusNwc_awready,
	output reg [3:0] NwcBus_awuser_id,
	output reg NwcBus_awuser_ap,
	output reg [3:0] NwcBus_awlen,
	output reg NwcBus_awvalid,
	output reg [27:0] NwcBus_awaddr,

	input BusNwc_wready,
	input [3:0] BusNwc_wuser_id,
	input BusNwc_wuser_last,
	output reg [31:0] NwcBus_wdata,
	output reg [3:0] NwcBus_wstrb,
	// from fc_ctrl 
	input [27:0] NcNwc_initAddr,
	input NcNwc_initAddrEn
);

localparam AWID = 4'b0110;

reg [27:0] _addr;
reg [batch_size-1:0][bias_size-1:0][31:0] _result;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		_addr <= 0;
	end else if (NcNwc_initAddrEn) _addr <= NcNwc_initAddr;
	else ;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) _result <= 0; 
	else if (FcNwc_result_en) _result <= FcNwc_result;
	else ;
end 

task write_addr;
	NwcBus_awlen <= 4'h0;
	NwcBus_awaddr <= _addr;
	NwcBus_awvalid <= 1'b1;
	NwcBus_awuser_ap <= 1'b1;
	NwcBus_awuser_id <= AWID;
endtask

/**** TODO ****************************
* task write_data; 
* a FSM to make write runing correctly;*/ 


endmodule 
