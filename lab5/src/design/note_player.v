module note_player(
    input clk,
    input reset,
    input play_enable,
    input [5:0] note_to_load,
    input [5:0] duration_to_load,
    input load_new_note,
    output done_with_note,
    input beat,
    input generate_next_sample,
    output [15:0] sample_out,
    output new_sample_ready
);

    wire [19:0] cur_note;
    wire [19:0] next_note;
    wire load_note_delayed;
    wire [5:0] counter;
    wire [5:0] next_counter;
    wire [19:0] next_cur_note;


    frequency_rom freq_lu( .clk(clk), .addr(note_to_load), .dout(next_note));
    
    dffr load_delay_ff(.clk(clk), .r(reset), .d(load_new_note), .q(load_note_delayed));
    assign next_cur_note = load_note_delayed ? next_note : cur_note;
    dffr #(20) note_ff(.clk(clk), .r(reset), .d(next_cur_note), .q(cur_note));

    assign next_counter =
        load_new_note ? duration_to_load :
        (play_enable && beat && (counter > 0)) ? counter - 6'd1 :
        counter;

    dffr #(6) counter_ff(.clk(clk), .r(reset), .d(next_counter), .q(counter));
    wire [15:0] sine_sample;
    sine_reader make_sample(.clk(clk),
        .reset(reset),
        .step_size(cur_note),
        .generate_next(generate_next_sample),
        .sample_ready(new_sample_ready),
        .sample(sine_sample)
    );
    assign sample_out = play_enable ? sine_sample : 16'b0;

    assign done_with_note = (counter == 6'd0);

endmodule