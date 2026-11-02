
module tb_programa2;

    reg         clk;
    reg         reset;
    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire        MemWrite;

    top dut(
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    // Reloj (periodo 10 ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Reset y duracion de la simulacion
    initial begin
        reset = 1;
        #30;
        reset = 0;
        #500;
        $finish;
    end

endmodule