# Versão 2: os 10 programas em sequência, sem preempção

**Ideia:** os 10 programas ficam juntos na memória de instruções. A CPU roda o
programa 1 até o `HALT`. O `HALT`, em vez de parar a CPU, passa para o
programa 2, que começa do endereço 0. Isso se repete até o `HALT` do programa
10, e só então a CPU para.

Isso é escalonamento **sem preempção** (FCFS, "primeiro a chegar, primeiro a
ser atendido"). Um programa só sai da CPU quando termina, e ninguém o
interrompe no meio.

O top-level é o `testeComponentes_multi.bdf`. Ele é **uma cópia do seu
`testeComponentes.bdf`** com poucas alterações, listadas abaixo. O datapath
continua o mesmo.

## O que mudou em relação ao `testeComponentes.bdf`

### Blocos

| Antes | Depois | O que mudou |
|---|---|---|
| `memInstrucao` | `memInstrucao_multi` | Guarda os 10 programas. Ganhou a entrada `programa[3..0]` |
| `PC_com_IN` | `PC_multi` | No `HALT`, passa para o próximo programa em vez de travar. Ganhou as saídas `programa[3..0]` e `resetUC` |
| (não tinha) | `registradorSaida` | Guarda o valor do último `OUT` para o display |

### Fios

| Fio | Antes | Depois |
|---|---|---|
| `programa[3..0]` | não existia | sai do `PC_multi` e entra na `memInstrucao_multi` |
| `resetCPU` da **unidade de controle** | `resetCPU` | `resetUC` (vem do `PC_multi`) |
| `valor` do display HEX3-0 | `DadosUm[13..0]` | `saidaOUT[13..0]` (vem do `registradorSaida`) |

Todos os outros blocos e fios estão iguais: `registradores`,
`memoriaDados_combinacional`, `in_user`, `temporizador`, `ULA`, os muxes,
`teste_unidadeControle`, `teste_mux_jump_TESTE` e os displays.

## Como funciona, passo a passo

```
             programa[3..0]
  PC_multi  ───────────────►  memInstrucao_multi
  (PC e nº                     endereço real = (programa − 1) × 128 + PC
   do programa) ◄── isHalt ── teste_unidadeControle
      │
      └── resetUC ──► resetCPU da teste_unidadeControle
```

1. Depois do reset, `programa = 1` e `PC = 0`.
2. A `memInstrucao_multi` busca a instrução no endereço
   `(programa − 1) × 128 + PC`. Cada programa ocupa uma "gaveta" de 128
   instruções: o programa 1 fica em 0–127, o programa 2 em 128–255, e assim
   por diante.
3. O programa roda normalmente (saltos, `IN`, `OUT`, tudo como antes).
4. Quando chega o `HALT`, a unidade de controle liga o `isHalt`. No `PC_multi`:
   - se não é o último programa: `programa ← programa + 1` e `PC ← 0`;
   - se é o programa 10: `halted ← 1` e a CPU para de vez.
5. No ciclo seguinte à troca, `resetUC` dá um pulso. Isso é necessário porque a
   `teste_unidadeControle` **guarda** o HALT (o registrador `halted` interno
   dela). Sem limpar, o `isHalt` ficaria em 1 para sempre e o próximo programa
   nem começaria.

### Por que os saltos dos programas continuam funcionando

O compilador gera cada programa começando no endereço 0, com saltos absolutos
(por exemplo `jmp 22`). Como o PC continua contando a partir de 0 dentro de
cada programa, e quem soma o início da gaveta é a memória, `jmp 22` vai para a
instrução 22 **do programa atual**. Nenhum programa precisou ser recompilado.

### Por que os registradores e a memória de dados não mudaram

Sem preempção, um programa só começa depois que o anterior terminou. Ninguém
precisa guardar os registradores ou a memória de um programa enquanto outro
roda, porque o anterior já acabou. Além disso, cada programa inicializa o que
usa: começa com `ldi $27`, `ldi $28` e `ldi $29` (as bases da pilha e da
memória) e escreve cada posição antes de ler. A simulação confirma isso: os
10 programas dão o resultado certo usando o mesmo banco de registradores e a
mesma memória de dados.

Isso **só vale sem preempção**. Com preempção, um programa é interrompido no
meio e outro usa a CPU. Aí seria preciso salvar o PC e os registradores de
cada um (troca de contexto) e separar a memória de dados. É o que a versão 1
(`processadorSO_nucleo.v`) faz.

## Os três arquivos novos

### `PC_multi.v`

É o `PC_com_IN` com a parte do HALT trocada:

```verilog
else if (isHalt) begin
    if (programa == NUM_PROGS)
        halted <= 1'b1;               // HALT do último programa
    else begin
        programa <= programa + 4'd1;  // HALT: próximo programa
        pcAtual <= 32'b0;             // começa do endereço 0
        trocouPrograma <= 1'b1;
    end
end
```

E `assign resetUC = resetCPU | trocouPrograma;`

### `memInstrucao_multi.v`

É gerado pelo script `ferramentas/gera_memInstrucao.py` a partir de
`programas/prog01.txt` … `prog10.txt`, que estão no formato que o seu
compilador gera (`mem[0] = 32'b...;`). A parte importante:

```verilog
wire [31:0] enderecoReal = (programa - 1) * TAM_PARTICAO + endInstr;
assign pcInstr = mem[enderecoReal];
assign posMem  = {18'b0, 3'b0, programa, endInstr[6:0]};
```

O `posMem` mudou de propósito: os displays que já estavam ligados a ele
passam a mostrar o PC e o número do programa.

### `registradorSaida.v`

```verilog
always @(posedge clock or posedge reset)
    if (reset)      valor <= 0;
    else if (isOut) valor <= dado;   // dado = DadosUm[13..0]
```

Antes o HEX3-0 mostrava `DadosUm` direto, que muda a cada instrução. O
resultado só aparecia no ciclo do `OUT`. Agora ele fica no display até o
próximo `OUT`.

## Na placa

As entradas são as mesmas do seu projeto (`clockUm`, `rstCPU`, `botaoIn`,
`SW[8..0]`), e o `IN` funciona igual a antes.

| Display | Mostra |
|---|---|
| HEX7-6 | PC do programa atual (`posMem[6..0]`) |
| HEX5-4 | número do programa em execução, de 1 a 10 (`posMem[13..7]`) |
| HEX3-0 | valor do último `OUT` |

O pino `haltedd` vai para 1 quando os 10 programas terminam.

## Na waveform do Quartus

1. O `temporizador` divide o clock por 2²⁵, o que é lento demais para a
   waveform. **Só para simular**, troque em `temporizador.v`:
   `assign reduzclock = contador[24];` → `assign reduzclock = contador[0];`.
   Volte para `contador[24]` antes de gravar na placa.
2. Compile (Ctrl+K) com `testeComponentes_multi` como top-level.
3. *File → New → University Program VWF*. Em *Edit → Set End Time*, coloque
   **35 us**. Insira os pinos pelo *Node Finder* (filtro *Pins: all*).
4. Entradas:

| Entrada | Valor |
|---|---|
| `clockUm` | clock com período de 20 ns |
| `rstCPU` | 0 de 0 a 100 ns, depois 1 (ele passa por um NOT, então 0 = reset) |
| `botaoIn` | clock com período de 800 ns ("aperta" sozinho; só faz efeito quando a CPU está esperando um IN) |
| `SW[8..0]` | 3 (todo `IN` recebe 3) |

5. Observe `posicao[31..0]` (bits 13..7 = programa, bits 6..0 = PC),
   `pcAtual`, `isHalt`, `haltedd` e `outDISPLAY`. O `outDISPLAY` mostra o
   valor no ciclo do `OUT`. O valor guardado aparece no HEX3-0.

Resultado esperado com todas as entradas iguais a 3 (verificado no simulador
com o próprio BDF):

| Programa | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Cálculo | 3+3+3 | 3×3 | 3×3/2 | mdc(3,3) | 3 é múltiplo de 3 | 3−3 | a = b | 3! | 3³ | 1+2+3 |
| OUT | 9 | 9 | 4 | 3 | 1 | 0 | 3 | 6 | 27 | 6 |

Cada programa termina antes do próximo começar, e o `haltedd` sobe por volta
de **28 µs**.

## Simulação no computador (sem Quartus)

```sh
sh simulacao_v2/simula_v2.sh
```

O script converte o próprio `testeComponentes_multi.bdf` para Verilog
(`ferramentas/bdf_para_verilog.py`), roda os 10 programas com entradas
diferentes e confere cada resultado. A saída fica em `simulacao_v2/log.txt`.
O mesmo conversor, aplicado ao `testeComponentes.bdf` original rodando o
fatorial de 5, dá `OUT = 120`, o que confirma que ele lê o BDF corretamente.

## Perguntas que o professor pode fazer

**Por que a mudança foi no processador e não no compilador?**
Os programas continuam iguais, compilados a partir do endereço 0. Quem decide
qual programa roda e onde ele está na memória é o hardware (`PC_multi` e
`memInstrucao_multi`). Esse é o papel de um sistema operacional: gerenciar a
execução dos programas sem que eles precisem saber disso.

**O que é "sem preempção" aqui?**
O programa só deixa a CPU quando executa `HALT`. Não há temporizador
interrompendo. A ordem é fixa: 1, 2, …, 10.

**O que acontece se um programa entrar em loop infinito?**
Os programas seguintes nunca rodam. Essa é a principal desvantagem do
escalonamento sem preempção, e é o que a preempção (quantum) resolve.

**Por que precisou do `resetUC`?**
A `teste_unidadeControle` guarda o HALT num registrador interno (`halted`), que
só é limpo pelo `resetCPU`. Na troca de programa, o `PC_multi` dá um pulso
nesse reset para a unidade de controle "esquecer" o HALT do programa anterior.

**Por que não salvar os registradores na troca?**
Porque o programa anterior terminou e não volta mais. Salvar o contexto só é
necessário quando um programa é interrompido no meio, ou seja, com preempção.

**Como o PC sabe onde está cada programa?**
O PC não sabe: ele sempre conta a partir de 0. A memória soma
`(programa − 1) × 128`, que é o endereço de início (a "base") do programa
atual.
