// Controle de execução do processador multiprogramado.
//
// Junta a lógica que decide se a instrução atual é executada neste ciclo:
//   - reset (botão ativo em 0) e o modo de escalonamento, lido no reset;
//   - espera do IN: a CPU para até o botão ser apertado, sem gastar quantum;
//   - fim do processo: HALT ou acesso fora da partição de memória;
//   - habilitação de escrita no banco de registradores e na memória de dados
//     (OUT não grava mais na memória, como fazia na versão monociclo).
module controleExecucao_SO (
    input  wire clock,
    input  wire botaoReset_n,       // KEY[0], ativo em 0
    input  wire botaoIN_n,          // KEY[1], ativo em 0
    input  wire chaveModo,          // SW[17]: 0 = sem preempção, 1 = com preempção
    input  wire tick,               // da baseTempo_SO
    input  wire todosFinalizados,   // do escalonador_SO

    // da unidade de controle
    input  wire isIN,
    input  wire isOut,
    input  wire isHalt,
    input  wire memWrite,

    // das memórias
    input  wire foraLimiteInstr,
    input  wire foraLimiteDados,

    output wire reset,              // ativo em 1, para os outros blocos
    output reg  modoPreemptivo,
    output wire executa,            // 1 = a instrução atual é executada neste ciclo
    output wire aguardandoIN,
    output wire fimProcesso,        // instrução atual encerra o processo
    output wire habilitaRegistradores,
    output wire memWriteDados       // memWrite sem o OUT
);
    assign reset = ~botaoReset_n;

    initial modoPreemptivo = 1'b0;
    always @(posedge clock) begin
        if (reset)
            modoPreemptivo <= chaveModo;
    end

    // Botão do IN: sincroniza e detecta o aperto (borda de descida)
    reg [2:0] botaoSync = 3'b111;
    always @(posedge clock)
        botaoSync <= {botaoSync[1:0], botaoIN_n};
    wire botaoApertado = botaoSync[2] & ~botaoSync[1];

    reg inOk = 1'b0;
    assign aguardandoIN = isIN && !inOk && !todosFinalizados;
    assign executa      = tick && !reset && !todosFinalizados && !aguardandoIN;

    always @(posedge clock or posedge reset) begin
        if (reset)
            inOk <= 1'b0;
        else if (executa && isIN)
            inOk <= 1'b0;                 // valor consumido
        else if (botaoApertado && isIN)
            inOk <= 1'b1;
    end

    assign fimProcesso           = isHalt || foraLimiteInstr || foraLimiteDados;
    assign habilitaRegistradores = executa && !fimProcesso;
    assign memWriteDados         = memWrite && !isOut;
endmodule
