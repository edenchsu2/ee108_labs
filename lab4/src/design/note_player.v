module note_player(
    input clk,
    input reset,
    input play_enable,  // When high we play, when low we don't.
    input [5:0] note_to_load,  // The note to play
    input [5:0] duration_to_load,  // The duration of the note to play
    input load_new_note,  // Tells us when we have a new note to load
    output done_with_note,  // When we are done with the note this stays high.
    input beat,  // This is our 1/48th second beat
    input generate_next_sample,  // Tells us when the codec wants a new sample
    output [15:0] sample_out,  // Our sample output
    output new_sample_ready  // Tells the codec when we've got a sample
);
    reg [19:0] cur_note;
    wire [19:0] next_note;
    reg [5:0] counter;
    wire [2:0] mux_select;
    reg [2:0] select;
    // Pitch generating
    
    
    // Note_length generating
    
    frequency_rom freq_lu(
        .clk(clk),
        .addr(note_to_load),
        .dout(next_note)
    );
    
    always @(*) begin
        if (load_new_note) begin
            cur_note = next_note;
        end
    end
    
    
    sine_reader make_sample(
        .clk(clk),
        .reset(reset),
        .step_size(cur_note),
        .generate_next(generate_next_sample),
        .sample_ready(new_sample_ready),
        .sample(sample_out)
    );
    
    
    // Select Mux
    assign mux_select = {load_new_note, play_enable, !play_enable} ;
    
    always @(*) begin
        casex (mux_select) 
            3'b1xx: select = 100; // may pause and switch song
            3'b01X: select = 010;
            3'b001: select = 001;
        default : select = 3'b010;
            endcase
    end
    
    // Decrease or load
    always @(*) begin
        case(select)
            3'b100 : counter = duration_to_load;
            3'b001 : counter = counter;
            3'b010 : counter = (beat & counter > 0)? counter - 6'b000001 : counter;
        default counter = duration_to_load;
        endcase       
    end
    
    assign done_with_note = (counter == 6'd0);          
    

endmodule
