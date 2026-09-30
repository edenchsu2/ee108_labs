`include "dvi_defines.v"

`define TEXT_LOC_X 16
`define ENTER_LOC_X 128

`define USERNAME_LOC_Y 88
`define USERNAME_ENTER_LOC_Y 104
`define PASSWORD_LOC_Y 128
`define PASSWORD_ENTER_LOC_Y 144
`define VALID_LOC_Y 200


module lab1_interface (
    // System signals
    input clk,
    input rst,

    // Password verifier interface
    output reg [63:0] username,
    output reg [63:0] password,
    input valid,

    // User interface
    input is_password,
    input enter_button,
    input next_char_button,
    input cursor_left_button,
    input cursor_right_button,
    
    // VGA video out
    output [3:0] r_out,
    output [3:0] g_out,
    output [3:0] b_out,
    output hsync,
    output vsync,
    output vde,
    
    // leds out 
    output [3:0] leds
);	 

    //==========================================================================
    // Display management -> do not touch!
    //==========================================================================
    // blinking leds to show life 
    wire [26:0] led_counter;
    dff #(.WIDTH (27)) led_div (
        .clk (clk),
        .d (led_counter + 27'd1),
        .q (led_counter)
    );
    assign leds = led_counter[26:23];
	 
    /// DVI controller boilerplate /////////////////////////////////////////////

    wire [`log2NUM_COLS-1:0] x_q;
    wire [`log2NUM_ROWS-1:0] y_q;
    	
    wire [`log2NUM_COLS-1:0] x;
	assign x = {1'b0, x_q[`log2NUM_COLS-1:1]};
	
    wire [`log2NUM_ROWS-1:0] y;
	assign y = {1'b0, y_q[`log2NUM_ROWS-1:1]};

	wire [10:0] true_x;
	wire [10:0] true_y; 
	
	
    /// Input sanitization boilerplate /////////////////////////////////////////
    parameter BPU_WIDTH = 20;
    
    wire conditioned_enter, conditioned_next_char;
    wire conditioned_cursor_left, conditioned_cursor_right;
    
        
    button_press_unit #(.WIDTH(BPU_WIDTH)) bpu1(
        .clk(clk),
        .reset(rst),
        .in(enter_button),
        .out(conditioned_enter)
    );

    button_press_unit #(.WIDTH(BPU_WIDTH)) bpu2(
        .clk(clk),
        .reset(rst),
        .in(next_char_button),
        .out(conditioned_next_char)
    );
   
    button_press_unit #(.WIDTH(BPU_WIDTH)) bpu3(
        .clk(clk),
        .reset(rst),
        .in(cursor_left_button),
        .out(conditioned_cursor_left)
    );
   
    button_press_unit #(.WIDTH(BPU_WIDTH)) bpu4(
        .clk(clk),
        .reset(rst),
        .in(cursor_right_button),
        .out(conditioned_cursor_right)
    );
   
	wire char_up;
    one_pulse next_char_pulser (
	    .clk(clk), 
	    .reset(rst), 
	    .in(conditioned_next_char), 
	    .out(char_up)
	);
	
    wire [63:0] username_tmp;
    wire [63:0] password_tmp;
    
    wire [7:0] r_1, g_1, b_1;
    wire [7:0] r_2, g_2, b_2;
    wire [7:0] r_3, g_3, b_3;
      	
	wire [7:0] r, g, b;
   
    input_box usr_box (
        .clk(clk),
        .rst(rst),
        
        .cursor_left(conditioned_cursor_left),
        .cursor_right(conditioned_cursor_right),
        .char_up(char_up),
        .char_dn(0),
        .en(~is_password),
          
        .value(username_tmp),
          
        .x(x - `ENTER_LOC_X),
        .y(y - `USERNAME_ENTER_LOC_Y),
        .r(r_1),
        .g(g_1),
        .b(b_1)
    );
   
    input_box pass_box (
        .clk(clk),
        .rst(rst),
      
        .cursor_left(conditioned_cursor_left),
        .cursor_right(conditioned_cursor_right),
        .char_up(char_up),
        .char_dn(0),
        .en(is_password),
      
        .value(password_tmp),
      
        .x(x - `ENTER_LOC_X),
        .y(y - `PASSWORD_ENTER_LOC_Y),
        .r(r_2),
        .g(g_2),
        .b(b_2)
    );

    always @(posedge clk) begin
        if (rst) begin
            username <= 64'b0;
            password <= 64'b0;
        end else begin
            if (conditioned_enter) begin
                username <= username_tmp;
                password <= password_tmp;
            end
        end
    end
    
    /// Extra display logic ////////////////////////////////////////////////////
    reg valid_flopped;
    always @(posedge clk) begin
        valid_flopped <= valid;
	end
   
    reg [8:0] rom_base_addr;
    wire [8:0] rom_addr;
    	
	assign rom_addr = rom_base_addr + y[2:0];
    wire [7:0] rom_data;
	
    tcgrom char_rom (.addr(rom_addr), .data(rom_data));

    reg [1:0] color;

    always @(*) begin
        if (y >= `USERNAME_LOC_Y && y < `USERNAME_LOC_Y + 7) begin
            color = 2'd0;
            case (x[`log2NUM_COLS-1:3])
                `TEXT_LOC_X    : rom_base_addr = (9'd21 << 3); // U
                `TEXT_LOC_X + 1: rom_base_addr = (9'd19 << 3); // S
                `TEXT_LOC_X + 2: rom_base_addr = (9'd05 << 3); // E
                `TEXT_LOC_X + 3: rom_base_addr = (9'd18 << 3); // R
                `TEXT_LOC_X + 4: rom_base_addr = (9'd14 << 3); // N
                `TEXT_LOC_X + 5: rom_base_addr = (9'd01 << 3); // A
                `TEXT_LOC_X + 6: rom_base_addr = (9'd13 << 3); // M
                `TEXT_LOC_X + 7: rom_base_addr = (9'd05 << 3); // E
                `TEXT_LOC_X + 8: rom_base_addr = (9'd39 << 3); // :
                default: rom_base_addr = 9'h100;
            endcase
        end else if (y >= `PASSWORD_LOC_Y && y < `PASSWORD_LOC_Y + 7) begin
            color = 2'd0;
            case (x[`log2NUM_COLS-1:3])
                `TEXT_LOC_X    : rom_base_addr = (9'd16 << 3); // P
                `TEXT_LOC_X + 1: rom_base_addr = (9'd01 << 3); // A
                `TEXT_LOC_X + 2: rom_base_addr = (9'd19 << 3); // S
                `TEXT_LOC_X + 3: rom_base_addr = (9'd19 << 3); // S
                `TEXT_LOC_X + 4: rom_base_addr = (9'd23 << 3); // W
                `TEXT_LOC_X + 5: rom_base_addr = (9'd15 << 3); // O
                `TEXT_LOC_X + 6: rom_base_addr = (9'd18 << 3); // R
                `TEXT_LOC_X + 7: rom_base_addr = (9'd04 << 3); // D
                `TEXT_LOC_X + 8: rom_base_addr = (9'd39 << 3); // :
                default: rom_base_addr = 9'h100;
            endcase
        end else if (y >= `VALID_LOC_Y && y < (`VALID_LOC_Y + 7)) begin
            if (username==64'b0 && password==64'b0 ) begin
                color = 2'd0;
                rom_base_addr = 9'h100;
            end else if (valid_flopped) begin
                color = 2'd1;
                case (x[`log2NUM_COLS-1:3])
                    `TEXT_LOC_X    : rom_base_addr = (9'd16 << 3); // P
                    `TEXT_LOC_X + 1: rom_base_addr = (9'd01 << 3); // A
                    `TEXT_LOC_X + 2: rom_base_addr = (9'd19 << 3); // S
                    `TEXT_LOC_X + 3: rom_base_addr = (9'd19 << 3); // S
                    `TEXT_LOC_X + 4: rom_base_addr = (9'd23 << 3); // W
                    `TEXT_LOC_X + 5: rom_base_addr = (9'd15 << 3); // O
                    `TEXT_LOC_X + 6: rom_base_addr = (9'd18 << 3); // R
                    `TEXT_LOC_X + 7: rom_base_addr = (9'd04 << 3); // D
                    `TEXT_LOC_X + 8: rom_base_addr = 9'h100; //  
                    `TEXT_LOC_X + 9: rom_base_addr = (9'd22 << 3); // V
                    `TEXT_LOC_X + 10: rom_base_addr = (9'd01 << 3); // A
                    `TEXT_LOC_X + 11: rom_base_addr = (9'd12 << 3); // L
                    `TEXT_LOC_X + 12: rom_base_addr = (9'd09 << 3); // I
                    `TEXT_LOC_X + 13: rom_base_addr = (9'd04 << 3); // D
                    `TEXT_LOC_X + 14: rom_base_addr = (9'd33 << 3); // !
                    default: rom_base_addr = 9'h100;
                endcase
            end else begin
                color = 2'd2;
                case (x[`log2NUM_COLS-1:3])
                    `TEXT_LOC_X    : rom_base_addr = (9'd16 << 3); // P
                    `TEXT_LOC_X + 1: rom_base_addr = (9'd01 << 3); // A
                    `TEXT_LOC_X + 2: rom_base_addr = (9'd19 << 3); // S
                    `TEXT_LOC_X + 3: rom_base_addr = (9'd19 << 3); // S
                    `TEXT_LOC_X + 4: rom_base_addr = (9'd23 << 3); // W
                    `TEXT_LOC_X + 5: rom_base_addr = (9'd15 << 3); // O
                    `TEXT_LOC_X + 6: rom_base_addr = (9'd18 << 3); // R
                    `TEXT_LOC_X + 7: rom_base_addr = (9'd04 << 3); // D
                    `TEXT_LOC_X + 8: rom_base_addr = 9'h100; //  
                    `TEXT_LOC_X + 9: rom_base_addr = (9'd09 << 3); // I
                    `TEXT_LOC_X + 10: rom_base_addr = (9'd14 << 3); // N
                    `TEXT_LOC_X + 11: rom_base_addr = (9'd22 << 3); // V
                    `TEXT_LOC_X + 12: rom_base_addr = (9'd01 << 3); // A
                    `TEXT_LOC_X + 13: rom_base_addr = (9'd12 << 3); // L
                    `TEXT_LOC_X + 14: rom_base_addr = (9'd09 << 3); // I
                    `TEXT_LOC_X + 15: rom_base_addr = (9'd04 << 3); // D
                    `TEXT_LOC_X + 16: rom_base_addr = (9'd33 << 3); // !
                    `TEXT_LOC_X + 17: rom_base_addr = (9'd33 << 3); // !
                    default: rom_base_addr = 9'h100;
                endcase
            end
        end else begin
            color = 2'd0;
            rom_base_addr = 9'h100;
        end
    end
   
    wire [7:0] rom_bit_select; 
	assign rom_bit_select = 8'b10000000 >> x[2:0];
	
    wire char_px; 
	assign char_px = |(rom_data & rom_bit_select);
    
    assign r_3 = char_px & (color==2'd0 || color==2'd2) ? 8'hFF : 8'h00;
    assign g_3 = char_px & (color==2'd0 || color==2'd1) ? 8'hFF : 8'h00;
    assign b_3 = char_px & (color==2'd0) ? 8'hFF : 8'h00;
 
    assign r = r_1 | r_2 | r_3;
    assign g = g_1 | g_2 | g_3;
    assign b = b_1 | b_2 | b_3;
    
    wire valid_vga, de;
    wire blank;
    vga_controller_800x480_60 vga_control (
        .pixel_clk(clk),
        .rst(rst),
        .HS(hsync),
        .VS(vsync),
        .VDE(vde),
        .hcount(true_x),
        .vcount(true_y),
        .blank(blank)
    );
    
    assign r_out = r[7:4];
    assign g_out = g[7:4];
    assign b_out = b[7:4];
	
	dff #(.WIDTH (11)) x_dff (
        .clk (clk),
        .d (true_x),
        .q (x_q)
    );
 
	dff #(.WIDTH (11)) y_dff (
        .clk (clk),
        .d (true_y),
        .q (y_q)
	);
	
endmodule
