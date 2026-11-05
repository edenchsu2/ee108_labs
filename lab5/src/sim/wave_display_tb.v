
`timescale 1ns / 1ps

module wave_display_tb();

    reg clk, reset, valid, read_index;
    reg [10:0] x;
    reg [9:0] y;
    reg [7:0] read_value;

    wire [8:0] read_address;
    wire valid_pixel;
    wire [7:0] r, g, b;

    integer errors;

    // Device under test
    wave_display dut (
        .clk(clk),
        .reset(reset),
        .x(x),
        .y(y),
        .valid(valid),
        .read_index(read_index),
        .read_value(read_value),
        .read_address(read_address),
        .valid_pixel(valid_pixel),
        .r(r),
        .g(g),
        .b(b)
    );

    // 100 MHz clock
    always begin
        #5 clk = 0;
        #5 clk = 1;
    end

    // RAM
    reg [7:0] memory [0:511];

    always @(posedge clk) begin
        read_value <= memory[read_address];
    end

    // Check pixel after registers update
    task check_pixel;
        input expected;
        begin
            #1;
            if (valid_pixel !== expected) begin
                $display("ERROR: x=%d y=%d expected=%b got=%b time=%t",
                         x, y, expected, valid_pixel, $time);
                errors = errors + 1;
            end
            else begin
                $display("PASS: x=%d y=%d valid_pixel=%b",
                         x, y, valid_pixel);
            end
        end
    endtask

    // Advance one clock while setting VGA coordinates
    task step;
        input [10:0] next_x;
        input [9:0] next_y;
        input next_valid;
        begin
            @(negedge clk);
            x = next_x;
            y = next_y;
            valid = next_valid;
            @(posedge clk);
            #1;
        end
    endtask

    integer i;

    initial begin
        errors = 0;
        reset = 1;
        valid = 0;
        read_index = 0;
        x = 0;
        y = 0;
        read_value = 0;

        // Default all RAM samples to 0
        for (i = 0; i < 512; i = i + 1)
            memory[i] = 8'd0;

        // Adjusted sample = raw / 2 + 32
        //
        // RAM[0] = 136 -> adjusted = 100
        // RAM[1] = 236 -> adjusted = 150
        // RAM[2] = 176 -> adjusted = 120

        memory[0] = 8'd136;
        memory[1] = 8'd236;
        memory[2] = 8'd176;

        // Also populate the second buffer
        memory[256] = 8'd136;
        memory[257] = 8'd236;
        memory[258] = 8'd176;

        // Reset
        #20;
        reset = 0;

        // TEST 1: Address mapping
        $display("\nTEST 1: Address mapping");

        step(11'd256, 10'd200, 1);

        if (read_address !== 9'd0) begin
            $display("ERROR: expected address 0, got %d", read_address);
            errors = errors + 1;
        end

        step(11'd258, 10'd200, 1);

        if (read_address !== 9'd1) begin
            $display("ERROR: expected address 1, got %d", read_address);
            errors = errors + 1;
        end

        step(11'd512, 10'd200, 1);

        if (read_address !== 9'd128) begin
            $display("ERROR: expected address 128, got %d", read_address);
            errors = errors + 1;
        end

        // TEST 2: Valid pixel inside sample bounds
        $display("\nTEST 2: Upward waveform");

        // Leave region to reset history
        step(11'd0, 10'd240, 0);
        step(11'd0, 10'd240, 0);

        // Y = 120, between samples 100 and 150
        step(11'd256, 10'd240, 1);
        step(11'd257, 10'd240, 1);
        step(11'd258, 10'd240, 1);
        step(11'd259, 10'd240, 1);

        $display("Current sample=%d previous=%d",
                 dut.current_sample, dut.previous_sample);

        // TEST 3: Outside Y bounds
        $display("\nTEST 3: Outside waveform bounds");

        // Y = 170, not between 100 and 150
        step(11'd0, 10'd340, 0);
        step(11'd0, 10'd340, 0);

        step(11'd256, 10'd340, 1);
        step(11'd257, 10'd340, 1);
        step(11'd258, 10'd340, 1);
        step(11'd259, 10'd340, 1);

        check_pixel(0);

        // TEST 4: Invalid VGA pixel
        $display("\nTEST 4: Invalid pixel");

        step(11'd260, 10'd240, 0);
        step(11'd261, 10'd240, 0);
        check_pixel(0);

        // TEST 5: Outside horizontal display region
        $display("\nTEST 5: Outside display region");

        step(11'd100, 10'd240, 1);
        step(11'd101, 10'd240, 1);
        check_pixel(0);

        // TEST 6: Bottom half of screen
        $display("\nTEST 6: Bottom half");

        step(11'd300, 10'd600, 1);
        step(11'd301, 10'd600, 1);
        check_pixel(0);

        // TEST 7: Switch read buffer
        $display("\nTEST 7: Read index");

        @(negedge clk);
        read_index = 1;

        step(11'd256, 10'd240, 1);

        if (read_address !== 9'd256) begin
            $display("ERROR: expected address 256, got %d", read_address);
            errors = errors + 1;
        end

        $display("\n---------------------------");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%d TESTS FAILED", errors);
        $display("---------------------------");

        $finish;
    end

endmodule
