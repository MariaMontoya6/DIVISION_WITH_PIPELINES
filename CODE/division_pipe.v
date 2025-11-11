module division_pipe (
    input clk,
    input reset,
    input start,
    input [7:0] A,      // Dividendo
    input [7:0] B,      // Divisor
    output reg valid,
    output reg [15:0] P // [15:8] = Cociente, [7:0] = Residuo
);
    // Registros para las etapas del pipeline
    reg [7:0] A_pipe [0:7];     // Dividendo en cada etapa
    reg [7:0] B_pipe [0:7];     // Divisor en cada etapa
    reg [7:0] Q_pipe [0:8];     // Cociente parcial
    reg [8:0] R_pipe [0:8];     // Residuo parcial (9 bits para comparación)
    reg valid_pipe [0:8];
    
    // DECLARAR LAS VARIABLES TEMPORALES AQUÍ (fuera del always)
    reg [8:0] R_shifted;
    reg [8:0] R_temp;
    
    integer i;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) begin
                A_pipe[i] <= 0;
                B_pipe[i] <= 0;
                Q_pipe[i] <= 0;
                R_pipe[i] <= 0;
                valid_pipe[i] <= 0;
            end
            Q_pipe[8] <= 0;
            R_pipe[8] <= 0;
            valid_pipe[8] <= 0;
            valid <= 0;
            P <= 0;
        end
        else begin
            // Salida del pipeline
            valid <= valid_pipe[8];
            P <= {Q_pipe[8], R_pipe[8][7:0]};
            
            // Propagar etapa 7 a etapa 8
            Q_pipe[8] <= Q_pipe[7];
            R_pipe[8] <= R_pipe[7];
            valid_pipe[8] <= valid_pipe[7];
            
            // Entrada al pipeline (Etapa 0)
            if (start) begin
                if (B == 0) begin
                    A_pipe[0] <= 0;
                    B_pipe[0] <= 0;
                    Q_pipe[0] <= 8'hFF;
                    R_pipe[0] <= 9'h1FF;
                    valid_pipe[0] <= 1;
                    $display("ERROR: División por cero detectada!");
                end else begin
                    A_pipe[0] <= A;
                    B_pipe[0] <= B;
                    Q_pipe[0] <= 0;
                    R_pipe[0] <= 0;
                    valid_pipe[0] <= 1;
                    $display("Pipeline Div: A=%d, B=%d", A, B);
                end
            end else begin
                valid_pipe[0] <= 0;
            end
            
            // Etapas del pipeline (1-7): Shift-and-Subtract
            for (i = 1; i <= 7; i = i + 1) begin
                if (valid_pipe[i-1]) begin
                    A_pipe[i] <= A_pipe[i-1];
                    B_pipe[i] <= B_pipe[i-1];
                    
                    // Shift-and-Subtract Algorithm
                    // 1. Desplazar residuo e introducir el siguiente bit de A
                    R_shifted = {R_pipe[i-1][7:0], A_pipe[i-1][8-i]};
                    
                    // 2. Intentar restar el divisor
                    R_temp = R_shifted - {1'b0, B_pipe[i-1]};
                    
                    // 3. Si cabe (sin signo negativo), actualizar
                    if (R_temp[8] == 0) begin
                        R_pipe[i] <= R_temp;
                        Q_pipe[i] <= {Q_pipe[i-1][6:0], 1'b1};
                    end else begin
                        R_pipe[i] <= R_shifted;
                        Q_pipe[i] <= {Q_pipe[i-1][6:0], 1'b0};
                    end
                    
                    if (i == 7) begin
                        $display("Pipeline Div: Etapa final, Q=%d, R=%d", 
                                Q_pipe[i][7:0], R_pipe[i][7:0]);
                    end
                end else begin
                    Q_pipe[i] <= Q_pipe[i-1];
                    R_pipe[i] <= R_pipe[i-1];
                    A_pipe[i] <= A_pipe[i-1];
                    B_pipe[i] <= B_pipe[i-1];
                end
                valid_pipe[i] <= valid_pipe[i-1];
            end
        end
    end
endmodule