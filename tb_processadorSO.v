// Testbench do processador multiprogramado.
//
// Roda os 10 programas duas vezes: SEM preempção (FCFS) e COM preempção
// (Round-Robin). O testbench faz o papel do usuário: quando o processador
// para em um IN, coloca o próximo valor da lista daquele programa em SW[8:0]
// e aperta KEY[1].
//
// Gera:
//   - log das trocas de contexto
//   - tabela por processo: instruções executadas, término, espera, resultado
//   - simulacao/gantt_sem_preempcao.csv e simulacao/gantt_com_preempcao.csv
//     (uma linha por instrução executada: tempo, programa, pc)
//
// Rodar (Icarus Verilog):
//   iverilog -g2012 -o simulacao/tb.vvp -f simulacao/arquivos.txt
//   vvp simulacao/tb.vvp
`timescale 1ns / 1ps

module tb_processadorSO;

    localparam NUM_PROGS = 10;
    parameter  QUANTUM   = 10;   // pode ser trocado com iverilog -Ptb_processadorSO.QUANTUM=N

    reg         CLOCK_50 = 1'b0;
    reg  [1:0]  KEY      = 2'b11;
    reg  [17:0] SW       = 18'b0;
    wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
    wire [17:0] LEDR;
    wire [8:0]  LEDG;

    // DIV = 2: uma instrução a cada 2 ciclos de clock na simulação
    // (mínimo, porque a memória de dados tem leitura síncrona)
    processadorSO_nucleo #(
        .NUM_PROGS(NUM_PROGS),
        .QUANTUM(QUANTUM),
        .DIV_LENTO(2),
        .DIV_RAPIDO(2)
    ) dut (
        .CLOCK_50(CLOCK_50), .KEY(KEY), .SW(SW),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
        .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6), .HEX7(HEX7),
        .LEDR(LEDR), .LEDG(LEDG)
    );

    always #10 CLOCK_50 = ~CLOCK_50;

    // ------------------------------------------------------------------
    // Entradas de cada programa e resultado esperado
    // ------------------------------------------------------------------
    reg [8:0]  entradas [0:NUM_PROGS-1][0:3];
    reg [31:0] esperado [0:NUM_PROGS-1];
    reg [255:0] nome    [0:NUM_PROGS-1];
    integer    proxEntrada [0:NUM_PROGS-1];

    initial begin
        nome[0] = "soma 3 entradas";   entradas[0][0] = 5;  entradas[0][1] = 7;  entradas[0][2] = 9; esperado[0] = 21;
        nome[1] = "multiplicacao";     entradas[1][0] = 6;  entradas[1][1] = 7;                      esperado[1] = 42;
        nome[2] = "area triangulo";    entradas[2][0] = 10; entradas[2][1] = 6;                      esperado[2] = 30;
        nome[3] = "mdc (gcd)";         entradas[3][0] = 48; entradas[3][1] = 18;                     esperado[3] = 6;
        nome[4] = "divisivel por 3";   entradas[4][0] = 9;                                           esperado[4] = 1;
        nome[5] = "subtracao";         entradas[5][0] = 20; entradas[5][1] = 8;                      esperado[5] = 12;
        nome[6] = "compara a,b";       entradas[6][0] = 3;  entradas[6][1] = 8;                      esperado[6] = 1;
        nome[7] = "fatorial";          entradas[7][0] = 6;                                           esperado[7] = 720;
        nome[8] = "potencia";          entradas[8][0] = 2;  entradas[8][1] = 5;                      esperado[8] = 32;
        nome[9] = "somatorio";         entradas[9][0] = 20;                                          esperado[9] = 210;
    end

    // ------------------------------------------------------------------
    // Métricas
    // ------------------------------------------------------------------
    integer tempo;                          // instruções executadas (todas)
    integer instrProc  [0:NUM_PROGS-1];     // instruções de cada processo (burst)
    integer inicioProc [0:NUM_PROGS-1];     // primeira vez que ganhou a CPU
    integer fimProc    [0:NUM_PROGS-1];     // instante do HALT (turnaround)
    integer trocas, preempcoes;
    integer gantt;
    integer p;

    // "Usuário": responde aos IN (aperta o botão uma vez e espera o IN executar)
    reg respondendo = 1'b0;
    always @(posedge CLOCK_50) begin
        KEY[1] <= 1'b1;
        if (dut.executa && dut.isIN)
            respondendo <= 1'b0;
        else if (dut.aguardandoIN && !respondendo) begin
            SW[8:0] <= entradas[dut.processoAtual][proxEntrada[dut.processoAtual]];
            proxEntrada[dut.processoAtual] <= proxEntrada[dut.processoAtual] + 1;
            KEY[1] <= 1'b0;
            respondendo <= 1'b1;
        end
    end

    // Monitor de execução
    always @(posedge CLOCK_50) begin
        if (dut.executa) begin
            if (inicioProc[dut.processoAtual] < 0)
                inicioProc[dut.processoAtual] = tempo;
            instrProc[dut.processoAtual] = instrProc[dut.processoAtual] + 1;
            $fdisplay(gantt, "%0d,%0d,%0d", tempo, dut.processoAtual + 1, dut.pcAtual);
            tempo = tempo + 1;

            if (dut.fimProcesso) begin
                fimProc[dut.processoAtual] = tempo;
                $display("  t=%4d  P%0d terminou (HALT)%s", tempo, dut.processoAtual + 1,
                         (dut.foraLimiteInstr || dut.foraLimiteDados) ? " -- FALHA: acesso fora da particao" : "");
            end
            if (dut.isOut)
                $display("  t=%4d  P%0d OUT = %0d", tempo, dut.processoAtual + 1, dut.DadosUm);
        end
        if (dut.trocaContexto) begin
            trocas = trocas + 1;
            if (dut.preempcao) begin
                preempcoes = preempcoes + 1;
                $display("  t=%4d  troca de contexto (fim do quantum) -> P%0d  (pc restaurado = %0d)",
                         tempo, dut.processoAtual + 1, dut.pcAtual);
            end
            else
                $display("  t=%4d  troca de contexto (HALT)           -> P%0d  (pc restaurado = %0d)",
                         tempo, dut.processoAtual + 1, dut.pcAtual);
        end
    end

    // ------------------------------------------------------------------
    // Execução de um modo completo
    // ------------------------------------------------------------------
    integer erros;
    real somaTurnaround, somaEspera, somaResposta;

    task roda_modo(input preemptivo, input [8*40-1:0] arquivo);
        integer ciclos;
        begin
            for (p = 0; p < NUM_PROGS; p = p + 1) begin
                proxEntrada[p] = 0;
                instrProc[p]   = 0;
                inicioProc[p]  = -1;
                fimProc[p]     = -1;
            end
            tempo = 0; trocas = 0; preempcoes = 0;
            gantt = $fopen(arquivo, "w");
            $fdisplay(gantt, "tempo,programa,pc");

            SW[17] = preemptivo;
            KEY[0] = 1'b0;                  // reset
            repeat (3) @(posedge CLOCK_50);
            KEY[0] = 1'b1;

            ciclos = 0;
            while (!dut.todosFinalizados && ciclos < 400000) begin
                @(posedge CLOCK_50);
                ciclos = ciclos + 1;
            end
            @(posedge CLOCK_50);
            $fclose(gantt);

            if (!dut.todosFinalizados) begin
                $display("ERRO: timeout, os programas nao terminaram");
                erros = erros + 1;
            end

            $display("");
            $display("  Proc  Programa            Instr  1a vez  Termino  Espera  Resultado  Esperado");
            somaTurnaround = 0; somaEspera = 0; somaResposta = 0;
            for (p = 0; p < NUM_PROGS; p = p + 1) begin
                $display("  P%-3d  %-18s  %5d  %6d  %7d  %6d  %9d  %8d %s",
                         p + 1, nome[p], instrProc[p], inicioProc[p], fimProc[p],
                         fimProc[p] - instrProc[p], dut.resultado[p], esperado[p],
                         (dut.resultado[p] == esperado[p]) ? "ok" : "<-- DIFERENTE");
                if (dut.resultado[p] != esperado[p]) erros = erros + 1;
                somaTurnaround = somaTurnaround + fimProc[p];
                somaEspera     = somaEspera + (fimProc[p] - instrProc[p]);
                somaResposta   = somaResposta + inicioProc[p];
            end
            $display("");
            $display("  Tempo total: %0d instrucoes | trocas de contexto: %0d (preempcoes: %0d)",
                     tempo, trocas, preempcoes);
            $display("  Turnaround medio: %0.1f | Espera media: %0.1f | Resposta media (1a vez na CPU): %0.1f",
                     somaTurnaround / NUM_PROGS, somaEspera / NUM_PROGS, somaResposta / NUM_PROGS);
        end
    endtask

    initial begin
        erros = 0;
        $display("==================================================================");
        $display(" MODO 1: SEM PREEMPCAO (FCFS - cada programa roda ate o HALT)");
        $display("==================================================================");
        roda_modo(1'b0, "simulacao/gantt_sem_preempcao.csv");

        $display("");
        $display("==================================================================");
        $display(" MODO 2: COM PREEMPCAO (Round-Robin, quantum = %0d instrucoes)", QUANTUM);
        $display("==================================================================");
        roda_modo(1'b1, "simulacao/gantt_com_preempcao.csv");

        $display("");
        if (erros == 0) $display("RESULTADO: todos os programas corretos nos dois modos");
        else            $display("RESULTADO: %0d erro(s)", erros);
        $finish;
    end

endmodule
