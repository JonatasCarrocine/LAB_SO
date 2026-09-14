module registradores(
	input clock,
	input isHalt, // << NOVO
	
	input [4:0] leituraUm, //rs
	input [4:0] leituraDois, //rt
	input [4:0] regEscrita, //rd (mux_regdst)
	input [31:0] escreveDado, //dado a escrever
	input escreveReg, // sinal de controle WriteEnable
	
	// NOVOS PARA A INSTRUÇÃO IN:
   input isIN,                 // sinal dizendo se a instrução atual é IN
   input [8:0] inData,        // valor digitado pelo usuário
	
	output [31:0] DadosUm,
	output [31:0] DadosDois
);
	
	reg [31:0] registradores [31:0];
	
	// Leitura assíncrona
   assign DadosUm   = registradores[leituraUm];
   assign DadosDois = registradores[leituraDois];
	
	// Escrita síncrona
    always @(posedge clock) begin
        if (!isHalt && escreveReg && regEscrita != 0) begin
            if (isIN)
                registradores[regEscrita] <= inData;   // ← valor do usuário
            else
                registradores[regEscrita] <= escreveDado;
        end
    end
endmodule