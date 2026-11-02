module regfile(input         clk,
               // Puerto de escritura Via 0
               input         we3_0,
               input  [4:0]  a3_0,
               input  [31:0] wd3_0,
               // Puerto de escritura Via 1
               input         we3_1,
               input  [4:0]  a3_1,
               input  [31:0] wd3_1,
               // Puertos de lectura Via 0 (Instruccion 0)
               input  [4:0]  a1_0, a2_0,
               output [31:0] rd1_0, rd2_0,
               // Puertos de lectura Via 1 (Instruccion 1)
               input  [4:0]  a1_1, a2_1,
               output [31:0] rd1_1, rd2_1);

  reg [31:0] rf[31:0];

  // Escrituras sincronas en posedge clk
  // Si ambas vias escriben al mismo registro, la via 1 (instruccion posterior) tiene prioridad
  always @(posedge clk) begin
    if (we3_0 && (a3_0 != 5'd0)) rf[a3_0] <= wd3_0;
    if (we3_1 && (a3_1 != 5'd0)) rf[a3_1] <= wd3_1;
  end

  // Lecturas asincronas con bypass interno para WB y cero permanente en x0
  // Puerto lectura 1 - Via 0:
  assign rd1_0 = (a1_0 == 5'd0) ? 32'b0 :
                 (we3_1 && (a3_1 == a1_0) && (a3_1 != 5'd0)) ? wd3_1 :
                 (we3_0 && (a3_0 == a1_0) && (a3_0 != 5'd0)) ? wd3_0 : rf[a1_0];

  // Puerto lectura 2 - Via 0:
  assign rd2_0 = (a2_0 == 5'd0) ? 32'b0 :
                 (we3_1 && (a3_1 == a2_0) && (a3_1 != 5'd0)) ? wd3_1 :
                 (we3_0 && (a3_0 == a2_0) && (a3_0 != 5'd0)) ? wd3_0 : rf[a2_0];

  // Puerto lectura 1 - Via 1:
  assign rd1_1 = (a1_1 == 5'd0) ? 32'b0 :
                 (we3_1 && (a3_1 == a1_1) && (a3_1 != 5'd0)) ? wd3_1 :
                 (we3_0 && (a3_0 == a1_1) && (a3_0 != 5'd0)) ? wd3_0 : rf[a1_1];

  // Puerto lectura 2 - Via 1:
  assign rd2_1 = (a2_1 == 5'd0) ? 32'b0 :
                 (we3_1 && (a3_1 == a2_1) && (a3_1 != 5'd0)) ? wd3_1 :
                 (we3_0 && (a3_0 == a2_1) && (a3_0 != 5'd0)) ? wd3_0 : rf[a2_1];

endmodule
