// Base de tempo do processador multiprogramado.
//
// Substitui o "temporizador" (que gerava um clock lento): todo o circuito roda
// no clock de 50 MHz e "tick" fica em 1 durante um ciclo a cada DIV ciclos.
// Cada tick executa uma instrução. Assim o botão do IN, o escalonador e as
// memórias ficam no mesmo domínio de clock.
//
// Na waveform do Quartus, mude os parâmetros deste bloco para 2 (clique com o
// botão direito no símbolo > Properties > Parameters).
module baseTempo_SO #(
    parameter DIV_LENTO  = 25_000_000,  // ciclos por instrução com rapido = 0 (>= 2)
    parameter DIV_RAPIDO = 1_000_000    // ciclos por instrução com rapido = 1 (>= 2)
) (
    input  wire clock,
    input  wire reset,
    input  wire rapido,     // SW[16]
    output wire tick
);
    reg [31:0] divCont = 32'd0;
    wire [31:0] divisor = rapido ? DIV_RAPIDO : DIV_LENTO;

    assign tick = (divCont >= divisor - 1);

    always @(posedge clock or posedge reset) begin
        if (reset)     divCont <= 32'd0;
        else if (tick) divCont <= 32'd0;
        else           divCont <= divCont + 32'd1;
    end
endmodule
