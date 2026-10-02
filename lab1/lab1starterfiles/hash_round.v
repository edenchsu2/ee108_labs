module hash_round #(parameter ROUND=0)(
   input [7:0] in_byte,
   input [31:0] in_state,
   output wire [31:0] out_state
);
   
	// Declarations
	wire [7:0] a;
	wire [7:0] b;
	wire [7:0] c;
	wire [7:0] d;
	reg [7:0] mix;
	wire [7:0] mixed_a;
	wire [7:0] rotated_mixed_a;
	
	// State splitting
	assign {d,c,b,a} = in_state;
	
	// Mix function
	always @(*) begin
	   case(ROUND)
	   0: mix = (c & b) | (~b & d);
	   1: mix = (c & b) | (~b & d);
	   2: mix = (c & b) | (~b & d);
	   3: mix = (c & b) | (b & d) | (c & d);
	   4: mix = (c & b) | (b & d) | (c & d);
	   5: mix = c ^ b ^d;
	   6: mix = c ^ b ^d;
	   7: mix = c ^ b ^d;
	   default: mix = 0;
	   endcase   
	end
	
	assign mixed_a = mix + a + in_byte;
	   
	
	// Rotator
	rotator #(.WIDTH(8)) mixed_a_rotator(
	       .direction(1'b1),
	       .in(mixed_a),
	       .distance(ROUND),
	       .out(rotated_mixed_a)
	       );
	// Output state assignment
	assign out_state = {c, b, rotated_mixed_a, d};

endmodule
