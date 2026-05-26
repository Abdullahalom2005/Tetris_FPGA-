`timescale 1ns / 1ps

module vga_sync (
    input wire clk_25MHz,
    output reg hsync,
    output reg vsync,
    output reg [9:0] h_count,
    output reg [9:0] v_count,
    output wire video_on  // Tells the game if we are in the visible screen area
);
    localparam H_ACTIVE = 640, H_FRONT = 16, H_SYNC = 96, H_BACK = 48, H_TOTAL = 800;
    localparam V_ACTIVE = 480, V_FRONT = 10, V_SYNC = 2,  V_BACK = 33, V_TOTAL = 525;

    initial begin h_count = 0; v_count = 0; end

    always @(posedge clk_25MHz) begin
        if (h_count == H_TOTAL - 1) begin
            h_count <= 0;
            if (v_count == V_TOTAL - 1) v_count <= 0;
            else v_count <= v_count + 1;
        end else begin
            h_count <= h_count + 1;
        end
    end

    always @(posedge clk_25MHz) begin
        hsync <= ~((h_count >= H_ACTIVE + H_FRONT) && (h_count < H_ACTIVE + H_FRONT + H_SYNC));
        vsync <= ~((v_count >= V_ACTIVE + V_FRONT) && (v_count < V_ACTIVE + V_FRONT + V_SYNC));
    end

    // High only when the beam is in the 640x480 visible area
    assign video_on = (h_count < H_ACTIVE) && (v_count < V_ACTIVE);

endmodule