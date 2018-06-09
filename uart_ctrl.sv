module uart_ctrl
(
	input clk, rst_n, 
	input rxd, 
	input ena, // enable the uart_ctrl, remember until uart sent a bit, with 2Mbps!!
	input wr_sel, // select the mode: write/read
	input link_read, // read bus switch
	input link_write, // write bus switch
	output reg txd, uart_rvalid, uart_wready, // rvalid: flag that means the data from rxd has been sent to the bus. wready: flag that means the data sent an 8bit to txd;
	inout [31:0] data
);

reg [31:0] data_out_buf, data_in_buf;
reg [7:0] read_buf;
reg [9:0] write_buf;
reg [3:0] rstate, wstate;
reg [2:0] byte_sel;

assign data = link_read ? data_out_buf : 32'hzzzz_zzzz;
always @* uart_rvalid = byte_sel[2];

always @(posedge clk) begin
	if (link_write) begin
    data_in_buf <= link_write ? data : data_in_buf; 
	end else begin
    if (uart_wready && ena) begin
			data_in_buf <= {data_in_buf[23:0], 8'b0};
    end else begin
			data_in_buf <= data_in_buf;
		end 
	end 
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		data_out_buf <= 0;
		//data_in_buf <= 0;
		read_buf <= 0;
		write_buf <= 0;
		rstate <= 0;
		wstate <= 0;
		byte_sel <= 0;  
		//uart_rvalid <= 0;
		uart_wready <= 1;
	end else begin
		if (ena) begin 
			if (wr_sel) begin //wr_sel=1, read
				case (rstate) 
					4'h0: begin
						rstate <= ~rxd ? 4'h1 : 4'h0;
						if (byte_sel == 3'h4) begin
							byte_sel <= 3'b0;
						end else ;
					end 
					4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8: begin
						read_buf <= {read_buf[6:0], rxd};
						rstate <= rstate + 4'b1;
					end 
					4'h9: begin
						data_out_buf <= {data_out_buf[23:0], read_buf};
						byte_sel <= byte_sel + 3'b1;
						rstate <= 4'h0;
					end 
					default: rstate <= 4'h0;
				endcase
			end else begin // wr_sel=0, write
				case (wstate) 
					4'h0: begin
						txd <= 1'b1;
						write_buf <= {1'b0, data_in_buf[31:24], 1'b1};
						wstate <= 4'h1;
						uart_wready <= 1'b0;
					end 
					4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8, 4'h9, 4'ha: begin
						txd <= write_buf[9];
						write_buf <= {write_buf[8:0], 1'b0};
						wstate <= wstate + 4'b1;
					end 
					default: begin 
						wstate <= 4'h0;
						uart_wready <= 1'b1;
					end 
				endcase
			end 
		end else ;// ena = 0 hold everything unchanged
	end
end 

endmodule
