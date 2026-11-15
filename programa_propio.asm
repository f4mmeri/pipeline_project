# Programa propio EF: llena un arreglo, lo suma y hace dos llamadas a funcion
.text
        addi x1, x0, 1024        # base de datos
        addi x2, x0, 5           # N = 5
        addi x3, x0, 0           # i = 0
        addi x6, x1, 0           # puntero
fill:   beq  x3, x2, sum_init    # fin del llenado
        addi x5, x3, 1           # x5 = i + 1
        sw   x5, 0(x6)           # arr[i] = i + 1
        addi x6, x6, 4
        addi x3, x3, 1
        jal  x0, fill            # salto de vuelta (jal)
sum_init:
        addi x3, x0, 0
        addi x6, x1, 0
        addi x4, x0, 0           # suma = 0
sum:    beq  x3, x2, calls
        lw   x7, 0(x6)
        add  x4, x4, x7          # load-use con el lw
        addi x6, x6, 4
        addi x3, x3, 1
        jal  x0, sum
calls:  jal  x10, f_larga        # llamada 1 (ra = 0x50)
        jal  x10, f_corta        # llamada 2 (ra = 0x54)
        addi x16, x0, 15
        beq  x4, x16, ok         # TOMADO: anula las dos siguientes
        addi x20, x0, 99         # camino incorrecto, debe quedar en 0
        addi x21, x0, 99         # camino incorrecto, debe quedar en 0
ok:     addi x17, x0, 7
        beq  x4, x17, malo       # NO tomado
        addi x18, x0, 1
        add  x31, x4, x13        # 15 + 32 = 47
        sw   x31, 1588(x0)       # marca de fin (misma que usa el testbench)
fin:    jal  x0, fin
malo:   addi x22, x0, 99         # nunca debe ejecutarse
        jal  x0, fin
f_larga:
        add  x11, x4, x4         # 30
        addi x11, x11, 1         # 31
        sw   x11, 20(x1)         # conflicto de memoria con el lw siguiente
        lw   x12, 20(x1)
        addi x13, x12, 1         # load-use: 32
        jalr x0, x10, 0          # retorno: ra listo, se resuelve en ID (C)
f_corta:
        jalr x0, x10, 0          # retorno inmediato: ra en M, cae a EX (C)