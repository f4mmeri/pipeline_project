`timescale 1ns/1ps
module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;

  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  // PC de la etiqueta fin del programa que se esta corriendo (CAMBIAR segun programa):
  //   programa del profe: 356     programa propio: 120 (0x78)
  localparam FIN_PC = 32'd68;

  initial begin
    reset = 1;
    # 22;
    reset = 0;
  end

  always begin
    clk = 1;
    # 5;
    clk = 0;
    # 5;
  end

  // ---- senales de retiro (propagadas hasta Writeback) ----
  wire        v0  = dut.rvpipeline.dp.Valid0W;
  wire        v1  = dut.rvpipeline.dp.Valid1W;
  wire [31:0] pc0 = dut.rvpipeline.dp.PC0W;
  wire [31:0] pc1 = dut.rvpipeline.dp.PC1W;

  // ---- marca del ultimo sw (aparece en MEM) y su paso por WB ----
  wire sw_final = (MemWrite === 1'b1) && (DataAdr === 32'd1588);
  reg  sw_final_W = 0;
  reg  fin = 0;

  // ---- contadores (visibles en el waveform) ----
  integer ciclos = 0, retiradas = 0;
  integer saltos_ID = 0, saltos_EX = 0, stalls = 0;

  always @(posedge clk) begin
    sw_final_W <= sw_final;
    if (!reset && !fin) begin
      ciclos    <= ciclos + 1;
      retiradas <= retiradas + ((v0 && pc0 < FIN_PC) ? 1 : 0)
                             + ((v1 && pc1 < FIN_PC) ? 1 : 0);
      if (dut.rvpipeline.dp.PCSrcD) saltos_ID <= saltos_ID + 1;  // 0 en A y B
      if (dut.rvpipeline.dp.PCSrcE) saltos_EX <= saltos_EX + 1;
      if (dut.rvpipeline.dp.StallD) stalls    <= stalls + 1;    // load-use
      if (sw_final_W) fin <= 1;        // este ciclo (sw en WB) si se cuenta
    end
  end

  // ---- marcas de fin de etapa del programa del profe (para el waveform) ----
  wire fin_A = (MemWrite === 1'b1) && (DataAdr === 32'd1544);
  wire fin_B = (MemWrite === 1'b1) && (DataAdr === 32'd1556);
  wire fin_C = (MemWrite === 1'b1) && (DataAdr === 32'd1568);
  wire fin_D = sw_final;
  reg [3:0] marca1, marca2;
  always @(posedge clk) begin
    marca1 <= {fin_D, fin_C, fin_B, fin_A};
    marca2 <= marca1;
  end
  wire check_A = marca2[0], check_B = marca2[1],
       check_C = marca2[2], check_D = marca2[3];

  // ---- resumen final y parada ----
  reg listo = 0;
  always @(negedge clk) begin
    if (fin && !listo) begin
      listo = 1;
      $display("=================================");
      $display("=== RESULTADOS EXPERIMENTALES ===");
      $display("=================================");
      $display("Ciclos:                  %0d", ciclos);
      $display("Instrucciones retiradas: %0d", retiradas);
      $display("IPC:                     %f", (ciclos > 0) ? (retiradas * 1.0 / ciclos) : 0.0);
      $display("CPI:                     %f", (retiradas > 0) ? (ciclos * 1.0 / retiradas) : 0.0);
      $display("Saltos resueltos en ID:  %0d", saltos_ID);
      $display("Saltos resueltos en EX:  %0d", saltos_EX);
      $display("Ciclos de stall (load-use): %0d", stalls);
      $display("=================================");
      repeat (2) @(negedge clk);
      $stop;
    end
  end
endmodule
