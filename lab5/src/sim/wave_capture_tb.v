// Samples arrive as 1-cycle new_sample_ready pulses with idle cycles in between
module wave_capture_tb();

    reg clk, reset;
    reg new_sample_ready, wave_display_idle;
    reg [15:0] new_sample_in;

    wire [8:0] write_address;
    wire write_enable;
    wire [7:0] write_sample;
    wire read_index;

    integer errors = 0;
    integer i;

    // one-hot state encodings (match wave_capture.v)
    localparam ARMED = 3'b001, ACTIVE = 3'b010, WAIT = 3'b100;

    wave_capture dut(
        .clk(clk),
        .reset(reset),
        .new_sample_ready(new_sample_ready),
        .new_sample_in(new_sample_in),
        .wave_display_idle(wave_display_idle),
        .write_address(write_address),
        .write_enable(write_enable),
        .write_sample(write_sample),
        .read_index(read_index)
    );

    // 100 MHz clock
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Send one sample: pulse new_sample_ready for one cycle, then hold the
    // value for a few idle cycles. Checks the write on the pulse cycle and
    // that nothing is written while new_sample_ready is low.
    task send_sample(input [15:0] s, input exp_we, input [8:0] exp_addr);
    begin
        @(negedge clk);
        new_sample_in = s;
        new_sample_ready = 1'b1;
        #1;
        if (write_enable !== exp_we) begin
            $display("ERROR t=%0t sample=%h: write_enable=%b, expected %b",
                     $time, s, write_enable, exp_we);
            errors = errors + 1;
        end else if (exp_we && (write_address !== exp_addr ||
                                write_sample !== {~s[15], s[14:8]})) begin
            $display("ERROR t=%0t sample=%h: addr=%0d data=%0d, expected addr=%0d data=%0d",
                     $time, s, write_address, write_sample, exp_addr, {~s[15], s[14:8]});
            errors = errors + 1;
        end
        @(negedge clk);
        new_sample_ready = 1'b0;
        repeat (3) begin
            #1;
            if (write_enable !== 1'b0) begin
                $display("ERROR t=%0t: write_enable high without new_sample_ready", $time);
                errors = errors + 1;
            end
            @(negedge clk);
        end
    end
    endtask

    // Compare state and read_index against expected values
    task check(input [2:0] exp_state, input exp_ri, input [8*60:1] msg);
    begin
        if (dut.state !== exp_state || read_index !== exp_ri) begin
            $display("ERROR %0s: state=%b read_index=%b, expected state=%b read_index=%b",
                     msg, dut.state, read_index, exp_state, exp_ri);
            errors = errors + 1;
        end else
            $display("PASS  %0s", msg);
    end
    endtask

    initial begin
        // ---- Test 1: reset ----
        reset = 1'b1; new_sample_ready = 1'b0; new_sample_in = 16'd0;
        wave_display_idle = 1'b0;
        repeat (3) @(negedge clk);
        reset = 1'b0;
        @(negedge clk);
        check(ARMED, 1'b0, "T1 reset -> ARMED, read_index=0");

        // ---- Test 2: no trigger without a negative->positive crossing ----
        send_sample(16'h4000, 1'b0, 9'd0);   // positive
        send_sample(16'h2000, 1'b0, 9'd0);   // positive
        send_sample(16'hC000, 1'b0, 9'd0);   // positive -> negative (wrong direction)
        send_sample(16'hA000, 1'b0, 9'd0);   // negative
        check(ARMED, 1'b0, "T2 no trigger on +/+ or +->- crossing");

        // ---- Test 3: negative -> positive crossing triggers capture ----
        send_sample(16'h1000, 1'b0, 9'd0);   // crossing detected on this sample
        check(ACTIVE, 1'b0, "T3 -> ACTIVE on -->+ crossing");

        // ---- Test 4: capture 256 samples into the upper half (read_index=0) ----
        // s = i*256 - 32768, so the stored value {~s[15], s[14:8]} equals i:
        // the RAM fills with a 0..255 ramp, easy to see in the waveform.
        for (i = 0; i < 256; i = i + 1)
            send_sample(i*256 - 32768, 1'b1, {1'b1, i[7:0]});
        check(WAIT, 1'b0, "T4 256 writes to 256..511, -> WAIT");

        // ---- Test 5: WAIT ignores samples while display is busy ----
        send_sample(16'h1234, 1'b0, 9'd0);
        send_sample(16'hF000, 1'b0, 9'd0);
        check(WAIT, 1'b0, "T5 WAIT holds, no writes while busy");

        // ---- Test 6: display idle -> flip read_index, back to ARMED ----
        @(negedge clk); wave_display_idle = 1'b1;
        @(negedge clk); wave_display_idle = 1'b0;
        check(ARMED, 1'b1, "T6 idle -> read_index flips, ARMED");

        // ---- Test 7: second capture writes to the lower half (0..255) ----
        send_sample(16'h8000, 1'b0, 9'd0);   // negative
        send_sample(16'h0100, 1'b0, 9'd0);   // crossing
        for (i = 0; i < 4; i = i + 1)
            send_sample(i*256 - 32768, 1'b1, {1'b0, i[7:0]});
        check(ACTIVE, 1'b1, "T7 second capture writes to 0..255");

        // ---- Test 8: reset mid-capture ----
        @(negedge clk); reset = 1'b1;
        @(negedge clk); reset = 1'b0;
        @(negedge clk);
        check(ARMED, 1'b0, "T8 reset mid-capture -> ARMED, read_index=0");

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d ERRORS", errors);
        $finish;
    end

endmodule