module note_player_tb();

    reg clk, reset, play_enable, generate_next_sample;
    reg [5:0] note_to_load;
    reg [5:0] duration_to_load;
    reg load_new_note;
    wire done_with_note, new_sample_ready, beat;
    wire [15:0] sample_out;

    note_player np(
        .clk(clk),
        .reset(reset),

        .play_enable(play_enable),
        .note_to_load(note_to_load),
        .duration_to_load(duration_to_load),
        .load_new_note(load_new_note),
        .done_with_note(done_with_note),

        .beat(beat),
        .generate_next_sample(generate_next_sample),
        .sample_out(sample_out),
        .new_sample_ready(new_sample_ready)
    );
    
 

    // Clock and reset
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        repeat (4) #5 clk = ~clk;
        reset = 1'b0;
        forever #5 clk = ~clk;
    end
    
     beat_generator #(.WIDTH(17), .STOP(300)) beat_gen(
        .clk(clk),
        .reset(reset),
        .en(1'b1),
        .beat(beat)
    );

    // Tests
    initial begin
        
        #20
        reset = 0;
        
        note_to_load = 6'b001010;
        duration_to_load = 6'b000010;
        load_new_note = 1;
        play_enable = 1;
        generate_next_sample = 1;
        
        #30    
        load_new_note = 0;
        $display("Expected %d for duration load", duration_to_load);

        #20000
        duration_to_load = 6'b000100;
        note_to_load = 6'b111111;
        load_new_note = 1;
        
        #2000
        load_new_note = 0;
        
        #2000
        play_enable = 0;
        
        #8000
        play_enable=1;
        
        
     
        

        $display("Hello hello");

    end

endmodule
