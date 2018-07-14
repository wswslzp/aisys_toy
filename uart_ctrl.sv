module uart_ctrl
(
	// from outside 
	input clk, rst_n,
	input rxd,
	output reg txd,
	// from uart_clkgen
	input UckUc_clk_bps,
	input UckUc_clk_smp,
	input UckUc_txd_ena,
	input UckUc_rxd_ena,
	// to bus_bridge
	input [31:0] UbUc_data_in,
	output reg [31:0] UcUb_data_out,
	// from control_unit
	output reg UcUb_data_out_en,
	input UbUc_data_in_en,
	input [2:0] UnUc_wr_sel,
	output reg UcUn_txd_valid, UcUn_rxd_ready
);

reg [31:0] data_in_buf;
reg [1:0] state, nstate;
reg [1:0] wstate, nwstate;
reg [1:0] rstate, nrstate;
reg [2:0] t_cnt;
reg [3:0] r_cnt, bit_cnt, data_cnt;
reg t0, t1, neg, rxd_start;
reg frame_end;
reg [7:0] txd_buf;

always @(posedge clk, negedge rst_n) begin
	if (~rst_n) state <= 2'h0;
	else state <= nstate;
end 

always @* begin
	case(state) 
		2'h0: begin
			if (UnUc_wr_sel == 3'b100) nstate = 2'h1; // if UnUc_wr_sel=100, then state change to write/send/txd mode (2'h1)
			else if (UnUc_wr_sel == 3'b010) nstate = 2'h2; // if UnUc_wr_sel=010, then state change to read/rxd mode (2'h2)
			else nstate = 2'h0; // if UnUc_wr_sel=000, then the transition close and the state change to idle (2'h0) 
		end 
		2'h1: nstate = UnUc_wr_sel == 3'b001 ? 2'h0 : 2'h1;
		2'h2: nstate = UnUc_wr_sel == 3'b001 ? 2'h0 : 2'h2;
		default: nstate = 2'h0;
	endcase
end

// Code below about txd
always @(posedge UckUc_clk_bps, negedge rst_n) begin
	if (!rst_n) wstate <= 0;
	else begin
		if (state != 2'h1) wstate <= 0;
		else wstate <= nwstate;
	end
end

always @* begin
	case (wstate) 
		2'h0: begin
			if (UbUc_data_in_en == 1 && state == 2'h1) nwstate = 2'h0;
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
	case (wstate) 
		4'h0: begin 
			txd <= 0;
			frame_end <= 0;
		end
		4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6, 4'h7, 4'h8: begin
			txd <= txd_buf[7];
			txd_buf <= txd_buf << 1;
		end 
		4'h9: begin
			txd <= 1;
			frame_end <= 1;
		end 
	endcase
endtask

always @(posedge UckUc_clk_bps) begin
	case (wstate) 
		2'h0: begin
			if (UbUc_data_in_en == 1 && state == 2'h1) begin
				data_in_buf <= UbUc_data_in;
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
			if (t_cnt == 3'h4 &&  frame_end == 1) UcUn_txd_valid <= 1;// if 32bit data has all been sent, then UcUn_txd_valid = 1;
		end 
	endcase
end 

// Code below about rxd
always @(posedge UckUc_clk_smp, negedge rst_n) begin
	if (!rst_n) rstate <= 0;
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
			else if (r_cnt == 4'h7 && rxd_start != 0) nrstate = 2'h0; // The middle is not 0, and maybe wrong
			else nrstate = 2'h2;
		end 
		2'h2: nrstate = bit_cnt == 4'h8 ? 2'h0 : 2'h2;
	endcase
end 

always @(posedge UckUc_clk_smp) begin
	case (rstate) 
		2'h0: begin
			t0 <= txd;
			t1 <= t0;
			neg <= ~t0 & t1;
			bit_cnt <= 0;
			r_cnt <= 0;
			frame_end <= 0;
		end 
		2'h1: begin
			r_cnt <= r_cnt + 1;
			if (r_cnt == 4'h7) rxd_start <= rxd;// r_cnt==7, sample the data
		end 
		2'h2: begin
			r_cnt <= r_cnt + 1;
			if (r_cnt == 4'h7)
				UcUb_data_out <= {UcUb_data_out[30:0], rxd};
			else;
			if (bit_cnt != 4'h8)  
				bit_cnt <= bit_cnt + 1;
			else begin 
				bit_cnt <= 0;
				frame_end <= 1;
			end
		end
	endcase
end

always @(posedge frame_end) begin
	if (data_cnt != 3'h4) begin
		data_cnt <= data_cnt + 1;
		UcUn_rxd_ready <= 0;
	end
	else begin
		data_cnt <= 0;
		UcUn_rxd_ready <= 1;// when 32bit data has been read from the rxd, then UcUn_rxd_ready==1
		UcUb_data_out_en <= 1;
	end
end

endmodule
