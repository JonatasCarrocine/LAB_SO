module escalonador_TESTE (
	 input  wire       clock,
    input  wire       reset,
    input  wire       enable,          // Habilita preempção
    input  wire [1:0] prog_sel,        // Seleção manual
	 
	 input wire cpu_stall, //Interromper quando usuario entra um valor

    output reg        quantum_expired,
    output reg [1:0]  current_prog,
    output reg [1:0]  next_prog,
    output reg        prog_load_en,
	 
	 output wire [31:0] prog_base_addr,   // <-- NOVO
	 
	 //DEBUG
	 output wire [3:0] dbg_cycle_counter, 
	 output wire dbg_quantum_stage
);

	parameter QUANTUM = 10;  // Quantum de 10 ciclos
	
	reg [3:0] cycle_counter;  // Contador de ciclos (0-15)
	reg preempt_enabled_prev;  // Rastreia se preempção estava ativa antes
	reg quantum_stage; // NOVO: mantém pulso por 2 ciclos
 
	
	// Round-robin simples (2 programas)
   wire [1:0] next_prog_calc =
        (current_prog == 2'b00) ? 2'b01 :
		  (current_prog == 2'b01) ? 2'b10 :
                                 2'b01;
	
	// -----------------------------
   // TABELA DE BASE DOS PROGRAMAS
   // -----------------------------
   reg [31:0] prog_base_table [0:3];

   initial begin
      prog_base_table[1] = 32'd100;    // Programa 0 → mem[0..]
      prog_base_table[2] = 32'd200;  // Programa 1 → mem[100..]
      //prog_base_table[2] = 32'd200;
      //prog_base_table[3] = 32'd300;
   end
	
	// Base do programa ATUAL (combinacional)
   assign prog_base_addr = prog_base_table[current_prog];
	
	//DEBUG
   assign dbg_cycle_counter = cycle_counter;
   assign dbg_quantum_stage = quantum_stage;
   
	initial begin
		cycle_counter = 4'b0000;
		current_prog = 2'b00;
		next_prog = 2'b00;
		quantum_expired = 1'b0;
		prog_load_en = 1'b0;
		preempt_enabled_prev = 1'b0;
	end
	
	always @(posedge clock or posedge reset) begin
		if(reset) begin
			cycle_counter <= 4'b0000;
			current_prog <= 2'b00;
			next_prog <= 2'b00;
			quantum_expired <= 1'b0;
			prog_load_en <= 1'b0;
			preempt_enabled_prev <= 1'b0;
			quantum_stage <= 1'b0; // NOVO
		end
		else if (cpu_stall) begin
			quantum_expired <= 1'b0;
			cycle_counter   <= cycle_counter; // congela
		end
		else if (enable) begin
			prog_load_en <= 1'b0; // nunca em preempção
			
			// Se preempção foi habilitada (transição 0→1), reseta o contador
			if (!preempt_enabled_prev) begin
            cycle_counter <= 4'b0001;
            quantum_expired <= 1'b0;
				quantum_stage <= 1'b0;
				preempt_enabled_prev <= 1'b1;
         end
			// Verifica se quantum expirou
			else if (cycle_counter == (QUANTUM - 1) && !quantum_stage) begin
				quantum_expired <= 1'b1;
				// IMPORTANTE:
            // current_prog ainda é o antigo nesse ciclo
				prog_load_en    <= 1'b1;
            next_prog <= next_prog_calc;
            cycle_counter <= 4'b0000;
				quantum_stage <= 1'b1; // Mantém pulso
			end
			// Segundo ciclo do pulso
         else if (quantum_stage) begin
            quantum_expired <= 1'b1; // Mantém alto
            quantum_stage <= 1'b0; // Desliga no próximo
            current_prog <= next_prog; // Atualiza current_prog
         end
			else begin
				// Incrementa contador de ciclos
				cycle_counter <= cycle_counter + 1;
				quantum_expired <= 1'b0;
			end
		end
      else begin
         // Modo manual
         quantum_expired <= 1'b0;
			quantum_stage <= 1'b0;

         if (prog_sel != current_prog) begin
             prog_load_en <= 1'b1;
             current_prog <= prog_sel;
             next_prog <= prog_sel;
             cycle_counter <= 4'b0000;
         end
         else begin
             prog_load_en <= 1'b0;
         end
			
			preempt_enabled_prev <= enable;
      end
    end

endmodule