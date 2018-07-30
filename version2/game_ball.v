module control_ball(
	input clk, resetn, go, draw_done,
	output reg enable_color, enable_move, writeEn, draw,
    output reg done, reset_counter
    );
    
    wire hold, hold1;
	
	timer_l t002(
        .clk(clk), 
        .resetn(reset), 
        .enable(1'b1), 
        .dividend(26'd16), 
        .time_up(hold)
        );
    timer_l t003(
        .clk(clk), 
        .resetn(reset1), 
        .enable(1'b1), 
        .dividend(26'd100000), 
        .time_up(hold1)
        );

	reg [2:0] current_state, next_state;


    always @(posedge clk) begin
		if (!resetn)
			current_state <= DONE1;
		else
			current_state <= next_state;
	end

	localparam  WAIT = 4'd0, 
                ERASE = 4'd1,
				MOVE = 4'd2,                 
				DRAW = 4'd3,                
                DONE1 = 4'd4;
    
    always @(*)
    begin: state_table
        case (current_state)
            WAIT: next_state = go ? ERASE : WAIT;
            ERASE: next_state = draw_done ? MOVE : ERASE;
            MOVE: next_state = hold1 ? DRAW : MOVE;
            DRAW: next_state = draw_done ? DONE1 : DRAW;
            DONE1: next_state = hold ? WAIT : DONE1;
		endcase
	 end

    reg reset, reset1;
	always @(*)
	begin
		writeEn = 1'b0;
		enable_color = 1'b0;
        enable_move = 1'b0;
        writeEn = 1'b0;
        draw = 1'b0;
        reset = 1'b0;
        reset1 = 1'b0;
        done = 1'b0;
        reset_counter = 1'b0;

		case (current_state)
			WAIT: begin
            end
			ERASE: begin
                writeEn = 1'b1;
                draw = 1'b1;
                reset_counter = 1'b1;
            end
			MOVE: begin
				enable_move = 1'b1;
                reset1 = 1'b1;
            end
            DRAW: begin
                reset_counter = 1'b1;
                enable_color = 1'b1;
                writeEn = 1'b1;
                draw = 1'b1;
            end
            DONE1: begin
                done = 1'b1;
                reset = 1'b1;
            end
		endcase
	end

endmodule


module datapath_ball(
    input clk, resetn, enable_color, enable_move, draw, reset_counter,
	input [7:0] x_paddle, x_paddle_top,
    output [7:0] x_out,
	output [6:0] y_out,
	output [2:0] color_out,
    output draw_done
);

    wire [7:0] x_pos;
    wire [6:0] y_pos;
    xy_counter_ball movement(
        .clk(clk),
        .resetn(resetn),
        .enable_move(enable_move),
		.x_paddle(x_paddle),
        .x_paddle_top(x_paddle_top),
        .x_out(x_pos),
        .y_out(y_pos)  
    );

    ball_draw data(
        .clk(clk),
        .resetn(reset_counter),
        .x_in(x_pos),
        .y_in(y_pos),
        .x_out(x_out),
        .y_out(y_out),
        .done(draw_done)
    ); 
    wire change_color;
    timer_l t8(clk, resetn, 1'b1, 26'd1, change_color);
    reg [2:0] count;
    always @(posedge change_color) begin
        if (count == 3'b110)
            count <= 3'b001;
        else
            count <= count + 1'b1;
    end
    assign color_out = enable_color ? count : 3'b000;

endmodule


module ball_draw(
	input clk, resetn,
	input [7:0] x_in, 
	input [6:0] y_in,
	output [7:0] x_out, 
	output [6:0] y_out,
    output done
);
	
	reg [3:0] count;
	always @(posedge clk) begin
		if (!resetn)
			count <= 4'b0000;
		else if (count == 4'b1111)
			count <= 4'b0000;
		else
			count <= count + 1'b1;
	end
    assign done = (count == 4'b1111);  
	assign x_out = x_in + count[1:0];
	assign y_out = y_in + count[3:2];


    // reg [1:0] count;
    // always @(posedge clk) begin
	// 	if (!resetn)
	// 		count <= 2'd0;
	// 	else if (count == 2'd3)
	// 		count <= 2'd0;
	// 	else
	// 		count <= count + 1'b1;
	// end
    // assign done = (count == 2'd3);  
	// assign x_out = x_in + count[0];
	// assign y_out = y_in + count[1];

endmodule


module xy_counter_ball(
    input clk, resetn, enable_move,
	input [7:0] x_paddle, x_paddle_top,
    output reg [7:0] x_out,
    output reg [6:0] y_out
);
    reg done;
    wire reset;
    assign reset = (y_out + 3'd5 > 7'd110) | (y_out < 7'd12);
    always@(posedge enable_move, negedge resetn) begin
        if (!resetn) begin
            x_out <= 8'd80;
            y_out <= 7'd60;
		   end
        else if (reset) begin
            x_out <= 8'd80;
            y_out <= 7'd60;
        end
        else begin
            if (x_direction)
                x_out <= x_out + 1'b1;
            else if (!x_direction)
                x_out <= x_out - 1'b1;
            if (y_direction)
				y_out <= y_out + 1'b1;
			else if (!y_direction)
				y_out <= y_out - 1'b1;
        end
       
    end
 
    reg x_direction;
    reg y_direction;
    always @(posedge clk) begin
            if (!resetn)
                x_direction <= 1'b1;
            else 
            begin
                if (x_direction) 
                begin
                    if (x_out + 2'd3 > 8'd108)
                        x_direction <= 1'b0;
                    else
                        x_direction <= 1'b1;
                end

                else
                begin
                    if (x_out == 8'd51)
                        x_direction <= 1'b1;
                    else
                        x_direction <= 1'b0;
                end

            end

        end
    always @(posedge clk) begin
		if (!resetn)
			y_direction <= 1;
		else begin
			if (y_direction) begin
				if (((y_out + 2'd3 >= 7'd108) & (y_out <=7'd106)) & (((x_out + 3'd3 >= x_paddle) & (x_out <= x_paddle ))    | x_out <= 7'd60 | x_out >= 7'd100)) 
                    y_direction <= 1'b0;
				else
					y_direction <= 1'b1;
			end
			else begin
				if ((y_out <= 7'd12) & (y_out > 7'd10) & (((x_out + 3'd3 >= x_paddle_top) & (x_out <= x_paddle_top))    | x_out <= 7'd60 | x_out >= 7'd100))
					y_direction <= 1'b1;
				else
					y_direction <= 1'b0;
			end
		end
	end
endmodule