module hazard(
    // Numeros de registro Via 0
    input  [4:0] Rs1_0D, Rs2_0D,
    input  [4:0] Rs1_0E, Rs2_0E,
    input  [4:0] Rd0E, Rd0M, Rd0W,

    // Numeros de registro Via 1
    input  [4:0] Rs1_1D, Rs2_1D,
    input  [4:0] Rs1_1E, Rs2_1E,
    input  [4:0] Rd1E, Rd1M, Rd1W,

    // Senales de control
    input        RegWrite0M, RegWrite1M,
    input        RegWrite0W, RegWrite1W,
    input        ResultSrc0E0,   // 1 = la instruccion en E es un lw
    input        PCSrcE,

    // Salidas hacia el datapath
    output       StallF,
    output       StallD,
    output       FlushD,
    output       FlushE
);

    wire lwStall;

    // STALL (load-use: si un lw en EX es requerido por cualquiera de las vias en Decode)
    assign lwStall = ResultSrc0E0 && (
        (Rs1_0D == Rd0E && Rs1_0D != 5'd0) ||
        (Rs2_0D == Rd0E && Rs2_0D != 5'd0) ||
        (Rs1_1D == Rd0E && Rs1_1D != 5'd0) ||
        (Rs2_1D == Rd0E && Rs2_1D != 5'd0)
    );

    assign StallF = lwStall;
    assign StallD = lwStall;

    // FLUSH
    assign FlushD = PCSrcE;
    assign FlushE = lwStall || PCSrcE;

endmodule
