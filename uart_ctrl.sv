module uart_ctrl
(
	// from outside 
	input clk, rst_n,
	input rxd,
	output txd,
	// from uart_clkgen
	input clk_bps,
	input clk_smp,
	input txd_ena,
	input rxd_ena,
	// to bus_bridge
	input [31:0] data_in,
	output reg [31:0] data_out,
	// from control_unit
	output reg data_out_en,
	input data_in_en,
	input [2:0] wr_sel,
	output reg txd_valid, rxd_ready
);

reg [31:0] data_in_buf;
reg [1:0] state, nstate;
reg [1:0] wstate, nwstate;
reg [1:0] rstate, nrstate;
reg [2:0] t_cnt;
reg [3:0] r_cnt, frame_cnt, data_cnt;
reg t0, t1, neg, rxd_smp;
reg frame_end;

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) state <= 2'h0;
	else state <= nstate;
end 

always @* begin
	case(state) 
		2'h0: begin
			if (wr_sel == 3'b100) nstate = 2'h1; // if wr_sel=100, then state change to write/send/txd mode (2'h1)
			else if (wr_sel == 3'b010) nstate = 2'h2; // if wr_sel=010, then state change to read/rxd mode (2'h2)
			else nstate = 2'h0; // if wr_sel=000, then the transition close and the state change to idle (2'h0) 
		end 
		2'h1: nstate = wr_sel == 3'b001 ? 2'h0 : 2'h1;
		2'h2: nstate = wr_sel == 3'b001 ? 2'h0 : 2'h2;
		default: nstate = 2'h0;
	endcase
end

// Code below about txd
always @(posedge clk_bps, negedge rst_n) begin
	if (!rst_n) wstate <= 0;
	else begin
		if (state != 2'h1) wstate <= 0;
		else wstate <= nwstate;
	end
end

always @* begin
	case (wstate) 
		2'h0: begin
			if (data_in_en == 1 && state == 2'h1) nwstate = 2'h0;
			else nwstate = 2'h1;
		end 
		2'h1: begin
			nwstate = 2'h2;
		end 
		2'h2: begin
			if (!frame_end) nwstate = 2'h2;
			else if (frame_end == 1 && t_cnt != 3'h4) nwstate = 2'h1;
			else nwstate = 2'h0;
		end
		default: nwstate = 0;
	endcase
end

task send;
	case (tstate) 
		4'h0: begin 
			txd <= 0;
			frame_end <= 0;
		end
		4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8: begin
			txd <= txd_buf[7];
			txd_buf <= txd_buf << 1;
		end 
		4'h10: begin
			txd <= 1;
			frame_end <= 1;
		end 
	endcase
endtask

always @(posedge clk_bps) begin
	case (wstate) 
		2'h0: begin
			if (data_in_en == 1 && state == 2'h1) begin
				data_in_buf <= data_in;
				t_cnt <= 0;
			end 
		end
		2'h1: begin
			txd_buf <= data_in_buf[31:24];
			data_in_buf <= data_in_buf << 8;
			t_cnt <= t_cnt + 1;
		end 
		2'h2: begin
			send;
			if (t_cnt == 3'h4 &&  frame_end == 1) txd_valid <= 1;
		end 
	endcase
end 

// Code below about rxd
always @(posedge clk_smp, negedge rst_n) begin
	if (!rst_n) begin rstate <= 0;
	else begin
		if (state != 2'h2) rstate <= 0;
		else rstate <= nrstate;
	end
end 

always @* begin
	case (rstate) 
		2'h0: nrstate = neg == 1 ? 2'h1 : 2'h0; //negedge detection actived then change the state
		2'h1: begin
			if (r_cnt != 4'h7) nrstate = 2'h1;
			else if (r_cnt == 4'h7 && rxd_smp != 0) nrstate = 2'h0; // The middle is not 0, and maybe wrong
			else nrstate = 2'h2;
		end 
		2'h2: nrstate = frame_cnt == 4'h8 ? 2'h0 : 2'h2;
	endcase
end 

always @(posedge clk_smp) begin
	case (rstate) 
		2'h0: begin
			t0 <= txd;
			t1 <= t0;
			neg <= ~t0 & t1;
			frame_cnt <= 0;
			r_cnt <= 0;
			rxd_ready <= 0;
		end 
		2'h1: begin
			r_cnt <= r_cnt + 1;
			if (r_cnt == 4'h7) rxd_smp <= rxd;
		end 
		2'h2: begin
			r_cnt <= r_cnt + 1;
			if (r_cnt == 4'h7) data_out[0] <= rxd;
			data_out <= data_out << 1;
			if (frame_cnt != 4'h8)  
				frame_cnt <= frame_cnt + 1;
			else begin 
				frame_cnt <= 0;
				frame_end <= 1;
			end
		end
	endcase
end

always @(posedge rxd_ready) begin
	if (data_cnt != 3'h4) data_cnt <= data_cnt + 1;
	else begin
		data_cnt <= 0;
		rxd_ready <= 1;
	end
end

endmodule
