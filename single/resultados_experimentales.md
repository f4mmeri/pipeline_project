# Propio  
```
Ciclos:                  129
Instrucciones retiradas: 85
IPC:                     0.658915
CPI:                     1.517647
Saltos resueltos en ID:  0
Saltos resueltos en EX:  17
Ciclos de stall (load-use): 6
=================================
testbench.v:127: $stop called at 1335000 (1ps)
```  


# Profesor  

```
Ciclos:                  459
Instrucciones retiradas: 312
IPC:                     0.679739
CPI:                     1.471154
Saltos resueltos en ID:  0
Saltos resueltos en EX:  67
Ciclos de stall (load-use): 9
=================================
testbench.v:127: $stop called at 4635000 (1ps)
```  


# Resultados esperados completos  

```
	Single	Dual	Dual Opt
Programa propio (85 instr.)			
Ciclos	129	103	90
IPC / CPI	0.659 / 1.518	0.825 / 1.212	0.944 / 1.059
Speedup vs Single	1.00	1.25	1.43
Programa del profesor (312 instr.)			
Ciclos	459	394	382
IPC / CPI	0.680 / 1.471	0.792 / 1.263	0.817 / 1.224
Speedup vs Single	1.00	1.17	1.20
Stalls load-use	9	10	10
```