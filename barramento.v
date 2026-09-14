module barramento (in, inBotao, saida);
	input [13:0] in;
	input [3:0] inBotao;
	
	output [13:0] saida;
	reg [13:0] valor;
	
	always @(in, inBotao) begin
		case (inBotao[3:0])
			4'b0001: valor = in;
			4'b0010: valor = in;
			default valor = 0;
		endcase
	end
	
	assign saida = valor;
endmodule