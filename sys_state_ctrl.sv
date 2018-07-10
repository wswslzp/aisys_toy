module sys_state_ctrl #
(parameter layer_def=16'h4444) 
(
	// from outside 
	input clk, rst_n,
	output reg system_end
	
	// uart side
	output reg uart_done,
	input uart_wrSel,
	output reg uart_en,
	output reg wrsel,
	
	// from conv
	output reg conv_en,
	input conv_done,

	// from maxpool
	output reg pool_en,
	input reg pool_done
);

reg [4:0] state, nstate;
reg [15:0] layers;//every 4bits represent a layer group;
localparam 
	idle=5'h1,
	read=5'h2,
	conv=5'h3,
	pool=5'h4,
	write=5'h5;

always @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		state <= idle;
	end else begin
		state <= nstate;
	end 
end 

always @* begin
	case (state) 
		idle: nstate = uart_done ? read : idle;
		read: nstate = uart_done ? conv : read;
		conv: begin
			if (!conv_done) nstate = conv;
			else if (conv_end && layers[3:0] < layer_def[3:0]) nstate = conv;
			else nstate = pool;
		end 
		pool: begin
			if (!pool_done) nstate = pool;
			else if (pool_done && layer_def[3:0] != 0) nstate = conv;
			else nstate = write;
		end 
		write: nstate = uart_done ? idle : write;
		default: nstate = idle;
	endcase
end 

always @(posedge clk) begin
	case (state) 
		idle: begin
			uart_en <= 1;
			conv_en <= 1'b0;
			pool_en <= 1'b0;
			uart_wrSel <= 1;
			system_end <= 1'b0;
		end 
		read: if (uart_valid) begin
			conv_en <= 1;
			uart_en <= 1'b0;
			pool_en <= 1'b0;
		end 
		conv: if (conv_done) begin
			if (layers[3:0] < layer_def[3:0]) begin
				layers[3:0] <= layer[3:0] + 1;
				conv_init_addr <= flt_beg_addr[27:0];
				conv_init_addr_en <= 1;
			end else begin
				layers <= {layers[11:0], 4'b0};
				conv_en <= 1'b0;
				pool_en <= 1'b1;
			end 
		end 
		pool: if (pool_done) begin
			if (layers[3:0] == 0) begin
				pool_en <= 1'b0;
				uart_en <= 1'b1;
				uart_wrSel <= 1'b0;
			end else begin
				conv_en <= 1'b1;
				pool_en <= 1'b0;
				uart_en <= 1'b0;
			end 
		end
		write: if (uart_done) begin
			system_end <= 1'b1;
		end 
	end case
end 

endmodule
