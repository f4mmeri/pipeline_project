`timescale 1ns/1ps
module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;

  // instantiate device to be tested
  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  // initialize test
  initial begin
    reset = 1; # 22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    clk = 1;
    # 5; clk = 0; # 5;
  end

  // ---- contador de ciclos (desde que se suelta el reset) ----
  integer ciclos = 0;
  reg     fin    = 0;
  always @(posedge clk) if (!reset && !fin) ciclos <= ciclos + 1;

  // ---- marcas de fin de etapa: ultimo sw de cada etapa (aparece en MEM) ----
  wire fin_A = (MemWrite === 1'b1) && (DataAdr === 32'd1544); // sw x10, 8(x1)
  wire fin_B = (MemWrite === 1'b1) && (DataAdr === 32'd1556); // sw x18, 20(x1)
  wire fin_C = (MemWrite === 1'b1) && (DataAdr === 32'd1568); // sw x24, 32(x1)
  wire fin_D = (MemWrite === 1'b1) && (DataAdr === 32'd1588); // sw x31, 52(x1)

  // Punto de comprobacion: 2 ciclos despues de la marca, cuando ya se
  // escribieron en el banco de registros las instrucciones de la etapa.
  reg [3:0] marca1, marca2;
  always @(posedge clk) begin
    marca1 <= {fin_D, fin_C, fin_B, fin_A};
    marca2 <= marca1;
  end
  wire check_A = marca2[0];
  wire check_B = marca2[1];
  wire check_C = marca2[2];
  wire check_D = marca2[3];

  // Termina al llegar al ultimo sw; espera 3 ciclos para ver el estado final
  always @(negedge clk) begin
    if (fin_D && !fin) begin
      fin = 1;                    // congela el contador de ciclos
      repeat (3) @(negedge clk);
      $stop;
    end
  end
endmodule