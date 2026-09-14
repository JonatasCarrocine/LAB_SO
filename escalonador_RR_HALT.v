module escalonador_RR_HALT (
    input  wire        clock,
    input  wire        reset,
    input  wire        enable_preemption,  // 1 = Round-Robin, 0 = Sem preempção
    input  wire [1:0]  manual_prog_sel,    // Seleção manual (quando preempção = 0)
    input  wire        start_execution,    // Pulso para iniciar execução
    input  wire        prog_halt,          // Pulso: programa atual executou HALT

    // Saídas
    output reg  [1:0]  current_prog,       // Programa em execução (01 ou 10)
    output reg  [31:0] prog_base_addr,     // Endereço base do programa atual
    output reg         context_switch,     // Pulso de troca de contexto
    output reg         load_program,       // Sinal para carregar novo programa
    output reg         halt_geral,         // Flag: todos os programas deram HALT

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
    reg switch_pending;

    // Flags de programas vivos: bit0 -> programa 01, bit1 -> programa 10
    reg [1:0] prog_alive;

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

    // Retorna próximo programa vivo diferente do atual; se só houver um vivo retorna ele; se nenhum retorna 2'b00
    function [1:0] find_next_alive;
        input [1:0] cur;
        input [1:0] alive;
        begin
            if (alive == 2'b00) begin
                find_next_alive = 2'b00;
            end
            else begin
                if (cur == 2'b01) begin
                    if (alive[1]) find_next_alive = 2'b10;
                    else if (alive[0]) find_next_alive = 2'b01;
                    else find_next_alive = 2'b00;
                end
                else if (cur == 2'b10) begin
                    if (alive[0]) find_next_alive = 2'b01;
                    else if (alive[1]) find_next_alive = 2'b10;
                    else find_next_alive = 2'b00;
                end
                else begin
                    if (alive[0]) find_next_alive = 2'b01;
                    else if (alive[1]) find_next_alive = 2'b10;
                    else find_next_alive = 2'b00;
                end
            end
        end
    endfunction

    // Sinais de debug
    assign dbg_counter = cycle_counter;
    assign dbg_quantum_expired = quantum_expired;

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
        switch_pending = 1'b0;
        prog_alive = 2'b11; // ambos vivos inicialmente
        halt_geral = 1'b0;
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
            switch_pending <= 1'b0;
            prog_alive <= 2'b11;
            halt_geral <= 1'b0;
        end
        else begin
            // Limpa pulsos por default
            context_switch <= 1'b0;
            load_program <= 1'b0;
            quantum_expired <= 1'b0;

            // Se recebeu HALT do programa atual
            if (execution_running && prog_halt) begin
                // Marca programa atual como morto
                if (current_prog == 2'b01) prog_alive[0] <= 1'b0;
                else if (current_prog == 2'b10) prog_alive[1] <= 1'b0;

                // Calcula próximo vivo (excluindo o que acabou de morrer)
                next_prog <= find_next_alive(current_prog, prog_alive & ~( (current_prog==2'b01) ? 2'b01 : 2'b10 ));

                if (next_prog == 2'b00) begin
                    // Nenhum vivo -> para execução e sinaliza halt geral
                    execution_running <= 1'b0;
                    halt_geral <= 1'b1;
                end
                else begin
                    // Troca imediata para próximo vivo
                    current_prog <= next_prog;
                    prog_base_addr <= get_base_addr(next_prog);
                    context_switch <= 1'b1;
                    load_program <= 1'b1;
                    cycle_counter <= 4'd0;
                    switch_pending <= 1'b0;
                end
            end
            // Iniciar execução
            else if (start_execution && !execution_running) begin
                execution_running <= 1'b1;
                cycle_counter <= 4'd0;
                prog_alive <= 2'b11; // ao iniciar consideramos ambos vivos; ajuste se desejar persistir flags
                halt_geral <= 1'b0;  // limpa halt geral ao reiniciar
                if (enable_preemption) begin
                    if (prog_alive[0]) begin
                        current_prog <= 2'b01;
                        prog_base_addr <= get_base_addr(2'b01);
                    end
                    else if (prog_alive[1]) begin
                        current_prog <= 2'b10;
                        prog_base_addr <= get_base_addr(2'b10);
                    end
                    else begin
                        execution_running <= 1'b0; // nenhum vivo
                        halt_geral <= 1'b1;
                    end
                end
                else begin
                    current_prog <= manual_prog_sel;
                    prog_base_addr <= get_base_addr(manual_prog_sel);
                end
                load_program <= 1'b1;
            end
            // Modo com preempção (Round-Robin)
            else if (execution_running && enable_preemption) begin
                if (switch_pending) begin
                    if (next_prog != 2'b00 && ((next_prog==2'b01 && prog_alive[0]) || (next_prog==2'b10 && prog_alive[1]))) begin
                        current_prog <= next_prog;
                        prog_base_addr <= get_base_addr(next_prog);
                        context_switch <= 1'b1;
                        load_program <= 1'b1;
                    end
                    else begin
                        next_prog <= find_next_alive(current_prog, prog_alive);
                        if (next_prog != 2'b00 && next_prog != current_prog) begin
                            current_prog <= next_prog;
                            prog_base_addr <= get_base_addr(next_prog);
                            context_switch <= 1'b1;
                            load_program <= 1'b1;
                        end
                    end
                    switch_pending <= 1'b0;
                    cycle_counter <= 4'd0;
                end
                else begin
                    // Incrementa contador
                    cycle_counter <= cycle_counter + 4'd1;

                    // Verifica se quantum expirou
                    if (cycle_counter == (QUANTUM - 1)) begin
                        quantum_expired <= 1'b1;
                        next_prog <= find_next_alive(current_prog, prog_alive);
                        if (next_prog != 2'b00 && next_prog != current_prog) begin
                            switch_pending <= 1'b1;
                        end
                        else begin
                            // se não há outro vivo, mantém execução no mesmo programa e reseta contador
                            cycle_counter <= 4'd0;
                            switch_pending <= 1'b0;
                        end
                    end
                end
            end
            // Modo sem preempção (manual)
            else if (execution_running && !enable_preemption) begin
                if (manual_prog_sel != current_prog && ((manual_prog_sel==2'b01 && prog_alive[0]) || (manual_prog_sel==2'b10 && prog_alive[1]))) begin
                    current_prog <= manual_prog_sel;
                    prog_base_addr <= get_base_addr(manual_prog_sel);
                    context_switch <= 1'b1;
                    load_program <= 1'b1;
                end
            end
        end
    end

endmodule