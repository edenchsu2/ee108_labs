module sine_reader(
    input clk,
    input reset,
    input [19:0] step_size,
    input generate_next,

    output sample_ready,
    output wire [15:0] sample
);

    wire [21:0] current_addr, next_addr;
    dffr #(22) sine_ff(.clk(clk), .r(reset), .d(next_addr), .q(current_addr));
    //step if generate_next
    assign next_addr = generate_next ? current_addr + {2'b00, step_size} : current_addr;
    
    wire [9:0] rom_addr;
    //if in quadrants 2 and 4, (01 or 11) you need to flip horizontally
    assign rom_addr = current_addr[20] ? ~current_addr[19:10] : current_addr[19:10];
    
    wire[15:0] rom_sample;
    sine_rom sr(.clk(clk), .addr(rom_addr), .dout(rom_sample));
    wire should_negate;
    wire one_to_two;
    //should_negate becomes 1 if we are in quadrants 3 and 4
    dffr negate_ff (.clk(clk), .r(reset), .d(current_addr[21]), .q(should_negate));
    dffr ready_ff_one (.clk(clk), .r(reset), .d(generate_next), .q(one_to_two));
    dffr ready_ff_two(.clk(clk), .r(reset), .d(one_to_two), .q(sample_ready));
    //flip vertically if should_negate
    assign sample = should_negate ? (16'b0 - rom_sample) : rom_sample;
    
endmodule
