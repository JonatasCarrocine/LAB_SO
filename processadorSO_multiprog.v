// Top-level para a placa DE2-115. Veja a descrição das chaves, botões,
// displays e LEDs em processadorSO_nucleo.v.
module processadorSO_multiprog (
    input  wire        CLOCK_50,
    input  wire [1:0]  KEY,
    input  wire [17:0] SW,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
    output wire [17:0] LEDR,
    output wire [8:0]  LEDG
);

    processadorSO_nucleo u_nucleo (
        .CLOCK_50(CLOCK_50), .KEY(KEY), .SW(SW),
        .HEX0(HEX0), .HEX1(HEX1), .HEX2(HEX2), .HEX3(HEX3),
        .HEX4(HEX4), .HEX5(HEX5), .HEX6(HEX6), .HEX7(HEX7),
        .LEDR(LEDR), .LEDG(LEDG),
        .dbg_programa(), .dbg_pc(), .dbg_instrucao(), .dbg_executa(),
        .dbg_quantum(), .dbg_trocaContexto(), .dbg_preempcao(),
        .dbg_aguardandoIN(), .dbg_todosFinalizados(), .dbg_finalizados(),
        .dbg_programaOut(), .dbg_valorOut(), .dbg_trocas()
    );

endmodule
