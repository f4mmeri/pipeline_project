module issue_unit(
    input  [31:0] Instr0D, Instr1D,
    input         Valid0D, Valid1D,
    input         StallOld, StallYoung,
    output        Issue0, Issue1, HoldYounger,
    output        PairRAW, PairStructural, PairWAW, PairControl
);

    wire [6:0] op0 = Instr0D[6:0], op1 = Instr1D[6:0];
    wire [4:0] rd0 = Instr0D[11:7], rd1 = Instr1D[11:7];
    wire [4:0] rs1_1 = Instr1D[19:15], rs2_1 = Instr1D[24:20];

    function uses_rs1;
        input [6:0] op;
        begin
          case(op)
            7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011,
            7'b1100011, 7'b1100111: uses_rs1 = 1'b1;
            default: uses_rs1 = 1'b0;
          endcase
        end
    endfunction

    function uses_rs2;
        input [6:0] op;
        begin
          case(op)
            7'b0110011, 7'b0100011, 7'b1100011: uses_rs2 = 1'b1;
            default: uses_rs2 = 1'b0;
          endcase
        end
    endfunction

    function writes_rd;
        input [6:0] op;
        begin
          case(op)
            7'b0110011, 7'b0010011, 7'b0000011, 7'b1101111,
            7'b1100111, 7'b0110111, 7'b0010111: writes_rd = 1'b1;
            default: writes_rd = 1'b0;
          endcase
        end
    endfunction

    wire mem0 = (op0 == 7'b0000011) || (op0 == 7'b0100011);
    wire mem1 = (op1 == 7'b0000011) || (op1 == 7'b0100011);
    wire branch0 = (op0 == 7'b1100011) || (op0 == 7'b1101111) || (op0 == 7'b1100111);
    wire branch1 = (op1 == 7'b1100011) || (op1 == 7'b1101111) || (op1 == 7'b1100111);

    wire wr0 = writes_rd(op0) && (rd0 != 5'd0);
    wire wr1 = writes_rd(op1) && (rd1 != 5'd0);
    wire pair = Valid0D && Valid1D;

    assign PairRAW = pair && wr0 && ((uses_rs1(op1) && (rs1_1 == rd0)) || (uses_rs2(op1) && (rs2_1 == rd0)));
    assign PairStructural = pair && ((mem0 && mem1) || (branch0 && branch1));
    assign PairWAW = pair && wr0 && wr1 && (rd0 == rd1);
    // Conservador: no emitir la joven junto a un branch en primera posicion.
    assign PairControl = pair && branch0;

    assign Issue0 = Valid0D && !StallOld;
    assign Issue1 = Issue0 && Valid1D && !StallYoung && !(PairRAW || PairStructural || PairWAW || PairControl);
    assign HoldYounger = Issue0 && Valid1D && !Issue1;

endmodule