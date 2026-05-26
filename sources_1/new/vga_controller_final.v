`timescale 1ns / 1ps

module vga_controller (
    input wire clk_25MHz,
    input wire rst,
    input wire btn_left,
    input wire btn_right,
    input wire btn_rotate,
    input wire btn_down,
    input wire [9:0] h_count, // Incoming from vga_sync
    input wire [9:0] v_count, // Incoming from vga_sync
    input wire video_on,      // Incoming from vga_sync
    output reg [2:0] rgb      // Outgoing to monitor
);

    // =========================================================
    // 1. INSTANTIATE DEBOUNCERS
    // =========================================================
    wire left_pulse, right_pulse, rot_pulse, down_pulse;
    debouncer d1 (.clk_25MHz(clk_25MHz), .btn_in(btn_left),   .btn_pulse(left_pulse));
    debouncer d2 (.clk_25MHz(clk_25MHz), .btn_in(btn_right),  .btn_pulse(right_pulse));
    debouncer d3 (.clk_25MHz(clk_25MHz), .btn_in(btn_rotate), .btn_pulse(rot_pulse));
    debouncer d4 (.clk_25MHz(clk_25MHz), .btn_in(btn_down),   .btn_pulse(down_pulse));

    // =========================================================
    // 2. INSTANTIATE LFSR
    // =========================================================
    wire [1:0] random_shape;
    wire [2:0] random_color;
    lfsr_randomizer rng (.clk_25MHz(clk_25MHz), .random_shape(random_shape), .random_color(random_color));

    // =========================================================
    // 3. MEMORY BOARD
    // =========================================================
    reg [2:0] board [0:19][0:9];
    integer i, j;
    initial begin
        for (i = 0; i < 20; i = i + 1)
            for (j = 0; j < 10; j = j + 1)
                board[i][j] = 3'b000;
    end

    // =========================================================
    // 4. CURRENT SHAPE GENERATOR MATH
    // =========================================================
    reg signed [5:0] block_x = 4, block_y = 0; 
    reg [1:0] rot = 0;
    reg [1:0] shape_type = 0; 
    reg [2:0] block_color = 3'b011;

    reg signed [5:0] b1_x, b1_y, b2_x, b2_y, b3_x, b3_y, b4_x, b4_y;

    always @(*) begin
        b1_x = block_x; b1_y = block_y; 
        case(shape_type)
            2'd0: begin // SQUARE 
                b2_x=block_x+1; b2_y=block_y; b3_x=block_x; b3_y=block_y+1; b4_x=block_x+1; b4_y=block_y+1; 
            end
            2'd1: begin // LINE
                if (rot[0] == 0) begin b2_x=block_x-1; b2_y=block_y; b3_x=block_x+1; b3_y=block_y; b4_x=block_x+2; b4_y=block_y; end
                else             begin b2_x=block_x; b2_y=block_y-1; b3_x=block_x; b3_y=block_y+1; b4_x=block_x; b4_y=block_y+2; end
            end
            2'd2: begin // T-SHAPE
                case(rot)
                    0: begin b2_x=block_x-1; b2_y=block_y; b3_x=block_x+1; b3_y=block_y; b4_x=block_x; b4_y=block_y-1; end
                    1: begin b2_x=block_x; b2_y=block_y-1; b3_x=block_x; b3_y=block_y+1; b4_x=block_x+1; b4_y=block_y; end
                    2: begin b2_x=block_x+1; b2_y=block_y; b3_x=block_x-1; b3_y=block_y; b4_x=block_x; b4_y=block_y+1; end
                    3: begin b2_x=block_x; b2_y=block_y+1; b3_x=block_x; b3_y=block_y-1; b4_x=block_x-1; b4_y=block_y; end
                endcase
            end
            2'd3: begin // L-SHAPE
                case(rot)
                    0: begin b2_x=block_x-1; b2_y=block_y; b3_x=block_x+1; b3_y=block_y; b4_x=block_x+1; b4_y=block_y-1; end
                    1: begin b2_x=block_x; b2_y=block_y-1; b3_x=block_x; b3_y=block_y+1; b4_x=block_x+1; b4_y=block_y+1; end
                    2: begin b2_x=block_x+1; b2_y=block_y; b3_x=block_x-1; b3_y=block_y; b4_x=block_x-1; b4_y=block_y+1; end
                    3: begin b2_x=block_x; b2_y=block_y+1; b3_x=block_x; b3_y=block_y-1; b4_x=block_x-1; b4_y=block_y-1; end
                endcase
            end
        endcase
    end

    // =========================================================
    // 5. LOOK-AHEAD COLLISION DETECTION 
    // =========================================================
    wire [1:0] next_rot = rot + 1;
    reg signed [5:0] n2_x, n2_y, n3_x, n3_y, n4_x, n4_y;

    always @(*) begin
        case(shape_type)
            2'd0: begin n2_x=block_x+1; n2_y=block_y; n3_x=block_x; n3_y=block_y+1; n4_x=block_x+1; n4_y=block_y+1; end
            2'd1: begin
                if (next_rot[0] == 0) begin n2_x=block_x-1; n2_y=block_y; n3_x=block_x+1; n3_y=block_y; n4_x=block_x+2; n4_y=block_y; end
                else                  begin n2_x=block_x; n2_y=block_y-1; n3_x=block_x; n3_y=block_y+1; n4_x=block_x; n4_y=block_y+2; end
            end
            2'd2: begin
                case(next_rot)
                    0: begin n2_x=block_x-1; n2_y=block_y; n3_x=block_x+1; n3_y=block_y; n4_x=block_x; n4_y=block_y-1; end
                    1: begin n2_x=block_x; n2_y=block_y-1; n3_x=block_x; n3_y=block_y+1; n4_x=block_x+1; n4_y=block_y; end
                    2: begin n2_x=block_x+1; n2_y=block_y; n3_x=block_x-1; n3_y=block_y; n4_x=block_x; n4_y=block_y+1; end
                    3: begin n2_x=block_x; n2_y=block_y+1; n3_x=block_x; n3_y=block_y-1; n4_x=block_x-1; n4_y=block_y; end
                endcase
            end
            2'd3: begin
                case(next_rot)
                    0: begin n2_x=block_x-1; n2_y=block_y; n3_x=block_x+1; n3_y=block_y; n4_x=block_x+1; n4_y=block_y-1; end
                    1: begin n2_x=block_x; n2_y=block_y-1; n3_x=block_x; n3_y=block_y+1; n4_x=block_x+1; n4_y=block_y+1; end
                    2: begin n2_x=block_x+1; n2_y=block_y; n3_x=block_x-1; n3_y=block_y; n4_x=block_x-1; n4_y=block_y+1; end
                    3: begin n2_x=block_x; n2_y=block_y+1; n3_x=block_x; n3_y=block_y-1; n4_x=block_x-1; n4_y=block_y-1; end
                endcase
            end
        endcase
    end

    wire rot_hit_bounds = (block_x < 0 || block_x > 9 || block_y > 19) || 
                          (n2_x < 0 || n2_x > 9 || n2_y > 19) ||
                          (n3_x < 0 || n3_x > 9 || n3_y > 19) || 
                          (n4_x < 0 || n4_x > 9 || n4_y > 19);

    wire rot_overlap_2 = (n2_y >= 0 && n2_y < 20 && n2_x >= 0 && n2_x < 10) ? (board[n2_y][n2_x] != 3'b000) : 1'b0;
    wire rot_overlap_3 = (n3_y >= 0 && n3_y < 20 && n3_x >= 0 && n3_x < 10) ? (board[n3_y][n3_x] != 3'b000) : 1'b0;
    wire rot_overlap_4 = (n4_y >= 0 && n4_y < 20 && n4_x >= 0 && n4_x < 10) ? (board[n4_y][n4_x] != 3'b000) : 1'b0;
    wire rot_invalid = rot_hit_bounds || rot_overlap_2 || rot_overlap_3 || rot_overlap_4;

    wire left_overlap  = ((b1_y>=0&&b1_y<20&&b1_x-1>=0)?(board[b1_y][b1_x-1]!=0):0) || ((b2_y>=0&&b2_y<20&&b2_x-1>=0)?(board[b2_y][b2_x-1]!=0):0) ||
                         ((b3_y>=0&&b3_y<20&&b3_x-1>=0)?(board[b3_y][b3_x-1]!=0):0) || ((b4_y>=0&&b4_y<20&&b4_x-1>=0)?(board[b4_y][b4_x-1]!=0):0);
                         
    wire right_overlap = ((b1_y>=0&&b1_y<20&&b1_x+1<10)?(board[b1_y][b1_x+1]!=0):0) || ((b2_y>=0&&b2_y<20&&b2_x+1<10)?(board[b2_y][b2_x+1]!=0):0) ||
                         ((b3_y>=0&&b3_y<20&&b3_x+1<10)?(board[b3_y][b3_x+1]!=0):0) || ((b4_y>=0&&b4_y<20&&b4_x+1<10)?(board[b4_y][b4_x+1]!=0):0);

    wire hit_left_wall  = (b1_x <= 0) || (b2_x <= 0) || (b3_x <= 0) || (b4_x <= 0) || left_overlap;
    wire hit_right_wall = (b1_x >= 9) || (b2_x >= 9) || (b3_x >= 9) || (b4_x >= 9) || right_overlap;

    wire hit_floor = (b1_y >= 19) || (b2_y >= 19) || (b3_y >= 19) || (b4_y >= 19);
    wire check_1 = (b1_y >= 0 && b1_y < 19 && b1_x >= 0 && b1_x <= 9) ? (board[b1_y+1][b1_x] != 3'b000) : 1'b0;
    wire check_2 = (b2_y >= 0 && b2_y < 19 && b2_x >= 0 && b2_x <= 9) ? (board[b2_y+1][b2_x] != 3'b000) : 1'b0;
    wire check_3 = (b3_y >= 0 && b3_y < 19 && b3_x >= 0 && b3_x <= 9) ? (board[b3_y+1][b3_x] != 3'b000) : 1'b0;
    wire check_4 = (b4_y >= 0 && b4_y < 19 && b4_x >= 0 && b4_x <= 9) ? (board[b4_y+1][b4_x] != 3'b000) : 1'b0;
    wire collision_down = hit_floor || check_1 || check_2 || check_3 || check_4;

    // =========================================================
    // 6. GAME LOOP FSM 
    // =========================================================
    reg [24:0] grav_counter = 0; 
    reg [24:0] fall_speed = 10_000_000; 
    
    reg hard_drop_active = 0;
    wire [24:0] current_speed = (hard_drop_active) ? 25'd0 : fall_speed;
    wire tick = (grav_counter >= current_speed); 
    
    localparam FALL = 0, LOCK = 1, SCAN = 2, SHIFT = 3, SPAWN = 4, GAME_OVER = 5;
    reg [2:0] state = FALL;
    
    reg [4:0] scan_y = 19;
    reg [4:0] shift_y = 19;

    wire row_full = (board[scan_y][0] != 3'b000) && (board[scan_y][1] != 3'b000) &&
                    (board[scan_y][2] != 3'b000) && (board[scan_y][3] != 3'b000) &&
                    (board[scan_y][4] != 3'b000) && (board[scan_y][5] != 3'b000) &&
                    (board[scan_y][6] != 3'b000) && (board[scan_y][7] != 3'b000) &&
                    (board[scan_y][8] != 3'b000) && (board[scan_y][9] != 3'b000);

    always @(posedge clk_25MHz or posedge rst) begin
        if (rst) begin
            block_x <= 4; block_y <= 0; state <= FALL;
            fall_speed <= 10_000_000; 
            grav_counter <= 0;
            state <= GAME_OVER;
            scan_y <= 19;
            hard_drop_active <= 0;
        end else begin
            
            if (state == FALL) begin
                if (rot_pulse && !rot_invalid) rot <= rot + 1;
                if (left_pulse && !hit_left_wall) block_x <= block_x - 1;
                if (right_pulse && !hit_right_wall) block_x <= block_x + 1;
                if (down_pulse) hard_drop_active <= 1; 
                
                if (tick) begin
                    if (!collision_down) begin
                        block_y <= block_y + 1;
                    end else begin
                        if (block_y == 0) begin
                            state <= GAME_OVER;
                            scan_y <= 19;
                        end else begin
                            state <= LOCK; 
                        end
                    end
                    grav_counter <= 0;
                end else grav_counter <= grav_counter + 1;
            end 
            
            else if (state == LOCK) begin 
                if (b1_y >= 0 && b1_y < 20 && b1_x >= 0 && b1_x < 10) board[b1_y][b1_x] <= block_color;
                if (b2_y >= 0 && b2_y < 20 && b2_x >= 0 && b2_x < 10) board[b2_y][b2_x] <= block_color;
                if (b3_y >= 0 && b3_y < 20 && b3_x >= 0 && b3_x < 10) board[b3_y][b3_x] <= block_color;
                if (b4_y >= 0 && b4_y < 20 && b4_x >= 0 && b4_x < 10) board[b4_y][b4_x] <= block_color;
                
                state <= SCAN;
                scan_y <= 19; 
            end
            
            else if (state == SCAN) begin
                if (row_full) begin
                    shift_y <= scan_y;
                    state <= SHIFT;
                    if (fall_speed > 2_000_000) fall_speed <= fall_speed - 500_000;
                end else begin
                    if (scan_y == 0) state <= SPAWN; 
                    else scan_y <= scan_y - 1;       
                end
            end
            
            else if (state == SHIFT) begin
                if (shift_y > 0) begin
                    board[shift_y][0] <= board[shift_y-1][0]; board[shift_y][1] <= board[shift_y-1][1];
                    board[shift_y][2] <= board[shift_y-1][2]; board[shift_y][3] <= board[shift_y-1][3];
                    board[shift_y][4] <= board[shift_y-1][4]; board[shift_y][5] <= board[shift_y-1][5];
                    board[shift_y][6] <= board[shift_y-1][6]; board[shift_y][7] <= board[shift_y-1][7];
                    board[shift_y][8] <= board[shift_y-1][8]; board[shift_y][9] <= board[shift_y-1][9];
                    shift_y <= shift_y - 1; 
                end else begin
                    board[0][0]<=3'b000; board[0][1]<=3'b000; board[0][2]<=3'b000; board[0][3]<=3'b000; board[0][4]<=3'b000;
                    board[0][5]<=3'b000; board[0][6]<=3'b000; board[0][7]<=3'b000; board[0][8]<=3'b000; board[0][9]<=3'b000;
                    state <= SCAN; 
                end
            end
            
            else if (state == SPAWN) begin
                block_y <= 0; block_x <= 4; rot <= 0;
                shape_type <= random_shape; 
                block_color <= random_color;
                hard_drop_active <= 0; 
                state <= FALL;
            end
            
            else if (state == GAME_OVER) begin
                if (grav_counter >= 1_000_000) begin
                    board[scan_y][0]<=3'b000; board[scan_y][1]<=3'b000; board[scan_y][2]<=3'b000; board[scan_y][3]<=3'b000; board[scan_y][4]<=3'b000;
                    board[scan_y][5]<=3'b000; board[scan_y][6]<=3'b000; board[scan_y][7]<=3'b000; board[scan_y][8]<=3'b000; board[scan_y][9]<=3'b000;
                    
                    if (scan_y == 0) begin
                        state <= SPAWN;
                        fall_speed <= 10_000_000; 
                    end else begin
                        scan_y <= scan_y - 1;
                    end
                    grav_counter <= 0;
                end else begin
                    grav_counter <= grav_counter + 1;
                end
            end
            
        end
    end

    // =========================================================
    // 7. RENDER PIPELINE
    // =========================================================
    localparam GRID_OFFSET_X = 220; localparam GRID_OFFSET_Y = 40;  
    wire in_grid = (h_count >= GRID_OFFSET_X && h_count < GRID_OFFSET_X + 200) && (v_count >= GRID_OFFSET_Y && v_count < GRID_OFFSET_Y + 400);
    wire signed [5:0] grid_x = (h_count - GRID_OFFSET_X) / 20;
    wire signed [5:0] grid_y = (v_count - GRID_OFFSET_Y) / 20;

    wire is_b1 = (grid_x == b1_x) && (grid_y == b1_y);
    wire is_b2 = (grid_x == b2_x) && (grid_y == b2_y);
    wire is_b3 = (grid_x == b3_x) && (grid_y == b3_y);
    wire is_b4 = (grid_x == b4_x) && (grid_y == b4_y);
    
    wire is_active_block = (is_b1 || is_b2 || is_b3 || is_b4) && (state != GAME_OVER);
    
    wire is_border = ((h_count >= 218 && h_count < 220) || (h_count >= 420 && h_count < 422)) && (v_count >= 38 && v_count < 442) ||
                     (v_count >= 440 && v_count < 442) && (h_count >= 218 && h_count < 422);

    always @(posedge clk_25MHz) begin
        if (video_on) begin // Protects the physical monitor blanking phase
            if (in_grid && is_active_block)         rgb <= block_color;
            else if (in_grid && board[grid_y][grid_x] != 3'b000) rgb <= board[grid_y][grid_x]; 
            else if (is_border) begin
                if (state == GAME_OVER) rgb <= 3'b100; // RED
                else                    rgb <= 3'b111; // WHITE
            end
            else                                    rgb <= 3'b000; 
        end else rgb <= 3'b000;
    end
endmodule