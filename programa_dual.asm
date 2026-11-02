# ==============================================================================
# PROGRAMA DUAL-ISSUE: DEMOSTRACION DE DUAL FETCH, DUAL DECODE Y DUAL EXECUTE
# ==============================================================================
# Cada ciclo de reloj procesa pares de instrucciones simultaneas:
#
# PAR 1 (PC = 0): Inicializaciones simultaneas en paralelo
addi x1, x0, 10          # Via 0: x1 = 10
addi x2, x0, 20          # Via 1: x2 = 20
#
# PAR 2 (PC = 8): Inicializaciones simultaneas en paralelo
addi x3, x0, 30          # Via 0: x3 = 30
addi x4, x0, 40          # Via 1: x4 = 40
#
# PAR 3 (PC = 16): NOPs de sincronizacion
nop                      # Via 0: NOP
nop                      # Via 1: NOP
#
# PAR 4 (PC = 24): Operaciones aritmeticas simultaneas (ALU0 y ALU1 en paralelo)
add  x5, x1, x2          # Via 0: x5 = 10 + 20 = 30  (en ALU0)
add  x6, x3, x4          # Via 1: x6 = 30 + 40 = 70  (en ALU1)
#
# PAR 5 (PC = 32): Operaciones logicas simultaneas (ALU0 y ALU1 en paralelo)
or   x7, x1, x2          # Via 0: x7 = 10 | 20 = 30  (en ALU0)
and  x8, x3, x4          # Via 1: x8 = 30 & 40 = 0   (en ALU1)
#
# PAR 6 (PC = 40): Carga de valor testigo de fin de ejecucion
addi x19, x0, 25         # Via 0: x19 = 25
nop                      # Via 1: NOP
#
# PAR 7 (PC = 48): Almacenamiento en memoria de datos
sw   x19, 100(x0)        # Via 0: mem[100] = 25
nop                      # Via 1: NOP
#
# PAR 8 (PC = 56): Bucle final
fin:
jal  x0, fin             # Via 0: Salto a fin
nop                      # Via 1: NOP

