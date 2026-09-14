module mux_jump  (pcBranch, jumpEnd, jump, pcProx);
	input  wire [31:0] pcBranch;   // saída do mux do branch
   input  wire [31:0] jumpEnd;  // endereço de jump (instr[25:0] << 2)
   input  wire        jump;      // sinal da unidade de controle
   output wire [31:0] pcProx;       // próximo valor do PC

   assign pcProx = (jump) ? jumpEnd : pcBranch;

endmodule