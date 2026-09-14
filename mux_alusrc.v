module mux_alusrc(readDataDois,immExt,aluSrc,aluInDois);
	input wire [31:0] readDataDois; //valor de rt (registrador)
	input wire [31:0] immExt; //imediato extendido
	input wire aluSrc; //sinal de controle
	output wire [31:0] aluInDois; //saida para a ULA

   // Se ALUSrc = 0 → pega valor do registrador (rt)
   // Se ALUSrc = 1 → pega imediato estendido
   assign aluInDois = (aluSrc) ? immExt : readDataDois;

endmodule