module verifier (
   input [63:0] password,
   input [63:0] username,
   output wire valid
   
);

    wire [3:0] pass_length, user_length, cam_addr;
    wire [31:0] pass_hash, rom_data, pass_rom_data;
    wire cam_valid, match;
    
    length_finder pass_lf(.string(password), .length(pass_length));
    length_finder user_lf(.string(username), .length(user_length));
    
    hasher h(.data(password), .data_len(pass_length), .hash(pass_hash));
    cam user_cam(.data_len(user_length), .data(username), .valid(cam_valid), .addr(cam_addr));
    hash_rom pass_rom(.addr(cam_addr), .data(pass_rom_data));
    
    assign match = pass_rom_data == pass_hash;
    assign valid = match & cam_valid;
    
    
    

	

endmodule
