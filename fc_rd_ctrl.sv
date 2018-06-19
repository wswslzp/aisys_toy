module fc_rd_ctrl #
(parameter batch_size=1,
 parameter feature_size=1,
 parameter bias_size=1,
 parameter word_len=32)
(
	input clk, rst_n,
	// from fully_connect ------------ Nrc=Network read ctrl,
	// Fc=Fully-connect=Netwwork
	output reg [batch_size-1:0][feature_size-1:0][31:0] NrcFc_data,
	output reg [feature_size-1:0][bias_size-1:0][31:0] NrcFc_weight,
	output reg [bias_size-1:0][31:0] NrcFc_bias,
	output reg NrcFc_data_valid, NrcFc_weight_valid, NrcFc_bias_valid,
	// from bus
	output reg NrcBus_arvalid,
	output reg [3:0] NrcBus_aruserid,
	output reg [3:0] NrcBus_arlen,
	output reg NrcBus_aruserap,
	output reg [27:0] NrcBus_araddr,

	input BusNrc_arready,
	input BusNrc_rvalid,
	input BusNrc_rlast,
	input BusNrc_rid,
	input [31:0] BusNrc_rdata,
	// from fully_connect ctrl
	input [27:0] NcNrc_initAddr,
	input NcNrc_initAddrEn,
	output reg NrcNc_initAddrRq,
	output reg NrcNc_rd_end
);

localparam DATA_SIZE = batch_size * feature_size;
localparam WEIGHT_SIZE = feature_size * bias_size;
localparam BIAS_SIZE = batch_size * bias_size;
localparam ARID = 4'b1001;

reg [2:0] state, nstate;
reg [31:0] cnt;
reg [2:0] data_type;
reg [27:0] _addr;
reg [5:0] rd_cnt;
reg burst_done;
//reg [31:0] _data;

task reset;
	burst_done <= 0;
	rd_cnt <= 0;
	_addr <= 0;
	data_type <= 0;
	NrcFc_data <= 0;
	NrcFc_weight <= 0;
	NrcBus_aruserid <= 0
	NrcBus_arlen <= 0;
	NrcFc_bias <= 0;
	NrcBus_aruserap <= 0;
	NrcBus_araddr <= 0;
	NrcBus_arvalid <= 0;
	NrcFc_data_valid <= 0;
	NrcFc_weight_valid <= 0;
	NrcFc_bias_valid <= 0;
	NrcNc_rd_end <= 0;
endtask

// when flag == 1, read nothing
task read_addr;
	NrcBus_aruserid <= ARID;
	NrcBus_arlen <= 4'h0;
	NrcBus_aruserap <= 1'b1;
	NrcBus_araddr <= _addr;
	NrcBus_arvalid <= 1'b1;
endtask

// when rvalid == 1, begin to read
task read_data;
	if (BusNrc_rvalid && BusNrc_rid == ARID) begin
		if (rd_cnt == 5'd16) begin
			burst_done <= 1'b1;
			rd_cnt <= 0;
		end else burst_done <= 1'b0;
		case (data_type) 
			3'b001: begin
				NrcFc_data <= (NrcFc_data << 32) + BusNrc_rdata;
				rd_cnt <= rd_cnt + 1;
			end 
			3'b010: begin
				NrcFc_weight <= (NrcFc_weight << 32) + BusNrc_rdata;
				rd_cnt <= rd_cnt + 1;
			end 
			3'b100: begin
				NrcFc_bias <= (NrcFc_bias << 32) + BusNrc_rdata;
				rd_cnt <= rd_cnt + 1;
			end
			default: begin
				NrcFc_data <= NrcFc_data;
				NrcFc_weight <= NrcFc_weight;
				NrcFc_bias <= NrcFc_bias;
			end 
		endcase
	end else ;
endtask

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= 3'h0;
	end else state <= nstate;
end 

always @* begin
	case (state) 
		3'h0: nstate = rst_n ? 3'h1 : 3'h0;
		3'h1: nstate = NcNrc_initAddrEn ? 3'h2 : 3'h1;
		3'h2: nstate = 3'h3;
		3'h3: nstate = BusNrc_arready ? 3'h4 : 3'h3;
		3'h4: begin
			if (!burst_done) nstate = 3'h4;
			else begin
				case (data_type) 
					3'b001: nstate = cnt == DATA_SIZE ? 3'h1 : 3'h2;
					3'b010: nstate = cnt == WEIGHT_SIZE ? 3'h1 : 3'h2;
					3'b100: nstate = cnt == BIAS_SIZE ? 3'h1 : 3'h2;
				endcase
			end
		end
		default: nstate = 3'h0;
	endcase
end

always @(posedge clk) begin
	case (state) 

		3'h0: begin
			if (!rst_n) begin
				reset;
			end else begin
				NrcNc_initAddrRq <= 1'b1;
				data_type <= 3'b001;
			end
		end 

		3'h1: begin
			if (NcNrc_initAddrEn) begin
				_addr <= NcNrc_initAddr;
				NrcNc_initAddrRq <= 0;
			end
		end 

		3'h2: begin
			cnt <= cnt + 1;
			_addr <= _addr + _addr * 16 * 32/word_len; // word_len shoule be 32;
		end 

		3'h3: begin
			read_addr;
		end 

		3'h4: begin
			NrcBus_arvalid <= 1'b0;
			read_data;
			case (data_type) 
				3'h001: begin
					if (cnt == DATA_SIZE) begin
						NrcNc_initAddrRq <= 1'b1;
						data_type <= 3'b010;
						NrcFc_data_valid <= 1'b1;
					end else ;
				end
				
				3'b010: begin
					if (cnt == WEIGHT_SIZE) begin
						NrcNc_initAddrRq <= 1'b1;
						data_type <= 3'b100;
						NrcFc_weight_valid <= 1'b1;
					end else;
				end 

				3'b100: begin
					if (cnt == BIAS_SIZE) begin
						NrcNc_initAddrRq <= 1'b1;
						data_type <= 3'b001;
						NrcFc_bias_valid <= 1'b1;
						NrcNc_rd_end <= 1'b1;
					end 
				end

				default: begin
					NrcFc_bias_valid <= 0;
					NrcFc_data_valid <= 0;
					NrcFc_weight_valid <= 0;
				end 
			endcase
		end 

		default: reset;

	endcase
end

endmodule
