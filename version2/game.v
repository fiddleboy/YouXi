`include "timer.v"
`include "game_ball.v"
`include "game_paddle.v"
module game(
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
		VGA_B,   						//	VGA Blue[9:0]
        LEDR,
		HEX0,
		HEX1,
		HEX2,
		HEX3
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
    output  [9:0]   LEDR;
	output  [6:0] 	HEX0;
	output  [6:0] 	HEX1;
	output  [6:0] 	HEX2;
	output  [6:0] 	HEX3;
	
//	hex_decoder hex0(x[3:0], HEX0[6:0]);
//	hex_decoder hex1(x[7:4], HEX1[6:0]);
//	hex_decoder hex2(y[3:0], HEX2[6:0]);
//	hex_decoder hex3(y[6:4], HEX3[6:0]);





	wire resetn;
	assign resetn = KEY[0];
	
	// Create the colour, x, y and writeEn wires that are inputs to the controller.
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
			.resetn(resetn),
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


	wire left, right;
	assign left = !KEY[3];
	assign right = !KEY[2];

    

	
    wire en_ball, en_pad, paddle_done, ball_done;
	wire hold, hold1, draw_hold;
    control_game(
        .clk(CLOCK_50),
        .resetn(resetn),
        .go(1'b1),
        .left(left),
        .right(right),
        .writeEn(writeEn),
        .x_out(x),
        .y_out(y),
        .color_out(colour),
        .enable_ball(en_ball),
        .enable_paddle(en_pad),
		.paddle_done(paddle_done),
		.ball_done(ball_done)
    );  
    assign LEDR[1] = en_pad;
	assign LEDR[2] = paddle_done;
	assign LEDR[3] = ball_done;
	// assign LEDR[7] = hold;
	// assign LEDR[8] = hold1;
	// assign LEDR[9] = draw_hold;
    // assign LEDR[9] = hold;
    // assign LEDR[0] = enable_color;
    // assign LEDR[1] = enable_move;
    // assign LEDR[2] = writeEn;
endmodule


module control_game(
	input clk, resetn, go, left, right, 
	output writeEn,
	output reg [7:0] x_out, 
	output reg [6:0] y_out, 
	output reg enable_ball, enable_paddle, 
	output reg [2:0] color_out,
	output paddle_done, ball_done
    );

    wire writeEn0, writeEn1;
    wire enable_color_ball, enable_color_paddle, enable_move_ball, enable_move_paddle;
    wire [7:0] x_ball, x_paddle; 
	wire [6:0] y_ball, y_paddle;
	wire [2:0] color_ball, color_paddle;

	reg [2:0] current_state, next_state;
    always @(posedge clk) begin
		if (!resetn)
			current_state <= DRAW_BALL;
		else
			current_state <= next_state;
	end

	localparam  DRAW_BALL = 3'd0,
                DRAW_PADDLE = 3'd1;

	// wire done_signal;
	// timer_l t100(.clk(clk), .resetn(resetn), .enable(1'b1), .dividend(26'd1), .time_up(done_signal));


	always @(*) 
	begin: state_table
		case (current_state)
			DRAW_BALL: next_state = ball_done ? DRAW_PADDLE : DRAW_BALL;
            DRAW_PADDLE: next_state = paddle_done ? DRAW_BALL : DRAW_PADDLE;
			default: next_state = DRAW_BALL;
		endcase
	end

	always @(*)
	begin
        enable_ball = 1'b0;
        enable_paddle = 1'b0;

		case (current_state)
			DRAW_BALL: begin
                enable_ball = 1'b1;
            end
            DRAW_PADDLE: begin
                enable_paddle = 1'b1;
            end
		endcase
	end

	wire draw, draw1;
	control_paddle c0(
		.clk(clk), 
		.resetn(resetn), 
		.go(enable_paddle), 
		.draw_done(draw_done1),
		.enable_color(enable_color_paddle), 
		.enable_move(enable_move_paddle), 
		.writeEn(writeEn0), 
		.done(paddle_done),
		.draw(draw)
		);
	
    control_ball c1(
        .clk(clk), 
        .resetn(resetn), 
        .go(enable_ball),
		.draw_done(draw_done),
        .enable_color(enable_color_ball),
        .enable_move(enable_move_ball),
        .writeEn(writeEn1),
		.draw(draw1),
        .done(ball_done)
        );	
	
	assign writeEn = writeEn0 | writeEn1;
	wire draw_done, draw_done1;
	datapath_ball p0(
		.clk(clk),
		.resetn(resetn),
        .enable_color(enable_color_ball),
        .enable_move(enable_move_ball),
		.draw(draw1),
		.x_paddle(x_paddle),
		.x_out(x_ball),
		.y_out(y_ball),
		.color_out(color_ball),
		.draw_done(draw_done)
	);

    datapath_paddle p1(
		.clk(clk),
		.resetn(resetn),
        .enable_color(enable_color_paddle),
        .enable_move(enable_move_paddle),
		.left(left),
		.right(right),
		.draw(draw),
		.x_out(x_paddle),
		.y_out(y_paddle),		
		.color_out(color_paddle),
		.draw_done(draw_done1),
	);

    always @(*) begin
        if (enable_ball & ~enable_paddle) begin
            x_out = x_ball;
            y_out = y_ball;
            color_out = color_ball;
        end
        else if (enable_paddle & ~enable_ball) begin
            x_out = x_paddle;
            y_out = y_paddle;
            color_out = color_paddle;
        end
    end
	// always @(*) begin
	// 	x_out = x_ball;
    // 	y_out = y_ball;
    // 	color_out = color_ball;
	// end

endmodule



