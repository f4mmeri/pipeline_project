module datapath(
    input clk,
    input reset,

    // Control etapa Decode - Via 0
    input        RegWrite0D,
    input        MemWrite0D,
    input        Jump0D,
    input        Jalr0D,
    input        Branch0D,
    input        ALUSrc0D,
    input  [1:0] ResultSrc0D,
    input  [1:0] ImmSrc0D,
    input  [2:0] ALUControl0D,

    // Control etapa Decode - Via 1
    input        RegWrite1D,
    input        MemWrite1D,
    input        Jump1D,
    input        Jalr1D,
    input        Branch1D,
    input        ALUSrc1D,
    input  [1:0] ResultSrc1D,
    input  [1:0] ImmSrc1D,
    input  [2:0] ALUControl1D,

    // Issue Unit: autorizaciones independientes por slot
    input        Issue0, Issue1, HoldYounger,
    output reg   Valid0D, Valid1D,
    output       Load0E, Load1E,

    // Senales desde la Hazard Unit
    input        StallF,
    input        StallD,
    input        FlushD,
    input        FlushE,

    // Hacia los controladores (Decode)
    output [6:0] op0,
    output [2:0] funct3_0,
    output       funct7b5_0,

    output [6:0] op1,
    output [2:0] funct3_1,
    output       funct7b5_1,

    // Hacia la Hazard Unit
    output [4:0] Rs1_0D, Rs2_0D,
    output [4:0] Rs1_1D, Rs2_1D,
    output reg [4:0] Rs1_0E, Rs2_0E,
    output reg [4:0] Rs1_1E, Rs2_1E,
    output reg [4:0] Rd0E, Rd1E,
    output reg [4:0] Rd0M, Rd1M,
    output reg [4:0] Rd0W, Rd1W,
    output       PCSrcE,
    output       PCSrcD,           // salto resuelto en Decode (optimizacion EF)
    output [31:0] PCTargetD,       // destino calculado en Decode
    output reg   RegWrite0M, RegWrite1M,
    output reg   RegWrite0W, RegWrite1W,
    output       ResultSrc0E0,

    // Memoria de Instrucciones (Dual Fetch)
    output [31:0] PCF,
    input  [31:0] Instr0F,
    input  [31:0] Instr1F,

    // Memoria de Datos
    output [31:0] ALUResultM,
    output [31:0] WriteDataM,
    output        MemWriteM,
    input  [31:0] ReadDataM,

    // Salidas de diagnostico / evidencia para simulacion
    output reg [31:0] Instr0D, Instr1D,
    output     [31:0] ALUResult0E, ALUResult1E,
    output     [31:0] Result0W, Result1W
);

    // 1 = Dual-Issue optimizado (C). 0 = Dual-Issue base (comportamiento E2).
    localparam EARLY_BRANCH = 1;

    // =========================================================================
    // DECLARACIONES (todas antes de su uso)
    // =========================================================================
    // Fetch
    reg  [31:0] PCFReg;
    reg  [31:0] PC0D, PC1D;
    wire [31:0] PCTargetE;
    assign PCF = PCFReg;

    // Decode
    wire [31:0] RD1_0D, RD2_0D;
    wire [31:0] RD1_1D, RD2_1D;
    wire [31:0] ImmExt0D, ImmExt1D;

    // ID/EX - Via 0
    reg        RegWrite0E, MemWrite0E, Jump0E, Jalr0E, Branch0E, ALUSrc0E;
    reg [1:0]  ResultSrc0E;
    reg [2:0]  ALUControl0E;
    reg [31:0] RD1_0E, RD2_0E, PC0E, ImmExt0E;

    // ID/EX - Via 1
    reg        RegWrite1E, MemWrite1E, Jump1E, Jalr1E, Branch1E, ALUSrc1E;
    reg [1:0]  ResultSrc1E;
    reg [2:0]  ALUControl1E;
    reg [31:0] RD1_1E, RD2_1E, PC1E, ImmExt1E;

    // EX/MEM
    reg [1:0]  ResultSrc0M, ResultSrc1M;
    reg [31:0] ALUResult0M, ALUResult1M;
    reg [31:0] WriteData0M, WriteData1M;
    reg [31:0] PC0M, PC1M;
    reg        MemWrite0M, MemWrite1M;

    // MEM/WB
    reg [1:0]  ResultSrc0W, ResultSrc1W;
    reg [31:0] ALUResult0W, ALUResult1W;
    reg [31:0] ReadData0W, ReadData1W;
    reg [31:0] PC0W, PC1W;

    // =========================================================================
    // RESOLUCION ANTICIPADA DE SALTOS EN DECODE (EF)
    // =========================================================================
    // Busy_v: rs1 de la via v tiene productor en EX o MEM. No existe forwarding
    // hacia Decode, asi que el jalr no puede resolverse aqui y cae a Execute.
    // (Un productor en WB lo cubre el bypass interno del banco de registros.)
    wire Busy0D = Jalr0D && Valid0D && (
        (RegWrite0E && Rd0E != 5'd0 && Rd0E == Rs1_0D) ||
        (RegWrite1E && Rd1E != 5'd0 && Rd1E == Rs1_0D) ||
        (RegWrite0M && Rd0M != 5'd0 && Rd0M == Rs1_0D) ||
        (RegWrite1M && Rd1M != 5'd0 && Rd1M == Rs1_0D));

    wire Busy1D = Jalr1D && Valid1D && (
        (RegWrite0E && Rd0E != 5'd0 && Rd0E == Rs1_1D) ||
        (RegWrite1E && Rd1E != 5'd0 && Rd1E == Rs1_1D) ||
        (RegWrite0M && Rd0M != 5'd0 && Rd0M == Rs1_1D) ||
        (RegWrite1M && Rd1M != 5'd0 && Rd1M == Rs1_1D));

    // Early_v: salto que se resuelve en Decode.
    //   jal  -> siempre (destino = PC + imm, sin registros)
    //   jalr -> solo si rs1 esta disponible
    // Depende de Issue: un salto que no sale no debe redirigir el PC.
    wire Early0 = (EARLY_BRANCH != 0) && Issue0 &&
                  ((Jump0D && !Jalr0D) || (Jalr0D && !Busy0D));
    wire Early1 = (EARLY_BRANCH != 0) && Issue1 &&
                  ((Jump1D && !Jalr1D) || (Jalr1D && !Busy1D));

    // Destinos (la suma pasa por un wire para poder seleccionar bits)
    wire [31:0] JalrSum0D = RD1_0D + ImmExt0D;
    wire [31:0] JalrSum1D = RD1_1D + ImmExt1D;
    wire [31:0] Target0D  = Jalr0D ? {JalrSum0D[31:1], 1'b0} : (PC0D + ImmExt0D);
    wire [31:0] Target1D  = Jalr1D ? {JalrSum1D[31:1], 1'b0} : (PC1D + ImmExt1D);

    // Un salto tomado en EX tiene prioridad (el salto en Decode seria del
    // camino incorrecto).
    assign PCSrcD    = !PCSrcE && (Early0 || Early1);
    assign PCTargetD = Early0 ? Target0D : Target1D;

    // ================================================================
    // FETCH / IF-ID: PCF apunta a la PROXIMA instruccion no almacenada.
    // 2 emitidas: reemplazar par completo y PCF += 8.
    // 1 emitida: desplazar joven -> vieja; traer una y PCF += 4.
    // 0 emitidas: mantener PCF e IF/ID sin cambios.
    // Redirect desde EX (FlushD) > redirect desde Decode (PCSrcD) > retencion.
    // ================================================================
    always @(posedge clk) begin
      if (reset) begin
        PCFReg  <= 32'b0;
        Instr0D <= 32'h00000013;
        Instr1D <= 32'h00000013;
        PC0D    <= 32'b0;
        PC1D    <= 32'b0;
        Valid0D <= 1'b0;
        Valid1D <= 1'b0;
      end else if (FlushD) begin
        // Redirect desde Execute: el par en IF/ID es del camino incorrecto.
        PCFReg  <= PCTargetE;
        Instr0D <= 32'h00000013;
        Instr1D <= 32'h00000013;
        PC0D    <= 32'b0;
        PC1D    <= 32'b0;
        Valid0D <= 1'b0;
        Valid1D <= 1'b0;
      end else if (PCSrcD) begin
        // Redirect desde Decode: se vacia IF/ID (ambos slots invalidos) y el
        // PC se carga con el destino. El par secuencial que iba a entrar se
        // descarta; el destino llega a Decode un ciclo despues.
        PCFReg  <= PCTargetD;
        Instr0D <= 32'h00000013;
        Instr1D <= 32'h00000013;
        PC0D    <= 32'b0;
        PC1D    <= 32'b0;
        Valid0D <= 1'b0;
        Valid1D <= 1'b0;
      end else if (!Valid0D) begin
        // Llenado inicial o despues de redirect.
        Instr0D <= Instr0F;
        Instr1D <= Instr1F;
        PC0D    <= PCFReg;
        PC1D    <= PCFReg + 32'd4;
        PCFReg  <= PCFReg + 32'd8;
        Valid0D <= 1'b1;
        Valid1D <= 1'b1;
      end else if (Issue0 && Issue1) begin
        Instr0D <= Instr0F;
        Instr1D <= Instr1F;
        PC0D    <= PCFReg;
        PC1D    <= PCFReg + 32'd4;
        PCFReg  <= PCFReg + 32'd8;
        Valid0D <= 1'b1;
        Valid1D <= 1'b1;
      end else if (HoldYounger) begin
        // Issue parcial: joven pasa a slot antiguo sin duplicacion.
        Instr0D <= Instr1D;
        PC0D    <= PC1D;
        Instr1D <= Instr0F;
        PC1D    <= PCFReg;
        PCFReg  <= PCFReg + 32'd4;
        Valid0D <= Valid1D;
        Valid1D <= 1'b1;
      end else if (Issue0) begin
        // Caso excepcional: solo habia una instruccion valida.
        Instr0D <= Instr0F;
        Instr1D <= Instr1F;
        PC0D    <= PCFReg;
        PC1D    <= PCFReg + 32'd4;
        PCFReg  <= PCFReg + 32'd8;
        Valid0D <= 1'b1;
        Valid1D <= 1'b1;
      end
      // Ninguna emitida: IF/ID y PC quedan congelados.
    end

    // =========================================================================
    // 2. DECODE (DUAL DECODE)
    // =========================================================================
    // Via 0
    assign op0        = Instr0D[6:0];
    assign funct3_0   = Instr0D[14:12];
    assign funct7b5_0 = Instr0D[30];
    assign Rs1_0D     = Instr0D[19:15];
    assign Rs2_0D     = Instr0D[24:20];
    wire [4:0] Rd0D   = Instr0D[11:7];

    // Via 1
    assign op1        = Instr1D[6:0];
    assign funct3_1   = Instr1D[14:12];
    assign funct7b5_1 = Instr1D[30];
    assign Rs1_1D     = Instr1D[19:15];
    assign Rs2_1D     = Instr1D[24:20];
    wire [4:0] Rd1D   = Instr1D[11:7];

    // Banco de Registros 4R / 2W
    regfile rf(
        .clk(clk),
        .reset(reset),
        .we3_0(RegWrite0W), .a3_0(Rd0W), .wd3_0(Result0W),
        .we3_1(RegWrite1W), .a3_1(Rd1W), .wd3_1(Result1W),
        .a1_0(Rs1_0D), .a2_0(Rs2_0D), .rd1_0(RD1_0D), .rd2_0(RD2_0D),
        .a1_1(Rs1_1D), .a2_1(Rs2_1D), .rd1_1(RD1_1D), .rd2_1(RD2_1D)
    );

    // Extension de inmediatos para ambas vias
    extend ext0(.instr(Instr0D[31:7]), .immsrc(ImmSrc0D), .immext(ImmExt0D));
    extend ext1(.instr(Instr1D[31:7]), .immsrc(ImmSrc1D), .immext(ImmExt1D));

    // =========================================================================
    // REGISTRO ID/EX (DUAL ID/EX)
    // =========================================================================
    always @(posedge clk) begin
        if (reset || FlushE) begin
            RegWrite0E   <= 1'b0; MemWrite0E <= 1'b0; Jump0E <= 1'b0; Jalr0E <= 1'b0; Branch0E <= 1'b0;
            ALUSrc0E     <= 1'b0; ResultSrc0E <= 2'b00; ALUControl0E <= 3'b000;
            RD1_0E       <= 32'b0; RD2_0E <= 32'b0; PC0E <= 32'b0; ImmExt0E <= 32'b0;
            Rs1_0E       <= 5'b0; Rs2_0E <= 5'b0; Rd0E <= 5'b0;

            RegWrite1E   <= 1'b0; MemWrite1E <= 1'b0; Jump1E <= 1'b0; Jalr1E <= 1'b0; Branch1E <= 1'b0;
            ALUSrc1E     <= 1'b0; ResultSrc1E <= 2'b00; ALUControl1E <= 3'b000;
            RD1_1E       <= 32'b0; RD2_1E <= 32'b0; PC1E <= 32'b0; ImmExt1E <= 32'b0;
            Rs1_1E       <= 5'b0; Rs2_1E <= 5'b0; Rd1E <= 5'b0;
        end
        else begin
            // Via 0. Jump/Jalr se apagan si el salto ya se resolvio en Decode,
            // para que Execute no repita la redireccion. Un jalr que cayo al
            // fallback (Early0 = 0) llega a EX con Jump0E = Jalr0E = 1.
            RegWrite0E   <= Issue0 && RegWrite0D; MemWrite0E <= Issue0 && MemWrite0D;
            Jump0E       <= Issue0 && Jump0D && !Early0;
            Jalr0E       <= Issue0 && Jalr0D && !Early0;
            Branch0E     <= Issue0 && Branch0D;
            ALUSrc0E     <= ALUSrc0D;   ResultSrc0E <= ResultSrc0D;
            ALUControl0E <= ALUControl0D;
            RD1_0E       <= RD1_0D;     RD2_0E     <= RD2_0D;
            PC0E         <= PC0D;       ImmExt0E   <= ImmExt0D;
            Rs1_0E       <= Rs1_0D;     Rs2_0E     <= Rs2_0D;     Rd0E <= Rd0D;

            // Via 1
            RegWrite1E   <= Issue1 && RegWrite1D; MemWrite1E <= Issue1 && MemWrite1D;
            Jump1E       <= Issue1 && Jump1D && !Early1;
            Jalr1E       <= Issue1 && Jalr1D && !Early1;
            Branch1E     <= Issue1 && Branch1D;
            ALUSrc1E     <= ALUSrc1D;   ResultSrc1E <= ResultSrc1D;
            ALUControl1E <= ALUControl1D;
            RD1_1E       <= RD1_1D;     RD2_1E     <= RD2_1D;
            PC1E         <= PC1D;       ImmExt1E   <= ImmExt1D;
            Rs1_1E       <= Rs1_1D;     Rs2_1E     <= Rs2_1D;     Rd1E <= Rd1D;
        end
    end

    assign ResultSrc0E0 = RegWrite0E && ResultSrc0E[0];
    assign Load0E = RegWrite0E && ResultSrc0E[0];
    assign Load1E = RegWrite1E && ResultSrc1E[0];

    // =========================================================================
    // 3. EXECUTE (DOS ALUs EN PARALELO)
    // =========================================================================
    // Forwarding desde M (ALU, excepto load) y W (incluye load).
    // El dato de via 1 es mas joven y tiene prioridad en el mismo ciclo.
    wire [31:0] FwdA0, FwdB0, FwdA1, FwdB1;
    wire Hit0M0 = RegWrite0M && !ResultSrc0M[0] && (Rd0M != 5'd0);
    wire Hit1M1 = RegWrite1M && !ResultSrc1M[0] && (Rd1M != 5'd0);
    wire Hit0W0 = RegWrite0W && (Rd0W != 5'd0);
    wire Hit1W1 = RegWrite1W && (Rd1W != 5'd0);

    // Los mux incluyen PC+4 para JAL/JALR, no solo el resultado ALU.
    wire [31:0] MVal0 = ResultSrc0M[1] ? (PC0M + 32'd4) : ALUResult0M;
    wire [31:0] MVal1 = ResultSrc1M[1] ? (PC1M + 32'd4) : ALUResult1M;

    assign FwdA0 = (Rs1_0E == 5'd0) ? 32'b0 :
                   (Hit1M1 && (Rd1M == Rs1_0E)) ? MVal1 :
                   (Hit0M0 && (Rd0M == Rs1_0E)) ? MVal0 :
                   (Hit1W1 && (Rd1W == Rs1_0E)) ? Result1W :
                   (Hit0W0 && (Rd0W == Rs1_0E)) ? Result0W : RD1_0E;

    assign FwdB0 = (Rs2_0E == 5'd0) ? 32'b0 :
                   (Hit1M1 && (Rd1M == Rs2_0E)) ? MVal1 :
                   (Hit0M0 && (Rd0M == Rs2_0E)) ? MVal0 :
                   (Hit1W1 && (Rd1W == Rs2_0E)) ? Result1W :
                   (Hit0W0 && (Rd0W == Rs2_0E)) ? Result0W : RD2_0E;

    assign FwdA1 = (Rs1_1E == 5'd0) ? 32'b0 :
                   (Hit1M1 && (Rd1M == Rs1_1E)) ? MVal1 :
                   (Hit0M0 && (Rd0M == Rs1_1E)) ? MVal0 :
                   (Hit1W1 && (Rd1W == Rs1_1E)) ? Result1W :
                   (Hit0W0 && (Rd0W == Rs1_1E)) ? Result0W : RD1_1E;

    assign FwdB1 = (Rs2_1E == 5'd0) ? 32'b0 :
                   (Hit1M1 && (Rd1M == Rs2_1E)) ? MVal1 :
                   (Hit0M0 && (Rd0M == Rs2_1E)) ? MVal0 :
                   (Hit1W1 && (Rd1W == Rs2_1E)) ? Result1W :
                   (Hit0W0 && (Rd0W == Rs2_1E)) ? Result0W : RD2_1E;

    wire [31:0] SrcA0E = FwdA0;
    wire [31:0] SrcB0E = ALUSrc0E ? ImmExt0E : FwdB0;
    wire [31:0] SrcA1E = FwdA1;
    wire [31:0] SrcB1E = ALUSrc1E ? ImmExt1E : FwdB1;
    wire Zero0E, Zero1E;

    alu alu0(.a(SrcA0E), .b(SrcB0E), .alucontrol(ALUControl0E),
             .result(ALUResult0E), .zero(Zero0E));
    alu alu1(.a(SrcA1E), .b(SrcB1E), .alucontrol(ALUControl1E),
             .result(ALUResult1E), .zero(Zero1E));

    wire Take0 = (Branch0E && Zero0E) || Jump0E;
    wire Take1 = (Branch1E && Zero1E) || Jump1E;
    assign PCSrcE = Take0 || Take1;
    wire [31:0] Target0E = Jalr0E ? {ALUResult0E[31:1], 1'b0} : (PC0E + ImmExt0E);
    wire [31:0] Target1E = Jalr1E ? {ALUResult1E[31:1], 1'b0} : (PC1E + ImmExt1E);
    assign PCTargetE = Take0 ? Target0E : Target1E;

    // =========================================================================
    // REGISTRO EX/MEM (DUAL EX/MEM)
    // =========================================================================
    always @(posedge clk) begin
        if (reset) begin
            RegWrite0M  <= 1'b0; MemWrite0M <= 1'b0; ResultSrc0M <= 2'b00;
            ALUResult0M <= 32'b0; WriteData0M <= 32'b0; Rd0M <= 5'b0; PC0M <= 32'b0;

            RegWrite1M  <= 1'b0; MemWrite1M <= 1'b0; WriteData1M <= 32'b0; ResultSrc1M <= 2'b00;
            ALUResult1M <= 32'b0; Rd1M <= 5'b0; PC1M <= 32'b0;
        end
        else begin
            RegWrite0M  <= RegWrite0E; MemWrite0M <= MemWrite0E; ResultSrc0M <= ResultSrc0E;
            ALUResult0M <= ALUResult0E; WriteData0M <= FwdB0; Rd0M <= Rd0E; PC0M <= PC0E;

            RegWrite1M  <= RegWrite1E; MemWrite1M <= MemWrite1E; WriteData1M <= FwdB1; ResultSrc1M <= ResultSrc1E;
            ALUResult1M <= ALUResult1E; Rd1M <= Rd1E; PC1M <= PC1E;
        end
    end

    // =========================================================================
    // 4. MEMORY (ACCESO A MEMORIA DE DATOS)
    // =========================================================================
    // La Issue Unit garantiza a lo sumo un acceso a memoria por ciclo.
    wire MemOp1M = MemWrite1M || (RegWrite1M && ResultSrc1M[0]);
    assign ALUResultM = MemOp1M ? ALUResult1M : ALUResult0M;
    assign WriteDataM = MemOp1M ? WriteData1M : WriteData0M;
    assign MemWriteM  = MemOp1M ? MemWrite1M : MemWrite0M;

    // =========================================================================
    // REGISTRO MEM/WB (DUAL MEM/WB)
    // =========================================================================
    always @(posedge clk) begin
        if (reset) begin
            RegWrite0W  <= 1'b0; ResultSrc0W <= 2'b00;
            ALUResult0W <= 32'b0; ReadData0W <= 32'b0; Rd0W <= 5'b0; PC0W <= 32'b0;

            RegWrite1W  <= 1'b0; ResultSrc1W <= 2'b00;
            ALUResult1W <= 32'b0; ReadData1W <= 32'b0; Rd1W <= 5'b0; PC1W <= 32'b0;
        end
        else begin
            RegWrite0W  <= RegWrite0M; ResultSrc0W <= ResultSrc0M;
            ALUResult0W <= ALUResult0M; ReadData0W <= MemOp1M ? 32'b0 : ReadDataM; Rd0W <= Rd0M; PC0W <= PC0M;

            RegWrite1W  <= RegWrite1M; ResultSrc1W <= ResultSrc1M;
            ALUResult1W <= ALUResult1M; ReadData1W <= MemOp1M ? ReadDataM : 32'b0; Rd1W <= Rd1M; PC1W <= PC1M;
        end
    end

    // =========================================================================
    // 5. WRITEBACK (DUAL, 2 ESCRITURAS SIMULTANEAS)
    // =========================================================================
    mux3 #(32) resmux0(.d0(ALUResult0W), .d1(ReadData0W), .d2(PC0W + 32'd4),
                       .s(ResultSrc0W), .y(Result0W));
    mux3 #(32) resmux1(.d0(ALUResult1W), .d1(ReadData1W), .d2(PC1W + 32'd4),
                       .s(ResultSrc1W), .y(Result1W));

    // =========================================================================
    // INSTRUMENTACION DE RETIRADAS (solo medicion, no afecta al hardware)
    // =========================================================================
    reg Valid0E, Valid1E, Valid0M, Valid1M, Valid0W, Valid1W;
    always @(posedge clk) begin
        if (reset || FlushE) begin Valid0E <= 1'b0; Valid1E <= 1'b0; end
        else begin Valid0E <= Issue0; Valid1E <= Issue1; end
        if (reset) begin
            Valid0M <= 1'b0; Valid1M <= 1'b0; Valid0W <= 1'b0; Valid1W <= 1'b0;
        end else begin
            Valid0M <= Valid0E; Valid1M <= Valid1E;
            Valid0W <= Valid0M; Valid1W <= Valid1M;
        end
    end

endmodule