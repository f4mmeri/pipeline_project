module dmem(input  clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg [31:0] RAM[0:511];   // 2 KB (antes 64 palabras): cubre hasta la direccion 2047
  integer i;

  initial begin
    for (i = 0; i < 512; i = i + 1) RAM[i] = 32'b0;
  end

  assign rd = RAM[a[31:2]]; // word aligned

  always @(posedge clk) begin
    if (we) RAM[a[31:2]] <= wd;
  end
endmodule
