module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;
  
  // instantiate device to be tested
  top dut(
    .clk(clk), 
    .reset(reset), 
    .WriteData(WriteData), 
    .DataAdr(DataAdr), 
    .MemWrite(MemWrite)
  );

  // initialize test
  initial begin
    reset = 1; # 22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    clk = 1;
    # 5; clk = 0; # 5;
  end

  // check results
  always @(negedge clk) begin
    if(MemWrite) begin
      if(DataAdr === 100 & WriteData === 25) begin
        $display("Simulation succeeded");
        $stop;
      end else if (DataAdr !== 96) begin
        $display("Simulation failed");
        $stop;

        integer n_jal_early = 0, n_jalr_early = 0, n_jalr_ex = 0;

// dentro del always @(negedge clk) ... if (running && !done) begin
if (dut.rvpipeline.dp.PCSrcD) begin
  if (dut.rvpipeline.dp.Early0) begin
    if (dut.rvpipeline.dp.Jalr0D) n_jalr_early = n_jalr_early + 1;
    else                          n_jal_early  = n_jal_early  + 1;
  end else begin
    if (dut.rvpipeline.dp.Jalr1D) n_jalr_early = n_jalr_early + 1;
    else                          n_jal_early  = n_jal_early  + 1;
  end
end
// jalr que cayó a EX: salió pero estaba Busy
if ((dut.rvpipeline.dp.Issue0 && dut.rvpipeline.dp.Busy0D) ||
    (dut.rvpipeline.dp.Issue1 && dut.rvpipeline.dp.Busy1D))
  if (!dut.rvpipeline.dp.PCSrcE) n_jalr_ex = n_jalr_ex + 1;
      end
    end
  end
endmodule