module somador(pcmais, imm_ext, branchEnd);
		input wire [31:0] pcmais;
		input wire [31:0] imm_ext;
		
		output wire [31:0] branchEnd;
		assign branchEnd = pcmais + imm_ext;
endmodule