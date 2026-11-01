module datapath(
    input clk,
    input reset,

    //control de la etapa Decode
    input        RegWriteD,
    input        MemWriteD,
    input        JumpD,
    input        JumpRegD,
    input        BranchD,
    input        ALUSrcD,
    input  [1:0] ResultSrcD,
    input  [1:0] ImmSrcD,
    input  [2:0] ALUControlD,

    //desde la hazard unit 
    input        StallF,
    input        StallD,
    input        FlushD,
    input        FlushE,
    input  [1:0] ForwardAE,
    input  [1:0] ForwardBE,

    // Hacia el controller
    output [6:0] op,
    output [2:0] funct3,
    output       funct7b5,

    // Hacia la Hazard Unit 
    output [4:0] Rs1D,
    output [4:0] Rs2D,
    output reg [4:0] Rs1E,
    output reg [4:0] Rs2E,
    output reg [4:0] RdE,
    output reg [4:0] RdM,
    output reg [4:0] RdW,
    output       PCSrcE,
    output reg   RegWriteM,
    output reg   RegWriteW,
    output       ResultSrcE0,

    //  Instruction Memory 
    output [31:0] PCF,
    input  [31:0] InstrF,

    //   Data Memory  
    output reg [31:0] ALUResultM,
    output reg [31:0] WriteDataM,
    output reg        MemWriteM,
    input      [31:0] ReadDataM
);

 
    // DECLARACION DE SENALES
 

    //   Fetch  
    wire [31:0] PCNextF;
    wire [31:0] PCPlus4F;
    wire [31:0] PCTargetE;
    wire        PCEnable;

    //   Registro IF/ID  
    reg [31:0] InstrD;
    reg [31:0] PCD;
    reg [31:0] PCPlus4D;

    //   Decode  
    wire [31:0] RD1D;
    wire [31:0] RD2D;
    wire [31:0] ImmExtD;
    wire [4:0]  RdD;

    //   Registro ID/EX  
    reg        RegWriteE;
    reg        MemWriteE;
    reg        JumpE;
    reg        JumpRegE;
    reg        BranchE;
    reg        ALUSrcE;
    reg [1:0]  ResultSrcE;
    reg [2:0]  ALUControlE;
    reg [31:0] RD1E;
    reg [31:0] RD2E;
    reg [31:0] PCE;
    reg [31:0] ImmExtE;
    reg [31:0] PCPlus4E;

    //   Execute  
    wire [31:0] SrcAE;
    wire [31:0] SrcBE;
    wire [31:0] WriteDataE;
    wire [31:0] ALUResultE;
    wire        ZeroE;

    //   Registro EX/MEM  
    reg [1:0]  ResultSrcM;
    reg [31:0] PCPlus4M;

    //   Registro MEM/WB  
    reg [1:0]  ResultSrcW;
    reg [31:0] ALUResultW;
    reg [31:0] ReadDataW;
    reg [31:0] PCPlus4W;

    //   Writeback  
    wire [31:0] ResultW;

 
    // FETCH
 

    // PCEnable = 0 si StallF = 1 (congelar el PC)
    assign PCEnable = !StallF;

    // PC + 4
    assign PCPlus4F = PCF + 32'd4;

    // Elegir siguiente PC: 0 = PC+4, 1 = destino del salto
    mux2 #(32) pcmux(
        .d0(PCPlus4F),
        .d1(PCTargetE),
        .s(PCSrcE),
        .y(PCNextF)
    );

    // Registro del PC (con enable)
    flopenr #(32) pcreg(
        .clk(clk),
        .reset(reset),
        .en(PCEnable),
        .d(PCNextF),
        .q(PCF)
    );


 
    // REGISTRO IF/ID
 

    always @(posedge clk) begin
        if (reset || FlushD) begin
            // Limpiar: se inserta un NOP (addi x0, x0, 0)
            InstrD   <= 32'h00000013;
            PCD      <= 32'b0;
            PCPlus4D <= 32'b0;
        end
        else if (!StallD) begin
            // Avanzar normalmente
            InstrD   <= InstrF;
            PCD      <= PCF;
            PCPlus4D <= PCPlus4F;
        end
        // Si StallD = 1, se mantiene el valor anterior
    end


 
    //DECODE
 

    // Separar los campos de la instruccion
    assign op       = InstrD[6:0];
    assign funct3   = InstrD[14:12];
    assign funct7b5 = InstrD[30];

    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD  = InstrD[11:7];

    // Banco de registros
    // Lee con Rs1D y Rs2D (etapa D)
    // Escribe con RdW, ResultW y RegWriteW (etapa W)
    // IMPORTANTE: el regfile debe escribir en negedge clk
    regfile rf(
        .clk(clk),
        .we3(RegWriteW),
        .a1(Rs1D),
        .a2(Rs2D),
        .a3(RdW),
        .wd3(ResultW),
        .rd1(RD1D),
        .rd2(RD2D)
    );

    // Extension del inmediato
    extend ext(
        .instr(InstrD[31:7]),
        .immsrc(ImmSrcD),
        .immext(ImmExtD)
    );


     // REGISTRO ID/EX
   

    always @(posedge clk) begin
        if (reset || FlushE) begin
            // Limpiar todo (osea burbuja)
            RegWriteE   <= 1'b0;
            MemWriteE   <= 1'b0;
            JumpE       <= 1'b0;
            JumpRegE    <= 1'b0;
            BranchE     <= 1'b0;
            ALUSrcE     <= 1'b0;
            ResultSrcE  <= 2'b00;
            ALUControlE <= 3'b000;

            RD1E        <= 32'b0;
            RD2E        <= 32'b0;
            PCE         <= 32'b0;
            ImmExtE     <= 32'b0;
            PCPlus4E    <= 32'b0;

            Rs1E        <= 5'b0;
            Rs2E        <= 5'b0;
            RdE         <= 5'b0;
        end
        else begin
            // Pasar las senales de control
            RegWriteE   <= RegWriteD;
            MemWriteE   <= MemWriteD;
            JumpE       <= JumpD;
            JumpRegE    <= JumpRegD;
            BranchE     <= BranchD;
            ALUSrcE     <= ALUSrcD;
            ResultSrcE  <= ResultSrcD;
            ALUControlE <= ALUControlD;

            // Pasar los datos
            RD1E        <= RD1D;
            RD2E        <= RD2D;
            PCE         <= PCD;
            ImmExtE     <= ImmExtD;
            PCPlus4E    <= PCPlus4D;

            // Pasar los numeros de registro
            Rs1E        <= Rs1D;
            Rs2E        <= Rs2D;
            RdE         <= RdD;
        end
    end

    // Bit 0 de ResultSrcE: indica que la instruccion es un lw
    assign ResultSrcE0 = ResultSrcE[0];


     //EXECUTE
 

    // Forwarding para el operando A
    // 00 = RD1E, 01 = ResultW, 10 = ALUResultM
    mux3 #(32) fwdA(
        .d0(RD1E),
        .d1(ResultW),
        .d2(ALUResultM),
        .s(ForwardAE),
        .y(SrcAE)
    );

    // Forwarding para el operando B
    // (tambien es el dato que se guarda en un sw)
    mux3 #(32) fwdB(
        .d0(RD2E),
        .d1(ResultW),
        .d2(ALUResultM),
        .s(ForwardBE),
        .y(WriteDataE)
    );

    // Elegir entre registro o inmediato para la ALU
    // 0 = WriteDataE, 1 = ImmExtE
    mux2 #(32) srcbmux(
        .d0(WriteDataE),
        .d1(ImmExtE),
        .s(ALUSrcE),
        .y(SrcBE)
    );

    // ALU
    alu alu_inst(
        .a(SrcAE),
        .b(SrcBE),
        .alucontrol(ALUControlE),
        .result(ALUResultE),
        .zero(ZeroE)
    );

    // Destino del salto
    // Para branch y jal la base es PCE; para jalr es SrcAE
    wire [31:0] PCTargetBaseE;
    assign PCTargetBaseE = JumpRegE ? SrcAE : PCE;
    assign PCTargetE = (PCTargetBaseE + ImmExtE) & ~32'b1;

    // Se toma el salto si es branch con Zero, o si es jump
    assign PCSrcE = (BranchE && ZeroE) || JumpE;


    //REGISTRO EX/MEM
 

    always @(posedge clk) begin
        if (reset) begin
            RegWriteM  <= 1'b0;
            MemWriteM  <= 1'b0;
            ResultSrcM <= 2'b00;

            ALUResultM <= 32'b0;
            WriteDataM <= 32'b0;
            PCPlus4M   <= 32'b0;

            RdM        <= 5'b0;
        end
        else begin
            RegWriteM  <= RegWriteE;
            MemWriteM  <= MemWriteE;
            ResultSrcM <= ResultSrcE;

            ALUResultM <= ALUResultE;
            WriteDataM <= WriteDataE;
            PCPlus4M   <= PCPlus4E;

            RdM        <= RdE;
        end
    end

 
    // MEMORY
 


    
    // REGISTRO MEM/WB
     

    always @(posedge clk) begin
        if (reset) begin
            RegWriteW  <= 1'b0;
            ResultSrcW <= 2'b00;

            ALUResultW <= 32'b0;
            ReadDataW  <= 32'b0;
            PCPlus4W   <= 32'b0;

            RdW        <= 5'b0;
        end
        else begin
            RegWriteW  <= RegWriteM;
            ResultSrcW <= ResultSrcM;

            ALUResultW <= ALUResultM;
            ReadDataW  <= ReadDataM;
            PCPlus4W   <= PCPlus4M;

            RdW        <= RdM;
        end
    end


 
    //WRITEBACK
  

    mux3 #(32) resmux(
        .d0(ALUResultW),
        .d1(ReadDataW),
        .d2(PCPlus4W),
        .s(ResultSrcW),
        .y(ResultW)
    );

endmodule
