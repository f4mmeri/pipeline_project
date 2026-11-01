# PROGRAMA 1 - ISA sin dependencias
# Ninguna instruccion lee un registro escrito por las 3
# instrucciones anteriores, asi que la Hazard Unit no interviene.

#   Inicializacion  
addi x1, x0, 12          # x1  = 12
addi x2, x0, 10          # x2  = 10
nop
nop
nop

#   Tipo R (leen solo x1, x2)  
add  x3, x1, x2          # x3  = 22
sub  x4, x1, x2          # x4  = 2
and  x5, x1, x2          # x5  = 8
or   x6, x1, x2          # x6  = 14
xor  x7, x1, x2          # x7  = 6
slt  x8, x2, x1          # x8  = 1   (10 < 12)

#   Tipo I (leen solo x1, x2)  
addi x9,  x1, 5          # x9  = 17
andi x10, x1, 10         # x10 = 8
ori  x11, x1, 3          # x11 = 15
xori x12, x1, 5          # x12 = 9
slti x13, x2, 11         # x13 = 1   (10 < 11)
nop
nop
nop

#   Memoria  
sw   x3, 0(x0)           # mem[0]  = 22
sw   x4, 4(x0)           # mem[4]  = 2
sw   x5, 8(x0)           # mem[8]  = 8
lw   x14, 0(x0)          # x14 = 22
lw   x15, 4(x0)          # x15 = 2

#   Branch NO tomado (12 != 10, no hay flush)  
beq  x1, x2, salto1
addi x17, x0, 1          # x17 = 1 (se ejecuta porque no se toma)
salto1:
nop

#   jal (salta sobre dos nop)  
jal  x16, salto2         # x16 = PC+4 = 0x70
nop
nop
salto2:

#   Verificar lw guardando en memoria  
sw   x14, 12(x0)         # mem[12] = 22
sw   x15, 16(x0)         # mem[16] = 2

#   Marca de fin: el testbench espera esta escritura  
addi x19, x0, 25
nop
nop
nop
sw   x19, 100(x0)        # mem[100] = 25  (senal de fin)

fin:
jal  x0, fin             # bucle infinito