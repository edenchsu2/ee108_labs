module mcu(
    input clk,
    input reset,
    input play_button,
    input next_button,
    output play,
    output reset_player,
    output [1:0] song,
    input song_done
);

    wire state, next_state, advance_song;
    wire [1:0] next_song;
    dffr state_ff(.clk(clk), .r(reset), .d(next_state), .q(state));
    dffr #(2)song_ff(.clk(clk), .r(reset), .d(next_song), .q(song));

    assign next_state = (state == 1'b0) ? play_button :
                        (play_button || next_button || song_done) ? 1'b0 : 1'b1;
                        
    assign advance_song = song_done || next_button;
    assign next_song = advance_song ? song + 2'b1 : song;
    
    assign play = state;
    

endmodule
