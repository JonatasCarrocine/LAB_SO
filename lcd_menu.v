//=======================================================
//  Módulo: LCD Menu Interativo - DE2-115
//=======================================================
module lcd_menu (
    input  wire CLOCK_50,          // clock de 50 MHz
    input  wire [3:0] SW,         // switches do kit
    output wire [7:0] LCD_DATA,    // barramento de dados
    output wire LCD_EN,            // enable
    output wire LCD_RS,            // register select
    output wire LCD_RW,            // read/write
    output wire LCD_ON,            // ligar LCD
    output wire LCD_BLON           // backlight
);

//-------------------------------------------------------
// Ativa LCD e backlight
//-------------------------------------------------------
assign LCD_ON   = 1'b1;
assign LCD_BLON = 1'b1;
assign LCD_RW   = 1'b0; // sempre escrever (write)

//-------------------------------------------------------
// Controle de tempo (mesmo estilo do seu Hello World)
//-------------------------------------------------------
reg [25:0] counter;
always @(posedge CLOCK_50)
    counter <= counter + 1;

wire enable_pulse = (counter == 26'd0);

//-------------------------------------------------------
// Mensagens fixas
//-------------------------------------------------------
reg [7:0] msg_linha1 [0:15];
reg [7:0] msg_linha2 [0:15];
reg [7:0] msg_prog   [0:15];
reg [7:0] msg_exec   [0:15];

initial begin
    // Tela principal
    msg_linha1[0]  = "1"; msg_linha1[1]  = " "; msg_linha1[2]  = "-";
    msg_linha1[3]  = " "; msg_linha1[4]  = "N"; msg_linha1[5]  = " ";
    msg_linha1[6]  = "p"; msg_linha1[7]  = "r"; msg_linha1[8]  = "e";
    msg_linha1[9]  = "m"; msg_linha1[10] = " "; msg_linha1[11] = " ";
    msg_linha1[12] = " "; msg_linha1[13] = " "; msg_linha1[14] = " "; msg_linha1[15] = " ";

    msg_linha2[0]  = "2"; msg_linha2[1]  = " "; msg_linha2[2]  = "-";
    msg_linha2[3]  = " "; msg_linha2[4]  = "P"; msg_linha2[5]  = "r";
    msg_linha2[6]  = "e"; msg_linha2[7]  = "m"; msg_linha2[8]  = " ";
    msg_linha2[9]  = " "; msg_linha2[10] = " "; msg_linha2[11] = " ";
    msg_linha2[12] = " "; msg_linha2[13] = " "; msg_linha2[14] = " "; msg_linha2[15] = " ";

    // Tela "Escolha um programa"
    msg_prog[0]  = "E"; msg_prog[1]  = "s"; msg_prog[2]  = "c"; msg_prog[3]  = "o";
    msg_prog[4]  = "l"; msg_prog[5]  = "h"; msg_prog[6]  = "a"; msg_prog[7]  = " ";
    msg_prog[8]  = "u"; msg_prog[9]  = "m"; msg_prog[10] = " ";
    msg_prog[11] = "p"; msg_prog[12] = "r"; msg_prog[13] = "o";
    msg_prog[14] = "g"; msg_prog[15] = "r";

    // Tela "Executando"
    msg_exec[0]  = "E"; msg_exec[1]  = "x"; msg_exec[2]  = "e"; msg_exec[3]  = "c";
    msg_exec[4]  = "u"; msg_exec[5]  = "t"; msg_exec[6]  = "a"; msg_exec[7]  = "n";
    msg_exec[8]  = "d"; msg_exec[9]  = "o"; msg_exec[10] = " "; msg_exec[11] = " ";
    msg_exec[12] = " "; msg_exec[13] = " "; msg_exec[14] = " "; msg_exec[15] = " ";
end

//-------------------------------------------------------
// Máquina de estados (controla o display)
//-------------------------------------------------------
reg [5:0] state = 0;
reg [3:0] index = 0;
reg [7:0] lcd_data_reg;
reg       lcd_rs_reg;
reg       lcd_en_reg;
assign LCD_DATA = lcd_data_reg;
assign LCD_RS   = lcd_rs_reg;
assign LCD_EN   = lcd_en_reg;

always @(posedge CLOCK_50) begin
    if (enable_pulse) begin
        case (state)
            //---------------------------------------------------
            // Inicialização do LCD
            //---------------------------------------------------
            0: begin lcd_data_reg <= 8'h38; lcd_rs_reg <= 0; lcd_en_reg <= 1; state <= 1; end
            1: begin lcd_en_reg <= 0; state <= 2; end
            2: begin lcd_data_reg <= 8'h0C; lcd_rs_reg <= 0; lcd_en_reg <= 1; state <= 3; end
            3: begin lcd_en_reg <= 0; state <= 4; end
            4: begin lcd_data_reg <= 8'h01; lcd_rs_reg <= 0; lcd_en_reg <= 1; state <= 5; end
            5: begin lcd_en_reg <= 0; state <= 10; index <= 0; end

            //---------------------------------------------------
            // Escrita das telas conforme switches
            //---------------------------------------------------
            // Tela principal
            10: begin
                lcd_rs_reg <= 1;
                lcd_data_reg <= msg_linha1[index];
                lcd_en_reg <= 1;
                state <= 11;
            end
            11: begin
                lcd_en_reg <= 0;
                if (index < 15) index <= index + 1;
                else begin
                    state <= 12; index <= 0;
                end
            end
            12: begin
                lcd_rs_reg <= 0; lcd_data_reg <= 8'hC0; lcd_en_reg <= 1; state <= 13;
            end
            13: begin
                lcd_en_reg <= 0; state <= 14;
            end
            14: begin
                lcd_rs_reg <= 1;
                lcd_data_reg <= msg_linha2[index];
                lcd_en_reg <= 1;
                state <= 15;
            end
            15: begin
                lcd_en_reg <= 0;
                if (index < 15) index <= index + 1;
                else begin
                    state <= 20;
                    index <= 0;
                end
            end

            //---------------------------------------------------
            // Troca de telas conforme SW
            //---------------------------------------------------
            20: begin
                if (SW[1]) state <= 30;
                else if (SW[2]) state <= 40;
                else state <= 10; // mantém menu
            end

            // Tela "Escolha um programa"
            30: begin
                lcd_rs_reg <= 0; lcd_data_reg <= 8'h01; lcd_en_reg <= 1; state <= 31;
            end
            31: begin
                lcd_en_reg <= 0; lcd_rs_reg <= 1; lcd_data_reg <= msg_prog[index]; state <= 32;
            end
            32: begin
                lcd_en_reg <= 1; state <= 33;
            end
            33: begin
                lcd_en_reg <= 0;
                if (index < 15) index <= index + 1;
                else begin
                    index <= 0;
                    if (~SW[1]) state <= 10; // volta se soltar SW1
                end
            end

            // Tela "Executando"
            40: begin
                lcd_rs_reg <= 0; lcd_data_reg <= 8'h01; lcd_en_reg <= 1; state <= 41;
            end
            41: begin
                lcd_en_reg <= 0; lcd_rs_reg <= 1; lcd_data_reg <= msg_exec[index]; state <= 42;
            end
            42: begin
                lcd_en_reg <= 1; state <= 43;
            end
            43: begin
                lcd_en_reg <= 0;
                if (index < 15) index <= index + 1;
                else begin
                    index <= 0;
                    if (~SW[2]) state <= 10; // volta se soltar SW2
                end
            end
        endcase
    end
end

endmodule
