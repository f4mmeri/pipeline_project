module top(input  clk, reset, 
           output [31:0] WriteData, DataAdr, 
           output MemWrite);
  
  wire [31:0] PC, ReadData; 
  wire [31:0] Instr0, Instr1;
  
  // Instanciar procesador RISC-V con Dual Fetch, Dual Decode y Datapath Dual-Issue
  riscvpipeline rvpipeline (
    .clk(clk), 
    .reset(reset), 
    .PC(PC), 
    .Instr0(Instr0),
    .Instr1(Instr1), 
    .MemWrite(MemWrite), 
    .DataAdr(DataAdr), 
    .WriteData(WriteData), 
    .ReadData(ReadData)
  ); 

  // Memoria de instrucciones con soporte Dual Fetch
  imem imem(
    .a(PC), 
    .rd0(Instr0),
    .rd1(Instr1)
  ); 

  // Memoria de datos (conectada a la Via 0)
  dmem dmem(
    .clk(clk), 
    .we(MemWrite), 
    .a(DataAdr), 
    .wd(WriteData), 
    .rd(ReadData)
  ); 
  
endmodule
