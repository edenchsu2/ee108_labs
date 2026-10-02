module hash_rom(
   input [2:0] addr,
   output reg [31:0] data
);
   
	// Module body
	always @(*) begin
	   case(addr)
	       3'b000: data = 32'hDC1A2C9E;
	       3'b001: data = 32'hDC2EA8E4;
	       3'b010: data = 32'h355FACC3;
	       3'b011: data = 32'hAAF4ADC9;
	       3'b100: data = 32'h13D41CED;
	       3'b101: data = 32'h7EBCF8A8;
	       3'b110: data = 32'hF3CDDB9B;
	       3'b111: data = 32'h9948E6BE;
	       default: data = 32'h0;     
	   endcase
	end

endmodule
