# Montando o top-level em BDF

O arquivo `processadorSO_nucleo.v` só liga blocos, sem lógica própria. Cada
instância dele vira **um símbolo** no BDF e cada `wire` vira **um fio ou
barramento com aquele nome**. Este guia traz a mesma ligação em forma de
tabela. Se ficar dúvida em algum fio, o `.v` é a referência.

## 1. Gerar os símbolos (.bsf)

Abra cada arquivo abaixo no Quartus e use
*File → Create/Update → Create Symbol Files for Current File*:

| Novos (precisam de símbolo) | Já existentes (regere o símbolo para garantir que bate com o .v) |
|---|---|
| `baseTempo_SO.v` | `teste_unidadeControle.v` |
| `controleExecucao_SO.v` | `ULA.v` |
| `escalonador_SO.v` | `extensorSinal.v` |
| `memInstrucao_SO.v` | `mux_regdst.v`, `mux_alusrc.v`, `mux_memtoreg.v` |
| `memoriaDados_SO.v` | `somadorUm.v` |
| `bancoRegistradores_SO.v` | `teste_mux_jump_TESTE.v` |
| `saidaOUT_SO.v` | `display7seg_2decimais.v`, `display7seg_decimal.v` |
| `leds_SO.v` | |

## 2. Criar o BDF

1. *File → New → Block Diagram/Schematic File*. Salve como `SO_multiprog.bdf`
   (o projeto já tem um `processadorSO.bdf` antigo, então use outro nome).
2. Botão direito no arquivo em *Project Navigator → Files* → *Set as Top-Level Entity*.
3. Insira os símbolos com duplo clique na área do desenho → *Project*.
4. Insira os pinos (*Pin Tool* ou duplo clique → `primitives/pin`):

| Tipo | Nome do pino |
|---|---|
| input | `CLOCK_50`, `KEY[1..0]`, `SW[17..0]` |
| output | `HEX0[6..0]` … `HEX7[6..0]`, `LEDR[17..0]`, `LEDG[8..0]` |

### Como ligar sem fios cruzando a tela inteira

No BDF, **dois fios com o mesmo nome estão ligados**, mesmo sem uma linha entre
eles. Faça um fio curto saindo de cada porta, clique com o botão direito nele
→ *Properties* e dê o nome da tabela. Para pegar parte de um barramento, use a
notação `..` do Quartus, por exemplo `instrucao[25..21]` ou `SW[8..0]`.

Um pino também é um fio com nome: o pino `SW[17..0]` já cria os nomes
`SW[17]`, `SW[16]`, `SW[8..0]`, … Basta usar esses nomes nas portas.

## 3. Ligações, bloco por bloco

Nas tabelas, "fio" é o nome que você coloca no fio ligado àquela porta.

### baseTempo_SO
| Porta | Fio |
|---|---|
| clock | `CLOCK_50` |
| reset | `reset` |
| rapido | `SW[16]` |
| tick | `tick` |

Parâmetros: `DIV_LENTO = 25000000`, `DIV_RAPIDO = 1000000` na placa. **Para a
waveform, mude os dois para 2** (botão direito no símbolo → *Properties* →
*Parameters*).

### controleExecucao_SO
| Porta | Fio |
|---|---|
| clock | `CLOCK_50` |
| botaoReset_n | `KEY[0]` |
| botaoIN_n | `KEY[1]` |
| chaveModo | `SW[17]` |
| tick | `tick` |
| todosFinalizados | `todosFinalizados` |
| isIN / isOut / isHalt / memWrite | `isIN` / `isOut` / `isHalt` / `memWrite` |
| foraLimiteInstr / foraLimiteDados | `foraLimiteInstr` / `foraLimiteDados` |
| **saídas:** reset | `reset` |
| modoPreemptivo | `modoPreemptivo` |
| executa | `executa` |
| aguardandoIN | `aguardandoIN` |
| fimProcesso | `fimProcesso` |
| habilitaRegistradores | `habilitaRegistradores` |
| memWriteDados | `memWriteDados` |

### escalonador_SO
| Porta | Fio |
|---|---|
| clock / reset | `CLOCK_50` / `reset` |
| executa | `executa` |
| modoPreemptivo | `modoPreemptivo` |
| pcProx[31..0] | `pcProx[31..0]` |
| fimProcesso | `fimProcesso` |
| **saídas:** processoAtual[3..0] | `processoAtual[3..0]` |
| numeroPrograma[3..0] | `numeroPrograma[3..0]` |
| pcAtual[31..0] | `pcAtual[31..0]` |
| finalizado[9..0] | `finalizado[9..0]` |
| todosFinalizados | `todosFinalizados` |
| trocaContexto / preempcao | `trocaContexto` / `preempcao` |
| contQuantum[7..0] | `contQuantum[7..0]` |

