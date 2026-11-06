`define ARMED  3'b001
`define ACTIVE 3'b010
`define WAIT   3'b100

module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in,
    input wave_display_idle,

    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index
);

// FSM wires
reg  [2:0] next_state;
wire [2:0] state;
wire [7:0] counter;

// Transition wires
wire prev_sign;
wire zero_crossing;

wire [7:0] next_counter;

// Remember the sign of the last sample; update only on new sample
dffre prev_sign_ff(.clk(clk), .r(reset), .en(new_sample_ready), .d(new_sample_in[15]), .q(prev_sign));
// positive crossing: prev negative, curr non-zero (sign bit 0)
assign zero_crossing = new_sample_ready & prev_sign & ~new_sample_in[15];

// Do FSM
dffr #(3) state_ff(.clk(clk), .r(reset), .d(next_state), .q(state));
always @(*) begin
    case(state)
      `ARMED: next_state = zero_crossing ? `ACTIVE : `ARMED;
      `ACTIVE: next_state = ((counter == 255) & new_sample_ready) ? `WAIT : `ACTIVE;
      `WAIT: next_state = wave_display_idle ? `ARMED : `WAIT;
      default: next_state = `ARMED;
    endcase
end

// counter that increments only in active state
assign next_counter = ((state == `ACTIVE) & (new_sample_ready)) ? counter + 8'd1 : //increment
                      (state == `ARMED) ? 8'd0 : counter;                
                      
dffr #(8) counter_ff(.clk(clk), .r(reset), .d(next_counter), .q(counter));

// write into RAM
assign write_address = { !read_index , counter};
assign write_enable = new_sample_ready & (state == `ACTIVE);
assign write_sample = new_sample_in[15:8] +  8'd128;

// flip read index when leaving WAIT (display idle), swapping the buffers
dffr write_index_ff(
    .clk(clk), 
    .r(reset), 
    .d(((state == `WAIT) & (wave_display_idle)) ? !read_index : read_index),
    .q(read_index)
);

endmodule