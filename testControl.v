module game(
    input [9:0] SW,
    input CLOCK_50,
    input [3:0] KEY,
    output [9:0] LEDR
);
    wire ld_top, ld_bottom, ld_color, writeEn;
    control c0(CLOCK_50, KEY[0], !KEY[1], ld_top, ld_bottom, ld_color, writeEn);
    assign LEDR[0] = ld_top;
    assign LEDR[1] = ld_bottom;
    assign LEDR[2] = writeEn;
    assign LEDR[3] = ld_color;
endmodule


module control(
	input clk, resetn, go,
	output reg ld_top, ld_bottom, ld_color, writeEn
	);


	reg [2:0] current_state, next_state;

	
	localparam  TOP = 3'b000,
				TOP_WAIT = 3'b001,
				BOTTOM = 3'b010,
				BOTTOM_WAIT = 3'b011,
				PLOT = 3'b100;


	//reset
	always @(posedge clk) begin
		if (!resetn)
			current_state <= TOP;
		else
			current_state <= next_state;
	end

	//state table
	always @(*) 
	begin: state_table
		case (current_state)
			TOP: next_state = go ? TOP_WAIT : TOP;
			TOP_WAIT: next_state = go ? TOP_WAIT : BOTTOM;
			BOTTOM: next_state = go ? BOTTOM_WAIT : BOTTOM;
			BOTTOM_WAIT: next_state = go ? BOTTOM_WAIT : PLOT;
			PLOT: next_state = PLOT;
			default: next_state = TOP;
		endcase
	end


	//output logic	aka output of datapath control signals
	always @(*)
	begin
		ld_top = 1'b0;
		ld_bottom = 1'b0;
		writeEn = 0;

		case (current_state)
			TOP: begin 
				ld_top = 1'b1;
				ld_bottom = 1'b0;
				PLOT: writeEn = 1;
			end
			BOTTOM: begin
				PLOT: writeEn = 1;
				ld_top = 1'b0;
				ld_bottom = 1'b1;
			end
			
			PLOT: writeEn = 1;

		endcase

	end

endmodule
