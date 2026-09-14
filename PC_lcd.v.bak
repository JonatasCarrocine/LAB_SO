module PC_lcd (clock, isHalt, resetCPU, pcNext, pcAtual ,halted
	,quantum_expired
   ,preemption_mode
   ,context_pc_in
   ,context_restore);
	input wire clock;
	input wire isHalt;
	input wire resetCPU;
	input wire [31:0] pcNext;
	
	
	input wire quantum_expired;
    input wire preemption_mode;
    input wire [31:0] context_pc_in;  // PC restaurado do contexto
    input wire context_restore;        // Sinal para restaurar contexto
		
	output reg [31:0] pcAtual;
	
	// estado permanente do halt
	output reg halted;

	initial begin
		pcAtual = 32'b0;
		halted = 1'b0;
	end

	always @(posedge clock or posedge resetCPU) begin
		if(resetCPU) begin
			pcAtual <= 32'b0;
			halted <=1'b0;
		end else begin
			// quando vier o HALT, trave o estado
			if (isHalt)
				halted <= 1'b1;

			// só incrementa PC se não estiver halted
			if (!halted) begin
				if (preemption_mode && context_restore) begin
					// Restaura PC do contexto salvo
               pcAtual <= context_pc_in;
				end
				else if (preemption_mode && quantum_expired) begin
					// Mantém PC atual (será salvo pelo escalonador)
               pcAtual <= pcAtual;
				end
				else begin
					//Incrementa PC normalmente
					pcAtual <= pcNext;
				end
			end
		end
	end
			
endmodule