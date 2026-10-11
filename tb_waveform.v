// Reproduz os estímulos sugeridos para a waveform do Quartus (README_SO.md),
// usando o top-level processadorSO_sim:
//   clock      : período de 20 ns
//   reset      : 1 de 0 a 100 ns, depois 0
//   valorIN    : 3 (constante: todo IN recebe 3)
//   botaoIN    : clock de período 400 ns (aperta e solta sozinho)
//   modo       : 0 na primeira rodada, 1 na segunda
// Mostra cada OUT e o instante em que todos os programas terminam.
//
//   iverilog -g2012 -o simulacao/tbw.vvp tb_waveform.v processadorSO_sim.v $(tail -n +2 simulacao/arquivos.txt)
//   vvp simulacao/tbw.vvp
`timescale 1ns / 1ps

module tb_waveform;
    reg        clock = 1'b0;
    reg        reset = 1'b1;
    reg        modoPreemptivo = 1'b0;
    reg  [8:0] valorIN = 9'd3;
    reg        botaoIN = 1'b0;

    wire [3:0]  programa, programaOut;
    wire [31:0] pc, instrucao;
    wire [7:0]  quantum;
    wire [9:0]  finalizados;
    wire [13:0] valorOut;
    wire [6:0]  trocas;
    wire executa, trocaContexto, preempcao, aguardandoIN, todosFinalizados;

    processadorSO_sim dut (
        .clock(clock), .reset(reset), .modoPreemptivo(modoPreemptivo),
        .valorIN(valorIN), .botaoIN(botaoIN),
        .programa(programa), .pc(pc), .instrucao(instrucao), .executa(executa),
        .quantum(quantum), .trocaContexto(trocaContexto), .preempcao(preempcao),
        .aguardandoIN(aguardandoIN), .todosFinalizados(todosFinalizados),
        .finalizados(finalizados), .programaOut(programaOut),
        .valorOut(valorOut), .trocas(trocas)
    );

    always #10  clock   = ~clock;
    always #200 botaoIN = ~botaoIN;

    always @(posedge clock)
        if (executa && instrucao[31:26] == 6'b010110)
            $display("  %t  P%0d OUT = %0d", $time, programa, dut.u_nucleo.DadosUm);

    real inicio;

    task rodada(input modo);
        begin
            inicio = $realtime;
            reset = 1'b1; modoPreemptivo = modo;
            #100 reset = 1'b0;
            wait (todosFinalizados);
            $display("  todos terminaram %0.2f us depois do inicio da rodada, trocas de contexto = %0d",
                     ($realtime - inicio) / 1000.0, trocas);
        end
    endtask

    initial begin
        $timeformat(-6, 2, " us", 10);
        $display("Rodada 1: sem preempcao");
        rodada(1'b0);
        $display("Rodada 2: com preempcao");
        rodada(1'b1);
        $finish;
    end
endmodule
