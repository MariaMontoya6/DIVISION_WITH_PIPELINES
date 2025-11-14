# README 

Este proyecto implementa y compara dos arquitecturas diferentes para un divisor de números de 8 bits en Verilog:

* Divisor sin Pipeline: Arquitectura secuencial que procesa una operación completa antes de comenzar la siguiente.

* Divisor con Pipeline: Arquitectura paralela que procesa múltiples operaciones simultáneamente usando el algoritmo Shift-and-Subtract. 

Esta comparacion la hace mediante un testbench que permite: 

* Comparación simultánea de ambos divisores con mismos estímulos
* Múltiples escenarios de prueba:

    * Operaciones únicas
    * Series espaciadas
    * Operaciones back-to-back (alta velocidad)
    * Casos especiales (división por cero, casos límite)

* Métricas automáticas de rendimiento
* Detección de errores y comparación de resultados