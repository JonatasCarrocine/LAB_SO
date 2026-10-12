// Saída (OUT) e estatísticas do processador multiprogramado.
//
// Guarda o último valor de OUT, o resultado de cada programa, o total de
// trocas de contexto e se algum programa foi encerrado por falha de memória.
// Também escolhe o que vai para os displays:
//   durante a execução       : programa atual | programa do último OUT | último OUT
//   depois que todos acabaram: programa em SW[3:0] | nº de trocas | resultado dele
module saidaOUT_SO #(
    parameter NUM_PROGS = 10
) (
    input  wire        clock,
    input  wire        reset,
    input  wire        executa,
    input  wire        isOut,
    input  wire [3:0]  processo,          // processoAtual do escalonador (0..9)
    input  wire [31:0] DadosUm,           // registrador rs (valor do OUT)
    input  wire        trocaContexto,
    input  wire        fimProcesso,       // para registrar falha de memória
    input  wire        isHalt,
    input  wire        todosFinalizados,
    input  wire [3:0]  selPrograma,       // SW[3:0]: programa (1..10) a mostrar no fim

    output reg  [13:0] ultimoOut,
    output wire [3:0]  programaOut,       // programa do último OUT (1..10)
    output reg  [6:0]  trocas,
    output reg         houveFalha,

    // para os displays
    output wire [6:0]  numEsquerda,       // HEX7-6
    output wire [6:0]  numMeio,           // HEX5-4
    output wire [13:0] valorDireita       // HEX3-0
);
    reg [3:0]  ultimoOutProc;
    reg [13:0] resultado [0:NUM_PROGS-1];

    integer i;
    initial begin
        ultimoOut     = 14'd0;
        ultimoOutProc = 4'd0;
        trocas        = 7'd0;
        houveFalha    = 1'b0;
        for (i = 0; i < NUM_PROGS; i = i + 1)
            resultado[i] = 14'd0;
    end

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ultimoOut     <= 14'd0;
            ultimoOutProc <= 4'd0;
            trocas        <= 7'd0;
            houveFalha    <= 1'b0;
            for (i = 0; i < NUM_PROGS; i = i + 1)
                resultado[i] <= 14'd0;
        end
        else begin
            if (executa && isOut) begin
                ultimoOut           <= DadosUm[13:0];
                ultimoOutProc       <= processo;
                resultado[processo] <= DadosUm[13:0];
            end
            if (trocaContexto && trocas != 7'd99)
                trocas <= trocas + 7'd1;
            if (executa && fimProcesso && !isHalt)
                houveFalha <= 1'b1;
        end
    end

    assign programaOut = ultimoOutProc + 4'd1;

    wire [3:0] progEscolhido = (selPrograma >= 1 && selPrograma <= NUM_PROGS) ? selPrograma - 4'd1 : 4'd0;

    assign numEsquerda  = todosFinalizados ? {3'b0, progEscolhido} + 7'd1 : {3'b0, processo} + 7'd1;
    assign numMeio      = todosFinalizados ? trocas : {3'b0, programaOut};
    assign valorDireita = todosFinalizados ? resultado[progEscolhido] : ultimoOut;
endmodule
