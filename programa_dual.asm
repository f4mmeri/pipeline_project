# ==============================================================================
# PROGRAMA DUAL-ISSUE: EVIDENCIA DE DUAL FETCH Y DUAL DECODE
# ==============================================================================
# Cada ciclo se capta y decodifica un par de instrucciones (PC += 8).
# Dentro de cada par las instrucciones son independientes, y cada consumidor
# esta a 3 pares o mas de su productor (no depende de forwarding).
#
# PAR 1 (PC = 0x00): inicializaciones
addi x1, x0, 10          # Via 0: x1 = 10
addi x2, x0, 20          # Via 1: x2 = 20
#
# PAR 2 (PC = 0x08): inicializaciones
addi x3, x0, 30          # Via 0: x3 = 30
addi x4, x0, 40          # Via 1: x4 = 40
#
# PAR 3 (PC = 0x10): nops de separacion
nop                      # Via 0
nop                      # Via 1
#
# PAR 4 (PC = 0x18): nops de separacion
nop                      # Via 0
nop                      # Via 1
#
# PAR 5 (PC = 0x20): operaciones aritmeticas
add  x5, x1, x2          # Via 0: x5 = 10 + 20 = 30
add  x6, x3, x4          # Via 1: x6 = 30 + 40 = 70
#
# PAR 6 (PC = 0x28): operaciones logicas
or   x7, x1, x2          # Via 0: x7 = 10 | 20 = 30
and  x8, x3, x4          # Via 1: x8 = 30 & 40 = 8
#
# PAR 7 (PC = 0x30): valor testigo de fin
addi x19, x0, 25         # Via 0: x19 = 25
nop                      # Via 1
#
# PAR 8 (PC = 0x38): nops de separacion
nop                      # Via 0
nop                      # Via 1
#
# PAR 9 (PC = 0x40): nops de separacion
nop                      # Via 0
nop                      # Via 1
#
# PAR 10 (PC = 0x48): marca de fin en memoria
sw   x19, 100(x0)        # Via 0: mem[100] = 25
nop                      # Via 1
#
# PAR 11 (PC = 0x50): bucle final
fin:
jal  x0, fin             # Via 0: salto a si mismo
nop                      # Via 1