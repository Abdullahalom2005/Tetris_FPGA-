`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.05.2026 10:59:22
// Design Name: 
// Module Name: tetris
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tetris (
    input wire clk_100MHz,   
    input wire rst,          
    input wire btn_left,     
    input wire btn_right,    
    input wire btn_rotate,   
    input wire btn_down,     // FIX: Added the down button to the main inputs
    output wire hsync,       
    output wire vsync,       
    output wire [3:0] vga_r, 
    output wire [3:0] vga_g, 
    output wire [3:0] vga_b  
);

    // 1. Clock Divider (100 MHz -> 25 MHz)
    reg [1:0] clk_div = 0;
    wire clk_25MHz;
    
    always @(posedge clk_100MHz) begin
        clk_div <= clk_div + 1;
    end
    assign clk_25MHz = clk_div[1];

    // 2. Instantiate the Game Controller
    wire [2:0] rgb_3bit; 
    
    vga_controller my_game (
        .clk_25MHz(clk_25MHz),
        .rst(rst),
        .btn_left(btn_left),     
        .btn_right(btn_right),   
        .btn_rotate(btn_rotate), 
        .btn_down(btn_down),     // FIX: Passed the down button signal into the game logic
        .hsync(hsync),
        .vsync(vsync),
        .rgb(rgb_3bit)
    );

    // 3. Color Mapping
    assign vga_r = {4{rgb_3bit[2]}}; 
    assign vga_g = {4{rgb_3bit[1]}};
    assign vga_b = {4{rgb_3bit[0]}};

endmodule