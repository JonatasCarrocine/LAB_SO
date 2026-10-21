// PC para executar vários programas em sequência, SEM preempção.
//
// É o PC_com_IN com uma mudança: no HALT, em vez de travar a CPU, ele
// passa para o próximo programa (programa + 1) e volta o PC para 0.
// Só depois do HALT do último programa a CPU para de vez (halted = 1).
//
// resetUC vai no resetCPU da unidade de controle: além do reset normal, ele
// pulsa por um ciclo na troca de programa para limpar o "halted" que a
// unidade de controle guarda quando vê um HALT.
module PC_multi #(
	parameter NUM_PROGS = 10
) (clock, isHalt, resetCPU, pcNext, cpu_en, pcAtual, halted, programa, resetUC);
	input wire clock;
	input wire isHalt;
	input wire resetCPU;
	input wire [31:0] pcNext;
	input wire cpu_en;

	output reg [31:0] pcAtual;
	output reg halted;            // 1 = todos os programas terminaram
	output reg [3:0] programa;    // programa em execução: 1, 2, ..., NUM_PROGS
	output wire resetUC;

	reg trocouPrograma;

	initial begin
		pcAtual = 32'b0;
		halted = 1'b0;
		programa = 4'd1;
		trocouPrograma = 1'b0;
	end

	assign resetUC = resetCPU | trocouPrograma;

	always @(posedge clock or posedge resetCPU) begin
		if (resetCPU) begin
			pcAtual <= 32'b0;
			halted <= 1'b0;
			programa <= 4'd1;
			trocouPrograma <= 1'b0;
		end else begin
			trocouPrograma <= 1'b0;

			if (halted)
				pcAtual <= pcAtual;               // acabou tudo: mantém
			else if (isHalt) begin
				if (programa == NUM_PROGS)
					halted <= 1'b1;               // HALT do último programa
				else begin
					programa <= programa + 4'd1;  // HALT: próximo programa
					pcAtual <= 32'b0;             // começa do endereço 0
					trocouPrograma <= 1'b1;
				end
			end
			else if (cpu_en)
				pcAtual <= pcNext;
			else
				pcAtual <= pcAtual;               // esperando o IN
		end
	end

endmodule
