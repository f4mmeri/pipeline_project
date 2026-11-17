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
  //   programa del profe: +FIN=356     programa propio: +FIN=120 (0x78)
  // Se elige al correr:  vvp -n sim.vvp +PROG=programa_profesor.mem +FIN=356 +VCD=prof.vcd
  reg [31:0]    FIN_PC;
  reg [8*40:1]  prog, vcd;
  integer k;
  initial begin
    if (!$value$plusargs("FIN=%d", FIN_PC)) FIN_PC = 32'd120;
    if (!$value$plusargs("VCD=%s", vcd))    vcd    = "salida.vcd";
    $dumpfile(vcd);
    $dumpvars(0, testbench);
    if ($value$plusargs("PROG=%s", prog)) begin
      #1;
      for (k = 0; k < 256; k = k + 1) dut.imem.RAM[k] = 32'h00000013;
      $readmemh(prog, dut.imem.RAM);
    end
  end

  // ---- registros y memoria visibles en GTKWave (Icarus no guarda arreglos) ----
  wire [31:0] x4  = dut.rvpipeline.dp.rf.rf[4];
  wire [31:0] x5  = dut.rvpipeline.dp.rf.rf[5];
  wire [31:0] x10 = dut.rvpipeline.dp.rf.rf[10];
  wire [31:0] x12 = dut.rvpipeline.dp.rf.rf[12];
  wire [31:0] x13 = dut.rvpipeline.dp.rf.rf[13];
  wire [31:0] x15 = dut.rvpipeline.dp.rf.rf[15];
  wire [31:0] x18 = dut.rvpipeline.dp.rf.rf[18];
  wire [31:0] x21 = dut.rvpipeline.dp.rf.rf[21];
  wire [31:0] x22 = dut.rvpipeline.dp.rf.rf[22];
  wire [31:0] x24 = dut.rvpipeline.dp.rf.rf[24];
  wire [31:0] x28 = dut.rvpipeline.dp.rf.rf[28];
  wire [31:0] x29 = dut.rvpipeline.dp.rf.rf[29];
  wire [31:0] x31 = dut.rvpipeline.dp.rf.rf[31];
  wire [31:0] M1536 = dut.dmem.RAM[384];
  wire [31:0] M1544 = dut.dmem.RAM[386];
  wire [31:0] M1556 = dut.dmem.RAM[389];
  wire [31:0] M1568 = dut.dmem.RAM[392];
  wire [31:0] M1576 = dut.dmem.RAM[394];
  wire [31:0] M1588 = dut.dmem.RAM[397];

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
      retiradas <= retiradas + ((v0 && pc0 != FIN_PC) ? 1 : 0)
                             + ((v1 && pc1 != FIN_PC) ? 1 : 0);
      if (dut.rvpipeline.dp.PCSrcD && dut.rvpipeline.dp.PCTargetD != FIN_PC) saltos_ID <= saltos_ID + 1;  // 0 en A y B
      if (dut.rvpipeline.dp.PCSrcE && dut.rvpipeline.dp.PCTargetE != FIN_PC) saltos_EX <= saltos_EX + 1;
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
