// Testbench da versão 2 (sem preempção).
//
// Simula o próprio testeComponentes_multi.bdf: o script simula_v2.sh converte
// o BDF para Verilog (módulo multi_bdf) com ferramentas/bdf_para_verilog.py.
// O testbench faz o papel do usuário: quando a CPU para no IN, coloca o
// valor nas chaves e aperta o botão. Confere o OUT de cada programa.
`timescale 1ns/1ps
module tb_multi_v2;
  reg clockUm=0, rstCPU=0, botaoIn=1; reg [8:0] SW=0;
  wire [31:0] pcAtual, Instrucao; wire haltedd;
  multi_bdf dut(.rstCPU(rstCPU), .clockUm(clockUm), .SW(SW), .botaoIn(botaoIn),
                .pcAtual(pcAtual), .Instrucao(Instrucao), .haltedd(haltedd));
  always #10 clockUm = ~clockUm;

  reg [8:0] entradas [1:10][0:3]; reg [31:0] esperado [1:10]; integer prox [1:10];
  integer k, p, erros = 0, ciclos = 0;
  initial begin
    entradas[1][0]=5;  entradas[1][1]=7; entradas[1][2]=9; esperado[1]=21;
    entradas[2][0]=6;  entradas[2][1]=7;  esperado[2]=42;
    entradas[3][0]=10; entradas[3][1]=6;  esperado[3]=30;
    entradas[4][0]=48; entradas[4][1]=18; esperado[4]=6;
    entradas[5][0]=9;                     esperado[5]=1;
    entradas[6][0]=20; entradas[6][1]=8;  esperado[6]=12;
    entradas[7][0]=3;  entradas[7][1]=8;  esperado[7]=1;
    entradas[8][0]=6;                     esperado[8]=720;
    entradas[9][0]=2;  entradas[9][1]=5;  esperado[9]=32;
    entradas[10][0]=20;                   esperado[10]=210;
    for (k=1;k<=10;k=k+1) prox[k]=0;
    for (k=0;k<32;k=k+1) dut.inst18.registradores[k]=0;   // FPGA liga com 0
    for (k=0;k<81;k=k+1) dut.inst10.mem[k]=0;
    #45 rstCPU = 1;
    while (!haltedd && ciclos < 20000) begin
      @(posedge clockUm); ciclos = ciclos + 1;
      // usuário: CPU parada no IN -> ajusta as chaves e aperta o botão
      if (dut.inst14.state == 1) begin
        p = dut.inst.programa;
        #3 SW = entradas[p][prox[p]]; prox[p] = prox[p] + 1; botaoIn = 0;
        @(posedge clockUm); #3 botaoIn = 1;
      end
    end
    $display("fim: haltedd=%b apos %0d ciclos", haltedd, ciclos);
    if (erros == 0 && haltedd) $display("RESULTADO: os 10 programas deram o resultado esperado");
    else $display("RESULTADO: %0d erro(s)", erros);
    $finish;
  end
  // registra cada OUT
  always @(posedge clockUm) if (rstCPU && dut.inst4.isOut) begin
    #1 $display("programa %0d: OUT = %0d (esperado %0d) %s", dut.inst.programa, dut.inst90.valor,
               esperado[dut.inst.programa], dut.inst90.valor == esperado[dut.inst.programa] ? "ok" : "<-- ERRO");
    if (dut.inst90.valor != esperado[dut.inst.programa]) erros = erros + 1;
  end
  always @(posedge clockUm) if (dut.inst.resetUC && rstCPU) #1 $display("  -> HALT: comeca o programa %0d (pc=%0d)", dut.inst.programa, pcAtual);
endmodule
