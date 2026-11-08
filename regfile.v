module regfile(
    input         clk,
    input         reset,
    input         we3_0,
    input  [4:0]  a3_0,
    input  [31:0] wd3_0,
    input         we3_1,
    input  [4:0]  a3_1,
    input  [31:0] wd3_1,
    input  [4:0]  a1_0, a2_0,
    output [31:0] rd1_0, rd2_0,
    input  [4:0]  a1_1, a2_1,
    output [31:0] rd1_1, rd2_1
);

    reg [31:0] rf[0:31];
    integer i;

    // Escritura sincrona con reset
    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) rf[i] <= 32'b0;
        end else begin
            if (we3_0 && a3_0 != 5'd0) rf[a3_0] <= wd3_0;
            // La via 1 es mas joven y gana una colision WAW sobre el mismo registro
            if (we3_1 && a3_1 != 5'd0) rf[a3_1] <= wd3_1;
        end
    end

    // Lecturas asincronas con bypass de WB (expresion explicita directa)
    assign rd1_0 = (a1_0 == 5'd0) ? 32'b0 :
                   (!reset && we3_1 && (a3_1 == a1_0) && (a3_1 != 5'd0)) ? wd3_1 :
                   (!reset && we3_0 && (a3_0 == a1_0) && (a3_0 != 5'd0)) ? wd3_0 : rf[a1_0];

    assign rd2_0 = (a2_0 == 5'd0) ? 32'b0 :
                   (!reset && we3_1 && (a3_1 == a2_0) && (a3_1 != 5'd0)) ? wd3_1 :
                   (!reset && we3_0 && (a3_0 == a2_0) && (a3_0 != 5'd0)) ? wd3_0 : rf[a2_0];

    assign rd1_1 = (a1_1 == 5'd0) ? 32'b0 :
                   (!reset && we3_1 && (a3_1 == a1_1) && (a3_1 != 5'd0)) ? wd3_1 :
                   (!reset && we3_0 && (a3_0 == a1_1) && (a3_0 != 5'd0)) ? wd3_0 : rf[a1_1];

    assign rd2_1 = (a2_1 == 5'd0) ? 32'b0 :
                   (!reset && we3_1 && (a3_1 == a2_1) && (a3_1 != 5'd0)) ? wd3_1 :
                   (!reset && we3_0 && (a3_0 == a2_1) && (a3_0 != 5'd0)) ? wd3_0 : rf[a2_1];

endmodule