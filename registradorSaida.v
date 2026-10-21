// Guarda o valor do último OUT para ele ficar parado no display.
//
// Antes o display mostrava DadosUm direto, que muda a cada instrução: o
// resultado só aparecia durante o ciclo do OUT. Com 10 programas rodando em
// sequência, o resultado de cada um fica no display até o próximo OUT.
module registradorSaida (clock, reset, isOut, dado, valor);
	input wire clock;
	input wire reset;
	input wire isOut;
	input wire [13:0] dado;      // DadosUm[13..0], o registrador do OUT

	output reg [13:0] valor;

	initial valor = 14'b0;

	always @(posedge clock or posedge reset) begin
		if (reset)
			valor <= 14'b0;
		else if (isOut)
			valor <= dado;
	end

endmodule
