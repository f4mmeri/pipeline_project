# Propio  
```
Ciclos:                  103
Instrucciones retiradas: 85
IPC:                     0.825243
CPI:                     1.211765
Saltos resueltos en ID:  0
Saltos resueltos en EX:  17
Ciclos de stall (load-use): 6
=================================
testbench.v:127: $stop called at 1075000 (1ps)
```


# Profesor  
```
Ciclos:                  394
Instrucciones retiradas: 312
IPC:                     0.791878
CPI:                     1.262821
Saltos resueltos en ID:  0
Saltos resueltos en EX:  67
Ciclos de stall (load-use): 10
=================================
testbench.v:127: $stop called at 3985000 (1ps)
```

# Esperado  

```
Propio Dual	Propio Opt	Profesor Dual	Profesor Opt
Ciclos	103	90	394	382
Retiradas	85	85	312	312
IPC	0.825	0.944	0.792	0.817
CPI	1.212	1.059	1.263	1.224
Saltos en ID / EX	0 / 17	13 / 4	0 / 67	12 / 55
Stalls	6	6	10	10
```