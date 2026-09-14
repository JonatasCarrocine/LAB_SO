module mux_BEQ_TESTE (
    input  wire [31:0] branch_mem,   // saída do mux do branch (ou PC+4 normal)
	 input  wire [5:0] instrucao,
    input  wire zero,    // flag zero
    output reg  [31:0] beqEnd      // próximo valor do PC
);

    always @(*) begin
        case (zero && instrucao == 6'b001111)
           1'b1: beqEnd <= branch_mem + 1;
        endcase
    end

endmodule