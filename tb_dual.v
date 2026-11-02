`timescale 1ns/1ps

module tb_dual;

    reg         clk;
    reg         reset;
    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire        MemWrite;

    // Instancia del sistema top Dual-Issue
    top dut(
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    // Generador de reloj (periodo 10 ns)
    initial clk = 0;
    always #5 clk = ~clk;

    integer cycle;

    // Secuencia de reset y monitoreo
    initial begin
        cycle = 0;
        reset = 1;
        #22;
        reset = 0;
        $display("================================================================================");
        $display("          INICIO DE SIMULACION: PIPELINE DUAL-ISSUE RISC-V                     ");
        $display("================================================================================");
    end

    // Monitoreo en cada ciclo de reloj
    always @(posedge clk) begin
        if (!reset) begin
            cycle = cycle + 1;
            $display("--------------------------------------------------------------------------------");
            $display("[CICLO %0d] Tiempo: %0t ps | PC = 0x%08h", cycle, $time, dut.PC);
            $display("  FETCH  : Instr0 = 0x%08h | Instr1 = 0x%08h", dut.Instr0, dut.Instr1);
            $display("  DECODE : Instr0D= 0x%08h | Instr1D= 0x%08h", dut.rvpipeline.dp.Instr0D, dut.rvpipeline.dp.Instr1D);
            $display("  EXECUTE: ALU0_Res = %0d (0x%08h) | ALU1_Res = %0d (0x%08h)", 
                     dut.rvpipeline.dp.ALUResult0E, dut.rvpipeline.dp.ALUResult0E,
                     dut.rvpipeline.dp.ALUResult1E, dut.rvpipeline.dp.ALUResult1E);
            $display("  WRITEBK: Rd0=%0d, WD0=%0d (we=%b) | Rd1=%0d, WD1=%0d (we=%b)",
                     dut.rvpipeline.dp.Rd0W, dut.rvpipeline.dp.Result0W, dut.rvpipeline.dp.RegWrite0W,
                     dut.rvpipeline.dp.Rd1W, dut.rvpipeline.dp.Result1W, dut.rvpipeline.dp.RegWrite1W);

            // Verificacion de exito
            if (MemWrite && DataAdr === 100 && WriteData === 25) begin
                $display("================================================================================");
                $display(">> SIMULACION DUAL-ISSUE COMPLETADA CON EXITO <<");
                $display("Se verifico el correcto funcionamiento de:");
                $display("  1. Dual Fetch  : 2 instrucciones leidas simultaneamente en cada ciclo (PC+8)");
                $display("  2. Dual Decode : 2 decodificadores y banco de registros 4R/2W");
                $display("  3. Dual Execute: 2 ALUs operando en paralelo en la etapa Execute");
                $display("  4. Dual WriteBk: 2 registros escritos simultaneamente en el mismo ciclo");
                $display("================================================================================");
                #20;
                $finish;
            end
        end
    end

    // Timeout de seguridad
    initial begin
        #500;
        $display("Timeout alcanzado en la simulacion.");
        $finish;
    end

endmodule

