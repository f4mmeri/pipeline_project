module imem(input  [31:0] a,
            output [31:0] rd);

  reg [31:0] RAM[0:255];   // 256 palabras (antes 64): el programa del profe tiene 90
  integer i;

  initial begin
      for (i = 0; i < 256; i = i + 1)
          RAM[i] = 32'h00000013;   // NOP = addi x0,x0,0
      $readmemh("programa_propio.mem", RAM);   // el testbench puede cambiarlo con +PROG=
  end

  assign rd = RAM[a[31:2]]; // word aligned
endmodule
