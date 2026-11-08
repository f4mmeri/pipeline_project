`timescale 1ns/1ps

// Testbench integral, no depende de rutas absolutas.
// Ejecutar como top de simulacion: tb_dual
module tb_dual;
    reg clk = 0;
    reg reset = 1;
    wire [31:0] WriteData, DataAdr;
    wire MemWrite;
    integer errors = 0;
    integer dual_count = 0;
    integer single_count = 0;
    integer stall_count = 0;
    integer i;

    top dut(
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    always #5 clk = ~clk;

    // Encoders RV32I (subconjunto probado)
    function [31:0] addi;
       input [4:0] rd, rs1;
       input integer imm;
       begin addi = {imm[11:0], rs1, 3'b000, rd, 7'b0010011}; end
    endfunction

    function [31:0] rtype;
       input [6:0] f7;
       input [4:0] rs2, rs1;
       input [2:0] f3;
       input [4:0] rd;
       begin rtype = {f7, rs2, rs1, f3, rd, 7'b0110011}; end
    endfunction

    function [31:0] lw;
       input [4:0] rd, rs1;
       input integer imm;
       begin lw = {imm[11:0], rs1, 3'b010, rd, 7'b0000011}; end
    endfunction

    function [31:0] sw;
       input [4:0] rs2, rs1;
       input integer imm;
       begin sw = {imm[11:5], rs2, rs1, 3'b010, imm[4:0], 7'b0100011}; end
    endfunction

    function [31:0] beq;
       input [4:0] rs1, rs2;
       input integer offset;
       begin beq = {offset[12], offset[10:5], rs2, rs1, 3'b000, offset[4:1], offset[11], 7'b1100011}; end
    endfunction

    task check_reg;
       input integer idx;
       input [31:0] expected;
       begin
         if (dut.rvpipeline.dp.rf.rf[idx] !== expected) begin
           $display("FAIL register x%0d = %h; expected %h", idx, dut.rvpipeline.dp.rf.rf[idx], expected);
           errors = errors + 1;
         end
       end
    endtask

    task check_mem;
       input integer idx;
       input [31:0] expected;
       begin
         if (dut.dmem.RAM[idx] !== expected) begin
           $display("FAIL memory [%0d] = %h; expected %h", idx, dut.dmem.RAM[idx], expected);
           errors = errors + 1;
         end
       end
    endtask

    task clear_and_reset;
       begin
         reset = 1'b1;
         for(i=0; i<256; i=i+1) dut.imem.RAM[i] = 32'h00000013;
         for(i=0; i<64; i=i+1)  dut.dmem.RAM[i] = 32'b0;
         dual_count = 0; single_count = 0; stall_count = 0;
         repeat(3) @(negedge clk);
       end
    endtask

    task run_program;
       input integer cycles;
       begin
         reset = 1'b0;
         repeat(cycles) @(negedge clk);
       end
    endtask

    always @(negedge clk) begin
      if(!reset) begin
        if(dut.rvpipeline.Issue0 && dut.rvpipeline.Issue1) dual_count = dual_count + 1;
        else if(dut.rvpipeline.Issue0) single_count = single_count + 1;
        else stall_count = stall_count + 1;

        if(dut.rvpipeline.Issue1 && !dut.rvpipeline.Issue0) begin
          $display("FAIL younger emitted without older");
          errors = errors + 1;
        end
      end
    end

    initial begin
      // 1: ALU independientes, RAW, store/load y load-use
      clear_and_reset;
      dut.imem.RAM[0] = addi(1,0,10);
      dut.imem.RAM[1] = addi(2,0,20);
      dut.imem.RAM[2] = rtype(0,2,1,0,3);          // add x3,x1,x2 = 30
      dut.imem.RAM[3] = rtype(7'b0100000,1,3,0,4); // sub x4,x3,x1 = 20
      dut.imem.RAM[4] = sw(4,0,0);
      dut.imem.RAM[5] = lw(5,0,0);
      dut.imem.RAM[6] = rtype(0,1,5,0,6);          // add x6,x5,x1 = 30
      dut.imem.RAM[7] = sw(6,0,4);
      run_program(40);
      check_reg(1,10); check_reg(2,20); check_reg(3,30);
      check_reg(4,20); check_reg(5,20); check_reg(6,30);
      check_mem(0,20); check_mem(1,30);
      if(dual_count==0 || single_count==0) begin
        $display("FAIL did not observe dual and single issue");
        errors = errors + 1;
      end
      $display("CASE1 dual=%0d single=%0d stalled=%0d", dual_count, single_count, stall_count);

      // 2: memoria in slot 1, forwarding de load y ALU + load
      clear_and_reset;
      dut.dmem.RAM[0] = 13; dut.dmem.RAM[1] = 17;
      dut.imem.RAM[0] = addi(1,0,7);
      dut.imem.RAM[1] = lw(5,0,0);
      dut.imem.RAM[2] = rtype(0,1,5,0,6); // 13+7=20
      dut.imem.RAM[3] = lw(7,0,4);
      run_program(30);
      check_reg(1,7); check_reg(5,13); check_reg(6,20); check_reg(7,17);

      // 3: dos memorias consecutivas deben serializarse
      clear_and_reset;
      dut.dmem.RAM[0] = 8; dut.dmem.RAM[1] = 9;
      dut.imem.RAM[0] = lw(1,0,0);
      dut.imem.RAM[1] = lw(2,0,4);
      dut.imem.RAM[2] = rtype(0,2,1,0,3);
      dut.imem.RAM[3] = sw(3,0,8);
      run_program(35);
      check_reg(1,8); check_reg(2,9); check_reg(3,17); check_mem(2,17);
      if(single_count==0) begin
        $display("FAIL did not serialize memory");
        errors = errors + 1;
      end

      // 4: branch tomado en primera posicion (descarta younger)
      clear_and_reset;
      dut.imem.RAM[0] = beq(0,0,12); // salta a indice 3
      dut.imem.RAM[1] = addi(1,0,99); // debe anularse
      dut.imem.RAM[2] = addi(2,0,88); // debe anularse
      dut.imem.RAM[3] = addi(3,0,7);
      run_program(25);
      check_reg(1,0); check_reg(2,0); check_reg(3,7);

      // 5: branch tomado en segunda posicion; conserva la anterior
      clear_and_reset;
      dut.imem.RAM[0] = addi(1,0,5);
      dut.imem.RAM[1] = beq(0,0,12); // salta a indice 4
      dut.imem.RAM[2] = addi(2,0,99);
      dut.imem.RAM[3] = addi(3,0,88);
      dut.imem.RAM[4] = addi(4,0,9);
      run_program(25);
      check_reg(1,5); check_reg(2,0); check_reg(3,0); check_reg(4,9);

      if(errors == 0) $display("PASS: cinco casos integrales completados");
      else begin
        $display("FAIL: %0d comprobaciones incorrectas", errors);
        $fatal(1, "Pruebas de entrega 2 fallidas");
      end
      $finish;
    end
endmodule
