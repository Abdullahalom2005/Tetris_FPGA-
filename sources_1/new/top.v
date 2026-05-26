`timescale 1ns / 1ps

module top (
    input wire clk_100MHz,
    input wire rst,
    input wire btn_left,
    input wire btn_right,
    input wire btn_rotate,
    input wire btn_down,
    output wire hsync,
    output wire vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);

    // 1. CLOCK DIVIDER (100 MHz to 25 MHz)
    reg [1:0] clk_div = 0;
    wire clk_25MHz;
    always @(posedge clk_100MHz) clk_div <= clk_div + 1;
    assign clk_25MHz = clk_div[1];

    // 2. INTERNAL WIRING (Connecting the Sync Engine to the Game Engine)
    wire [9:0] w_h_count, w_v_count;
    wire w_video_on;
    wire [2:0] w_rgb;

    // 3. INSTANTIATE VGA SYNC ENGINE
    vga_sync my_monitor (
        .clk_25MHz(clk_25MHz),
        .hsync(hsync),               // Goes directly to physical pin
        .vsync(vsync),               // Goes directly to physical pin
        .h_count(w_h_count),         // Goes to Game Engine
        .v_count(w_v_count),         // Goes to Game Engine
        .video_on(w_video_on)        // Goes to Game Engine
    );

    // 4. INSTANTIATE TETRIS GAME DATAPATH
    vga_controller my_tetris (
        .clk_25MHz(clk_25MHz),
        .rst(rst),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_rotate(btn_rotate),
        .btn_down(btn_down),
        .h_count(w_h_count),         // Incoming from Sync Engine
        .v_count(w_v_count),         // Incoming from Sync Engine
        .video_on(w_video_on),       // Incoming from Sync Engine
        .rgb(w_rgb)                  // Outgoing 3-bit color logic
    );

    // 5. COLOR EXPANSION (3-bit Logic to 12-bit Physical Pins)
    assign vga_r = {4{w_rgb[2]}}; 
    assign vga_g = {4{w_rgb[1]}};
    assign vga_b = {4{w_rgb[0]}};

endmodule