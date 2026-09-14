//=======================================================
//  Controlador de LCD: escreve mensagens completas
//=======================================================
module lcd_display(
    input  wire clk,
    input  wire [1:0] state,
    input  wire [1:0] prev_state,
    output reg [7:0] lcd_data,
    output reg lcd_en,
    output reg lcd_rs
);

    reg [7:0] message [0:31];
    reg [5:0] i;
    reg [3:0] step = 0;

    always @(posedge clk) begin
        lcd_en <= 0;

        // Reinicia a escrita ao mudar de tela
        if (state != prev_state)
            step <= 0;

        case (step)
            // -----------------------------
            // Inicialização básica
            // -----------------------------
            0: begin
                lcd_rs <= 0; lcd_data <= 8'h38; lcd_en <= 1; step <= 1;
            end
            1: begin
                lcd_rs <= 0; lcd_data <= 8'h0C; lcd_en <= 1; step <= 2;
            end
            2: begin
                lcd_rs <= 0; lcd_data <= 8'h01; lcd_en <= 1; step <= 3;
            end

            // -----------------------------
            // Define mensagem da tela
            // -----------------------------
            3: begin
                case (state)
                    // Tela principal
                    2'd0: begin
                        // Linha 1
                        message[0]  = "1"; message[1]  = " "; message[2]  = "-"; message[3]  = " ";
                        message[4]  = "N"; message[5]  = " "; message[6]  = "p"; message[7]  = "r";
                        message[8]  = "e"; message[9]  = "m"; message[10] = " "; message[11] = " "; 
                        message[12] = " "; message[13] = " "; message[14] = " "; message[15] = " ";
                        // Linha 2
                        message[16] = "2"; message[17] = " "; message[18] = "-"; message[19] = " ";
                        message[20] = "P"; message[21] = "r"; message[22] = "e"; message[23] = "m";
                        message[24] = " "; message[25] = " "; message[26] = " "; message[27] = " ";
                    end

                    // Tela "Escolha um programa"
                    2'd1: begin
                        message[0]  = "E"; message[1]  = "s"; message[2]  = "c"; message[3]  = "o";
                        message[4]  = "l"; message[5]  = "h"; message[6]  = "a"; message[7]  = " ";
                        message[8]  = "u"; message[9]  = "m"; message[10] = " "; message[11] = "p";
                        message[12] = "r"; message[13] = "o"; message[14] = "g"; message[15] = "r";
                        message[16] = "a"; message[17] = "m"; message[18] = "a"; message[19] = " ";
                    end

                    // Tela "Executando"
                    2'd2: begin
                        message[0]  = "E"; message[1]  = "x"; message[2]  = "e"; message[3]  = "c";
                        message[4]  = "u"; message[5]  = "t"; message[6]  = "a"; message[7]  = "n";
                        message[8]  = "d"; message[9]  = "o"; message[10] = " "; message[11] = " ";
                    end
                endcase
                i <= 0;
                step <= 4;
            end

            // -----------------------------
            // Escreve primeira linha
            // -----------------------------
            4: begin
                lcd_rs <= 1;
                lcd_data <= message[i];
                lcd_en <= 1;
                i <= i + 1;
                if (i == 15) step <= 5; // terminou linha 1
            end

            // -----------------------------
            // Move cursor para linha 2
            // -----------------------------
            5: begin
                lcd_rs <= 0;
                lcd_data <= 8'hC0; // endereço linha 2
                lcd_en <= 1;
                if (state == 0 || state == 1) step <= 6;
                else step <= 7; // EXECUTANDO só 1 linha
            end

            // -----------------------------
            // Escreve segunda linha (se houver)
            // -----------------------------
            6: begin
                lcd_rs <= 1;
                lcd_data <= message[i];
                lcd_en <= 1;
                i <= i + 1;
                if (i == 31) step <= 7;
            end

            // -----------------------------
            // Fim: mantém a tela estática
            // -----------------------------
            7: begin
                lcd_en <= 0;
                step <= 7;
            end
        endcase
    end
endmodule