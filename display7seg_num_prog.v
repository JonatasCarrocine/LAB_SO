module display7seg_num_prog (
    input  wire        clk,
    input  wire        reset,
    input  wire [1:0]  valor,       // valor de 0 a 99 (7 bits são suficientes)
    output reg  [6:0]  seg_unidade, // segmentos do display das unidades
    output reg  [6:0]  seg_dezena   // segmentos do display das dezenas
);

    // =====================================================
    // Conversão binário → decimal (unidade e dezena)
    // =====================================================
    reg [1:0] unidade, dezena;
    integer num;

    always @(*) begin
        num     = valor;
        unidade = num % 10;
        dezena  = num / 10;
    end

    // =====================================================
    // Função para converter dígito decimal em 7 segmentos
    // (catodo comum → '0' aceso = 0 apagado)
    // =====================================================
    function [6:0] bcdTo7seg;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0: bcdTo7seg = 7'b1000000;
                4'd1: bcdTo7seg = 7'b1111001;
                4'd2: bcdTo7seg = 7'b0100100;
                4'd3: bcdTo7seg = 7'b0110000;
                4'd4: bcdTo7seg = 7'b0011001;
                4'd5: bcdTo7seg = 7'b0010010;
                4'd6: bcdTo7seg = 7'b0000010;
                4'd7: bcdTo7seg = 7'b1111000;
                4'd8: bcdTo7seg = 7'b0000000;
                4'd9: bcdTo7seg = 7'b0010000;
                default: bcdTo7seg = 7'b1111111; // apagado
            endcase
        end
    endfunction

    // =====================================================
    // Geração das saídas
    // =====================================================
    always @(*) begin
        seg_unidade = bcdTo7seg(unidade);
        seg_dezena  = bcdTo7seg(dezena);
    end

endmodule
