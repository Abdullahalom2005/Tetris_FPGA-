`timescale 1ns / 1ps

module debouncer (
    input wire clk_25MHz,
    input wire btn_in,
    output wire btn_pulse
);
    reg [19:0] db_counter = 0;
    reg state = 0;
    reg prev = 0;

    always @(posedge clk_25MHz) begin
        if (db_counter == 625_000) begin // 40Hz sampling rate
            state <= btn_in;
            db_counter <= 0;
        end else begin
            db_counter <= db_counter + 1;
        end
        prev <= state; // Remember the past state to detect edges
    end
    
    // Outputs exactly one high pulse when the button is freshly pressed
    assign btn_pulse = state & ~prev; 
endmodule