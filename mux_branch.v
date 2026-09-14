module mux_branch (pcmais, branchEnd, branch, zero, isBranchNotEqual, pcProx);
	input  wire [31:0] pcmais;     // PC + 1
   input  wire [31:0] branchEnd;  // endereço do branch
   input  wire        branch;       // sinal da unidade de controle (isBranch)
   input  wire        zero;         // flag da ULA (resultado da subtração)
   input  wire        isBranchNotEqual; // 1 para BNE, 0 para BEQ
   output wire [31:0] pcProx;       // próximo valor do PC

   wire branch_taken;

   // BEQ: tomado se branch=1 e zero=1 (valores iguais)
   // BNE: tomado se branch=1 e zero=0 (valores diferentes)
   assign branch_taken = branch & (isBranchNotEqual ? ~zero : zero);
   
	// Se branch_taken=1 → vai para branch_addr
   // Se branch_taken=0 → segue fluxo normal (PC+1)
   assign pcProx = (branch_taken) ? branchEnd : pcmais;

endmodule