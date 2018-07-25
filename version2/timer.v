`include "timers_s.v"
`include "timers_l.v"


module part3(
    input CLOCK_50,
    input [0:0] KEY,
    output [9:0] LEDR
);
    timer_1_1_l t1_1(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[9])
    );

    timer_1_4_l t1_4(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[0])
    );

    timer_1_8_l t1_8(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[1])
    );

    timer_1_32_l t1_32(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[2])
    );


    timer_1_100_l t1_100(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[3])
    );


    timer_1_200_l t1_200(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[4])
    );


    timer_1_500_l t1_500(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[5])
    );

    timer_1_1000_l t1_1000(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[6])
    );


    timer_1_5000_l t1_5000(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[7])
    );


    timer_1_10000_l t1_10000(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .enable(1'b1),
        .time_up(LEDR[8])
    );


    // timer_1_1_s t1_1(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[8])
    // );

    // timer_1_4_s t1_4(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[0])
    // );

    // timer_1_8_s t1_8(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[1])
    // );

    // timer_1_32_s t1_32(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[2])
    // );


    // timer_1_100_s t1_100(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[3])
    // );


    // timer_1_200_s t1_200(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[4])
    // );


    // timer_1_500_s t1_500(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[5])
    // );

    // timer_1_1000_s t1_1000(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[6])
    // );


    // timer_1_5000_s t1_5000(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[7])
    // );


    // timer_1_10000_s t1_10000(
    //     .clk(CLOCK_50),
    //     .resetn(KEY[0]),
    //     .enable(1'b1),
    //     .time_up(LEDR[8])
    // );

endmodule