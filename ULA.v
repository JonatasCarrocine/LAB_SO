module ULA (a, b, alu_control, resultado, zero);
	
	input [31:0] a, b;
	// operando 1 (ReadData1)
	// operando 2 (mux_alusrc)
	 
	input [3:0] alu_control; //controle de operacao
	
	output zero; // flag zero (para beq)
	output reg [31:0] resultado; //saida da ula
	
	
	always @ (*) begin
		case (alu_control)
			4'b0000: resultado = a & b;                     // AND
         4'b0001: resultado = a | b;                     // OR
         4'b0010: resultado = a + b;                     // ADD
			4'b0011: resultado = a * b;                     // MULT
			4'b0100: resultado = a / b;                     // DIV
         4'b0110: resultado = a - b;                     // SUB
         4'b0111: resultado = (a < b) ? 32'b1 : 32'b0;   // SLT
			4'b1000: resultado = a;               				// MOVE (pass-through: retorna a)
         4'b0101: resultado = (a > b) ? 32'b1 : 32'b0;   // SGT
         4'b1001: resultado = (a <= b) ? 32'b1 : 32'b0;  // SLE
         4'b1010: resultado = (a >= b) ? 32'b1 : 32'b0;  // SGE
         4'b1100: resultado = ~(a | b);                  // NOR
         default: resultado = 32'b0;                     // caso inválido
		endcase
	end
	
	// Zero flag: ativo se resultado for 0
   assign zero = (resultado == 32'b0);
endmodule