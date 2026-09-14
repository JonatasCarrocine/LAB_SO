module PC_RR (
    input  wire        clock,
    input  wire        reset,
    input  wire [31:0] pcNext,             // Próximo PC (PC+4 ou branch)
    
    // Controle do escalonador
    input  wire [1:0]  current_prog,       // Programa atual (01 ou 10)
    input  wire [31:0] prog_base_addr,     // Base do programa atual
    input  wire        context_switch,     // Pulso de troca de contexto
    input  wire        load_program,       // Carrega novo programa
    
    // Controle de execução
    input  wire        isHalt,             // Halt do programa
    
    // Saídas
    output reg  [31:0] pcAtual,            // PC atual (absoluto)
    output wire [31:0] pc_relativo,        // PC relativo ao programa
    output reg         halted,
    
    // Debug
    output wire [31:0] dbg_saved_pc_prog1,
    output wire [31:0] dbg_saved_pc_prog2,
    output wire [31:0] dbg_base_prog1,
    output wire [31:0] dbg_base_prog2
);

    // Contextos salvos de cada programa
    // [0] não usado, [1] = programa 1, [2] = programa 2
    reg [31:0] saved_pc_offset [0:2];   // PC relativo salvo
    reg [31:0] saved_base [0:2];        // Base salva
    
    // Sinais de controle interno
    reg switch_stage;  // Estágio da troca de contexto
    reg [1:0] prev_prog;
    
    // Debug
    assign dbg_saved_pc_prog1 = saved_pc_offset[1];
    assign dbg_saved_pc_prog2 = saved_pc_offset[2];
    assign dbg_base_prog1 = saved_base[1];
    assign dbg_base_prog2 = saved_base[2];
    
    // PC relativo ao programa atual (COMBINACIONAL)
    wire [31:0] pc_relativo_comb;
    wire [31:0] pcNext_efetivo;  // PC efetivo considerando contexto
    
    // Se o PC vem de um jump, precisa ser ajustado para o programa atual
    assign pcNext_efetivo = pcNext;
    
    assign pc_relativo_comb = (current_prog == 2'b01 || current_prog == 2'b10) ?
                              pcNext_efetivo - saved_base[current_prog] : 32'd0;
    
    assign pc_relativo = pc_relativo_comb;
    
    // Inicialização
    initial begin
        pcAtual = 32'd0;
        halted = 1'b0;
        switch_stage = 1'b0;
        prev_prog = 2'b00;
        
        // Inicializa bases dos programas
        saved_base[0] = 32'd0;
        saved_base[1] = 32'd100;  // Programa 1: 100-199
        saved_base[2] = 32'd200;  // Programa 2: 200-299
        
        // Inicializa offsets
        saved_pc_offset[0] = 32'd0;
        saved_pc_offset[1] = 32'd0;
        saved_pc_offset[2] = 32'd0;
    end
    
    // Lógica principal
    // NOVO: Determinar o PC do próximo ciclo de forma COMBINACIONAL
    wire [31:0] next_pc_combinatorial;
    
    assign next_pc_combinatorial = (load_program) ? prog_base_addr :
                                   (context_switch && !switch_stage) ? pcNext :
                                   (switch_stage) ? (saved_base[current_prog] + saved_pc_offset[current_prog]) :
                                   pcNext;  // Jump é processado aqui no mesmo ciclo!
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            pcAtual <= 32'd0;
            halted <= 1'b0;
            switch_stage <= 1'b0;
            prev_prog <= 2'b00;
            
            // Reseta offsets mas mantém bases
            saved_pc_offset[1] <= 32'd0;
            saved_pc_offset[2] <= 32'd0;
        end
        else if (isHalt) begin
            halted <= 1'b1;
        end
        else if (!halted) begin
            // CARREGAR NOVO PROGRAMA (primeira vez ou seleção manual)
            if (load_program) begin
                // Atualiza base do programa atual
                saved_base[current_prog] <= prog_base_addr;
                saved_pc_offset[current_prog] <= 32'd0;
                
                // Carrega PC inicial do programa
                pcAtual <= prog_base_addr;
                
                prev_prog <= current_prog;
                switch_stage <= 1'b0;
            end
            // TROCA DE CONTEXTO - ESTÁGIO 1: SALVAR
            else if (context_switch && !switch_stage) begin
                // Salva offset do programa que está SAINDO
                if (prev_prog == 2'b01 || prev_prog == 2'b10) begin
                    // Salva o PRÓXIMO PC (não o atual)
                    saved_pc_offset[prev_prog] <= pcNext - saved_base[prev_prog];
                end
                
                // Marca que precisa restaurar no próximo ciclo
                switch_stage <= 1'b1;
            end
            // TROCA DE CONTEXTO - ESTÁGIO 2: RESTAURAR
            else if (switch_stage) begin
                // Restaura PC do programa que está ENTRANDO
                if (current_prog == 2'b01 || current_prog == 2'b10) begin
                    pcAtual <= saved_base[current_prog] + saved_pc_offset[current_prog];
                end
                
                prev_prog <= current_prog;
                switch_stage <= 1'b0;
            end
            // EXECUÇÃO NORMAL - Jump é processado aqui no mesmo ciclo!
            else begin
                pcAtual <= pcNext;  // pcNext já contém o endereço de jump (combinacional)
                prev_prog <= current_prog;
            end
        end
    end

endmodule