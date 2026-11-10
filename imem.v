module imem(
    input  [31:0] a,
    output [31:0] rd0, rd1
);
    reg [31:0] RAM[0:255];
    integer i;
 

    initial begin
        for (i = 0; i < 256; i = i + 1)
            RAM[i] = 32'h00000013; // NOP = addi x0,x0,0
        $readmemh("C:/Users/ameri/OneDrive/Desktop/arqui/pipeline_proyect/programa_e2_p1.mem", RAM);
    end

    // PCF = siguiente instruccion no almacenada en IF/ID.
    assign rd0 = RAM[a[9:2]];
    assign rd1 = RAM[a[9:2] + 8'd1];
endmodule

