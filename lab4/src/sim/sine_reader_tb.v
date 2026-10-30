module sine_reader_tb();

    reg clk, reset, generate_next;
    reg [19:0] step_size;
    wire sample_ready;
    wire [15:0] sample;
    sine_reader dut(
        .clk(clk),
        .reset(reset),
        .step_size(step_size),
        .generate_next(generate_next),
        .sample_ready(sample_ready),
        .sample(sample)
    );

    // Clock and reset
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end
    
    task request_sample;
        begin
            @(negedge clk);
            generate_next = 1;
            @(negedge clk);
            generate_next = 0;
            @(negedge clk);
        end
    endtask

    integer i;
    initial begin
        clk = 0;
        reset = 1;
        step_size = 20'd0;
        generate_next = 0;
        repeat (2) @(negedge clk);
        reset = 0;

        // Advance by 256 ROM addresses per request
        step_size = 20'd262144;

        // Test all four quadrants
        for (i = 0; i < 16; i = i + 1) begin
            request_sample;
        end

        #20;
        $finish;
    end
    initial begin
        $monitor(
            "Time=%0t | quadrant=%b | rom_addr=%d | ready=%b | sample=%d (%h)",
            $time,
            dut.current_addr[21:20],
            dut.rom_addr,
            sample_ready,
            sample,
            sample
        );
    end
endmodule
