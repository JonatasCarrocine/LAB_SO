//=======================================================
//  Módulo: LCD Hello - DE2-115
//=======================================================
module lcd_hello (
    input  wire CLOCK_50,          // clock de 50 MHz
	 
	 input wire [3:0] SW,
	 input wire [1:0] KEY,
	 
    output wire [7:0] LCD_DATA,    // barramento de dados
    output wire LCD_EN,            // enable
    output wire LCD_RS,            // register select
    output wire LCD_RW,            // read/write
    output wire LCD_ON,            // ligar LCD
    output wire LCD_BLON,           // backlight
	 output reg EXEC_PROG,
	 output reg [3:0] LED_PROG
);

//-------------------------------------------------------
// Ativa LCD e backlight
//-------------------------------------------------------
assign LCD_ON   = 1'b1;
assign LCD_BLON = 1'b1;
assign LCD_RW   = 1'b0;  // sempre escrever (write)

//-------------------------------------------------------
// Mensagem a exibir
//-------------------------------------------------------
reg [7:0] message [0:11];
reg [7:0] msg2 [0:15];
reg [7:0] msg3 [0:12];
reg [7:0] msg4 [0:10];
reg [7:0] msg5 [0:13];
reg [7:0] msg6 [0:15];

initial begin
	 // ====== INICIO TELA 1 ========
	 message[0]  = " ";    message[1]  = " ";	 message[2]  = " ";    message[3]  = "L";
    message[4]  = "a";    message[5]  = "b";    message[6]  = " ";    message[7]  = "d";
    message[8]  = "e";    message[9]  = " ";    message[10]  = "S";	 message[11]  = "O";
	 
	 msg2[0] = " ";	 msg2[1] = " ";	 msg2[2] = " ";	 msg2[3] = "J";    msg2[4] = "o";
    msg2[5] = "n";    msg2[6] = "a";    msg2[7] = "t";	 msg2[8] = "a";	 msg2[9] = "s";
	 msg2[10] = " ";	 msg2[11] = "-";	 msg2[12] = ">";	 msg2[13] = "S";	 msg2[14] = "W";
	 msg2[15] = "0";
	 
	 // ====== FIM TELA 1 ========
	 
	 // ====== INICIO TELA 2 ========
    msg3[0] = " ";    msg3[1] = " ";    msg3[2] = "1";    msg3[3] = " ";    msg3[4] = "-";
    msg3[5] = " ";    msg3[6] = "N";    msg3[7] = " ";    msg3[8] = "P";    msg3[9] = "R";
    msg3[10] = "E";	 msg3[11] = "M";	 msg3[12] = "P";
	 
    msg4[0] = " ";    msg4[1] = " ";    msg4[2] = "2";    msg4[3] = " ";    msg4[4] = "-";
    msg4[5] = " ";    msg4[6] = "P";    msg4[7] = "R";    msg4[8] = "E";    msg4[9] = "M";
    msg4[10] = "P";
	 
	 // ====== FIM TELA 2 ========
	 
	 // tela 3
    msg5[0] = "S";    msg5[1] = "e";    msg5[2] = "l";    msg5[3] = "e";    msg5[4] = "c";
    msg5[5] = "i";    msg5[6] = "o";    msg5[7] = "n";    msg5[8] = "e";    msg5[9] = " ";
    msg5[10] = "P"; 	 msg5[11] = "r";	msg5[12] = "o"; 	 msg5[13] = "g";
	 
	 // tela 4
    msg6[0] = "E";    msg6[1] = "x";    msg6[2] = "e";    msg6[3] = "c";    msg6[4] = "u";
    msg6[5] = "t";    msg6[6] = "a";    msg6[7] = "n";    msg6[8] = "d";    msg6[9] = "o";
    msg6[10] = " "; 	 msg6[11] = "P";	 msg6[12] = "r"; 	 msg6[13] = "o";   msg6[14] = "g";
	 msg6[15] = "s";
end

//-------------------------------------------------------
// Controle de tempo e escrita
//-------------------------------------------------------
reg [20:0] counter;
always @(posedge CLOCK_50)
    counter <= counter + 1;

