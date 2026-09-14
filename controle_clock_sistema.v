module controle_clock_sistema (
    input clock,
    input start_execution,
    input [1:0] manual_prog_sel,
    input clock_enabled,  // Sinal que indica se o escalonador liberou o clock
    output reg clock_out
);

    always @(posedge clock) begin
        // O clock é ativado quando:
        // 1. start_execution = 1
        // 2. manual_prog_sel foi atualizado (não é 0)
        // 3. O escalonador liberou a execução
        if (start_execution && (manual_prog_sel != 2'b00) && clock_enabled) begin
            clock_out = clock;
        end else begin
            clock_out = 1'b0;
        end
    end

endmodule