Parâmetros: `NUM_PROGS = 10`, `QUANTUM = 10` (mude aqui o quantum).

### memInstrucao_SO
| Porta | Fio |
|---|---|
| processo[3..0] | `processoAtual[3..0]` |
| pcLogico[31..0] | `pcAtual[31..0]` |
| instrucao[31..0] | `instrucao[31..0]` |
| foraLimite | `foraLimiteInstr` |

### teste_unidadeControle
| Porta | Fio |
|---|---|
| opcode[5..0] | `instrucao[31..26]` |
| clock | `CLOCK_50` |
| resetCPU | **VCC** (símbolo `primitives/other/vcc`) |
| isOut, jump, regDst, regWrite, ALUSrc, memRead, memWrite, memToReg, isJr | fios com o mesmo nome da porta |
| opULA[3..0] | `opULA[3..0]` |
| PCSource[1..0] | `PCSource[1..0]` |
| isHalt, isIN, isBranch, isBranchNotEqual | fios com o mesmo nome da porta |

`jump` e `isJr` podem ficar sem ligação (o `PCSource` já carrega essa informação).

### mux_regdst
| Porta | Fio |
|---|---|
| rt[4..0] | `instrucao[20..16]` |
| rd[4..0] | `instrucao[15..11]` |
| regDst | `regDst` |
| writeReg[4..0] | `regEscrita[4..0]` |

### bancoRegistradores_SO
| Porta | Fio |
|---|---|
| clock | `CLOCK_50` |
| habilita | `habilitaRegistradores` |
| processo[3..0] | `processoAtual[3..0]` |
| leituraUm[4..0] | `instrucao[25..21]` |
| leituraDois[4..0] | `instrucao[20..16]` |
| regEscrita[4..0] | `regEscrita[4..0]` |
| escreveDado[31..0] | `escreveDado[31..0]` |
| escreveReg | `regWrite` |
| isIN | `isIN` |
| inData[8..0] | `SW[8..0]` |
| DadosUm[31..0] / DadosDois[31..0] | `DadosUm[31..0]` / `DadosDois[31..0]` |

### extensorSinal
| Porta | Fio |
|---|---|
| entrada[15..0] | `instrucao[15..0]` |
| extendido[31..0] | `extendido[31..0]` |

### mux_alusrc
| Porta | Fio |
|---|---|
| readDataDois[31..0] | `DadosDois[31..0]` |
| immExt[31..0] | `extendido[31..0]` |
| aluSrc | `ALUSrc` |
| aluInDois[31..0] | `entradaULA[31..0]` |

### ULA
| Porta | Fio |
|---|---|
| a[31..0] | `DadosUm[31..0]` |
| b[31..0] | `entradaULA[31..0]` |
| alu_control[3..0] | `opULA[3..0]` |
| resultado[31..0] | `resultadoULA[31..0]` |
| zero | `zero` |

### memoriaDados_SO
| Porta | Fio |
|---|---|
| clock | `CLOCK_50` |
| habilita | `executa` |
| processo[3..0] | `processoAtual[3..0]` |
| MemRead | `memRead` |
| MemWrite | `memWriteDados` (**não** o `memWrite` direto) |
| endereco[31..0] | `resultadoULA[31..0]` |
| writeData[31..0] | `DadosDois[31..0]` |
| readData[31..0] | `dadoMemoria[31..0]` |
| foraLimite | `foraLimiteDados` |

### mux_memtoreg
| Porta | Fio |
|---|---|
| lerDado[31..0] | `dadoMemoria[31..0]` |
| resultadoUla[31..0] | `resultadoULA[31..0]` |
| memToReg | `memToReg` |
| escreveDado[31..0] | `escreveDado[31..0]` |

### somadorUm
| Porta | Fio |
|---|---|
| in[31..0] | `pcAtual[31..0]` |
| mais[31..0] | `pcMaisUm[31..0]` |

### teste_mux_jump_TESTE
| Porta | Fio |
|---|---|
| pcBranch[31..0] | `pcMaisUm[31..0]` |
| jumpEnd[31..0] | `extendido[31..0]` |
| jrEnd[31..0] | `DadosUm[31..0]` |
| Branch | `isBranch` |
| Zero | `zero` |
| isBranchNotEqual | `isBranchNotEqual` |
| PCSource[1..0] | `PCSource[1..0]` |
| pcProx[31..0] | `pcProx[31..0]` |

