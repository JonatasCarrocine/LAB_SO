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

    wire clock = CLOCK_50;
    wire reset = ~KEY[0];

    // ==================================================================
    // Base de tempo: em vez de gerar um clock lento (temporizador), todo o
    // circuito roda no CLOCK_50 e "tick" habilita uma instrução por período.
    // Assim o botão do IN e o escalonador ficam no mesmo domínio de clock.
    // ==================================================================
    reg [31:0] divCont = 32'd0;
    wire [31:0] divisor = SW[16] ? DIV_RAPIDO : DIV_LENTO;
    wire tick = (divCont >= divisor - 1);

    always @(posedge clock or posedge reset) begin
        if (reset)     divCont <= 32'd0;
        else if (tick) divCont <= 32'd0;
        else           divCont <= divCont + 32'd1;
    end

    // Modo de escalonamento fixado no reset
    reg modoPreemptivo = 1'b0;
    always @(posedge clock) begin
        if (reset)
            modoPreemptivo <= SW[17];
    end

    // ==================================================================
    // Escalonador / tabela de processos
    // ==================================================================
    wire [3:0]  processoAtual;
    wire [31:0] pcAtual;
    wire [31:0] pcProx;
    wire [NUM_PROGS-1:0] finalizado;
    wire todosFinalizados, trocaContexto, preempcao;
    wire [7:0]  contQuantum;
    wire executa;
    wire fimProcesso;

    escalonador_SO #(.NUM_PROGS(NUM_PROGS), .QUANTUM(QUANTUM)) u_escalonador (
        .clock(clock),
        .reset(reset),
        .executa(executa),
        .modoPreemptivo(modoPreemptivo),
        .pcProx(pcProx),
        .fimProcesso(fimProcesso),
        .processoAtual(processoAtual),
        .pcAtual(pcAtual),
        .finalizado(finalizado),
        .todosFinalizados(todosFinalizados),
        .trocaContexto(trocaContexto),
        .preempcao(preempcao),
        .contQuantum(contQuantum)
    );

    // ==================================================================
    // Busca
    // ==================================================================
    wire [31:0] instrucao;
    wire        foraLimiteInstr;

    memInstrucao_SO #(.NUM_PROGS(NUM_PROGS), .TAM_PARTICAO(TAM_PARTICAO)) u_memInstrucao (
        .processo(processoAtual),
        .pcLogico(pcAtual),
        .instrucao(instrucao),
        .foraLimite(foraLimiteInstr)
    );

    // ==================================================================
    // Controle (mesma unidade de controle do processador monociclo).
    // O estado de HALT agora é por processo e fica no escalonador, por isso
    // o registrador "halted" interno é mantido em reset e isHalt é apenas a
    // decodificação da instrução HALT.
    // ==================================================================
    wire isOut, jump, regDst, regWrite, ALUSrc, memRead, memWrite, memToReg, isJr;
    wire [3:0] opULA;
    wire [1:0] PCSource;
    wire isHalt, isIN, isBranch, isBranchNotEqual;

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

    // ==================================================================
    // Entrada do usuário (IN): a CPU espera o KEY[1] sem consumir quantum
    // ==================================================================
    reg [2:0] keySync = 3'b111;
    always @(posedge clock)
        keySync <= {keySync[1:0], KEY[1]};
    wire botaoApertado = keySync[2] & ~keySync[1];   // borda de descida

    reg inOk = 1'b0;
    wire aguardandoIN = isIN && !inOk && !todosFinalizados;

    assign executa = tick && !reset && !todosFinalizados && !aguardandoIN;

    always @(posedge clock or posedge reset) begin
        if (reset)
            inOk <= 1'b0;
        else if (executa && isIN)
            inOk <= 1'b0;                 // valor consumido
        else if (botaoApertado && isIN)
            inOk <= 1'b1;
    end

    // ==================================================================
    // Datapath
    // ==================================================================
    wire [4:0]  regEscrita;
    wire [31:0] DadosUm, DadosDois, extendido, entradaULA, resultadoULA;
    wire [31:0] dadoMemoria, escreveDado, pcMaisUm;
    wire        zero, foraLimiteDados;

    assign fimProcesso = isHalt || foraLimiteInstr || foraLimiteDados;

    mux_regdst u_mux_regdst (
        .rt(instrucao[20:16]),
        .rd(instrucao[15:11]),
        .regDst(regDst),
        .writeReg(regEscrita)
    );

    bancoRegistradores_SO #(.NUM_PROGS(NUM_PROGS)) u_registradores (
        .clock(clock),
        .habilita(executa && !fimProcesso),
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

    // OUT não grava na memória de dados (na versão monociclo ele ativava
    // memWrite e sobrescrevia mem[valor de saída])
    memoriaDados_SO #(.NUM_PROGS(NUM_PROGS), .TAM_PARTICAO(TAM_PARTICAO)) u_memoriaDados (
        .clock(clock),
        .habilita(executa),
        .processo(processoAtual),
        .MemRead(memRead),
        .MemWrite(memWrite && !isOut),
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

    // ==================================================================
    // Saída (OUT) e estatísticas
    // ==================================================================
    reg [13:0] ultimoOut     = 14'd0;
    reg [3:0]  ultimoOutProc = 4'd0;
    reg [13:0] resultado [0:NUM_PROGS-1];
    reg [6:0]  trocas = 7'd0;
    reg        houveFalha = 1'b0;

    integer i;
    initial begin
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
                ultimoOut                <= DadosUm[13:0];
                ultimoOutProc            <= processoAtual;
                resultado[processoAtual] <= DadosUm[13:0];
            end
            if (trocaContexto && trocas != 7'd99)
                trocas <= trocas + 7'd1;
            if (executa && (foraLimiteInstr || foraLimiteDados))
                houveFalha <= 1'b1;
        end
    end

    // ==================================================================
    // Displays e LEDs
    // ==================================================================
    wire [3:0] progEscolhido = (SW[3:0] >= 1 && SW[3:0] <= NUM_PROGS) ? SW[3:0] - 4'd1 : 4'd0;

    wire [6:0]  numEsquerda = todosFinalizados ? {3'b0, progEscolhido} + 7'd1 : {3'b0, processoAtual} + 7'd1;
    wire [6:0]  numMeio     = todosFinalizados ? trocas : {3'b0, ultimoOutProc} + 7'd1;
    wire [13:0] valorDireita = todosFinalizados ? resultado[progEscolhido] : ultimoOut;

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

    assign LEDR[NUM_PROGS-1:0] = finalizado;
    assign LEDR[10:NUM_PROGS]  = 0;
    assign LEDR[17:11]         = pcAtual[6:0];

    assign LEDG[0]   = aguardandoIN;
    assign LEDG[1]   = modoPreemptivo;
    assign LEDG[2]   = todosFinalizados;
    assign LEDG[3]   = houveFalha;
    assign LEDG[8:4] = 5'b0;

    // ==================================================================
    // Depuração
    // ==================================================================
    assign dbg_programa         = processoAtual + 4'd1;
    assign dbg_pc               = pcAtual;
    assign dbg_instrucao        = instrucao;
    assign dbg_executa          = executa;
    assign dbg_quantum          = contQuantum;
    assign dbg_trocaContexto    = trocaContexto;
    assign dbg_preempcao        = preempcao;
    assign dbg_aguardandoIN     = aguardandoIN;
    assign dbg_todosFinalizados = todosFinalizados;
    assign dbg_finalizados      = finalizado;
    assign dbg_programaOut      = ultimoOutProc + 4'd1;
    assign dbg_valorOut         = ultimoOut;
    assign dbg_trocas           = trocas;

endmodule
