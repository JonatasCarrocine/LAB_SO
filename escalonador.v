module escalonador (
	input wire clock,
	input wire reset,
	input wire enable,          // Habilita preempção
	input wire [1:0] prog_sel,  // Programa atual selecionado
	output reg quantum_expired, // Indica que quantum expirou
	output reg [1:0] next_prog, // Próximo programa a executar
	output reg prog_load_en     // Novo: sinal para carregar programa
);

	parameter QUANTUM = 10;  // Quantum de 10 ciclos
	
	reg [3:0] cycle_counter;  // Contador de ciclos (0-15)
   reg [1:0] current_prog;   // Programa em execução
	
	reg preempt_enabled_prev;  // Rastreia se preempção estava ativa antes
	wire [1:0] next_prog_calc; // Próximo programa (combinatório)
   
	initial begin
		cycle_counter = 4'b0;
		current_prog = 2'b00;
		next_prog = 2'b00;
		quantum_expired = 1'b0;
		prog_load_en = 1'b0;
		preempt_enabled_prev = 1'b0;
	end
	
	// Lógica combinatória para calcular o próximo programa
	assign next_prog_calc = (current_prog == 2'b00) ? 2'b01 :
	                         (current_prog == 2'b01) ? 2'b10 :
	                         (current_prog == 2'b10) ? 2'b11 :
	                         2'b00;
	
	always @(posedge clock or posedge reset) begin
		if(reset) begin
			cycle_counter <= 0;
			current_prog <= 0;
			next_prog <= 2'b00;
			quantum_expired <= 0;
			prog_load_en <= 1'b0;
			preempt_enabled_prev <= 1'b0;
		end
		else if (enable) begin
			// Se preempção foi habilitada (transição 0→1), reseta o contador
			if (!preempt_enabled_prev) begin
				cycle_counter <= 4'b0;
				quantum_expired <= 1'b0;
				prog_load_en <= 1'b0;
			end
			// Verifica se quantum expirou
			else if (cycle_counter >= (QUANTUM - 1)) begin
				quantum_expired <= 1'b1;
				prog_load_en <= 1'b1;      // Sinaliza para carregar programa
				
				// Muda para o próximo programa
				current_prog <= next_prog_calc;
				next_prog <= next_prog_calc;
				cycle_counter <= 4'b0;
			end
			else begin
				// Incrementa contador de ciclos
				cycle_counter <= cycle_counter + 1;
				quantum_expired <= 1'b0;
				prog_load_en <= 1'b0;       // Desativa durante execução normal
			end
			
			// Atualiza rastreamento de enable
			preempt_enabled_prev <= enable;
		end
      else begin
			// Preempção desabilitada - Modo manual
			if (prog_sel != current_prog) begin
				// Novo programa selecionado manualmente
				quantum_expired <= 1'b0;
				prog_load_en <= 1'b1;       // Sinaliza carregamento
				next_prog <= prog_sel;
				current_prog <= prog_sel;
				cycle_counter <= 4'b0;
			end
			else begin
				quantum_expired <= 1'b0;
				prog_load_en <= 1'b0;       // Desativa se mesmo programa
				next_prog <= prog_sel;
			end
			
			// Atualiza rastreamento de enable
			preempt_enabled_prev <= enable;
      end
    end

endmodule