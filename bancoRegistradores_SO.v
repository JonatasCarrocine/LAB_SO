// Banco de registradores com um conjunto de 32 registradores por processo.
//
// É o "contexto" de cada processo guardado em hardware: na troca de
// contexto basta o escalonador mudar o número do processo, e os
// registradores do processo que saiu ficam preservados até ele voltar.
// O PC de cada processo é salvo/restaurado pelo escalonador (PCB).
module bancoRegistradores_SO #(
    parameter NUM_PROGS = 10
) (
    input  wire        clock,
    input  wire        habilita,      // 1 = a instrução atual está sendo executada neste ciclo
    input  wire [3:0]  processo,

    input  wire [4:0]  leituraUm,     // rs
    input  wire [4:0]  leituraDois,   // rt
    input  wire [4:0]  regEscrita,    // saída do mux_regdst
    input  wire [31:0] escreveDado,
    input  wire        escreveReg,

    input  wire        isIN,          // instrução IN: grava o valor do usuário
    input  wire [8:0]  inData,

    output wire [31:0] DadosUm,
    output wire [31:0] DadosDois
);
    reg [31:0] registradores [0:NUM_PROGS*32-1];

    integer i;
    initial begin
        for (i = 0; i < NUM_PROGS*32; i = i + 1)
            registradores[i] = 32'b0;
    end

    // $zero sempre lê 0
    assign DadosUm   = (leituraUm   == 5'd0) ? 32'b0 : registradores[{processo, leituraUm}];
    assign DadosDois = (leituraDois == 5'd0) ? 32'b0 : registradores[{processo, leituraDois}];

    always @(posedge clock) begin
        if (habilita && escreveReg && regEscrita != 5'd0) begin
            if (isIN)
                registradores[{processo, regEscrita}] <= {23'b0, inData};
            else
                registradores[{processo, regEscrita}] <= escreveDado;
        end
    end
endmodule
