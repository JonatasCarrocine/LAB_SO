module escalonador_RR (
    input  wire        clock,
    input  wire        reset,
    input  wire        enable_preemption,  // 1 = Round-Robin, 0 = Sem preempção
    input  wire [1:0]  manual_prog_sel,    // Seleção manual (quando preempção = 0)
    input  wire        start_execution,    // Pulso para iniciar execução
    
    // Saídas
    output reg  [1:0]  current_prog,       // Programa em execução (01 ou 10)
    output reg  [31:0] prog_base_addr,     // Endereço base do programa atual
    output reg         context_switch,     // Pulso de troca de contexto
    output reg         load_program,       // Sinal para carregar novo programa
    output wire        clock_enable,       // Sinal para habilitar clock do sistema
    
    // Debug
    output wire [3:0]  dbg_counter,
    output wire        dbg_quantum_expired
);

    // Parâmetros
    parameter QUANTUM = 10;
    
    // Registradores internos
    reg [3:0] cycle_counter;
    reg [1:0] next_prog;
    reg quantum_expired;
    reg execution_running;
    
    // Mapeamento de programas para endereços base
    function [31:0] get_base_addr;
        input [1:0] prog_id;
        begin
            case (prog_id)
                2'b01: get_base_addr = 32'd100;  // Programa 1
                2'b10: get_base_addr = 32'd200;  // Programa 2
                default: get_base_addr = 32'd0;
            endcase
        end
    endfunction
    
    // Sinais de debug
    assign dbg_counter = cycle_counter;
    assign dbg_quantum_expired = quantum_expired;
    
    // Clock habilitado quando:
    // 1. Execução iniciada (execution_running = 1)
    // 2. Um programa foi selecionado (manual_prog_sel != 0)
    // Em modo não preemptivo: clock ativo somente com essas condições
    // Em modo preemptivo: clock sempre ativo durante execução
    assign clock_enable = execution_running && ((enable_preemption) || (manual_prog_sel != 2'b00));
    
    
    // Inicialização
    initial begin
        current_prog = 2'b01;      // Começa com programa 1
        next_prog = 2'b01;
        cycle_counter = 4'd0;
        quantum_expired = 1'b0;
        context_switch = 1'b0;
        load_program = 1'b0;
        execution_running = 1'b0;
        prog_base_addr = 32'd100;
    end
    
    // Lógica principal
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            current_prog <= 2'b01;
            next_prog <= 2'b01;
            cycle_counter <= 4'd0;
            quantum_expired <= 1'b0;
            context_switch <= 1'b0;
            load_program <= 1'b0;
            execution_running <= 1'b0;
            prog_base_addr <= 32'd100;
        end
        else begin
            // Limpa pulsos
            context_switch <= 1'b0;
            load_program <= 1'b0;
            
            // Iniciar execução
            if (start_execution && !execution_running) begin
                execution_running <= 1'b1;
                cycle_counter <= 4'd0;
                if (enable_preemption) begin
                    current_prog <= 2'b01;  // Começa com programa 1
                    prog_base_addr <= 32'd100;
                end
                else begin
                    current_prog <= manual_prog_sel;
                    prog_base_addr <= get_base_addr(manual_prog_sel);
                end
                load_program <= 1'b1;
            end
            // Modo com preempção (Round-Robin)
            else if (execution_running && enable_preemption) begin
                // Incrementa contador
                cycle_counter <= cycle_counter + 4'd1;
                
                // Verifica se quantum expirou
                if (cycle_counter == (QUANTUM - 1)) begin
                    quantum_expired <= 1'b1;
                    
                    // Calcula próximo programa (alterna entre 01 e 10)
                    next_prog <= (current_prog == 2'b01) ? 2'b10 : 2'b01;
                    
                    // Reseta contador
                    cycle_counter <= 4'd0;
                    
                    // Sinaliza troca de contexto
                    context_switch <= 1'b1;
                end
                else begin
                    quantum_expired <= 1'b0;
                end
                
                // Atualiza programa atual no ciclo seguinte ao quantum
                if (quantum_expired) begin
                    current_prog <= next_prog;
                    prog_base_addr <= get_base_addr(next_prog);
                end
            end
            // Modo sem preempção (manual)
            else if (execution_running && !enable_preemption) begin
                // Verifica se usuário mudou o programa manualmente
                if (manual_prog_sel != current_prog) begin
                    current_prog <= manual_prog_sel;
                    prog_base_addr <= get_base_addr(manual_prog_sel);
                    context_switch <= 1'b1;
                    load_program <= 1'b1;
                end
            end
        end
    end

endmodule
