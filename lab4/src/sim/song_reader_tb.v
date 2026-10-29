`timescale 1ns/1ps
module song_reader_tb();

    reg clk, reset, play, note_done;
    reg [1:0] song;
    wire song_done, new_note;
    wire [5:0] note, duration;

    song_reader dut(
        .clk(clk), .reset(reset), .play(play), .song(song), .note_done(note_done),
        .song_done(song_done), .new_note(new_note),
        .note(note), .duration(duration) );

    //timeout watchdog
    initial begin
        #100000 // 10ps
        $display("TIMEOUT: state=%d index=%d.", dut.state, dut.index);
        $finish;
    end
    
    // Clock and reset
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        play = 1'b0;
        note_done = 1'b0;
        song = 2'b0;
        repeat (4) #5 clk = ~clk;
        reset = 1'b0;
        forever #5 clk = ~clk;
    end
    
    // Monitor block
    always @(posedge clk)
        if (new_note) begin
        $display("%t state=%d  index=%d --> note=%d | duration=%d.",
                  $time, dut.state, dut.index, note, duration);
        end
        
     // Helper taks
     task wait_new_note;
        begin
            #1
            while (!new_note) @(negedge clk);
            @(negedge clk);
        end
    endtask
     
    task finish_note;
        begin
            repeat (5) @(negedge clk);
            note_done = 1'b1;
            @(negedge clk);
            note_done = 1'b0;
        end
    endtask
    
    task wait_note_or_done;
        begin
            @(negedge clk);
            while (!new_note && !song_done) @(negedge clk);
        end
    endtask
    
    integer count, rests;
    task play_to_end;
        begin
            count = 0; rests = 0;
            wait_new_note; 
            count = count + 1;
            if (note == 0) begin
                rests = rests + 1;
            end
            while (!song_done) begin
                finish_note;
                wait_note_or_done;
                if (new_note) begin 
                    count = count + 1;
                    if (note == 0) begin
                        rests = rests + 1;
                    end
                end
            end
        end
    endtask

    // Tests
    initial begin
        // wait for the clock block to release reset
        @(negedge clk);
        while (reset) @(negedge clk);
        
        // Case 1: paused after reset
        $display("### Case 1: pause ###");
        repeat (20) @(negedge clk);
        if (dut.state != 1) begin
            $display("FAIL 1: state=%d, expected 1 (SEND).", dut.state);
        end
     
        // Case 2: press play -> first note
        $display("### Case 2: first note ###");
        play = 1;
        wait_new_note;
        if (note != 49 || duration != 12) begin
            $display("FAIL 2.");
        end
        
        // Case 3: finish note -> second note
        $display("### Case 3: next note ###");
        finish_note;
        wait_new_note;
        if (note != 1 || duration != 8 || dut.index != 1) begin
            $display("FAIL 3.");
        end   
        
        // Case 4: pause between notes -> nothing send -> resume -> entry 2
        $display("### Case 4: pause/resume ###");
        play = 0;
        finish_note;
        repeat (20) @(negedge clk); // should print nothing
        play = 1;
        wait_new_note;
        if (note != 51 || duration != 12 || dut.index != 2) begin
            $display("FAIL 4.");
        end 
        
        // Case 5: finish song
        $display("### Case 5: run to end ###");
        while (!song_done) begin
            finish_note;
            wait_note_or_done;
        end
        $display("Song done at index=%d", dut.index);
        repeat (5) @(negedge clk);
        if (!song_done) begin
            $display("FAIL 5: song_done dropped.");
        end
            
        // Case 6: song 3 (32 notes, no padding) -> ends via index == 31
        $display("### Case 6: full 32-note song ###");
        song = 3; reset = 1; @(negedge clk); reset = 0;
        play = 1;
        play_to_end;
        if (count != 32 || dut.index != 31) begin
            $display("FAIL 6: %0d notes, index %0d.", count, dut.index);
        end 
    
        // Case 7: reset with song = 1 -> restarts at song 1, note 0
        $display("### Case 7: switch to song 1 ###");
        song = 1; reset = 1; @(negedge clk); reset = 0;
        wait_new_note;
        if (dut.index != 0) begin
            $display("FAIL 7.");
        end 
        
        // Case 8: rest notes are sent, not treated as end of song
        $display("### Case 8: rests ###");
        song = 2; reset = 1; @(negedge clk); reset = 0;
        play_to_end;
        $display("Song 2: %0d notes, %0d rests sent.", count, rests);
        if (rests == 0) begin
            $display("FAIL 8.");
        end 
        
        // Case 9: stray note_done while paused in SEND -> ignored
        $display("### Case 9: stray note_done ###");
        song = 0; play = 0; reset = 1; @(negedge clk); reset = 0;
        repeat (3) @(negedge clk);
        note_done = 1; @(negedge clk); note_done = 0;
        repeat (3) @(negedge clk);
        if (dut.state != 1 || dut.index != 0) begin
            $display("FAIL 9.");
        end
        
        $display("### DONE ###");
        $finish;
    end
    
endmodule


