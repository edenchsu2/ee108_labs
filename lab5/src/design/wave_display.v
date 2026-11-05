
module wave_display(
    input clk,
    input reset,
    input [10:0] x,
    input [9:0] y,
    input valid,
    input read_index,
    input [7:0] read_value,
    output [8:0] read_address,
    output valid_pixel,
    output [7:0] r,
    output [7:0] g,
    output [7:0] b
);

    // Convert X coordinate into RAM address
    assign read_address = {read_index, x[9], x[7:1]};

    // Adjust sample for display
    wire [7:0] read_value_adjusted;
    assign read_value_adjusted = {1'b0, read_value[7:1]} + 8'd32;

    // Delay coordinates to account for RAM latency
    wire [10:0] x_delay;
    wire [9:0] y_delay;
    wire valid_delay;
    wire [8:0] address_delay;

    dffr #(11) x_ff (
        .clk(clk),
        .r(reset),
        .d(x),
        .q(x_delay)
    );

    dffr #(10) y_ff (
        .clk(clk),
        .r(reset),
        .d(y),
        .q(y_delay)
    );

    dffr #(1) valid_ff (
        .clk(clk),
        .r(reset),
        .d(valid),
        .q(valid_delay)
    );

    dffr #(9) address_ff (
        .clk(clk),
        .r(reset),
        .d(read_address),
        .q(address_delay)
    );

    // Check whether we're inside the waveform region
    wire display_region;
    assign display_region =
        valid_delay &&
        !y_delay[9] &&
        !x_delay[10] &&
        (x_delay[9:8] == 2'b01 ||
         x_delay[9:8] == 2'b10);

    wire [7:0] current_sample, previous_sample;
    wire [8:0] last_address;

    wire have_sample, have_pair;
    // Detect a new RAM address
    wire address_changed;
    assign address_changed = (address_delay != last_address);

    // Control signals
    wire load_first;
    wire load_next;

    assign load_first = display_region && !have_sample;

    assign load_next = display_region &&
                       have_sample &&
                       address_changed;

    // Next-state logic
    wire [7:0] next_current_sample, next_previous_sample;
    wire [8:0] next_last_address;

    wire next_have_sample, next_have_pair;
    // update current_sample if 
    assign next_current_sample =
        (load_first || load_next) ?
        read_value_adjusted : current_sample;
    // if load_next, new previous_sample is the current_sample
    assign next_previous_sample =
        load_next ? current_sample : previous_sample;
    // if anything to load, update address
    assign next_last_address =
        (load_first || load_next) ?
        address_delay : last_address;
    // if not in display_region, we don't have next_sample. If we are loading first, we have our first sample
    assign next_have_sample =
        !display_region ? 1'b0 :
        (load_first ? 1'b1 : have_sample);
    // if we are not in display_region, 0, if it's out first sample, we don't have pair, if we load_next, we have a pair. otherwise, stay the same
    assign next_have_pair =
        !display_region ? 1'b0 :
        (load_first ? 1'b0 :
        (load_next ? 1'b1 : have_pair));

    // flip flops for storage
    dffr #(8) current_ff (
        .clk(clk),
        .r(reset),
        .d(next_current_sample),
        .q(current_sample)
    );

    dffr #(8) previous_ff (
        .clk(clk),
        .r(reset),
        .d(next_previous_sample),
        .q(previous_sample)
    );

    dffr #(9) last_address_ff (
        .clk(clk),
        .r(reset),
        .d(next_last_address),
        .q(last_address)
    );

    dffr #(1) have_sample_ff (
        .clk(clk),
        .r(reset),
        .d(next_have_sample),
        .q(have_sample)
    );

    dffr #(1) have_pair_ff (
        .clk(clk),
        .r(reset),
        .d(next_have_pair),
        .q(have_pair)
    );

    // Determine Y coordinate
    wire [7:0] y_value;
    assign y_value = y_delay[8:1];

    // Find upper and lower waveform bounds
    wire [7:0] lower_bound;
    wire [7:0] upper_bound;

    wire [7:0] sample_a;
    wire [7:0] sample_b;
    //if no new sample, compare current and previous sample. If new sample, compare current sample and adjusted incoming read_val
    assign sample_a = address_changed ?
                      current_sample : previous_sample;

    assign sample_b = address_changed ?
                      read_value_adjusted : current_sample;

    assign lower_bound =
        (sample_a < sample_b) ? sample_a : sample_b;

    assign upper_bound =
        (sample_a > sample_b) ? sample_a : sample_b;

    // Check whether the line segment is valid
    wire segment_valid;
    assign segment_valid =
        have_sample &&
        (address_changed || have_pair);

    // Determine whether pixel is part of waveform
    wire next_valid_pixel;

    assign next_valid_pixel =
        display_region &&
        segment_valid &&
        (y_value >= lower_bound) &&
        (y_value <= upper_bound);

    dffr #(1) pixel_ff (
        .clk(clk),
        .r(reset),
        .d(next_valid_pixel),
        .q(valid_pixel)
    );

    // White waveform
    assign r = 8'hFF;
    assign g = 8'hFF;
    assign b = 8'hFF;

endmodule
