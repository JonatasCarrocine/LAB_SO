module PC_lcd_TESTE (
	input wire clock,
	input wire isHalt,
	input wire resetCPU,
	
	input wire [31:0] pcNext,
	
	//LOAD inicial
	input wire prog_load_en,           // Sinal de carregamento de novo programa
	input wire [31:0] prog_base_addr,  // Endereço base do novo programa
	
	//Preempcao
	input wire quantum_expired,
   input wire [1:0] current_prog,
   input wire [1:0] next_prog,
	
	input wire cpu_stall,
	
	
	output reg [31:0] pcAtual,
	output reg halted,                  // Estado permanente do halt
	output wire [31:0] pc_relativo,   // monitoramento
	
	output reg execution_active, //,
	
	//DEBUG
	output wire [31:0] dbg_saved_pc_rel_1,
	output wire [31:0] dbg_saved_pc_rel_2,

	output wire [31:0] dbg_saved_base_1,
	output wire [31:0] dbg_saved_base_2,
	
	output wire dbg_do_context_switch,
	output wire dbg_context_switch_stage
);

	reg [31:0] saved_pc_rel [2:0];
   reg [31:0] saved_base   [2:0];
	
	assign dbg_saved_pc_rel_1 = saved_pc_rel[1];
	assign dbg_saved_pc_rel_2 = saved_pc_rel[2];

	assign dbg_saved_base_1 = saved_base[1];
	assign dbg_saved_base_2 = saved_base[2];
	
	assign dbg_do_context_switch = do_context_switch;
	assign dbg_context_switch_stage = context_switch_stage;
	
	// PC relativo ao programa atual (para debug)
   assign pc_relativo = (current_prog == 2'b01 || current_prog == 2'b10) ?
                         pcAtual - saved_base[current_prog] : 32'd0;
	
	reg quantum_expired_prev;

	wire do_context_switch = quantum_expired && !quantum_expired_prev;
	
	reg freeze_pc;
	reg context_switch_stage; // NOVO: controla estágios da troca
	reg [1:0] pending_next_prog; //NOVO
	
	integer i;
	initial begin
		pcAtual = 32'b0;
		halted = 1'b0;
		execution_active = 1'b0;       // Começa desativado
		quantum_expired_prev = 1'b0;
		freeze_pc = 1'b0;
		context_switch_stage = 1'b0; // NOVO
		pending_next_prog = 2'b00; // NOVO
		
		for (i = 0; i < 3; i = i + 1) begin
            saved_pc_rel[i] = 32'd0;
		end
		
		saved_base[0] = 32'd0;
		saved_base[1] = 32'd100;
		saved_base[2] = 32'd200;
	end

	always @(posedge clock or posedge resetCPU) begin
		if(resetCPU) begin
			// Reset total do processador
			pcAtual 					<= 32'b0;
			halted 					<= 1'b0;
			execution_active 		<= 1'b0;   // Desativa execução no reset
			quantum_expired_prev <= 1'b0;
			freeze_pc 				<= 1'b0;
			context_switch_stage <= 1'b0;
			pending_next_prog 	<= 2'b00; // NOVO
		end
		// HALT trava tudo
		else if (isHalt) begin
         halted 				<= 1'b1;
         execution_active 	<= 1'b0;
      end
		else if (cpu_stall) begin
			pcAtual <= pcAtual;
		end
		else if (do_context_switch) begin
         // ESTÁGIO 1: SALVA o contexto do programa ATUAL
            if (current_prog == 2'b01 || current_prog == 2'b10) begin
                // Salva PC RELATIVO ao base do programa atual
                saved_pc_rel[current_prog] <= pcNext - saved_base[current_prog];
            end
            
					context_switch_stage <= 1'b1; // Marca que precisa restaurar
					pending_next_prog <= next_prog;
				
            halted <= 1'b0;
				execution_active 	<= 1'b1;
      end
		else if (context_switch_stage) begin
            // ESTÁGIO 2: RESTAURA o contexto do PRÓXIMO programa
            if (next_prog == 2'b01 || next_prog == 2'b10) begin
                // Restaura PC = base + offset salvo
                pcAtual <= saved_base[pending_next_prog] + saved_pc_rel[pending_next_prog];
            end
            
            context_switch_stage <= 1'b0;
				freeze_pc <= 1'b1;
      end
		else if (prog_load_en) begin
         // Apenas para boot/manual
         saved_base[current_prog]   <= prog_base_addr;
         saved_pc_rel[current_prog] <= 32'd0;
			pcAtual <= prog_base_addr;
			 
         halted 				<= 1'b0;
			execution_active 	<= 1'b1;
      end
      else if (!halted) begin
         if (freeze_pc) begin
				  pcAtual <= pcAtual; // segura um ciclo
				  freeze_pc <= 1'b0;
			 end
			 else begin
				  pcAtual <= pcNext;
			 end
      end
		
		quantum_expired_prev <= quantum_expired;
	end	
endmodule