// Top-level para simular na waveform do Quartus (University Program VWF).
//
// Diferenças em relação à placa:
//   - executa uma instrução a cada 2 ciclos de clock (na placa são 25 milhões);
//   - entradas com nomes simples e ativas em 1;
//   - os sinais internos (programa, PC, quantum, trocas de contexto...) saem
//     como pinos, porque a waveform só mostra os pinos do top-level.
//
// Para usar: em Assignments > Settings > General, escolha processadorSO_sim
// como top-level, compile e crie o arquivo .vwf (passo a passo no README_SO.md).
module processadorSO_sim (
    input  wire        clock,
    input  wire        reset,            // 1 = reset. O modo é lido enquanto reset = 1
    input  wire        modoPreemptivo,   // 0 = sem preempção (FCFS), 1 = com preempção (RR)
    input  wire [8:0]  valorIN,          // valor entregue à instrução IN
    input  wire        botaoIN,          // 1 = botão apertado (confirma o IN na borda de subida)

    output wire [3:0]  programa,         // programa em execução (1..10)
    output wire [31:0] pc,               // PC lógico do programa em execução
    output wire [31:0] instrucao,
    output wire        executa,          // 1 = instrução executada neste ciclo
    output wire [7:0]  quantum,          // instruções já usadas do quantum atual
    output wire        trocaContexto,    // pulso: trocou de programa
    output wire        preempcao,        // pulso: a troca foi por fim de quantum
    output wire        aguardandoIN,     // CPU parada esperando botaoIN
    output wire        todosFinalizados,
    output wire [9:0]  finalizados,      // bit i = programa i+1 terminou
    output wire [3:0]  programaOut,      // programa que fez o último OUT (1..10)
    output wire [13:0] valorOut,         // valor do último OUT
    output wire [6:0]  trocas            // total de trocas de contexto (até 99)
);

    processadorSO_nucleo #(
        .DIV_LENTO(2),
        .DIV_RAPIDO(2)
    ) u_nucleo (
        .CLOCK_50(clock),
        .KEY({~botaoIN, ~reset}),
        .SW({modoPreemptivo, 8'b0, valorIN}),
        .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5(), .HEX6(), .HEX7(),
        .LEDR(), .LEDG(),
        .dbg_programa(programa),
        .dbg_pc(pc),
        .dbg_instrucao(instrucao),
        .dbg_executa(executa),
        .dbg_quantum(quantum),
        .dbg_trocaContexto(trocaContexto),
        .dbg_preempcao(preempcao),
        .dbg_aguardandoIN(aguardandoIN),
        .dbg_todosFinalizados(todosFinalizados),
        .dbg_finalizados(finalizados),
        .dbg_programaOut(programaOut),
        .dbg_valorOut(valorOut),
        .dbg_trocas(trocas)
    );

endmodule