### saidaOUT_SO
| Porta | Fio |
|---|---|
| clock / reset | `CLOCK_50` / `reset` |
| executa | `executa` |
| isOut | `isOut` |
| processo[3..0] | `processoAtual[3..0]` |
| DadosUm[31..0] | `DadosUm[31..0]` |
| trocaContexto | `trocaContexto` |
| fimProcesso | `fimProcesso` |
| isHalt | `isHalt` |
| todosFinalizados | `todosFinalizados` |
| selPrograma[3..0] | `SW[3..0]` |
| **saídas:** ultimoOut[13..0] | `ultimoOut[13..0]` |
| programaOut[3..0] | `programaOut[3..0]` |
| trocas[6..0] | `trocas[6..0]` |
| houveFalha | `houveFalha` |
| numEsquerda[6..0] | `numEsquerda[6..0]` |
| numMeio[6..0] | `numMeio[6..0]` |
| valorDireita[13..0] | `valorDireita[13..0]` |

### Displays (3 símbolos)
| Símbolo | valor | Saídas |
|---|---|---|
| display7seg_2decimais | `numEsquerda[6..0]` | seg_unidade → `HEX6[6..0]`, seg_dezena → `HEX7[6..0]` |
| display7seg_2decimais | `numMeio[6..0]` | seg_unidade → `HEX4[6..0]`, seg_dezena → `HEX5[6..0]` |
| display7seg_decimal | `valorDireita[13..0]` | seg_unidade → `HEX0`, seg_dezena → `HEX1`, seg_centena → `HEX2`, seg_milhar → `HEX3` |

Nos três: `clk` → `CLOCK_50` e `reset` → `reset`.

### leds_SO
| Porta | Fio |
|---|---|
| finalizados[9..0] | `finalizado[9..0]` |
| pc[31..0] | `pcAtual[31..0]` |
| aguardandoIN | `aguardandoIN` |
| modoPreemptivo | `modoPreemptivo` |
| todosFinalizados | `todosFinalizados` |
| houveFalha | `houveFalha` |
| LEDR[17..0] | pino `LEDR[17..0]` |
| LEDG[8..0] | pino `LEDG[8..0]` |

## 4. Conferir

1. *Processing → Start → Start Analysis & Elaboration*. Erros comuns:
   - **"width mismatch"**: um fio com nome de largura diferente da porta
     (por exemplo `instrucao[25..20]` em vez de `instrucao[25..21]`).
   - **fio sem nome solto**: aparece como aviso de porta sem ligação. Confira
     se todas as portas das tabelas estão ligadas (só `jump` e `isJr` podem
     ficar soltas).
2. Em *Tools → Netlist Viewers → RTL Viewer*, compare com a hierarquia de
   `processadorSO_nucleo` (os mesmos blocos devem aparecer ligados).

## 5. Waveform com o BDF

Use o próprio BDF como top-level, com duas mudanças:

1. Em `baseTempo_SO`, coloque `DIV_LENTO = 2` e `DIV_RAPIDO = 2`.
2. Para ver os sinais internos, crie **pinos de saída extras** com o mesmo
   nome dos fios que quiser observar (assim eles se ligam pelo nome), por
   exemplo `numeroPrograma[3..0]`, `pcAtual[31..0]`, `contQuantum[7..0]`,
   `preempcao`, `trocaContexto`, `aguardandoIN`, `finalizado[9..0]`,
   `programaOut[3..0]` e `ultimoOut[13..0]`. Se o Quartus reclamar do nome,
   dê outro nome ao pino (por exemplo `out_programa[3..0]`) e ligue com uma
   linha até o fio.

As entradas da waveform passam a ser os pinos da placa (ativos em 0):

| Entrada | Valor |
|---|---|
| `CLOCK_50` | clock com período de 20 ns |
| `KEY[0]` (reset) | **0** de 0 a 100 ns, depois **1** |
| `KEY[1]` (botão IN) | clock com período de 400 ns |
| `SW[17]` | 0 = sem preempção, 1 = com preempção |
| `SW[8..0]` | 3 |
| demais `SW` | 0 |

O resultado esperado é o mesmo do `README_SO.md`: OUTs 9, 9, 4, 3, 1, 0, 3, 6,
27, 6, com término por volta de 30 µs (sem preempção) e 27 µs (com preempção).

Antes de montar a placa de novo, volte os parâmetros do `baseTempo_SO` para
os valores originais.
