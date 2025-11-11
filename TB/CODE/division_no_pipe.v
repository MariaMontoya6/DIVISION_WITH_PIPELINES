module division_no_pipe (
    input clk,
    input reset,
    input start,
    input [7:0] A,      // Dividendo 
    input [7:0] B,      // Divisor 
    output reg valid,
    output reg [15:0] P // [15:8] = Cociente, [7:0] = Residuo
);
    // Registros internos
    reg [7:0] A_reg, B_reg;
    reg [5:0] contador;
    reg en_proceso;
    reg error_div_cero;
   
    // Parámetro para ajustar el número de ciclos de retardo
    parameter CICLOS_DIVISION = 16;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            P <= 0;
            valid <= 0;
            contador <= 0;
            en_proceso <= 0;
            A_reg <= 0;
            B_reg <= 0;
            error_div_cero <= 0;
        end else begin
            if (start && !en_proceso) begin
                // Captura nuevos operandos
                A_reg <= A;
                B_reg <= B;
                en_proceso <= 1;
                valid <= 0;
                contador <= 0;
                
                // Verificar división por cero
                if (B == 0) begin
                    error_div_cero <= 1;
                    $display("No Pipeline division: ERROR - División por cero detectada! A=%d, B=%d", A, B);
                end else begin
                    error_div_cero <= 0;
                    $display("No Pipeline division: Capturando A=%d, B=%d", A, B);
                end
            end else if (en_proceso) begin
                if (contador < CICLOS_DIVISION - 1) begin
                    // Simulamos el procesamiento secuencial
                    contador <= contador + 1;
                end else begin
                    // Finaliza la division después de CICLOS_DIVISION
                    if (error_div_cero || B_reg == 0) begin
                        // Manejo de división por cero
                        P[15:8] <= 8'hFF;  // Cociente = 0xFF (indicador de error)
                        P[7:0]  <= 8'hFF;  // Residuo = 0xFF (indicador de error)
                        $display("División por cero: Resultado = ERROR (0xFF, 0xFF)");
                    end else begin
                        // División normal
                        P[15:8] <= A_reg / B_reg;  // Cociente
                        P[7:0]  <= A_reg % B_reg;  // Residuo
                        $display("División: %d / %d = %d, residuo = %d", 
                                A_reg, B_reg, A_reg/B_reg, A_reg%B_reg);
                    end
                    valid <= 1;
                    en_proceso <= 0;
                end
            end else if (valid) begin
                valid <= 0;  // Reset valid después de un ciclo
            end
        end
    end
endmodule