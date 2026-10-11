# Processador multiprogramado: execução sem e com preempção

Os 10 programas gerados pelo compilador ficam carregados ao mesmo tempo
no processador. Eles podem rodar de dois jeitos, escolhidos pela chave SW[17]
no momento do reset:

| Modo | SW[17] | Política | Quando o processo perde a CPU |
|---|---|---|---|
| Sem preempção | 0 | FCFS (lote) | só quando executa `HALT` |
| Com preempção | 1 | Round-Robin, quantum = 10 instruções | no `HALT` **ou** ao fim do quantum (interrupção de tempo) |

## Onde a mudança foi feita: processador ou compilador?

**No processador.** O compilador não muda nada, por três motivos:

1. **Preempção depende de hardware.** Quem tira a CPU de um programa no meio
   da execução é um temporizador (quantum), e o programa não sabe quando isso
   acontece. Se o compilador inserisse instruções de "ceder a vez" no código,
   o resultado seria escalonamento cooperativo, e não preempção.
2. **Relocação transparente.** Todo programa é compilado a partir do endereço 0
   (código e dados: `ldi $27,0`, `ldi $29,47`, saltos absolutos, endereço de
   retorno guardado na pilha). O hardware soma a base da partição de cada
   processo (registrador base/limite). Assim o mesmo binário funciona em
   qualquer partição, sem recompilar.
3. **Troca de contexto.** O PC e os registradores de cada processo precisam ser
   salvos e restaurados. Isso é papel do hardware/SO, não do programa.

O único passo "do lado do software" é colocar a saída do compilador em
`programas/progNN.txt` e rodar o script que monta a memória de instruções.

## O que foi acrescentado

| Arquivo | Função |
|---|---|
| `processadorSO_multiprog.v` | Novo top-level. Reaproveita o datapath monociclo (`teste_unidadeControle`, `ULA`, `extensorSinal`, `mux_*`, `somadorUm`, `teste_mux_jump_TESTE`, displays) |
| `escalonador_SO.v` | Tabela de processos (PCB com o PC salvo e o estado finalizado). FCFS ou Round-Robin. Salva e restaura o PC na troca de contexto |
| `bancoRegistradores_SO.v` | 32 registradores **por processo**: o contexto dos registradores fica preservado enquanto o processo está fora da CPU |
| `memInstrucao_SO.v` | **Gerado.** Uma partição de 128 instruções por programa. Endereço físico = `{processo, PC lógico}` |
| `memoriaDados_SO.v` | Uma partição de 128 palavras por programa (base/limite). Um acesso fora da partição encerra o processo (como uma falha de segmentação) |
| `programas/prog01..10.txt` | Os 10 programas, no formato que o compilador gera |
| `ferramentas/gera_memInstrucao.py` | Gera `memInstrucao_SO.v` a partir de `programas/` |
| `tb_processadorSO.v` | Testbench: roda os dois modos e confere os resultados |
| `ferramentas/gantt.py` | Desenha o diagrama de Gantt (`simulacao/gantt.png`) |

Os arquivos antigos (`testeComponentes.bdf`, `escalonador_RR*.v`, `PC_RR.v`
etc.) continuam no projeto, sem alterações. O `iZero.qsf` aponta para o novo
top-level `processadorSO_multiprog`. Para voltar ao processador de um programa
só, troque o `TOP_LEVEL_ENTITY` de volta para `testeComponentes`.

### Troca de contexto (Round-Robin)

No ciclo em que o processo executa a 10ª instrução do quantum:

1. `pcb[atual] <= PC seguinte` (salva o contexto).
2. O escalonador escolhe o próximo processo não finalizado, em ordem circular.
3. `PC <= pcb[próximo]` (restaura o contexto). Os registradores do próximo
   processo já estão no banco dele.

No `HALT`, o processo é marcado como finalizado e sai da fila. Quando todos
terminam, a CPU para.

### Entrada (IN)

Quando o processo atual executa um `IN`, a CPU espera o usuário (o LEDG[0]
acende). O display mostra qual programa está pedindo o valor. O tempo de espera
**não** consome o quantum, porque o quantum conta instruções executadas.

## Uso na placa (DE2-115)

As portas usam os nomes padrão da DE2-115 (`CLOCK_50`, `KEY`, `SW`, `HEX0..7`,
`LEDR`, `LEDG`). Para mapear os pinos, importe o arquivo de pinos da Terasic
(`DE2_115.qsf`) em *Assignments → Import Assignments*.