wire enable_pulse = (counter == 21'd0);


//-------------------------------------------------------
// Detecta borda de descida do botão KEY[0]
//-------------------------------------------------------
//reg key0_prev;
//wire key0_pressed = (key0_prev == 1'b1 && KEY[0] == 1'b0);
//always @(posedge CLOCK_50)
//    key0_prev <= KEY[0];


//-------------------------------------------------------
// Máquina de estados simples
//-------------------------------------------------------
reg [6:0] state = 0;
reg [4:0] char_index = 0; // índice do caractere atual
reg [7:0] lcd_data_reg;
reg       lcd_rs_reg;
reg       lcd_en_reg;

assign LCD_DATA = lcd_data_reg;
assign LCD_RS   = lcd_rs_reg;
assign LCD_EN   = lcd_en_reg;

always @(posedge CLOCK_50) begin
    if (enable_pulse) begin
        case (state)
            0: begin
                lcd_data_reg <= 8'h38; // modo 8 bits, 2 linhas
                lcd_rs_reg   <= 0;
                lcd_en_reg   <= 1;
                state <= 1;
            end
            1: begin lcd_en_reg <= 0; state <= 2; end

            2: begin
                lcd_data_reg <= 8'h0C; // display ON
                lcd_rs_reg   <= 0; lcd_en_reg   <= 1;
                state <= 3;
            end
            3: begin lcd_en_reg <= 0; state <= 4; end

            4: begin
                lcd_data_reg <= 8'h01; // limpar display
                lcd_rs_reg   <= 0; lcd_en_reg   <= 1;
                state <= 5;
            end
            5: begin lcd_en_reg <= 0; char_index <= 0; state <= 6; end

            6: begin
                lcd_data_reg <= message[char_index]; // primeiro caractere
                lcd_rs_reg   <= 1; lcd_en_reg   <= 1;
                state <= 7;
            end
				
            7: begin
                lcd_en_reg <= 0;
                // se terminou a mensagem, para
                if (char_index == 11)
                    state <= 8;  // estado "fim"
                else begin
                    char_index <= char_index + 1;
                    state <= 6;
                end
            end
				
				// ===== Mover para a 2ª linha - TELA 1 =====
            8: begin
                lcd_data_reg <= 8'hC0; // início da 2ª linha
                lcd_rs_reg   <= 0;
                lcd_en_reg   <= 1;
                state <= 9;
            end
            9: begin lcd_en_reg <= 0; char_index <= 0; state <= 10; end
				
				// ===== Escrever 2ª linha da TELA 1 =====
            10: begin
                lcd_data_reg <= msg2[char_index];
                lcd_rs_reg   <= 1;
                lcd_en_reg   <= 1;
                state <= 11;
            end
            11: begin
                lcd_en_reg <= 0;
                if (char_index == 15)
                    state <= 12; // fim
                else begin
                    char_index <= char_index + 1;
                    state <= 10;
                end
            end

            // --- Espera interação --- mensagem fixa
            12: begin
                lcd_en_reg <= 0;
                lcd_rs_reg <= 0;
                lcd_data_reg <= 8'h00;
					 if (SW[0] == 1 && KEY[0]==1)
							state <= 13; // troca de tela

            end

            // --- Limpa display ---
            13: begin
					lcd_data_reg <= 8'h01;
					lcd_rs_reg <= 0;
					lcd_en_reg <= 1;
					state <= 14;
				end
				
            14: begin
					lcd_en_reg <= 0;
					char_index <= 0;
					state <= 15;
				end

            // --- Escreve "1 - N PREMP" - tela 2 ---
            15: begin
					lcd_data_reg <= msg3[char_index];
					lcd_rs_reg <= 1;
					lcd_en_reg <= 1;
					state <= 16;
				end
            16: begin
                lcd_en_reg <= 0;
                if (char_index == 12) state <= 17;
                else begin char_index <= char_index + 1; state <= 15; end
            end
				
				
				// ===== Mover para a 2ª linha da tela 2 =====
            17: begin
                lcd_data_reg <= 8'hC0; // início da 2ª linha
                lcd_rs_reg   <= 0; lcd_en_reg   <= 1; state <= 18;
            end
            18: begin lcd_en_reg <= 0; char_index <= 0; state <= 19; end
				
				// ===== Escrever "2 - PREMP" =====
            19: begin
                lcd_data_reg <= msg4[char_index];
                lcd_rs_reg   <= 1;
                lcd_en_reg   <= 1;
                state <= 20;
            end
            20: begin
                lcd_en_reg <= 0;
                if (char_index == 10)
                    state <= 21; // fim tela 2
                else begin
                    char_index <= char_index + 1;
                    state <= 19;
                end
            end
				
            // --- Tela final 2 ---
            21: begin
                lcd_en_reg <= 0;
                lcd_rs_reg <= 0;
                lcd_data_reg <= 8'h00;
					 if (SW[0] == 1 && KEY[0]==1)
							state <= 22; // troca de tela
					 if (SW[1] == 1 && KEY[0]==1)
							state <= 27; // troca de tela
            end
				
				// --- Limpa display ---
            22: begin
					lcd_data_reg <= 8'h01;
					lcd_rs_reg <= 0; lcd_en_reg <= 1;
					state <= 23;
				end
				
            23: begin
					lcd_en_reg <= 0; char_index <= 0;
					state <= 24;
				end

            // --- Escreve "Selecionar prog" - tela 3 ---
            24: begin
					lcd_data_reg <= msg5[char_index];
					lcd_rs_reg <= 1;
					lcd_en_reg <= 1;
					state <= 25;
				end
				
            25: begin
                lcd_en_reg <= 0;
                if (char_index == 13) state <= 26; //fim
                else begin char_index <= char_index + 1; state <= 24; end
            end
				
				// --- Tela final 3 ---
            26: begin
                lcd_en_reg <= 0;
                lcd_rs_reg <= 0;
                lcd_data_reg <= 8'h00;
					 if (SW[0] == 1 && KEY[0]==1) begin
							EXEC_PROG <= 1; //Envia sinal para a memória
							LED_PROG <= 4'b0001;
					 end
					 if (SW[3] == 1 && KEY[0]==1)
							state <= 13; // troca para tela 2 (selecao de tipo de execucao)
            end
				
				// --- Limpa display para a tela 4 ---
            27: begin
					lcd_data_reg <= 8'h01;
					lcd_rs_reg <= 0; lcd_en_reg <= 1;
					state <= 28;
				end
				
            28: begin
					lcd_en_reg <= 0; char_index <= 0;
					state <= 29;
				end

            // --- Escreve "Executando progrs" - tela 4 ---
            29: begin
					lcd_data_reg <= msg6[char_index];
					lcd_rs_reg <= 1;
					lcd_en_reg <= 1;
					state <= 30;
				end
				
            30: begin
                lcd_en_reg <= 0;
                if (char_index == 15) state <= 31; //fim
                else begin char_index <= char_index + 1; state <= 29; end
            end
				
				// --- Tela final 3 ---
            31: begin
                lcd_en_reg <= 0;
                lcd_rs_reg <= 0;
                lcd_data_reg <= 8'h00;
					 if (SW[3] == 1 && KEY[0]==1)
							state <= 13; // troca para tela 2 (selecao de tipo de execucao)
            end

            default: state <= 0;
        endcase
    end
end

endmodule