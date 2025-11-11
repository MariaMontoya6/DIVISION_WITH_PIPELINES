module division_pipe (
    input clk,
    input reset,
    input start,
    input [7:0] A,      // Dividendo
    input [7:0] B,      // Divisor
    output reg valid,
    output reg [15:0] P // [15:8] = Cociente, [7:0] = Residuo
);
    // Registros para las etapas del pipeline (0 a 7 = 8 etapas)
    reg [7:0] A_pipe [0:7];     // Dividendo en cada etapa
    reg [7:0] B_pipe [0:7];     // Divisor en cada etapa
    reg [7:0] Q_pipe [0:8];     // Cociente parcial (9 niveles: 0-8)
    reg [8:0] R_pipe [0:8];     // Residuo parcial (9 bits)
    reg valid_pipe [0:8];
    
    integer i;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset de todas las etapas
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
            // ====== ETAPA 0: Entrada al pipeline ======
            if (start) begin
                if (B == 0) begin
                    A_pipe[0] <= 0;
                    B_pipe[0] <= 0;
                    Q_pipe[0] <= 8'hFF;
                    R_pipe[0] <= 9'h1FF;
                    valid_pipe[0] <= 1;
                end else begin
                    A_pipe[0] <= A;
                    B_pipe[0] <= B;
                    Q_pipe[0] <= 0;
                    R_pipe[0] <= 0;
                    valid_pipe[0] <= 1;
                end
            end else begin
                A_pipe[0] <= 0;
                B_pipe[0] <= 0;
                Q_pipe[0] <= 0;
                R_pipe[0] <= 0;
                valid_pipe[0] <= 0;
            end
            
            // ====== ETAPAS 1-7: Shift-and-Subtract (DESENROLLADAS) ======
            // ETAPA 1: Procesa bit 7 (MSB)
            A_pipe[1] <= A_pipe[0];
            B_pipe[1] <= B_pipe[0];
            valid_pipe[1] <= valid_pipe[0];
            if (valid_pipe[0] && B_pipe[0] != 0) begin
                if ({R_pipe[0][7:0], A_pipe[0][7]} >= {1'b0, B_pipe[0]}) begin
                    R_pipe[1] <= {R_pipe[0][7:0], A_pipe[0][7]} - {1'b0, B_pipe[0]};
                    Q_pipe[1] <= {Q_pipe[0][6:0], 1'b1};
                end else begin
                    R_pipe[1] <= {R_pipe[0][7:0], A_pipe[0][7]};
                    Q_pipe[1] <= {Q_pipe[0][6:0], 1'b0};
                end
            end else begin
                R_pipe[1] <= R_pipe[0];
                Q_pipe[1] <= Q_pipe[0];
            end
            
            // ETAPA 2: Procesa bit 6
            A_pipe[2] <= A_pipe[1];
            B_pipe[2] <= B_pipe[1];
            valid_pipe[2] <= valid_pipe[1];
            if (valid_pipe[1] && B_pipe[1] != 0) begin
                if ({R_pipe[1][7:0], A_pipe[1][6]} >= {1'b0, B_pipe[1]}) begin
                    R_pipe[2] <= {R_pipe[1][7:0], A_pipe[1][6]} - {1'b0, B_pipe[1]};
                    Q_pipe[2] <= {Q_pipe[1][6:0], 1'b1};
                end else begin
                    R_pipe[2] <= {R_pipe[1][7:0], A_pipe[1][6]};
                    Q_pipe[2] <= {Q_pipe[1][6:0], 1'b0};
                end
            end else begin
                R_pipe[2] <= R_pipe[1];
                Q_pipe[2] <= Q_pipe[1];
            end
            
            // ETAPA 3: Procesa bit 5
            A_pipe[3] <= A_pipe[2];
            B_pipe[3] <= B_pipe[2];
            valid_pipe[3] <= valid_pipe[2];
            if (valid_pipe[2] && B_pipe[2] != 0) begin
                if ({R_pipe[2][7:0], A_pipe[2][5]} >= {1'b0, B_pipe[2]}) begin
                    R_pipe[3] <= {R_pipe[2][7:0], A_pipe[2][5]} - {1'b0, B_pipe[2]};
                    Q_pipe[3] <= {Q_pipe[2][6:0], 1'b1};
                end else begin
                    R_pipe[3] <= {R_pipe[2][7:0], A_pipe[2][5]};
                    Q_pipe[3] <= {Q_pipe[2][6:0], 1'b0};
                end
            end else begin
                R_pipe[3] <= R_pipe[2];
                Q_pipe[3] <= Q_pipe[2];
            end
            
            // ETAPA 4: Procesa bit 4
            A_pipe[4] <= A_pipe[3];
            B_pipe[4] <= B_pipe[3];
            valid_pipe[4] <= valid_pipe[3];
            if (valid_pipe[3] && B_pipe[3] != 0) begin
                if ({R_pipe[3][7:0], A_pipe[3][4]} >= {1'b0, B_pipe[3]}) begin
                    R_pipe[4] <= {R_pipe[3][7:0], A_pipe[3][4]} - {1'b0, B_pipe[3]};
                    Q_pipe[4] <= {Q_pipe[3][6:0], 1'b1};
                end else begin
                    R_pipe[4] <= {R_pipe[3][7:0], A_pipe[3][4]};
                    Q_pipe[4] <= {Q_pipe[3][6:0], 1'b0};
                end
            end else begin
                R_pipe[4] <= R_pipe[3];
                Q_pipe[4] <= Q_pipe[3];
            end
            
            // ETAPA 5: Procesa bit 3
            A_pipe[5] <= A_pipe[4];
            B_pipe[5] <= B_pipe[4];
            valid_pipe[5] <= valid_pipe[4];
            if (valid_pipe[4] && B_pipe[4] != 0) begin
                if ({R_pipe[4][7:0], A_pipe[4][3]} >= {1'b0, B_pipe[4]}) begin
                    R_pipe[5] <= {R_pipe[4][7:0], A_pipe[4][3]} - {1'b0, B_pipe[4]};
                    Q_pipe[5] <= {Q_pipe[4][6:0], 1'b1};
                end else begin
                    R_pipe[5] <= {R_pipe[4][7:0], A_pipe[4][3]};
                    Q_pipe[5] <= {Q_pipe[4][6:0], 1'b0};
                end
            end else begin
                R_pipe[5] <= R_pipe[4];
                Q_pipe[5] <= Q_pipe[4];
            end
            
            // ETAPA 6: Procesa bit 2
            A_pipe[6] <= A_pipe[5];
            B_pipe[6] <= B_pipe[5];
            valid_pipe[6] <= valid_pipe[5];
            if (valid_pipe[5] && B_pipe[5] != 0) begin
                if ({R_pipe[5][7:0], A_pipe[5][2]} >= {1'b0, B_pipe[5]}) begin
                    R_pipe[6] <= {R_pipe[5][7:0], A_pipe[5][2]} - {1'b0, B_pipe[5]};
                    Q_pipe[6] <= {Q_pipe[5][6:0], 1'b1};
                end else begin
                    R_pipe[6] <= {R_pipe[5][7:0], A_pipe[5][2]};
                    Q_pipe[6] <= {Q_pipe[5][6:0], 1'b0};
                end
            end else begin
                R_pipe[6] <= R_pipe[5];
                Q_pipe[6] <= Q_pipe[5];
            end
            
            // ETAPA 7: Procesa bit 1
            A_pipe[7] <= A_pipe[6];
            B_pipe[7] <= B_pipe[6];
            valid_pipe[7] <= valid_pipe[6];
            if (valid_pipe[6] && B_pipe[6] != 0) begin
                if ({R_pipe[6][7:0], A_pipe[6][1]} >= {1'b0, B_pipe[6]}) begin
                    R_pipe[7] <= {R_pipe[6][7:0], A_pipe[6][1]} - {1'b0, B_pipe[6]};
                    Q_pipe[7] <= {Q_pipe[6][6:0], 1'b1};
                end else begin
                    R_pipe[7] <= {R_pipe[6][7:0], A_pipe[6][1]};
                    Q_pipe[7] <= {Q_pipe[6][6:0], 1'b0};
                end
            end else begin
                R_pipe[7] <= R_pipe[6];
                Q_pipe[7] <= Q_pipe[6];
            end
            
            // ====== ETAPA 8: Procesa bit 0 (LSB) y salida ======
            valid_pipe[8] <= valid_pipe[7];
            if (valid_pipe[7] && B_pipe[7] != 0) begin
                if ({R_pipe[7][7:0], A_pipe[7][0]} >= {1'b0, B_pipe[7]}) begin
                    R_pipe[8] <= {R_pipe[7][7:0], A_pipe[7][0]} - {1'b0, B_pipe[7]};
                    Q_pipe[8] <= {Q_pipe[7][6:0], 1'b1};
                end else begin
                    R_pipe[8] <= {R_pipe[7][7:0], A_pipe[7][0]};
                    Q_pipe[8] <= {Q_pipe[7][6:0], 1'b0};
                end
            end else begin
                R_pipe[8] <= R_pipe[7];
                Q_pipe[8] <= Q_pipe[7];
            end
            
            // ====== SALIDA FINAL ======
            valid <= valid_pipe[8];
            P <= {Q_pipe[8], R_pipe[8][7:0]};
        end
    end
endmodule