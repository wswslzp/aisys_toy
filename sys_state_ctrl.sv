// TODO : wait to rewrite!!!!!!!!
module sys_state_ctrl #
(parameter layer_def=16'h4444) 
(
	// from outside 
	input clk, rst_n,
	output reg system_end,
	
	// uart side
	input rdone, wdone,
	output reg [2:0] uart_wrSel,
	output reg uart_en,
	output reg uart_link_write,
	output reg uart_link_read,
	
	// from conv
	output reg conv_en,
	input conv_done,
	output reg conv_link_read, conv_link_write, conv_init_addr_en,
	output reg [27:0] conv_init_addr,

	// from maxpool
	output reg pool_en,
	input reg pool_done,
	output reg pool_link_read, pool_link_write,

	// from fully connect
	input fc_done,
	output reg fc_en,
	output reg fc_link_read, fc_link_write
);

reg [4:0] state, nstate;
reg [15:0] layers;//every 4bits represent a layer group;
localparam 
	idle=5'h1,
	read=5'h2,
	conv=5'h3,
	pool=5'h4,
	fc = 5'h5,
	write=5'h6;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= idle;
	end else begin
		state <= nstate;
	end 
end 

always @* begin
	case (state) 
		idle: nstate = rst_n ? read : idle;
		read: nstate = rdone ? conv : read;
		conv: begin
			if (!conv_done) nstate = conv;
			else if (conv_done && layers[3:0] < layer_def[3:0]) nstate = conv;
			else nstate = pool;
		end 
		pool: begin
			if (!pool_done) nstate = pool;
			else if (pool_done && layer_def[3:0] != 0) nstate = conv;
			else nstate = fc;
		end 
		fc: if (!fc_done) nstate = fc;
				else nstate = write;
		write: nstate = wdone ? idle : write;
		default: nstate = idle;
	endcase
end 

always @(posedge clk) begin
	case (state) 
		idle: begin
			uart_en <= 1;
			conv_en <= 1'b0;
			pool_en <= 1'b0;
			uart_wrSel <= 3'b0;
			system_end <= 1'b0;
			uart_link_read <= 1;
			uart_link_write <= 0;
			conv_link_read <= 0;
			conv_link_write <= 0;
			pool_link_read <= 0;
			pool_link_write <= 0;
			fc_link_read <= 0;
			fc_link_write <= 0;
		end 
		read: if (rdone) begin
			conv_en <= 1;
			uart_en <= 1'b0;
			uart_wrSel <= 3'b0;
			uart_link_read <= 0;
			uart_link_write <= 0;
			conv_link_read <= 1;
			conv_link_write <= 1;
			pool_link_read <= 0;
			pool_link_write <= 0;
			fc_link_read <= 0;
			fc_link_write <= 0;
			pool_en <= 1'b0;
			fc_en <= 0;
		end 
		conv: if (conv_done) begin
			if (layers[3:0] < layer_def[3:0]) begin
				layers[3:0] <= layers[3:0] + 1;
				//conv_init_addr <= flt_beg_addr[27:0];
				//conv_init_addr_en <= 1;
			end else begin
				layers <= {layers[11:0], 4'b0};
				conv_en <= 1'b0;
				conv_link_read <= 0;
				conv_link_write <= 0;
				pool_link_read <= 1;
				pool_link_write <= 1;
				fc_link_read <= 0;
				fc_link_write <= 0;
				fc_en <= 0;
				pool_en <= 1'b1;
			end 
		end 
		pool: if (pool_done) begin
			if (layers[3:0] == 0) begin
				pool_en <= 1'b0;
				fc_en <= 1;
				fc_link_read <= 1;
				conv_link_read <= 0;
				conv_link_write <= 0;
				fc_link_write <= 1;
				pool_link_read <= 0;
				pool_link_write <= 0;
			end else begin
				conv_link_read <= 1;
				conv_link_write <= 1;
				fc_en <= 0;
				fc_link_read <= 1;
				fc_link_write <= 1;
				pool_link_read <= 0;
				pool_link_write <= 0;
				conv_en <= 1'b1;
				pool_en <= 1'b0;
			end 
		end
		fc: if (fc_done) begin
			uart_en <= 1'b1;
			uart_wrSel <= 3'b010;
			uart_link_write <= 1;
			uart_link_read <= 0;
			fc_en <= 0;
			fc_link_read <= 0;
			fc_link_write <= 0;
		end
		write: if (wdone) begin
			system_end <= 1'b1;
		end 
	endcase
end 

endmodule
