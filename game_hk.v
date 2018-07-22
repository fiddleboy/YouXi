module game
	(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
        KEY,
        SW,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire reset;
	assign reset = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn, ld_x, ld_y, ld_color, enable;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.reset(reset),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x),
			.y(y),
			.plot(writeEn),
			/* Signals for the DAC to drive the monitor. */
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "black.mif";


    wire b_top, b_bottom;

	datapath data0(
		.clk(CLOCK_50),
		.reset(reset),
        .b_top(b_top),
        .b_bottom(b_bottom),
		.x_out(x),
		.y_out(y),
		.color_out(colour)
	);



    control c0(
		.clk(CLOCK_50),
		.reset(reset),
		.go(!(KEY[1])),
        .b_top(b_top),
        .b_bottom(b_bottom),
		.writeEn(writeEn)	
	);
endmodule

module delay_counter(
	input clk, reset, enable,
	output delay_enable;
);
	reg [19:0] count;
	always @(posedge clk) begin
		if (!reset)
			count <= 20'd833334;
		else if (enable) begin
			if (count == 20'd0)
				count <= 20'd833334;
			else
				count <= count - 1'b1;
		end
	end
		
	assign delay_enable = (count == 20'd0) ? 1 : 0;
	
endmodule


module control(
    input clk, reset, go,
    output reg b_top, b_bottom, writeEn
);
    reg [3:0] current_state, next_state;

    localparam  BORDER_TOP = 4'd0,
                BORDER_BOTTOM = 4'd1;

    always @(*)
    begin: state_table
        case (current_state)
            BORDER_TOP: next_state = BORDER_BOTTOM;
        endcase
    end

    always @(*)
    begin
        b_top = 1'b0;
        b_bottom = 1'b0;
        writeEn = 1'b0;

        case (current_state)
            BORDER_TOP: begin
                b_top = 1'b1;
                writeEn = 1'b1;
            end
            BORDER_BOTTOM: begin
                b_top = 1'b0;
                b_bottom = 1'b1;
                writeEn = 1'b1;
            end
        endcase

    end

endmodule





module x_counter(
    input clk, b_top, b_bottom,
    output reg [7:0] x_out
);
    wire [7:0] x_initial_pos;
    always @(*)
    begin
        if (b_top || b_bottom)
            x_initial_pos = 8'd15;
    end
    
    always @(posedge clk) begin
        if (!reset)
            x_out <= x_initial_pos;
        else if (b_top || b_bottom) begin
            x_out <= x_out + 1'b1;
        end
    end

endmodule





module y_counter(
    input b_top, b_bottom, reset,
    output [6:0] y_out

);

wire [6:0] y_initial_pos;
    always @(*)
    begin
        if (b_top)
            y_initial_pos = 7'd20;
        else if (b_bottom)
            y_initial_pos = 7'd105
    end
    
    always @(posedge clk) begin
        if (!reset)
            y_out <= y_initial_pos;
        else if (b_top || b_bottom) begin
            y_out <= y_out;
        end
    end


endmodule


module datapath(
    input clk, reset, b_top, b_bottom,
    output [7:0] x_out,
    output [6:0] y_out,
    output [2:0] color_out
);
    wire delay_enable;
    delay_counter d_c(  
        .clk(clk), 
        .reset(reset), 
        .enable(1'b1), 
        .delay_enable(delay_enable)
        );



    x_counter x_c0(
        .clk(delay_enable),
        .b_top(b_top),
        .b_bottom(b_bottom),
        .x_out(x_out)
    );


    y_counter y_c0(
        .clk(delay_enable),
        .b_top(b_top),
        .b_bottom(b_bottom),
        .y_out(y_out)
    );
    draw d0();

endmodule



module draw(
    input clk, reset,
    input [7:0] x_in, 
	input [6:0] y_in,
	input [2:0] color_in,
	output [7:0] x_out, 
	output [6:0] y_out, 
	output [2:0] color_out
);

endmodule