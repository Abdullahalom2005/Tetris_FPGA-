`timescale 1ns / 1ps

module lfsr_randomizer (
    input wire clk_25MHz,
    output wire [1:0] random_shape,
    output wire [2:0] random_color
);
    // Initial seed MUST not be zero
    reg [7:0] lfsr = 8'hAF; 
    
    // XOR taps at 7, 5, 4, and 3 create a maximum-length 255-state sequence
    always @(posedge clk_25MHz) begin
        lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end

    // Tap the bottom bits for the shape (0 to 3)
    assign random_shape = lfsr[1:0];
    
    // Tap the middle bits for color (1 to 6 to avoid Black)
    assign random_color = (lfsr[4:2] % 6) + 1;
endmodule