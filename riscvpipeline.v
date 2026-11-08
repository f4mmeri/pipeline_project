module riscvpipeline(
    input         clk,
    input         reset,

    // Instruction memory (Dual Fetch)
    output [31:0] PC,
    input  [31:0] Instr0,
    input  [31:0] Instr1,

    // Data memory
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData
);

    // =========================================================================
    // SENALES DATAPATH <-> CONTROLADORES
    // =========================================================================
    // Via 0
    wire [6:0] op0;
    wire [2:0] funct3_0;
    wire       funct7b5_0;
    wire       RegWrite0D, MemWrite0D, Jump0D, Branch0D, ALUSrc0D;
    wire [1:0] ResultSrc0D, ImmSrc0D;
    wire [2:0] ALUControl0D;

    // Via 1
    wire [6:0] op1;
    wire [2:0] funct3_1;
    wire       funct7b5_1;
    wire       RegWrite1D, MemWrite1D, Jump1D, Branch1D, ALUSrc1D;
    wire [1:0] ResultSrc1D, ImmSrc1D;
    wire [2:0] ALUControl1D;

    // =========================================================================
    // SENALES DATAPATH <-> HAZARD UNIT & ISSUE UNIT
    // =========================================================================
    wire [4:0] Rs1_0D, Rs2_0D, Rs1_1D, Rs2_1D;
    wire [4:0] Rs1_0E, Rs2_0E, Rs1_1E, Rs2_1E;
    wire [4:0] Rd0E, Rd1E, Rd0M, Rd1M, Rd0W, Rd1W;
    wire       PCSrcE;
    wire       RegWrite0M, RegWrite1M, RegWrite0W, RegWrite1W;
    wire       ResultSrc0E0;

    wire       StallF, StallD;
    wire       FlushD, FlushE;

    // =========================================================================
    // DUAL DECODE: DOS CONTROLADORES EN PARALELO
    // =========================================================================
    // Controlador Via 0
    controller c0(
        .op(op0),
        .funct3(funct3_0),
        .funct7b5(funct7b5_0),
        .ResultSrc(ResultSrc0D),
        .MemWrite(MemWrite0D),
        .ALUSrc(ALUSrc0D),
        .RegWrite(RegWrite0D),
        .Jump(Jump0D),
        .Branch(Branch0D),
        .ImmSrc(ImmSrc0D),
        .ALUControl(ALUControl0D)
    );

    // Controlador Via 1
    controller c1(
        .op(op1),
        .funct3(funct3_1),
        .funct7b5(funct7b5_1),
        .ResultSrc(ResultSrc1D),
        .MemWrite(MemWrite1D),
        .ALUSrc(ALUSrc1D),
        .RegWrite(RegWrite1D),
        .Jump(Jump1D),
        .Branch(Branch1D),
        .ImmSrc(ImmSrc1D),
        .ALUControl(ALUControl1D)
    );

    // =========================================================================
    // ISSUE UNIT + HAZARD UNIT
    // =========================================================================
    wire [31:0] Instr0D, Instr1D;
    wire Valid0D, Valid1D;
    wire Issue0, Issue1, HoldYounger;
    wire StallOld, StallYoung;
    wire PairRAW, PairStructural, PairWAW, PairControl;
    wire Load0E, Load1E;

    issue_unit iu(
        .Instr0D(Instr0D),
        .Instr1D(Instr1D),
        .Valid0D(Valid0D),
        .Valid1D(Valid1D),
        .StallOld(StallOld),
        .StallYoung(StallYoung),
        .Issue0(Issue0),
        .Issue1(Issue1),
        .HoldYounger(HoldYounger),
        .PairRAW(PairRAW),
        .PairStructural(PairStructural),
        .PairWAW(PairWAW),
        .PairControl(PairControl)
    );

    hazard hz(
        .Instr0D(Instr0D),
        .Instr1D(Instr1D),
        .Valid0D(Valid0D),
        .Valid1D(Valid1D),
        .Rd0E(Rd0E),
        .Rd1E(Rd1E),
        .Load0E(Load0E),
        .Load1E(Load1E),
        .PCSrcE(PCSrcE),
        .StallOld(StallOld),
        .StallYoung(StallYoung),
        .FlushD(FlushD),
        .FlushE(FlushE)
    );

    assign StallF = StallOld;
    assign StallD = StallOld;

    // =========================================================================
    // DATAPATH DUAL-ISSUE COMPLETO
    // =========================================================================
    datapath dp(
        .clk(clk),
        .reset(reset),

        // Control Via 0
        .RegWrite0D(RegWrite0D),
        .MemWrite0D(MemWrite0D),
        .Jump0D(Jump0D),
        .Branch0D(Branch0D),
        .ALUSrc0D(ALUSrc0D),
        .ResultSrc0D(ResultSrc0D),
        .ImmSrc0D(ImmSrc0D),
        .ALUControl0D(ALUControl0D),

        // Control Via 1
        .RegWrite1D(RegWrite1D),
        .MemWrite1D(MemWrite1D),
        .Jump1D(Jump1D),
        .Branch1D(Branch1D),
        .ALUSrc1D(ALUSrc1D),
        .ResultSrc1D(ResultSrc1D),
        .ImmSrc1D(ImmSrc1D),
        .ALUControl1D(ALUControl1D),

        // Decisiones de emision (ambas vias, PC, IF/ID e ID/EX)
        .Issue0(Issue0),
        .Issue1(Issue1),
        .HoldYounger(HoldYounger),
        .Valid0D(Valid0D),
        .Valid1D(Valid1D),
        .Load0E(Load0E),
        .Load1E(Load1E),

        // Hazards
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE),

        // Hacia controladores
        .op0(op0),
        .funct3_0(funct3_0),
        .funct7b5_0(funct7b5_0),
        .op1(op1),
        .funct3_1(funct3_1),
        .funct7b5_1(funct7b5_1),

        // Hacia hazard unit
        .Rs1_0D(Rs1_0D),
        .Rs2_0D(Rs2_0D),
        .Rs1_1D(Rs1_1D),
        .Rs2_1D(Rs2_1D),
        .Rs1_0E(Rs1_0E),
        .Rs2_0E(Rs2_0E),
        .Rs1_1E(Rs1_1E),
        .Rs2_1E(Rs2_1E),
        .Rd0E(Rd0E),
        .Rd1E(Rd1E),
        .Rd0M(Rd0M),
        .Rd1M(Rd1M),
        .Rd0W(Rd0W),
        .Rd1W(Rd1W),
        .PCSrcE(PCSrcE),
        .RegWrite0M(RegWrite0M),
        .RegWrite1M(RegWrite1M),
        .RegWrite0W(RegWrite0W),
        .RegWrite1W(RegWrite1W),
        .ResultSrc0E0(ResultSrc0E0),

        // Memoria de instrucciones (Dual Fetch)
        .PCF(PC),
        .Instr0F(Instr0),
        .Instr1F(Instr1),

        // Memoria de datos
        .ALUResultM(DataAdr),
        .WriteDataM(WriteData),
        .MemWriteM(MemWrite),
        .ReadDataM(ReadData),

        // Senales de diagnostico / simulacion
        .Instr0D(Instr0D),
        .Instr1D(Instr1D),
        .ALUResult0E(),
        .ALUResult1E(),
        .Result0W(),
        .Result1W()
    );

endmodule
