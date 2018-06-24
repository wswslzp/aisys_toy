module fc_ctrl #
(parameter data_init_addr=0,
	parameter weight_init_addr=0,
	parameter bias_init_addr=0)
(
	input clk, rst_n,
	// from fc_rd_ctrl
	output reg NcNrc_initAddrEn,
	output reg [27:0] NcNrc_initAddr,
	input NrcNc_initAddrRq,
	input [2:0] NrcNc_dataType,
	input NrcNc_rd_end,
	// from fc_wr_ctrl
	output reg [27:0] NcNwc_initAddr,
	output reg NcNwc_initAddrEn,
	input NwcNc_done,
	// from outside
	input fc_en,
	output reg fc_done
);

reg [1:0] state, nstate;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= 0;
	end else begin
		state <= nstate;
	end 
end 

always @* begin
	case (state) 
		2'h0: nstate = rst_n && fc_en ? 2'h1 : 2'h0;
		2'h1: nstate = 2'h2;
		2'h2: begin
			if (NrcNc_initAddrRq == 0 && NrcNc_rd_end == 0) begin
				nstate = 2'h2;
			end else if (NrcNc_initAddrRq == 1 && NrcNc_rd_end == 0) begin
				nstate = 2'h1;
			end else begin
				nstate = 2'h3;
			end 
		end 
		2'h3: nstate = NwcNc_done ? 2'h0 : 2'h3;
	endcase 
end

always @(posedge clk) begin
	case (state) 
		2'h0: begin
			if (!rst_n || !fc_en) begin
				reset;
			end
		end
		2'h1: begin
			case (NrcNc_dataType) 
				3'b001: begin // data
					NcNrc_initAddr <= data_init_addr;
					NcNrc_initAddrEn <= 1'b1;
				end
				3'b010: begin // weight
					NcNrc_initAddr <= weight_init_addr;
					NcNrc_initAddrEn <= 1'b1;
				end 
				3'b100: begin // bias 
					NcNrc_initAddr <= bias_init_addr;
					NcNrc_initAddrEn <= 1'b1;
				end 
				default: NcNrc_initAddrEn <= 0;
			endcase
		end 
		2'h2: begin
			if (NrcNc_rd_end) begin
				NcNwc_initAddr <= data_init_addr;
				NcNwc_initAddrEn <= 1'b1;
			end 
		end 
		2'h3: begin
			if (NwcNc_done) fc_done <= 1'b1;
		end
	endcase 
end

endmodule
