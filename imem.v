module imem(input  [31:0] a,
            output [31:0] rd0,
            output [31:0] rd1);
  
  reg [31:0] RAM[63:0]; 

  initial begin
              $readmemh("pipeline_proyect/programa_dual.mem", RAM); 
  end

  // DUAL FETCH: se leen dos instrucciones contiguas de 32 bits simultaneamente
  assign rd0 = RAM[a[31:2]];         // Instruccion 0 (Via 0, direccion PC)
  assign rd1 = RAM[a[31:2] + 1'b1];  // Instruccion 1 (Via 1, direccion PC + 4)

endmodule
