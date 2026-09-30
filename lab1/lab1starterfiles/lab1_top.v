module lab1_top (
    // System Clock (125MHz)
    input sysclk,

    // User interface
    input [3:0] btn,
    input [1:0] sw,

	// HDMI video out
	output TMDS_Clk_p,
	output TMDS_Clk_n,
	output [2:0] TMDS_Data_p,
	output [2:0] TMDS_Data_n,
	 
    // LEDs out 
    output [3:0] leds

);
    // Read input buttons and switches into their appropriate signals
    wire is_password = sw[0];
    wire rst = sw[1];
    
    wire enter_button, next_char_button, cursor_left_button, cursor_right_button;
    assign {enter_button, next_char_button, cursor_left_button, cursor_right_button} = btn;
    
    wire display_clk, serial_clk;
    wire LED0; // TODO: assign this to a real LED
    clk_wiz_0 U2 (
        .clk_out1(display_clk),	// 30 MHz
        .clk_out2(serial_clk),	// 150 Mhz
        .reset(rst),
        .locked(LED0),
        .clk_in1(sysclk)
    );
    
    wire vde, hsync, vsync;
    wire [3:0] r, g, b;
    wire [31:0] pix_data;
    assign pix_data = {
                        8'b0, 
                        r[3], r[3], r[2], r[2], r[1], r[1], r[0], r[0], 
                        g[3], g[3], g[2], g[2], g[1], g[1], g[0], g[0],
                        b[3], b[3], b[2], b[2], b[1], b[1], b[0], b[0]
                      };
    hdmi_tx_0 U3 (
        .pix_clk(display_clk),
        .pix_clkx5(serial_clk),
        .pix_clk_locked(LED0),
        .rst(rst),
        .pix_data(pix_data),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        .TMDS_CLK_P(TMDS_Clk_p),
        .TMDS_CLK_N(TMDS_Clk_n),
        .TMDS_DATA_P(TMDS_Data_p),
        .TMDS_DATA_N(TMDS_Data_n)
    );
    
  
  
    /// Verifier module ////////////////////////////////////////////////////////
    wire [63:0] username, password;
    wire valid;
    
    // Hey, here's your work!
    verifier user_verifier (
        .username(username),
        .password(password),
        .valid(valid)
    );
   
    // Blackboxed interface module
    lab1_interface interface (
        // System signals
        .clk(display_clk),
        .rst(rst),
       
        // Password verifier interface
        .username(username),
        .password(password),
        .valid(valid),

        // User interface
        .is_password(is_password),
        .enter_button(enter_button),
        .next_char_button(next_char_button),
        .cursor_left_button(cursor_left_button),
        .cursor_right_button(cursor_right_button),

        // VGA video output 
	    .hsync (hsync),
	    .vsync (vsync),	 
	    .r_out(r), 
	    .g_out(g),
	    .b_out(b),
        .vde(vde),
        
        // LED output
        .leds(leds)
	);
   
endmodule
