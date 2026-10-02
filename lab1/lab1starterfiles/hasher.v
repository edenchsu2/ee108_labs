module hasher (
   input [63:0] data,
   input [3:0] data_len,
   output wire [31:0] hash
);

	wire [7:0] first_data, second_data, third_data, fourth_data, fifth_data, sixth_data, seventh_data, eighth_data;
	wire [31:0] first_out, second_out, third_out, fourth_out, fifth_out, sixth_out, seventh_out, eighth_out;
	wire [31:0] final_state;
	wire rotate_dir;
	assign {eighth_data, seventh_data, sixth_data, fifth_data, fourth_data, third_data, second_data, first_data} = data;
	hash_round #(.ROUND(0)) first_hash_round(.in_byte(first_data),
	                                        .in_state(32'h55555555),
	                                        .out_state(first_out));
	                                        
	hash_round #(.ROUND(1)) second_hash_round(.in_byte(second_data),
	                                        .in_state(32'hAAAAAAAA),
	                                        .out_state(second_out));
	                                        
	hash_round #(.ROUND(2)) third_hash_round(.in_byte(third_data),
	                                        .in_state(first_out),
	                                        .out_state(third_out));
	                                        
	hash_round #(.ROUND(3)) fourth_hash_round(.in_byte(fourth_data),
	                                        .in_state(second_out),
	                                        .out_state(fourth_out));
	                                        
	hash_round #(.ROUND(4)) fifth_hash_round(.in_byte(fifth_data),
	                                        .in_state(third_out),
	                                        .out_state(fifth_out));
	                                        
	hash_round #(.ROUND(5)) sixth_hash_round(.in_byte(sixth_data),
	                                        .in_state(fourth_out),
	                                        .out_state(sixth_out));
	                                        
	hash_round #(.ROUND(6)) seventh_hash_round(.in_byte(seventh_data),
	                                        .in_state(fifth_out),
	                                        .out_state(seventh_out));
	                                        
	hash_round #(.ROUND(7)) eighth_hash_round(.in_byte(eighth_data),
	                                        .in_state(sixth_out),
	                                        .out_state(eighth_out));
	                                        
	assign final_state = seventh_out ^ eighth_out;
	assign rotate_dir = ^data_len;
	
	rotator #(.WIDTH(32))rotate(
	                   .direction(rotate_dir),
	                   .in(final_state),
	                   .distance({3'b000, final_state[4:0]}),
	                   .out(hash));
	
	
endmodule
