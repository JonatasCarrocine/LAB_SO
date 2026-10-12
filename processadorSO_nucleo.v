// Núcleo do processador multiprogramado: executa os 10 programas carregados em
// memInstrucao_SO, com ou sem preempção.
//
// Reaproveita o datapath monociclo do projeto (teste_unidadeControle, ULA,
// extensorSinal, muxes, somadorUm, teste_mux_jump_TESTE, displays) e
// acrescenta o suporte do "sistema operacional" em hardware:
//   - escalonador_SO          : tabela de processos, FCFS ou Round-Robin
//   - bancoRegistradores_SO   : um banco de 32 registradores por processo
//   - memInstrucao_SO         : uma partição de instruções por processo
//   - memoriaDados_SO         : uma partição de dados por processo (base/limite)
//
// Os programas não mudam: cada um continua compilado a partir do endereço 0.
//
// Este é o núcleo. Os top-levels são:
//   processadorSO_multiprog : placa DE2-115 (mesmas portas abaixo)
//   processadorSO_sim       : simulação na waveform do Quartus (clock rápido e
//                             sinais internos como pinos)
//
// Ligações na DE2-115:
//   CLOCK_50  : clock de 50 MHz
//   KEY[0]    : reset (ativo em 0). O modo é lido de SW[17] no reset.
//   KEY[1]    : confirma o valor de entrada da instrução IN (ativo em 0)
//   SW[8:0]   : valor de entrada da instrução IN
//   SW[16]    : 0 = clock lento (~2 instr/s), 1 = clock rápido (~50 instr/s)
//   SW[17]    : 0 = SEM preempção (FCFS), 1 = COM preempção (Round-Robin)
//   SW[3:0]   : depois que todos terminam, escolhe o programa (1..10) cujo
//               resultado aparece no display
//
//   Durante a execução:
//     HEX7-6 : programa em execução (1..10)
//     HEX5-4 : programa que fez o último OUT
//     HEX3-0 : valor do último OUT
//   Depois que todos terminam:
//     HEX7-6 : programa escolhido em SW[3:0]
//     HEX5-4 : número de trocas de contexto que ocorreram
//     HEX3-0 : resultado (OUT) do programa escolhido
//
//   LEDR[9:0]   : programas já finalizados
//   LEDR[17:11] : PC lógico do programa em execução
//   LEDG[0]     : aguardando entrada (IN) - ajuste SW[8:0] e aperte KEY[1]
//   LEDG[1]     : modo com preempção
//   LEDG[2]     : todos os programas terminaram
//   LEDG[3]     : algum programa foi encerrado por acesso fora da sua memória
//
// Este arquivo é só ligação entre blocos (nenhuma lógica própria): cada
// instância abaixo corresponde a um símbolo do BDF, e cada "wire" a um fio ou
// barramento com aquele nome. Veja MONTAGEM_BDF.md.
module processadorSO_nucleo #(
    parameter NUM_PROGS    = 10,
    parameter TAM_PARTICAO = 128,
    parameter QUANTUM      = 10,          // instruções por fatia (modo preemptivo)
    parameter DIV_LENTO    = 25_000_000,  // ciclos de 50 MHz por instrução (>= 2)
    parameter DIV_RAPIDO   = 1_000_000    // (>= 2, a memória de dados lê em 1 ciclo)
) (
    input  wire        CLOCK_50,
    input  wire [1:0]  KEY,
    input  wire [17:0] SW,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
    output wire [17:0] LEDR,
    output wire [8:0]  LEDG,

    // Sinais internos para depuração (usados pelo processadorSO_sim na waveform)
    output wire [3:0]  dbg_programa,        // programa em execução (1..10)
    output wire [31:0] dbg_pc,              // PC lógico do programa em execução
    output wire [31:0] dbg_instrucao,
    output wire        dbg_executa,         // 1 = instrução executada neste ciclo
    output wire [7:0]  dbg_quantum,         // instruções já usadas do quantum
    output wire        dbg_trocaContexto,   // pulso: trocou de programa
    output wire        dbg_preempcao,       // pulso: troca por fim de quantum
    output wire        dbg_aguardandoIN,
    output wire        dbg_todosFinalizados,
    output wire [9:0]  dbg_finalizados,
    output wire [3:0]  dbg_programaOut,     // programa que fez o último OUT (1..10)
    output wire [13:0] dbg_valorOut,        // valor do último OUT
    output wire [6:0]  dbg_trocas
);

    // ---------------- fios (nomes iguais aos do BDF) ----------------
    wire        clock = CLOCK_50;
    wire        reset, tick, modoPreemptivo, executa, aguardandoIN;
    wire        fimProcesso, habilitaRegistradores, memWriteDados;

    wire [3:0]  processoAtual, numeroPrograma;
    wire [31:0] pcAtual, pcProx, pcMaisUm;
    wire [NUM_PROGS-1:0] finalizado;
    wire        todosFinalizados, trocaContexto, preempcao;
    wire [7:0]  contQuantum;

    wire [31:0] instrucao;
    wire        foraLimiteInstr, foraLimiteDados;

    wire        isOut, jump, regDst, regWrite, ALUSrc, memRead, memWrite, memToReg, isJr;
    wire [3:0]  opULA;
    wire [1:0]  PCSource;
    wire        isHalt, isIN, isBranch, isBranchNotEqual;

    wire [4:0]  regEscrita;
    wire [31:0] DadosUm, DadosDois, extendido, entradaULA, resultadoULA;
    wire [31:0] dadoMemoria, escreveDado;
    wire        zero;

    wire [13:0] ultimoOut, valorDireita;
    wire [3:0]  programaOut;
    wire [6:0]  trocas, numEsquerda, numMeio;
    wire        houveFalha;

    // ---------------- controle do "sistema operacional" ----------------
    baseTempo_SO #(.DIV_LENTO(DIV_LENTO), .DIV_RAPIDO(DIV_RAPIDO)) u_baseTempo (
        .clock(clock),
        .reset(reset),
        .rapido(SW[16]),
        .tick(tick)
    );

    controleExecucao_SO u_controleExecucao (
        .clock(clock),
        .botaoReset_n(KEY[0]),
        .botaoIN_n(KEY[1]),
        .chaveModo(SW[17]),
        .tick(tick),
        .todosFinalizados(todosFinalizados),
        .isIN(isIN),
        .isOut(isOut),
        .isHalt(isHalt),
        .memWrite(memWrite),
        .foraLimiteInstr(foraLimiteInstr),
        .foraLimiteDados(foraLimiteDados),
        .reset(reset),
        .modoPreemptivo(modoPreemptivo),
        .executa(executa),
        .aguardandoIN(aguardandoIN),
        .fimProcesso(fimProcesso),
        .habilitaRegistradores(habilitaRegistradores),
        .memWriteDados(memWriteDados)
    );

    escalonador_SO #(.NUM_PROGS(NUM_PROGS), .QUANTUM(QUANTUM)) u_escalonador (
        .clock(clock),
        .reset(reset),
        .executa(executa),
        .modoPreemptivo(modoPreemptivo),
        .pcProx(pcProx),
        .fimProcesso(fimProcesso),
        .processoAtual(processoAtual),
        .numeroPrograma(numeroPrograma),
        .pcAtual(pcAtual),
        .finalizado(finalizado),
        .todosFinalizados(todosFinalizados),
        .trocaContexto(trocaContexto),
        .preempcao(preempcao),
        .contQuantum(contQuantum)
    );

    // ---------------- busca ----------------
    memInstrucao_SO #(.NUM_PROGS(NUM_PROGS), .TAM_PARTICAO(TAM_PARTICAO)) u_memInstrucao (
        .processo(processoAtual),
        .pcLogico(pcAtual),
        .instrucao(instrucao),
        .foraLimite(foraLimiteInstr)
    );

    // ---------------- controle (mesma unidade do monociclo) ----------------
    // resetCPU fica em 1 (VCC no BDF): o HALT agora é por processo e é
    // tratado no escalonador, então isHalt é só a decodificação da instrução.
    teste_unidadeControle u_controle (
        .opcode(instrucao[31:26]),
        .clock(clock),
        .resetCPU(1'b1),
        .isOut(isOut),
        .jump(jump),
        .regDst(regDst),
        .regWrite(regWrite),
        .ALUSrc(ALUSrc),
        .memRead(memRead),
        .memWrite(memWrite),
        .memToReg(memToReg),
        .isJr(isJr),
        .opULA(opULA),
        .PCSource(PCSource),
        .isHalt(isHalt),
        .isIN(isIN),
        .isBranch(isBranch),
        .isBranchNotEqual(isBranchNotEqual)
    );

    // ---------------- datapath ----------------
    mux_regdst u_mux_regdst (
        .rt(instrucao[20:16]),
        .rd(instrucao[15:11]),
        .regDst(regDst),
        .writeReg(regEscrita)
    );

    bancoRegistradores_SO #(.NUM_PROGS(NUM_PROGS)) u_registradores (
        .clock(clock),
        .habilita(habilitaRegistradores),
        .processo(processoAtual),
        .leituraUm(instrucao[25:21]),
        .leituraDois(instrucao[20:16]),
        .regEscrita(regEscrita),
        .escreveDado(escreveDado),
        .escreveReg(regWrite),
        .isIN(isIN),
        .inData(SW[8:0]),
        .DadosUm(DadosUm),
        .DadosDois(DadosDois)
    );

    extensorSinal u_extensor (
        .entrada(instrucao[15:0]),
        .extendido(extendido)
    );

    mux_alusrc u_mux_alusrc (
        .readDataDois(DadosDois),
        .immExt(extendido),
        .aluSrc(ALUSrc),
        .aluInDois(entradaULA)
    );

    ULA u_ula (
        .a(DadosUm),
        .b(entradaULA),
        .alu_control(opULA),
        .resultado(resultadoULA),
        .zero(zero)
    );

    memoriaDados_SO #(.NUM_PROGS(NUM_PROGS), .TAM_PARTICAO(TAM_PARTICAO)) u_memoriaDados (
        .clock(clock),
        .habilita(executa),
        .processo(processoAtual),
        .MemRead(memRead),
        .MemWrite(memWriteDados),
        .endereco(resultadoULA),
        .writeData(DadosDois),
        .readData(dadoMemoria),
        .foraLimite(foraLimiteDados)
    );

    mux_memtoreg u_mux_memtoreg (
        .lerDado(dadoMemoria),
        .resultadoUla(resultadoULA),
        .memToReg(memToReg),
        .escreveDado(escreveDado)
    );

    somadorUm u_somadorUm (
        .in(pcAtual),
        .mais(pcMaisUm)
    );

    // Endereços de salto/desvio são absolutos dentro do programa (lógicos);
    // a base da partição é somada só na memória de instruções.
    teste_mux_jump_TESTE u_mux_jump (
        .pcBranch(pcMaisUm),
        .jumpEnd(extendido),
        .jrEnd(DadosUm),
        .Branch(isBranch),
        .Zero(zero),
        .isBranchNotEqual(isBranchNotEqual),
        .PCSource(PCSource),
        .pcProx(pcProx)
    );

    // ---------------- saída, displays e LEDs ----------------
    saidaOUT_SO #(.NUM_PROGS(NUM_PROGS)) u_saidaOUT (
        .clock(clock),
        .reset(reset),
        .executa(executa),
        .isOut(isOut),
        .processo(processoAtual),
        .DadosUm(DadosUm),
        .trocaContexto(trocaContexto),
        .fimProcesso(fimProcesso),
        .isHalt(isHalt),
        .todosFinalizados(todosFinalizados),
        .selPrograma(SW[3:0]),
        .ultimoOut(ultimoOut),
        .programaOut(programaOut),
        .trocas(trocas),
        .houveFalha(houveFalha),
        .numEsquerda(numEsquerda),
        .numMeio(numMeio),
        .valorDireita(valorDireita)
    );

    display7seg_2decimais u_hex76 (
        .clk(clock), .reset(reset), .valor(numEsquerda),
        .seg_unidade(HEX6), .seg_dezena(HEX7)
    );

    display7seg_2decimais u_hex54 (
        .clk(clock), .reset(reset), .valor(numMeio),
        .seg_unidade(HEX4), .seg_dezena(HEX5)
    );

    display7seg_decimal u_hex30 (
        .clk(clock), .reset(reset), .valor(valorDireita),
        .seg_unidade(HEX0), .seg_dezena(HEX1), .seg_centena(HEX2), .seg_milhar(HEX3)
    );

    leds_SO u_leds (
        .finalizados(finalizado),
        .pc(pcAtual),
        .aguardandoIN(aguardandoIN),
        .modoPreemptivo(modoPreemptivo),
        .todosFinalizados(todosFinalizados),
        .houveFalha(houveFalha),
        .LEDR(LEDR),
        .LEDG(LEDG)
    );

    // ---------------- depuração (pinos de saída na waveform) ----------------
    assign dbg_programa         = numeroPrograma;
    assign dbg_pc               = pcAtual;
    assign dbg_instrucao        = instrucao;
    assign dbg_executa          = executa;
    assign dbg_quantum          = contQuantum;
    assign dbg_trocaContexto    = trocaContexto;
    assign dbg_preempcao        = preempcao;
    assign dbg_aguardandoIN     = aguardandoIN;
    assign dbg_todosFinalizados = todosFinalizados;
    assign dbg_finalizados      = finalizado;
    assign dbg_programaOut      = programaOut;
    assign dbg_valorOut         = ultimoOut;
    assign dbg_trocas           = trocas;

endmodule
