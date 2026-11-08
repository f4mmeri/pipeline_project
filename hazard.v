module hazard(
    input  [31:0] Instr0D, Instr1D,
    input         Valid0D, Valid1D,
    input  [4:0]  Rd0E, Rd1E,
    input         Load0E, Load1E,
    input         PCSrcE,
    output        StallOld, StallYoung,
    output        FlushD, FlushE
);

    function uses_rs1;
      input [6:0] op;
      begin
        case(op)
          7'b0110011, 7'b0010011, 7'b0000011, 7'b0100011, 7'b1100011, 7'b1100111: uses_rs1 = 1'b1;
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

    wire [4:0] a0 = Instr0D[19:15], b0 = Instr0D[24:20];
    wire [4:0] a1 = Instr1D[19:15], b1 = Instr1D[24:20];
    wire u0a = uses_rs1(Instr0D[6:0]), u0b = uses_rs2(Instr0D[6:0]);
    wire u1a = uses_rs1(Instr1D[6:0]), u1b = uses_rs2(Instr1D[6:0]);

    wire hit0 = (Load0E && Rd0E != 5'd0 && ((u0a && a0 == Rd0E) || (u0b && b0 == Rd0E))) ||
                (Load1E && Rd1E != 5'd0 && ((u0a && a0 == Rd1E) || (u0b && b0 == Rd1E)));
    wire hit1 = (Load0E && Rd0E != 5'd0 && ((u1a && a1 == Rd0E) || (u1b && b1 == Rd0E))) ||
                (Load1E && Rd1E != 5'd0 && ((u1a && a1 == Rd1E) || (u1b && b1 == Rd1E)));

    assign StallOld   = Valid0D && hit0;
    assign StallYoung = Valid1D && hit1;
    assign FlushD     = PCSrcE;
    assign FlushE     = PCSrcE; // burbuja de EX en redirect; stalls crean burbujas por Issue0/1

endmodule
