# PROGRAMA 2 - FORWARDING


#   Inicialización
addi x1, x0, 10          # x1 = 10
addi x2, x0, 5           # x2 = 5


#   Forwarding desde WB y MEM
add  x3, x1, x2          # x3 = 15


#   Forwarding desde MEM
sub  x4, x3, x2          # x4 = 10


#   Forwarding desde WB y MEM
add  x5, x3, x4          # x5 = 25


#   Operaciones lógicas con forwarding
and  x6, x5, x1          # x6 = 8
or   x7, x6, x2          # x7 = 13


#   Forwarding en operacion aritmetica
add  x8, x7, x5          # x8 = 38


# Fin
addi x19, x0, 25         # x19 = 25
nop
nop
nop
sw   x19, 100(x0)        # mem[100] = 25 (señal de fin)




#   Bucle infinito
fin:
jal  x0, fin