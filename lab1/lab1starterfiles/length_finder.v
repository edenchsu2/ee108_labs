module length_finder (
   input [63:0] string,
   output wire [3:0] length
);
   
	// wire declarations
	wire [7:0] is_character_null;
	wire [7:0] first_null_character;
	
	// is_character_null logic (8 lines of it!)
	assign is_character_null[0] = ~|(string[7:0]);
	assign is_character_null[1] = ~|(string[15:8]);
	assign is_character_null[2] = ~|(string[23:16]);
	assign is_character_null[3] = ~|(string[31:24]);
	assign is_character_null[4] = ~|(string[39:32]);
	assign is_character_null[5] = ~|(string[47:40]);
	assign is_character_null[6] = ~|(string[55:48]);
	assign is_character_null[7] = ~|(string[63:56]);
	// arbiter
	
	arbiter null_arbiter (
	   .in(is_character_null),
	   .out(first_null_character)
	);
	
	encoder null_encoder (
	   .in(first_null_character),
	   .out(length[2:0])
	);
	
	assign length[3] = (is_character_null == 8'b00000000);
  
endmodule
