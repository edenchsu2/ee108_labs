`timescale 1ns/1ps

module mcu_tb;

    reg clk;
    reg reset;
    reg play_button;
    reg next_button;
    reg song_done;
    wire play;
    wire [1:0] song;
    mcu dut (
        .clk(clk),
        .reset(reset),
        .play_button(play_button),
        .next_button(next_button),
        .song_done(song_done),
        .play(play),
        .song(song)
    );
    always begin
        #5 clk = ~clk;
    end

    task check;
        input expected_play;
        input [1:0] expected_song;
        begin
            if (play !== expected_play || song !== expected_song) begin
                $display("FAIL at time %0t: play=%b (expected %b), song=%d (expected %d)",
                         $time, play, expected_play, song, expected_song);
            end else begin
                $display("PASS at time %0t: play=%b, song=%d",
                         $time, play, song);
            end
        end
    endtask

    task step;
        input pb;
        input nb;
        input sd;
        begin
            @(negedge clk);
            play_button = pb;
            next_button = nb;
            song_done = sd;

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        play_button = 0;
        next_button = 0;
        song_done = 0;

        // Reset: start paused at song 0
        @(posedge clk);
        #1;
        check(1'b0, 2'd0);

        @(negedge clk);
        reset = 0;

        // Play song 0
        step(1, 0, 0);
        check(1'b1, 2'd0);

        // Pause song 0
        step(1, 0, 0);
        check(1'b0, 2'd0);

        // Resume song 0
        step(1, 0, 0);
        check(1'b1, 2'd0);

        // Song finishes: pause and advance to song 1
        step(0, 0, 1);
        check(1'b0, 2'd1);

        // Start song 1
        step(1, 0, 0);
        check(1'b1, 2'd1);

        // Next button: pause and advance to song 2
        step(0, 1, 0);
        check(1'b0, 2'd2);

        // Next while paused: advance to song 3, remain paused
        step(0, 1, 0);
        check(1'b0, 2'd3);

        // Next wraps song 3 to song 0
        step(0, 1, 0);
        check(1'b0, 2'd0);

        // Start song 0, then finish it
        step(1, 0, 0);
        check(1'b1, 2'd0);

        step(0, 0, 1);
        check(1'b0, 2'd1);
        $finish;
    end

endmodule