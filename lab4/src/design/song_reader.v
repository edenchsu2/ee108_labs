module song_reader(
    input clk,
    input reset,    // (reset | reset_player), from music_player
    input play,
    input [1:0] song,
    input note_done,
    output song_done,
    output [5:0] note,
    output [5:0] duration,
    output new_note
);

    // State encoding
    localparam FETCH = 2'd0,
               SEND  = 2'd1,
               WAIT  = 2'd2,
               DONE  = 2'd3;
               
    // State register
    wire [1:0] state;
    reg  [1:0] next_state;
    dffr #(2)  state_ff ( .clk(clk), .r(reset), .d(next_state), .q(state) );
    
    // Note indexing register 
    // reset -> index = 0
    wire [4:0] index, next_index;
    dffr #(5)  index_ff ( .clk(clk), .r(reset), .d(next_index), .q(index) );
    
    // ROM: address = {song, index}
    wire [11:0] rom_out;
    song_rom song_rom_inst ( .clk(clk), .addr({song, index}), .dout(rom_out) );
    assign note = rom_out[11:6];
    assign duration = rom_out[5:0];
    
    always @(*) begin
        case (state)
            FETCH: next_state = SEND;           // always
            SEND: 
                if (duration == 0) begin
                    next_state = DONE;          // end
                end
                else if (play) begin
                    next_state = WAIT;          // send note
                end
                else begin
                    next_state = SEND;          // paused
                end
            WAIT:
                if (!note_done) begin
                    next_state = WAIT;          // hold
                end
                else if (index == 5'b11111) begin
                    next_state = DONE;          // last note
                end
                else begin
                    next_state = FETCH;         // next_note
                end
            DONE:
                next_state = DONE;              // until reset
            default: next_state = FETCH;
        endcase
    end
    
    assign next_index = ((state == WAIT) && note_done && (index != 5'b11111))
                        ? index + 5'd1 : index;
    
    // Outputs
    assign new_note = (state == SEND) && play && (duration != 6'b0);
    assign song_done = (state == DONE);

endmodule

