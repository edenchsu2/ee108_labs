module length_finder_tb ();

   reg [63:0] in;
   wire [3:0] len;
   reg [3:0] expected;
   length_finder dut (
      .string (in),
      .length (len)
   );
   
   initial begin
      in = 64'hAABBCCDDEEFFAA00;
      expected = 4'b0000;
      #5
      $display("%b -> %b, expected %b", in, len, expected);
      
      in = 64'hAABBCCDDEEFFAA99;
      expected = 4'b1000;
      #5
      $display("%b -> %b, expected %b", in, len, expected);
      in = 64'hAABBCCDDEEFF00AA;
      expected = 4'b0001;
      #5
      $display("%b -> %b, expected %b", in, len, expected);
      in = 64'hAABBCCDDEE00FFAA;
      expected = 4'b0010;
      #5
      $display("%b -> %b, expected %b", in, len, expected);

      in = 64'hAABBCC00EE00FFAA;
      expected = 4'b0010;
      #5
      $display("%b -> %b, expected %b", in, len, expected);

      in = 64'h00BBCCDDEE44FFAA;
      expected = 4'b0111;
      #5
      $display("%b -> %b, expected %b", in, len, expected);

      in = 64'h00BBCC00EE44FFAA;
      expected = 4'b0100;
      #5
      $display("%b -> %b, expected %b", in, len, expected);

      in = 64'h44BBC00DEE44FFAA;
      expected = 4'b1000;
      #5
      $display("%b -> %b, expected %b", in, len, expected);

      in = 0;
      expected = 4'b0000;
      #5
      $display("%b -> %b, expected %b", in, len, expected);

   end
   
endmodule
