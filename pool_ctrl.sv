module pool_ctrl #
(parameter word_len=32,
 parameter channel_size=64)
(
	input clk, rst_n,
	// from the pool_rd_ctrl side
	input PrbPc_imgEnd, // represent that all pixel of the image is read;(last_pt)
	input [27:0] PrbPc_imgEndAddr, // last_point's address
	output reg PcPrb_initAddrEn,
	output reg [27:0] PcPrb_initAddr,
	input [5:0] ptc, ptr,
	input pt_en,
	// from pool_unit side
	input pool_start, // the maxpool start;
	output reg pool_end, // the maxpool is done;

	// from pool_wr_bridge
	input PwbPc_addrRq,
	output reg [27:0] PcPwb_primAddr,
	output reg PcPwb_primAddrEn,
	output reg [5:0] PcPwb_primAddrBias
);

reg [27:0] _ptr, _ptc;

always @(posedge clk, negedge rst_n) begin
	if(!rst_n || !pool_start) begin
		_ptr <= 0;
		_ptc <= 0;
	end else if (pt_en) begin
		_ptr <= ptr;
		_ptc <= ptc;
	end else ;
end 

always @(posedge clk, negedge rst_n) begin
	if(!rst_n || !pool_start) begin
		PcPrb_initAddr <= 28'b0;
		PcPrb_initAddrEn <= 1;
	end else PcPrb_initAddrEn <= 0;
end 

always @(posedge clk, negedge rst_n) begin
	if(!rst_n || !pool_start) begin
		PcPwb_primAddr <= 0;
		PcPwb_primAddrEn <= 0;
		PcPwb_primAddrBias <= 0;
	end else if (PwbPc_addrRq) begin
		PcPwb_primAddr <= (_ptr*64 + _ptc) * 64;
		PcPwb_primAddrEn <= 1;
		PcPwb_primAddrBias <= 0;
	end else ;
end 



endmodule
