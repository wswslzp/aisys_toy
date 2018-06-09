module conv_rd_bridge #
(parameter channel_size = 64,
 parameter repeat_time = 4, // need to read 4 times to complete 64 channels' pixel 
 parameter width=32) // databus's width 
(
	input clk, rst_n,
	// from the conv_layer side
	input [27:0] rd_addr,
	input addr_ena, // read addr enable
	output reg [channel_size*32-1:0] conv_in,
	output reg in_valid, // indicate that the data is valid

	// from the bus side
	input arready, // read addr ready
	input rvalid, 
	input rlast,
	input [3:0] rid,
	input [width-1:0] rdata,

	output reg arvalid,
	output reg [3:0] aruser_id,
	output reg [3:0] arlen,
	output reg aruser_ap,
	output reg [27:0] araddr
);

reg [27:0] addr;
reg [3:0] state, nstate;
reg [2:0] last_cnt;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n || !addr_ena) begin
		addr <= 28'b0;
	end else if (rlast == 1) begin
		addr <= addr + 28'h000_0010; // default len = 16
	end else if (addr_ena) begin
		addr <= rd_addr;
   end else ;
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= 4'h0;
	end else begin
		state <= nstate;
	end 
end 

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		last_cnt <= 0;
	end 
	else begin
		if (last_cnt != repeat_time && rlast) last_cnt <= last_cnt + 1;
		else if (last_cnt == repeat_time) last_cnt <= 0;
		else last_cnt <= last_cnt;
	end 
end 

always @(*) begin
	case(state)
		4'h0: nstate = addr_ena ? 4'h1 : 4'h0;

		4'h1: nstate = arready ? 4'h2 : 4'h1;

		4'h2: nstate = (rvalid && rid==4'h1) ? 4'h3 : 4'h2;

		4'h3: begin //nstate = rlast ? 4'h0 : 4'h3;
			if (rlast) begin
				nstate = 4'h1;
			end else nstate = 4'h3;
		end 

		default: nstate = 4'h0;
	endcase
end 

always @* begin
	case (state) 
		4'h0: begin
			arvalid = 1'b0;
			aruser_id = 4'h0;
			arlen = 4'h0;
			aruser_ap = 1'b0;
			araddr = 28'b0;
			in_valid = 1'b0;

		end 

		4'h1: begin
			arvalid = 1'b1;
			aruser_id = 4'h1;
			arlen = 4'h0;
			aruser_ap = 1'b1;
			araddr = addr;
			in_valid = 1'b0;
		end 

		4'h2: begin
			arvalid = 1'b1;
			aruser_id = 4'h1;
			arlen = 4'h0;
			aruser_ap = 1'b1;
			araddr = addr;
			in_valid = 1'b0;
		end

		4'h3: begin
			if (last_cnt == 3'h4) in_valid = 1'b1;
			else in_valid = 1'b0;
			arvalid = 1'b1;
			aruser_id = 4'h1;
			arlen = 4'h0;
			aruser_ap = 1'b1;
			araddr = addr;
		end 

		default: begin
			arvalid = 1'b0;
			aruser_id = 4'h0;
			arlen = 4'h0;
			aruser_ap = 1'b0;
			araddr = 28'b0;
			in_valid = 1'b0;

		end 
	endcase
end 

always @(posedge clk) begin
	if (state == 4'h3) begin
		conv_in <= {conv_in[channel_size*32-width-1:0], rdata};
	end else ;
end 

endmodule
