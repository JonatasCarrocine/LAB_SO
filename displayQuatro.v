module displayQuatro (in, saidaUnidade, saidaDezena, saidaCentena, saidaMilhar);
	input [31:0]in;

	output [0:6]saidaUnidade;
	output [0:6]saidaDezena;
	output [0:6]saidaCentena;
	output [0:6]saidaMilhar;
	
	reg [6:0] segmentos;
	
	reg [3:0] unidade;
	reg [3:0] dezena;
	reg [3:0] centena;
	reg [3:0] milhar;
	
	always @(*)
	begin
		milhar = (in/1000) % 10; //Divide por mil, e obtem o resto
		centena = (in/100) % 10; //divide por cem, e obtem o resto
		dezena = (in/10) % 10; // divide por dez, e obtem o resto
		unidade = in % 10;
	end
	
	function [6:0] bcd7seg;
		input [3:0] bcd;
		case(bcd) //0 - acesso, 1 - apagado
			4'b0000: bcd7seg = 7'b0000001; //0
			4'b0001: bcd7seg = 7'b1001111; //1
			4'b0010: bcd7seg = 7'b0010010; //2
			4'b0011: bcd7seg = 7'b0000110; //3
			4'b0100: bcd7seg = 7'b1001100; //4
			4'b0101: bcd7seg = 7'b0100100; //5
			4'b0110: bcd7seg = 7'b0100000; //6
			4'b0111: bcd7seg = 7'b0001111; //7
			4'b1000: bcd7seg = 7'b0000000; //8
			4'b1001: bcd7seg = 7'b0000100; //9
			default: bcd7seg = 7'b1111111;
		endcase
	endfunction
	
	assign saidaMilhar = bcd7seg(milhar);
	assign saidaCentena = bcd7seg(centena);
	assign saidaDezena = bcd7seg(dezena);
	assign saidaUnidade = bcd7seg(unidade);
endmodule