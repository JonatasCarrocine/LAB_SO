// Só para simulação no Icarus: a porta NOT do Quartus e um temporizador que
// não divide o clock (o original divide por 2^25, lento demais para simular).
module NOT (input IN, output OUT); assign OUT = ~IN; endmodule
module temporizador (input clock, output reduzclock); assign reduzclock = clock; endmodule
