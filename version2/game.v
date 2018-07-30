`include "timer.v"
`include "game_ball.v"
`include "game_paddle.v"
`include "game_paddle_top.v"
`include "draw_border.v"
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
        LEDR
		// HEX0,
		// HEX1,
		// HEX2,
		// HEX3,
		// HEX4,
		// HEX5
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
	// output  [6:0] 	HEX0;
	// output  [6:0] 	HEX1;
	// output  [6:0] 	HEX2;
	// output  [6:0] 	HEX3;
	// output  [6:0] 	HEX4;
	// output  [6:0] 	HEX5;
	
//	hex_decoder hex0(x[3:0], HEX0[6:0]);
//	hex_decoder hex1(x[7:4], HEX1[6:0]);
//	hex_decoder hex2(y[3:0], HEX2[6:0]);
//	hex_decoder hex3(y[6:4], HEX3[6:0]);
	// reg left_top, right_top;
	// always @(*) begin
	// 	if (SW[1] & ~SW[0]) begin
	// 		left_top = 1'b1;
	// 		right_top = 1'b0;
	// 	end
	// 	else if (SW[0] & ~SW[1]) begin
	// 		right_top = 1'b1;
	// 		left_top = 1'b0;
	// 	end
	// 	else begin
	// 		left_top = 1'b0;
	// 		right_top = 1'b0;
	// 	end

	// end

	wire resetn;
	assign resetn = SW[0];
	
	wire [2:0] colour;
	wire [7:0] x;
	wire [6:0] y;
	wire writeEn;

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

	wire left, right, left_top, right_top;
	assign left = !KEY[3];
	assign right = !KEY[2];
	assign left_top = !KEY[1];
	assign right_top = !KEY[0];
    wire paddle_done, ball_done, c;
    control_game(
        .clk(CLOCK_50),
        .resetn(resetn),
        .go(1'b1),
        .left(left),
        .right(right),
		.left_top(left_top),
  		.right_top(right_top),		
        .writeEn(writeEn),
        .x_out(x),
        .y_out(y),
        .color_out(colour)
    );  

endmodule


module control_game(
	input clk, resetn, go, left, right, left_top, right_top,
	output writeEn,
	output reg [7:0] x_out, 
	output reg [6:0] y_out,
	output reg [2:0] color_out
    );
	reg enable_ball, enable_paddle, enable_border;
    wire writeEn0, writeEn1, writeEn2;
    wire enable_color_ball, enable_color_paddle, enable_move_ball, enable_move_paddle;
    wire [7:0] x_ball, x_paddle; 
	wire [6:0] y_ball, y_paddle;
	wire [2:0] color_ball, color_paddle;

	reg [2:0] current_state, next_state;
    always @(posedge clk) begin
		if (!resetn)
			current_state <= DRAW_BORDER;
		else
			current_state <= next_state;
	end

	localparam  DRAW_BORDER = 3'd0,
				DRAW_BALL = 3'd1,
                DRAW_PADDLE = 3'd2,
				DRAW_PADDLE_TOP = 3'd3;

	always @(*) 
	begin: state_table
		case (current_state)
			DRAW_BORDER: next_state = draw_done_border ? DRAW_BALL : DRAW_BORDER;
			DRAW_BALL: next_state = ball_done ? DRAW_PADDLE : DRAW_BALL;
            DRAW_PADDLE: next_state = paddle_done ? DRAW_PADDLE_TOP : DRAW_PADDLE;
			DRAW_PADDLE_TOP: next_state = paddle_top_done ? DRAW_BALL : DRAW_PADDLE_TOP;
			default: next_state = DRAW_BORDER;
		endcase
	end
	reg enable_paddle_top;
	always @(*)
	begin
        enable_ball = 1'b0;
        enable_paddle = 1'b0;
		enable_border = 1'b0;
		enable_paddle_top = 1'b0;

		case (current_state)
			DRAW_BORDER: begin
				enable_border = 1'b1;
			end
			DRAW_BALL: begin
                enable_ball = 1'b1;
            end
            DRAW_PADDLE: begin
                enable_paddle = 1'b1;
            end
			DRAW_PADDLE_TOP: begin
				enable_paddle_top = 1'b1;
			end
		endcase
	end

	wire draw_done_border;
	wire [7:0] x_border;
	wire [6:0] y_border;
	wire [2:0] color_border;
	draw_border d0(
		.clk(clk),
		.resetn(resetn),
		.go(enable_border),
		.done(draw_done_border),
		.writeEn(writeEn2),
		.x_out(x_border),
		.y_out(y_border),
		.color_out(color_border)
	);

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
	wire draw_done2, enable_color_paddle_top, enable_move_paddle_top, writeEn3, paddle_top_done;
	wire draw2;
	control_paddle_top c2(
		.clk(clk), 
		.resetn(resetn), 
		.go(enable_paddle_top), 
		.draw_done(draw_done2),
		.enable_color(enable_color_paddle_top), 
		.enable_move(enable_move_paddle_top), 
		.writeEn(writeEn3), 
		.done(paddle_top_done),
		.draw(draw2)
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
        .done(ball_done),
		.reset_counter(reset_counter)
        );	
	
	assign writeEn = (writeEn0 | writeEn1 |writeEn2 | writeEn3);
	wire draw_done, draw_done1, reset_counter;
	
	datapath_ball p0(
		.clk(clk),
		.resetn(resetn),
        .enable_color(enable_color_ball),
        .enable_move(enable_move_ball),
		.draw(draw1),
		.reset_counter(reset_counter),
		.x_paddle(x_paddle),
		.x_paddle_top(x_paddle_top),
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

	wire [2:0] color_paddle_top;
	wire [7:0] x_paddle_top;
	wire [6:0] y_paddle_top;
	datapath_paddle_top p2(
		.clk(clk),
		.resetn(resetn),
        .enable_color(enable_color_paddle_top),
        .enable_move(enable_move_paddle_top),
		.left(left_top),
		.right(right_top),
		.draw(draw2),
		.x_out(x_paddle_top),
		.y_out(y_paddle_top),		
		.color_out(color_paddle_top),
		.draw_done(draw_done2),
	);

    always @(*) begin
		if (enable_border) begin
			x_out = x_border;
			y_out = y_border;
			color_out = color_border;
		end
		else if (enable_ball) begin
			x_out = x_ball;
			y_out = y_ball;
			color_out = color_ball;
		end
		else if (enable_paddle) begin
			x_out = x_paddle;
			y_out = y_paddle;
			color_out = color_paddle;
		end
		else if (enable_paddle_top) begin
			x_out = x_paddle_top;
			y_out = y_paddle_top;
			color_out = color_paddle_top;			
		end
    end

endmodule



