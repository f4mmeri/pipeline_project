# PROGRAMA 3 - STALLING (LOAD-USE)
# Una instruccion utiliza inmediatamente un dato cargado por lw.
# La Hazard Unit debe detener IF e ID durante un ciclo e insertar
# una burbuja en EX. Luego se continua mediante forwarding desde WB.

#   Inicializacion de memoria
addi x1, x0, 12          # x1 = 12
nop
nop
nop
sw   x1, 0(x0)           # mem[0] = 12

#   Primer Load-Use: stall obligatorio
lw   x2, 0(x0)           # x2 = 12
add  x3, x2, x1          # x3 = 24 (usa x2 inmediatamente: 1 stall)
sub  x4, x3, x1          # x4 = 12 (forwarding MEM -> A)

#   Segundo Load-Use: stall obligatorio
lw   x5, 0(x0)           # x5 = 12
addi x6, x5, 3           # x6 = 15 (usa x5 inmediatamente: 1 stall)
add  x7, x6, x3          # x7 = 39 (forwarding MEM -> A)

#   Marca de fin: el testbench espera esta escritura
addi x19, x0, 25         # x19 = 25
nop
nop
nop
sw   x19, 100(x0)        # mem[100] = 25 (senal de fin)

#   Bucle infinito
fin:
jal  x0, fin             # Mantiene el procesador ejecutandose
