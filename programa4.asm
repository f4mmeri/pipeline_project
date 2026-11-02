# PROGRAMA 4 - FLUSHING (BEQ Y JAL)
# Se comprueba que, al tomar un salto, las instrucciones
# que estaban en IF e ID sean anuladas (flush).
# Las instrucciones incorrectas NO deben modificar registros.

#   Inicializacion (sin dependencias cercanas al branch)
addi x1, x0, 7           # x1 = 7
addi x2, x0, 7           # x2 = 7
nop
nop
nop

#   Branch tomado: se deben anular las dos instrucciones siguientes
beq  x1, x2, salto1     # 7 == 7, salto tomado (flush)
addi x3, x0, 99          # NO ejecutar: instruccion en camino incorrecto
addi x4, x0, 88          # NO ejecutar: x4 debe seguir en 0

salto1:
addi x3, x0, 11          # x3 = 11 (destino correcto del beq)

#   JAL: se deben anular las instrucciones siguientes
jal  x0, salto2          # Salto incondicional (flush)
addi x5, x0, 77          # NO ejecutar: camino incorrecto
addi x6, x0, 66          # NO ejecutar: x6 debe seguir en 0

salto2:
addi x5, x0, 22          # x5 = 22 (destino correcto del jal)

#   Marca de fin: el testbench espera esta escritura
addi x19, x0, 25         # x19 = 25
nop
nop
nop
sw   x19, 100(x0)        # mem[100] = 25 (senal de fin)

#   Bucle infinito
fin:
jal  x0, fin             # Mantiene el procesador ejecutandose
