module teste_mux_jump_TESTE (
    input  wire [31:0] pcBranch,
    input  wire [31:0] jumpEnd,
    input  wire [31:0] jrEnd,
    input  wire        Branch,    // novo
    input  wire        Zero,      // novo (da ALU)
    input  wire        isBranchNotEqual,  // 1 para BNE, 0 para BEQ
    input  wire [1:0]  PCSource,
    output wire [31:0] pcProx
);

    // BEQ: tomado se Branch=1 e Zero=1 (valores iguais)
    // BNE: tomado se Branch=1 e Zero=0 (valores diferentes)
    wire branch_taken;
    assign branch_taken = Branch & (isBranchNotEqual ? ~Zero : Zero);

    assign pcProx = (PCSource == 2'b00) ? pcBranch : 
                    (PCSource == 2'b01) ? (branch_taken ? jumpEnd : pcBranch) :
                    (PCSource == 2'b10) ? jumpEnd :
                    (PCSource == 2'b11) ? jrEnd :
                    pcBranch;

endmodule
