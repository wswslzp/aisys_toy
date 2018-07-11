module uart_clkgen #
(
	/*****************************************************************
	* Freq_Word1 <= 32'd25770; Freq_Word1 <= 32'd412317; //300 bps
	*
	* Freq_Word1 <= 32'd51540; Freq_Word2 <= 32'd824634; //600 bps
	*
	* Freq_Word1 <= 32'd103079; Freq_Word2 <= 32'd1649267; //1200 bps
	*
	* Freq_Word1 <= 32'd206158; Freq_Word2 <= 32'd3298535; //2400 bps
	*
	* Freq_Word1 <= 32'd412317; Freq_Word2 <= 32'd6597070; //4800 bps
	*
	* Freq_Word1 <= 32'd824634; Freq_Word2 <= 32'd13194140; //9600 bps
	*
	* Freq_Word1 <= 32'd1649267; Freq_Word2 <= 32'd26388279; //19200 bps
	*
	* Freq_Word1 <= 32'd3298535; Freq_Word2 <= 32'd52776558; //38400 bps
	*
	* Freq_Word1 <= 32'd3693672; Freq_Word2 <= 32'd59098750; //43000 bps
	*
	* Freq_Word1 <= 32'd4810363; Freq_Word2 <= 32'd76965814; //56000 bps
	*
	* Freq_Word1 <= 32'd4947802; Freq_Word2 <= 32'd79164837; //57600 bps
	*
	* Freq_Word1 <= 32'd9895605; Freq_Word2 <= 32'd158329674; //115200bps
	*
	* Freq_Word1 <= 32'd10995116; Freq_Word2 <= 32'd175921860; //128000bps
	*
	* Freq_Word1 <= 32'd21990233; Freq_Word2 <= 32'd351843721; //256000bps
	* **********************************************************************/
	parameter Freq_Word1 = 21990233,
	parameter Freq_Word2 = 351843721
)
(
	input clki,
	input rst_n,
	output reg clk_bps, // send data in specified bps speed;
	output reg clk_smp, // sample data in 16 times of the speed in which uart sends;
	output reg txd_ena, // a edge_detect of the clk_bps
	output reg rxd_ena  // a edge_detect of the clk_smp
);

reg [31:0] cnt1, cnt2;
reg clk_bps_0, clk_bps_1, clk_smp_0, clk_smp_1;

always @(posedge clki, negedge rst_n) begin
	if (~rst_n) begin
		cnt1 <= 0;
		cnt2 <= 0;
	end else begin
		cnt1 <= cnt1 + Freq_Word1;
		cnt2 <= cnt2 + Freq_Word2;
	end 
end 

always @(posedge clki, negedge rst_n) begin
	if (~rst_n) begin
		clk_bps <= 0;
		clk_smp <= 0;
	end else begin
		if (cnt1 < 32'h7fff_ffff) begin 
			clk_bps_0 <= 1;
			clk_bps_1 <= clk_bps_0;
			clk_bps <= clk_bps_1;
		end 
		else begin
			clk_bps_0 <= 0;
			clk_bps_1 <= clk_bps_0;
			clk_bps <= clk_bps_1;
		end
		if (cnt2 < 32'h7fff_ffff) begin
			clk_smp_0 <= 1;
			clk_smp_1 <= clk_smp_0;
			clk_smp <= clk_smp_1;
		end 
		else begin
			clk_smp_0 <= 0;
			clk_smp_1 <= clk_smp_0;
			clk_smp <= clk_smp_1;
		end
	end
end 

always @* begin
	txd_ena = ~clk_bps & clk_bps_1;
	rxd_ena = ~clk_smp & clk_smp_1;	
end

endmodule 
