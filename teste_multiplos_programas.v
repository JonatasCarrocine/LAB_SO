// Testbench para testar modo não-preemptivo com múltiplos programas
`timescale 1ns / 1ps

module teste_multiplos_programas;

    reg clock;
    reg reset;
    
    // Sinais para memInstrucao_lcd
    reg [31:0] endInstr;
    reg [1:0] prog_sel;
    reg prog_load_en;
    reg quantum_expired;
    reg preemption_mode;
    
    // Saídas da memória de instruções
    wire [31:0] pcInstr;
    wire [31:0] posMem;
    
    // Instancia o módulo de memória de instruções
    memInstrucao_lcd mem_inst (
        .endInstr(endInstr),
        .pcInstr(pcInstr),
        .posMem(posMem),
        .clock(clock),
        .prog_sel(prog_sel),
        .prog_load_en(prog_load_en),
        .quantum_expired(quantum_expired),
        .preemption_mode(preemption_mode)
    );
    
    // Gerador de clock
    initial begin
        clock = 0;
        forever #5 clock = ~clock;  // Clock de 100 MHz (período 10ns)
    end
    
    // Testbench
    initial begin
        // Inicializa sinais
        reset = 1;
        endInstr = 32'd0;
        prog_sel = 2'b00;
        prog_load_en = 0;
        quantum_expired = 0;
        preemption_mode = 0;  // Modo NÃO-preemptivo
        
        #100;
        reset = 0;
        
        // ===== TESTE 1: Programa 0 =====
        $display("=== TESTE 1: Carregando Programa 0 ===");
        prog_sel = 2'b00;
        prog_load_en = 1;
        #20;
        prog_load_en = 0;
        
        // Simula execução do Programa 0 (vai até mem[22] = halt)
        #50;
        endInstr = 32'd1;  // PC incrementa
        #10;
        endInstr = 32'd2;
        #10;
        endInstr = 32'd3;
        #10;
        endInstr = 32'd4;
        #50;  // Aguarda mais alguns ciclos antes de trocar
        
        // ===== TESTE 2: Trocar para Programa 1 =====
        $display("=== TESTE 2: Carregando Programa 1 ===");
        prog_sel = 2'b01;
        prog_load_en = 1;
        #20;
        prog_load_en = 0;
        
        // Simula execução do Programa 1 (começa no endereço 100)
        #50;
        endInstr = 32'd101;
        #10;
        endInstr = 32'd102;
        #10;
        endInstr = 32'd103;
        #10;
        endInstr = 32'd104;
        #50;
        
        // ===== TESTE 3: Voltar para Programa 0 =====
        $display("=== TESTE 3: Carregando Programa 0 novamente ===");
        prog_sel = 2'b00;
        prog_load_en = 1;
        #20;
        prog_load_en = 0;
        
        // Verifica se PC foi resetado
        #50;
        endInstr = 32'd5;
        #10;
        endInstr = 32'd6;
        #50;
        
        // ===== TESTE 4: Programa 2 =====
        $display("=== TESTE 4: Carregando Programa 2 ===");
        prog_sel = 2'b10;
        prog_load_en = 1;
        #20;
        prog_load_en = 0;
        
        // Simula execução do Programa 2 (começa no endereço 200)
        #50;
        endInstr = 32'd201;
        #10;
        endInstr = 32'd202;
        #50;
        
        // ===== TESTE 5: Programa 3 =====
        $display("=== TESTE 5: Carregando Programa 3 ===");
        prog_sel = 2'b11;
        prog_load_en = 1;
        #20;
        prog_load_en = 0;
        
        // Simula execução do Programa 3 (começa no endereço 300)
        #50;
        endInstr = 32'd301;
        #10;
        endInstr = 32'd302;
        #50;
        
        $display("=== TESTE FINALIZADO ===");
        $finish;
    end
    
    // Monitor para visualizar os valores
    initial begin
        $monitor("Time=%0d | prog_sel=%b | prog_load_en=%b | endInstr=%d | pcInstr=%d | posMem=%b",
                 $time, prog_sel, prog_load_en, endInstr, pcInstr, posMem);
    end

endmodule
