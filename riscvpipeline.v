module riscvpipeline(
    input         clk,
    input         reset,

    // Instruction memory
    output [31:0] PC,
    input  [31:0] Instr,

    // Data memory
    output        MemWrite,
    output [31:0] DataAdr,
    output [31:0] WriteData,
    input  [31:0] ReadData
);

    //   Datapath <-> controller  
    wire [6:0] op;
    wire [2:0] funct3;
    wire       funct7b5;

    wire       RegWriteD;
    wire       MemWriteD;
    wire       JumpD;
    wire       BranchD;
    wire       ALUSrcD;
    wire [1:0] ResultSrcD;
    wire [1:0] ImmSrcD;
    wire [2:0] ALUControlD;

    //   Datapath <-> hazard  
    wire [4:0] Rs1D, Rs2D;
    wire [4:0] Rs1E, Rs2E;
    wire [4:0] RdE, RdM, RdW;
    wire       PCSrcE;
    wire       RegWriteM, RegWriteW;
    wire       ResultSrcE0;

    wire       StallF, StallD;
    wire       FlushD, FlushE;
    wire [1:0] ForwardAE, ForwardBE;


    //   Controller (etapa Decode)  
    controller c(
        .op(op),
        .funct3(funct3),
        .funct7b5(funct7b5),
        .ResultSrc(ResultSrcD),
        .MemWrite(MemWriteD),
        .ALUSrc(ALUSrcD),
        .RegWrite(RegWriteD),
        .Jump(JumpD),
        .Branch(BranchD),
        .ImmSrc(ImmSrcD),
        .ALUControl(ALUControlD)
    );


    //   Hazard Unit  
    hazard hz(
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .RdM(RdM),
        .RdW(RdW),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .ResultSrcE0(ResultSrcE0),
        .PCSrcE(PCSrcE),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),
        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE)
    );


    // Datapath 
    datapath dp(
        .clk(clk),
        .reset(reset),

        .RegWriteD(RegWriteD),
        .MemWriteD(MemWriteD),
        .JumpD(JumpD),
        .BranchD(BranchD),
        .ALUSrcD(ALUSrcD),
        .ResultSrcD(ResultSrcD),
        .ImmSrcD(ImmSrcD),
        .ALUControlD(ALUControlD),

        .StallF(StallF),
        .StallD(StallD),
        .FlushD(FlushD),
        .FlushE(FlushE),
        .ForwardAE(ForwardAE),
        .ForwardBE(ForwardBE),

        .op(op),
        .funct3(funct3),
        .funct7b5(funct7b5),

        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RdE(RdE),
        .RdM(RdM),
        .RdW(RdW),
        .PCSrcE(PCSrcE),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .ResultSrcE0(ResultSrcE0),

        // Instruction memory
        .PCF(PC),
        .InstrF(Instr),

        // Data memory
        .ALUResultM(DataAdr),
        .WriteDataM(WriteData),
        .MemWriteM(MemWrite),
        .ReadDataM(ReadData)
    );

endmodule
