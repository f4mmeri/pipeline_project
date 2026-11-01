module hazard(
    // Numeros de registro
    input  [4:0] Rs1D,
    input  [4:0] Rs2D,
    input  [4:0] Rs1E,
    input  [4:0] Rs2E,
    input  [4:0] RdE,
    input  [4:0] RdM,
    input  [4:0] RdW,

    // Senales de control
    input        RegWriteM,
    input        RegWriteW,
    input        ResultSrcE0,   // 1 = la instruccion en E es un lw
    input        PCSrcE,

    // Salidas hacia el datapath
    output reg [1:0] ForwardAE,
    output reg [1:0] ForwardBE,
    output           StallF,
    output           StallD,
    output           FlushD,
    output           FlushE
);

    wire lwStall;

    // FORWARDING 
    always @(*) begin
        // Operando A
        if ((Rs1E == RdM) && RegWriteM && (Rs1E != 0))
            ForwardAE = 2'b10;
        else if ((Rs1E == RdW) && RegWriteW && (Rs1E != 0))
            ForwardAE = 2'b01;
        else
            ForwardAE = 2'b00;

        // Operando B
        if ((Rs2E == RdM) && RegWriteM && (Rs2E != 0))
            ForwardBE = 2'b10;
        else if ((Rs2E == RdW) && RegWriteW && (Rs2E != 0))
            ForwardBE = 2'b01;
        else
            ForwardBE = 2'b00;
    end

    //STALL (load-use)  
    assign lwStall = ResultSrcE0 && ((Rs1D == RdE) || (Rs2D == RdE));

    assign StallF = lwStall;
    assign StallD = lwStall;

    // FLUSH  
    assign FlushD = PCSrcE;
    assign FlushE = lwStall || PCSrcE;

endmodule