| Entrada | Função |
|---|---|
| KEY[0] | reset (o modo é lido de SW[17] neste momento) |
| KEY[1] | confirma o valor do `IN` |
| SW[8:0] | valor do `IN` |
| SW[16] | 0 = lento (cerca de 2 instr/s), 1 = rápido (cerca de 50 instr/s) |
| SW[17] | 0 = sem preempção, 1 = com preempção |
| SW[3:0] | depois que todos terminam, escolhe o programa cujo resultado é mostrado |

| Saída | Durante a execução | Depois que todos terminam |
|---|---|---|
| HEX7-6 | programa em execução | programa escolhido em SW[3:0] |
| HEX5-4 | programa que fez o último OUT | número de trocas de contexto |
| HEX3-0 | valor do último OUT | resultado do programa escolhido |
| LEDR[9:0] | programas finalizados | |
| LEDR[17:11] | PC lógico do programa atual | |
| LEDG[0..3] | aguardando IN / modo preemptivo / todos terminaram / houve falha de memória | |

## Simulação

```sh
python3 ferramentas/gera_memInstrucao.py          # só se mudar algum programa
iverilog -g2012 -o simulacao/tb.vvp -f simulacao/arquivos.txt
vvp simulacao/tb.vvp | tee simulacao/log.txt
python3 ferramentas/gantt.py                      # opcional, precisa de matplotlib
```

Para outro quantum: `iverilog -g2012 -Ptb_processadorSO.QUANTUM=5 ...`

### Resultado (quantum = 10, saída completa em `simulacao/log.txt`)

Os 10 programas dão o mesmo resultado nos dois modos. A tabela abaixo mostra
como o escalonamento muda. Os tempos são contados em instruções executadas.
Todos os programas chegam em t = 0.

| Proc | Programa | Instr. | Término FCFS | Término RR | 1ª vez na CPU FCFS | 1ª vez na CPU RR | Resultado |
|---|---|---|---|---|---|---|---|
| P1 | soma 3 entradas (5,7,9) | 52 | 52 | 458 | 0 | 0 | 21 |
| P2 | multiplicação (6,7) | 39 | 91 | 319 | 52 | 10 | 42 |
| P3 | área do triângulo (10,6) | 41 | 132 | 410 | 91 | 20 | 30 |
| P4 | mdc (48,18) | 122 | 254 | 740 | 132 | 30 | 6 |
| P5 | divisível por 3 (9) | 40 | 294 | 349 | 254 | 40 | 1 |
| P6 | subtração (20,8) | 45 | 339 | 425 | 294 | 50 | 12 |
| P7 | compara (3,8) | 41 | 380 | 426 | 339 | 60 | 1 |
| P8 | fatorial (6) | 178 | 558 | 862 | 380 | 70 | 720 |
| P9 | potência (2,5) | 134 | 692 | 784 | 558 | 80 | 32 |
| P10 | somatório (20) | 514 | 1206 | 1206 | 692 | 90 | 210 |

| Métrica | Sem preempção | Com preempção |
|---|---|---|
| Tempo total | 1206 | 1206 |
| Trocas de contexto | 9 | 91 (82 por quantum) |
| Turnaround médio | 399.8 | 597.9 |
| Espera média | 279.2 | 477.3 |
| Tempo de resposta médio | 279.2 | **45.0** |

Leitura: com todos os programas chegando juntos, o FCFS termina os processos
mais cedo em média (turnaround menor). O Round-Robin dá a CPU a todos logo no
começo (tempo de resposta cerca de 6 vezes menor), mas paga com mais trocas
de contexto e turnaround maior.

O testbench também foi rodado com quantum 1, 2, 3, 7, 25 e 1000. Com
quantum 1 há uma troca a cada instrução (869 trocas) e todos os resultados
continuam corretos, o que mostra que o contexto é preservado.

![Gantt](simulacao/gantt.png)

## Para adicionar ou trocar um programa

1. Compile normalmente (a partir do endereço 0) e salve a saída
   `mem[i] = 32'b...;` em `programas/progNN.txt`. A primeira linha de
   comentário vira o título.
2. Rode `python3 ferramentas/gera_memInstrucao.py`.
3. Ajuste `NUM_PROGS` se mudar a quantidade (máximo 16). Cada programa
   precisa caber em 128 instruções e 128 palavras de dados.
