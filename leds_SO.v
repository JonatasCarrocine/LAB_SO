// Monta os barramentos de LEDs da DE2-115.
//   LEDR[9:0]   : programas já finalizados
//   LEDR[17:11] : PC lógico do programa em execução
//   LEDG[0]     : aguardando entrada (IN)
//   LEDG[1]     : modo com preempção
//   LEDG[2]     : todos os programas terminaram
//   LEDG[3]     : algum programa foi encerrado por acesso fora da sua memória
module leds_SO (
    input  wire [9:0]  finalizados,
    input  wire [31:0] pc,
    input  wire        aguardandoIN,
    input  wire        modoPreemptivo,
    input  wire        todosFinalizados,
    input  wire        houveFalha,
    output wire [17:0] LEDR,
    output wire [8:0]  LEDG
);
    assign LEDR = {pc[6:0], 1'b0, finalizados};
    assign LEDG = {5'b0, houveFalha, todosFinalizados, modoPreemptivo, aguardandoIN};
endmodule
