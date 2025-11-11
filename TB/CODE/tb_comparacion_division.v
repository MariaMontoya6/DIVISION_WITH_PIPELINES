`timescale 1ns / 1ps
`include "division_no_pipe.v"
`include "division_pipe.v"

module tb_comparacion_division;
    // Parámetros del testbench
    parameter CLK_PERIOD = 10; // Periodo de reloj en unidades de tiempo
    
    // Señales comunes
    reg clk;
    reg reset;
    reg start;
    reg [7:0] A, B;
    
    // Señales para el divisor sin pipeline
    wire valid_no_pipeline;
    wire [15:0] P_no_pipeline;
    wire [7:0] Q_no_pipeline = P_no_pipeline[15:8]; // Cociente
    wire [7:0] R_no_pipeline = P_no_pipeline[7:0];  // Residuo
    
    // Señales para el divisor con pipeline
    wire valid_pipeline;
    wire [15:0] P_pipeline;
    wire [7:0] Q_pipeline = P_pipeline[15:8]; // Cociente
    wire [7:0] R_pipeline = P_pipeline[7:0];  // Residuo
    
    // Contador para medir el rendimiento
    integer operaciones_completadas_no_pipeline;
    integer operaciones_completadas_pipeline;
    integer ciclos_transcurridos;
    integer errores_comparacion;
    integer i;
    
    // Instancia de los módulos
    division_no_pipe uut_no_pipeline (
        .clk(clk),
        .reset(reset),
        .start(start),
        .A(A),
        .B(B),
        .valid(valid_no_pipeline),
        .P(P_no_pipeline)
    );
    
    division_pipe uut_pipeline (
        .clk(clk),
        .reset(reset),
        .start(start),
        .A(A),
        .B(B),
        .valid(valid_pipeline),
        .P(P_pipeline)
    );
    
    // Generación de reloj
    always begin
        #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Contador de ciclos
    always @(posedge clk) begin
        if (reset)
            ciclos_transcurridos <= 0;
        else
            ciclos_transcurridos <= ciclos_transcurridos + 1;
    end
    
    // Monitoreo de operaciones completadas y resultados
    always @(posedge clk) begin
        if (reset) begin
            operaciones_completadas_no_pipeline <= 0;
            operaciones_completadas_pipeline <= 0;
            errores_comparacion <= 0;
        end else begin
            if (valid_no_pipeline) begin
                operaciones_completadas_no_pipeline <= operaciones_completadas_no_pipeline + 1;
                if (Q_no_pipeline == 8'hFF && R_no_pipeline == 8'hFF) begin
                    $display("Tiempo %t: Divisor sin pipeline - ERROR: División por cero", $time);
                end else begin
                    $display("Tiempo %t: Divisor sin pipeline - Cociente: %d, Residuo: %d", 
                             $time, Q_no_pipeline, R_no_pipeline);
                end
            end
            if (valid_pipeline) begin
                operaciones_completadas_pipeline <= operaciones_completadas_pipeline + 1;
                if (Q_pipeline == 8'hFF && R_pipeline == 8'hFF) begin
                    $display("Tiempo %t: Divisor con pipeline - ERROR: División por cero", $time);
                end else begin
                    $display("Tiempo %t: Divisor con pipeline - Cociente: %d, Residuo: %d", 
                             $time, Q_pipeline, R_pipeline);
                end
            end
            
            // Comparar resultados cuando ambos están válidos en el mismo ciclo
            if (valid_no_pipeline && valid_pipeline) begin
                if (P_no_pipeline != P_pipeline) begin
                    $display("ERROR: Resultados diferentes!");
                    $display("  No-Pipeline: Q=%d, R=%d", Q_no_pipeline, R_no_pipeline);
                    $display("  Pipeline:    Q=%d, R=%d", Q_pipeline, R_pipeline);
                    errores_comparacion <= errores_comparacion + 1;
                end else begin
                    $display("✓ Resultados coinciden: Q=%d, R=%d", Q_pipeline, R_pipeline);
                end
            end
        end
    end
    
    // Tarea para enviar operandos
    task enviar_operandos;
        input [7:0] operand_a;
        input [7:0] operand_b;
        begin
            @(posedge clk);
            A = operand_a;
            B = operand_b;
            start = 1;
            if (operand_b == 0) begin
                $display("Tiempo %t: Enviando operandos A=%d, B=%d (DIVISIÓN POR CERO)", 
                         $time, operand_a, operand_b);
            end else begin
                $display("Tiempo %t: Enviando operandos A=%d, B=%d (Esperado: Q=%d, R=%d)", 
                         $time, operand_a, operand_b, operand_a/operand_b, operand_a%operand_b);
            end
            @(posedge clk);
            start = 0;
        end
    endtask
    
    initial begin
        // Inicialización
        clk = 0;
        reset = 1;
        start = 0;
        A = 0;
        B = 0;
        operaciones_completadas_no_pipeline = 0;
        operaciones_completadas_pipeline = 0;
        ciclos_transcurridos = 0;
        errores_comparacion = 0;
        
        // Archivo para visualización con GTKWave
        $dumpfile("tb_comparacion_division.vcd");
        $dumpvars(0, tb_comparacion_division);
        
        $display("=======================================================");
        $display("  TESTBENCH: Comparación División Pipeline vs No-Pipeline");
        $display("=======================================================\n");
        
        // Reset inicial
        #20 reset = 0;
        #20; // Esperar unos ciclos después del reset
        
        // ===== PRUEBA 1: Una sola operación =====
        $display("\n--- PRUEBA 1: Una sola operación de división ---");
        enviar_operandos(8'd100, 8'd10);
        
        // Esperar a que ambos divisores terminen
        #200;
        
        // ===== PRUEBA 2: Serie de operaciones consecutivas con espacio =====
        $display("\n--- PRUEBA 2: Serie de operaciones consecutivas ---");
        enviar_operandos(8'd50, 8'd5);
        #30;
        enviar_operandos(8'd77, 8'd7);
        #30;
        enviar_operandos(8'd255, 8'd16);
        #30;
        enviar_operandos(8'd128, 8'd3);
        #30;
        enviar_operandos(8'd200, 8'd11);
        #30;
        
        // Esperar a que todas las operaciones se completen
        #200;
        
        // Mostrar resultados de la segunda prueba
        $display("\n--- Rendimiento después de %d ciclos ---", ciclos_transcurridos);
        $display("Divisor sin pipeline: %d operaciones completadas", operaciones_completadas_no_pipeline);
        $display("Divisor con pipeline: %d operaciones completadas", operaciones_completadas_pipeline);
        $display("Errores de comparación: %d", errores_comparacion);
        
        if (operaciones_completadas_no_pipeline > 0) begin
            $display("Mejora de rendimiento: %0.2fx", 
                    operaciones_completadas_pipeline * 1.0 / operaciones_completadas_no_pipeline);
        end
        
        // ===== PRUEBA 3: Operaciones consecutivas a alta velocidad =====
        $display("\n--- PRUEBA 3: Operaciones a alta velocidad (una por ciclo) ---");
        $display("Mostrando el efecto del pipeline...\n");
        
        for (i = 0; i < 10; i = i + 1) begin
            enviar_operandos(8'd150 + i*5, 8'd10 + i);
            // Solo esperamos 1 ciclo entre operaciones para mostrar el efecto del pipeline
        end
        
        // Esperar a que todas las operaciones se completen
        #300;
        
        // ===== PRUEBA 4: Casos especiales =====
        $display("\n--- PRUEBA 4: Casos especiales ---");
        
        // División por cero
        enviar_operandos(8'd100, 8'd0);
        #30;
        
        // Dividendo menor que divisor
        enviar_operandos(8'd5, 8'd20);
        #30;
        
        // Dividendo = 0
        enviar_operandos(8'd0, 8'd10);
        #30;
        
        // División exacta
        enviar_operandos(8'd144, 8'd12);
        #30;
        
        // Divisor = 1
        enviar_operandos(8'd255, 8'd1);
        #30;
        
        // Esperar a que se completen
        #300;
        
        // ===== RESULTADOS FINALES =====
        $display("\n=======================================================");
        $display("  RESULTADOS FINALES");
        $display("=======================================================");
        $display("Ciclos totales: %d", ciclos_transcurridos);
        $display("Divisor sin pipeline: %d operaciones completadas", operaciones_completadas_no_pipeline);
        $display("Divisor con pipeline: %d operaciones completadas", operaciones_completadas_pipeline);
        $display("Errores de comparación: %d", errores_comparacion);
        
        if (operaciones_completadas_no_pipeline > 0) begin
            $display("\nMejora de rendimiento del pipeline: %0.2fx", 
                    operaciones_completadas_pipeline * 1.0 / operaciones_completadas_no_pipeline);
            $display("Throughput sin pipeline: %0.3f ops/ciclo", 
                    operaciones_completadas_no_pipeline * 1.0 / ciclos_transcurridos);
            $display("Throughput con pipeline: %0.3f ops/ciclo", 
                    operaciones_completadas_pipeline * 1.0 / ciclos_transcurridos);
        end
        
        if (errores_comparacion == 0) begin
            $display("\n✓ TODAS LAS COMPARACIONES PASARON");
        end else begin
            $display("\n✗ SE ENCONTRARON %d ERRORES DE COMPARACIÓN", errores_comparacion);
        end
        $display("=======================================================\n");
        
        $finish;
    end
endmodule