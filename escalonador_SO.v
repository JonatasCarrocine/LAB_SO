// Escalonador de processos com dois modos:
//
//  modoPreemptivo = 0  -> SEM preempção (FCFS / lote): o processo atual roda
//                         até executar HALT; só então o próximo assume a CPU.
//  modoPreemptivo = 1  -> COM preempção (Round-Robin): além do HALT, a cada
//                         QUANTUM instruções executadas o processo perde a CPU
//                         (interrupção de temporizador) e o próximo processo
//                         pronto assume.
//
// Tabela de processos (PCB) mantida aqui:
//   pcb[i]         - PC salvo do processo i
//   finalizado[i]  - processo i já terminou (HALT ou falha de memória)
// Os registradores de cada processo ficam no bancoRegistradores_SO.
//
// A troca de contexto acontece no mesmo ciclo em que a última instrução do
// processo é executada: o PC seguinte dele é salvo no PCB e o PC do próximo
// processo é restaurado.
module escalonador_SO #(
    parameter NUM_PROGS = 10,
    parameter QUANTUM   = 10      // instruções por fatia de tempo (modo preemptivo)
) (
    input  wire        clock,
    input  wire        reset,
    input  wire        executa,         // 1 = instrução do processo atual executada neste ciclo
    input  wire        modoPreemptivo,
    input  wire [31:0] pcProx,          // próximo PC calculado pelo datapath
    input  wire        fimProcesso,     // instrução atual é HALT (ou falha)

    output reg  [3:0]  processoAtual,   // 0 = programa 1, ..., 9 = programa 10
    output reg  [31:0] pcAtual,         // PC lógico do processo atual
    output reg  [NUM_PROGS-1:0] finalizado,
    output reg         todosFinalizados,
    output reg         trocaContexto,   // pulso: houve troca de processo neste ciclo
    output reg         preempcao,       // pulso: a troca foi por fim de quantum
    output reg  [7:0]  contQuantum
);

    reg [31:0] pcb [0:NUM_PROGS-1];

    // ------------------------------------------------------------------
    // Próximo processo pronto, em ordem circular a partir do atual.
    // proxSemAtual: ignora o atual (usado quando ele termina).
    // proxComAtual: o atual entra por último (usado no fim do quantum;
    //               se só ele está pronto, continua ele).
    // ------------------------------------------------------------------
    reg [3:0] proxSemAtual, proxComAtual;
    reg       achouSemAtual, achouComAtual;
    integer k, idx;

    always @(*) begin
        proxSemAtual  = processoAtual;
        proxComAtual  = processoAtual;
        achouSemAtual = 1'b0;
        achouComAtual = 1'b0;
        for (k = NUM_PROGS; k >= 1; k = k - 1) begin
            idx = processoAtual + k;
            if (idx >= NUM_PROGS)
                idx = idx - NUM_PROGS;
            if (!finalizado[idx]) begin
                proxComAtual  = idx[3:0];
                achouComAtual = 1'b1;
                if (k != NUM_PROGS) begin
                    proxSemAtual  = idx[3:0];
                    achouSemAtual = 1'b1;
                end
            end
        end
    end

    wire fimQuantum = modoPreemptivo && (contQuantum == QUANTUM - 1);

    integer i;
    initial begin
        for (i = 0; i < NUM_PROGS; i = i + 1)
            pcb[i] = 32'd0;
        processoAtual    = 4'd0;
        pcAtual          = 32'd0;
        finalizado       = {NUM_PROGS{1'b0}};
        todosFinalizados = 1'b0;
        trocaContexto    = 1'b0;
        preempcao        = 1'b0;
        contQuantum      = 8'd0;
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < NUM_PROGS; i = i + 1)
                pcb[i] <= 32'd0;
            processoAtual    <= 4'd0;
            pcAtual          <= 32'd0;
            finalizado       <= {NUM_PROGS{1'b0}};
            todosFinalizados <= 1'b0;
            trocaContexto    <= 1'b0;
            preempcao        <= 1'b0;
            contQuantum      <= 8'd0;
        end
        else begin
            trocaContexto <= 1'b0;
            preempcao     <= 1'b0;

            if (executa && !todosFinalizados) begin
                if (fimProcesso) begin
                    // HALT: processo sai da fila e não volta mais
                    finalizado[processoAtual] <= 1'b1;
                    contQuantum <= 8'd0;
                    if (achouSemAtual) begin
                        processoAtual <= proxSemAtual;
                        pcAtual       <= pcb[proxSemAtual];
                        trocaContexto <= 1'b1;
                    end
                    else begin
                        todosFinalizados <= 1'b1;
                    end
                end
                else if (fimQuantum) begin
                    // Interrupção de tempo: salva contexto e passa a vez
                    pcb[processoAtual] <= pcProx;
                    contQuantum <= 8'd0;
                    if (proxComAtual != processoAtual) begin
                        processoAtual <= proxComAtual;
                        pcAtual       <= pcb[proxComAtual];
                        trocaContexto <= 1'b1;
                        preempcao     <= 1'b1;
                    end
                    else begin
                        pcAtual <= pcProx;   // único processo vivo: continua
                    end
                end
                else begin
                    pcAtual     <= pcProx;
                    contQuantum <= contQuantum + 8'd1;
                end
            end
        end
    end

endmodule
