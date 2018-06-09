module conv_ctrl #
(parameter word_len=32,
 parameter channel_size=64)
(
	input clk, rst_n,
	// from the conv_rd_ctrl side
	input CrbCc_imgEnd, // represent that all pixel of the image is read;
	input [27:0] CrbCc_imgEndAddr,
	output reg CrbCc_initAddrEn,
	output reg [27:0] CrbCc_initAddr,
	input [5:0] ptr, ptc,
	input pt_en,
	// from conv_unit side
	input conv_start, // the convolution start;
	output reg conv_end, // the convolution is done;

	// from conv_wr_ctrl
	input CwbCc_addrRq,
	output reg [27:0] CcCwb_primAddr,
	output reg CcCwb_primAddrEn,
	output reg [5:0] CcCwb_primAddrBias
);

reg [5:0] flt_cnt, cnv_cnt;
reg [27:0] _ptr, _ptc;

localparam 
	flt_begin_addr = 28'h800_0000,
	img_begin_addr = 28'h000_0000;

//assign _ptr = {22'b0, ptr};

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) cnv_cnt <= 6'b0;
	else if (flt_cnt == 6'b11_1111) cnv_cnt <= cnv_cnt + 1;
	else ;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) flt_cnt <= 6'b0;
	else if (CrbCc_imgEnd) flt_cnt <= flt_cnt + 1;
	else flt_cnt <= flt_cnt;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n || !conv_start) begin
		CrbCc_initAddr <= img_begin_addr;
		CrbCc_initAddrEn <= 1'b0;
	end else if (CrbCc_imgEnd) begin
		CrbCc_initAddrEn <= 1'b1;
		if (CrbCc_imgEndAddr[27] == 0) begin
			CrbCc_initAddr <= flt_begin_addr;
		end else if (flt_cnt == 6'b111_111) CrbCc_initAddr <= img_begin_addr;
		else CrbCc_initAddr <= CrbCc_imgEnd + 32/word_len;
	end else ; 
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n || !conv_start) begin
		_ptr <= 0;
		_ptc <= 0;
	end else if (pt_en == 1) begin
		_ptr <= ptr;
		_ptc <= ptc;
	end else ;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n || !conv_start) begin 
		CcCwb_primAddr <= 0;
		CcCwb_primAddrEn <= 0;
		CcCwb_primAddrBias <= 0;
	end else if (CwbCc_addrRq) begin
		CcCwb_primAddr <= img_begin_addr + (_ptr*64 + _ptc)*64*32/word_len;
		CcCwb_primAddrEn <= 1;
		CcCwb_primAddrBias <= flt_cnt*32/word_len;
	end else ;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n || cnv_cnt != 6'b11_1111) conv_end <= 0;
	else conv_end <= 1;
end 

endmodule


