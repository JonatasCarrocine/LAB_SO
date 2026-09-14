//=======================================================
//  Módulo: LCD Hello World - DE2-115
//=======================================================
module lcd_hello_world (
    input  wire CLOCK_50,          // clock de 50 MHz
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
assign LCD_RW   = 1'b0;  // sempre escrever (write)

//-------------------------------------------------------
// Mensagem a exibir
//-------------------------------------------------------
reg [7:0] message [0:10];
initial begin
    message[0]  = "H";
    message[1]  = "e";
    message[2]  = "l";
    message[3]  = "l";
    message[4]  = "o";
    message[5]  = " ";
    message[6]  = "W";
    message[7]  = "o";
    message[8]  = "r";
    message[9]  = "l";
    message[10] = "d";
end

//-------------------------------------------------------
// Controle de tempo e escrita
//-------------------------------------------------------
reg [25:0] counter;
always @(posedge CLOCK_50)
    counter <= counter + 1;

wire enable_pulse = (counter == 26'd0);

//-------------------------------------------------------
// Máquina de estados simples
//-------------------------------------------------------
reg [3:0] state = 0;
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
                lcd_rs_reg   <= 0;
                lcd_en_reg   <= 1;
                state <= 3;
            end
            3: begin lcd_en_reg <= 0; state <= 4; end

            4: begin
                lcd_data_reg <= 8'h01; // limpar display
                lcd_rs_reg   <= 0;
                lcd_en_reg   <= 1;
                state <= 5;
            end
            5: begin lcd_en_reg <= 0; state <= 6; end

            6: begin
                lcd_data_reg <= message[0]; // primeiro caractere
                lcd_rs_reg   <= 1;
                lcd_en_reg   <= 1;
                state <= 7;
            end
            7: begin
                lcd_en_reg <= 0;
                state <= 8;
            end

            8: begin
                // deslocar para o próximo caractere
                integer i;
                for (i = 0; i < 10; i = i + 1)
                    message[i] <= message[i+1];
                state <= 6;
            end

            default: state <= 6;
        endcase
    end
end

endmodule
