`timescale 1ns/1ps

module div_7 (

	input clk, rst, start,
	input [15:0] data,      // Max number is 65536
	
	output reg valid, busy,
	output reg [3:0] reminder,
	output reg [13:0] q			// div data/7 max result is ~9362 (14 bits)
	);

reg [15:0] data_reg;
reg [3:0] bit_cnt;

wire [4:0] shifted;

assign shifted = {reminder, 1'b0} + data_reg[bit_cnt]; 

localparam 	IDLE = 2'b00,
			RUN	 = 2'b01,
			DONE = 2'b10;

reg [1:0] state;

always @ (posedge clk)
begin

	if (rst)
		begin
			valid    <= 1'b0 ;
			busy     <= 1'b0 ;
			reminder <= 4'd0 ;
			q 		 <= 14'd0;
			bit_cnt  <= 4'd0;
			data_reg <= 16'd0;
			state    <= IDLE;
		end
		
	else
		begin
		
		valid <= 1'b0;
		
		case (state)
			
			IDLE : begin
				
				busy  <= 1'b0;
				
				if (start)
					begin
						busy	   <= 1'b1;
						reminder   <= 4'd0;
						q          <= 14'd0;
						bit_cnt    <= 4'd15;
						data_reg   <= data;
						state 	   <= RUN;
					end
				end
				
			RUN : begin 
				
				if (shifted >= 7)
					begin
						reminder <= shifted - 5'd7;
						q 		 <= {q[12:0], 1'b1};
					end
				else
					begin
						reminder <= shifted[3:0];
						q 		 <= {q[12:0], 1'b0};
				    end
				    
				if (bit_cnt == 4'd0)
					begin
						valid <= 1'b1;
						busy  <= 1'b0;
						state <= DONE;
					end
				else
					begin
						bit_cnt <= bit_cnt - 1;
					end
				end
				
			DONE : begin
				
				state <= IDLE;
				end
				
			default : begin
				
				state <= IDLE;
				end
			endcase
			
		end

end

endmodule				
		