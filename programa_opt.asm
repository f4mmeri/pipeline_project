        addi x1, x0, 1024      # 00 base
        addi x4, x0, 36        # 04 x4 = direccion de T (0x24)
        jal  x0, A             # 08 CASO 1: jal en slot 0
        addi x20, x0, 99       # 0C camino incorrecto
A:      addi x3, x0, 3         # 10 slot 0
        jal  x0, B             # 14 CASO 2: jal en slot 1
        addi x21, x0, 99       # 18 camino incorrecto
B:      jalr x9, x4, 0         # 1C CASO 3: rs1 listo, rd != x0 (link = 0x20)
        addi x22, x0, 99       # 20 camino incorrecto
T:      addi x6, x0, 52        # 24 produce rs1 (0x34)
        jalr x0, x6, 0         # 28 CASO 4: rs1 en E, cae a EX
        addi x23, x0, 99       # 2C camino incorrecto
        addi x24, x0, 99       # 30 camino incorrecto
U:      beq  x1, x1, V         # 34 CASO 5: beq tomado, se resuelve en EX
        jal  x25, fin          # 38 en Decode mientras el beq esta en EX: NO debe redirigir
        addi x27, x0, 99       # 3C camino incorrecto
V:      sw   x9, 1588(x0)      # 40 M[1588] = 32 (verifica el link) y marca de fin
fin:    jal  x0, fin           # 44