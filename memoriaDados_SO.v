// Memória de dados particionada (proteção de memória por base/limite).
//
// Cada processo enxerga sua própria memória começando no endereço 0, igual
// ao que o compilador gera. O hardware soma a base do processo:
//
//     endereço físico = {processo, endereço lógico}
//                     = processo * TAM_PARTICAO + endereço lógico
//
// Acesso com endereço lógico >= TAM_PARTICAO não é feito e levanta
// foraLimite (o escalonador encerra o processo, como uma falha de segmentação).
//
// A leitura é síncrona no clock rápido (CLOCK_50) para o Quartus usar blocos
// de RAM (M9K) em vez de flip-flops. Como cada instrução dura vários ciclos
// de CLOCK_50 (sinal "habilita"/tick), o dado lido está pronto bem antes da
// instrução terminar. Por isso o divisor de clock deve ser >= 2.
module memoriaDados_SO #(
    parameter NUM_PROGS    = 10,
    parameter TAM_PARTICAO = 128
) (
    input  wire        clock,
    input  wire        habilita,     // 1 = a instrução atual está sendo executada neste ciclo
    input  wire [3:0]  processo,
    input  wire        MemRead,
    input  wire        MemWrite,
    input  wire [31:0] endereco,     // endereço lógico (saída da ULA)
    input  wire [31:0] writeData,
    output wire [31:0] readData,
    output wire        foraLimite
);
    localparam BITS_PART = $clog2(TAM_PARTICAO);

    reg [31:0] mem [0:NUM_PROGS*TAM_PARTICAO-1];

    integer i;
    initial begin
        for (i = 0; i < NUM_PROGS*TAM_PARTICAO; i = i + 1)
            mem[i] = 32'b0;
    end

    wire [BITS_PART+3:0] fisico = {processo, endereco[BITS_PART-1:0]};

    assign foraLimite = (MemRead || MemWrite) && (endereco >= TAM_PARTICAO);

    reg [31:0] dadoLido = 32'b0;

    always @(posedge clock) begin
        if (habilita && MemWrite && !foraLimite)
            mem[fisico] <= writeData;
        dadoLido <= mem[fisico];
    end

    assign readData = (MemRead && !foraLimite) ? dadoLido : 32'b0;

endmodule
