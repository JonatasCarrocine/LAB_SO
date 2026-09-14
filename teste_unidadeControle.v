module teste_unidadeControle (
	input wire [5:0] opcode, //instr[31:26]-
	input wire clock, 
	input wire resetCPU, 
	output reg isOut, 
	output reg jump, 
	output reg regDst, 
	output reg regWrite, 
	output reg ALUSrc, 
	output reg memRead, 
	output reg memWrite, 
	output reg memToReg, 
	output reg isJr, 
	output reg [3:0] opULA, 
	output reg [1:0] PCSource, 
	output reg isHalt,
	output reg isIN,
	output reg isBranch,
	output reg isBranchNotEqual
);
	
	reg halted;
	
	always @(posedge clock or posedge resetCPU) begin
    if (resetCPU)
        halted <= 1'b0;
    else if (opcode == 6'b010111) // HALT detectado
        halted <= 1'b1;
    // não tem else: se entrou HALT uma vez, nunca mais volta pra 0
	end
	
	always @(*) begin
		// valores padrão (NOP)
		isOut 	= 1'b0;
      jump 		= 1'b0;
		regDst 	= 1'b0;
		regWrite = 1'b0;
		ALUSrc 	= 1'b0;
		memRead 	= 1'b0;
		memWrite = 1'b0;
		memToReg = 1'b0;
		opULA		= 4'b0000;
		PCSource = 2'b00;
		isJr 		= 1'b0;
		isHalt 	= halted;
		isIN		= 1'b0;
		isBranch = 1'b0;
		isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
		
		case (opcode)
			6'b000000: //Tipo add
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1; //Para pegar do registrador $rd
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
					opULA		= 4'b0010; //ADD
				end
			6'b000001: //Tipo addi
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b0;
					regWrite = 1'b1;
					ALUSrc 	= 1'b1;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
					opULA		= 4'b0010; //ADD
				end
			6'b000010: //Tipo sub
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1;
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
					opULA		= 4'b0110; //sub
				end
			6'b000100: //Tipo mult
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1;
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
					opULA		= 4'b0011; //MULT
				end
			6'b001001: //Tipo slt
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1; //Para pegar do registrador $rd
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;
					opULA		= 4'b0111; //SLT
				end
			6'b011011: //Tipo sgt
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1;
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;
					opULA		= 4'b0101; //SGT
				end
			6'b011100: //Tipo sle
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1;
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;
					opULA		= 4'b1001; //SLE
				end
			6'b011101: //Tipo sge
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1;
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;
					opULA		= 4'b1010; //SGE
				end
			6'b001100: //Tipo load
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b0; // Escreve em rt (bits [20:16])
					regWrite = 1'b1; // Habilita escrita
					ALUSrc 	= 1'b1; // Usa imediato
					memRead 	= 1'b1; // LÊ da memória
					memWrite = 1'b0; // Não escreve em memória
					memToReg = 1'b1; // Seleciona dado da MEMÓRIA (não ALU)
					isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
					opULA		= 4'b0010; //ADD
				end
			6'b001101: //Tipo LDI
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b0; // Escreve em rt (bits [20:16])
					regWrite = 1'b1; // Habilita escrita
					ALUSrc 	= 1'b1; // Usa imediato
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0; // Seleciona saída da ALU
					isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
					opULA		= 4'b0010; //ADD
				end
			6'b001110: //Tipo str (store)
				begin
					isOut 	= 1'b0;
					jump   	= 1'b0;
					regDst 	= 1'b0; 	// Não importa (não escreve em registrador)
					regWrite = 1'b0; 	// NÃO escreve em registrador
					ALUSrc 	= 1'b1;		// Usa imediato (offset)
					memRead 	= 1'b0;   // Não lê da memória
					memWrite = 1'b1;  // ESCREVE na memória
					memToReg = 1'b0;  // Não importa
					opULA		= 4'b0010; //ADD
				end
			6'b001111: //Tipo beq (branch if equal)
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b0;      // Não escreve em registrador
					regWrite = 1'b0;    // Não escreve
					ALUSrc 	= 1'b0;      // Lê dos registradores (rs e rt)
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					opULA		= 4'b0110; //SUB
					isBranch   = 1'b1;    // sinal de branch ativo
					isBranchNotEqual = 1'b0;  // BEQ: igualdade
					PCSource = 2'b01;   // Branch: usa resultado do mux_branch
				end
			6'b010000: //Tipo bne (branch if not equal)
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b0;      // Não escreve em registrador
					regWrite = 1'b0;    // Não escreve
					ALUSrc 	= 1'b0;      // Lê dos registradores (rs e rt)
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					opULA		= 4'b0110; //SUB
					isBranch   = 1'b1;    // sinal de branch ativo
					isBranchNotEqual = 1'b1;  // BNE: desigualdade (inverte lógica)
					PCSource = 2'b01;   // Branch: usa resultado do mux_branch
				end
			6'b010010: //Tipo JUMP
				begin
					isOut 	= 1'b0;
					jump   	= 1'b1;
					regDst 	= 1'b0;
					regWrite = 1'b1;
					ALUSrc 	= 1'b1;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					isBranchNotEqual = 1'b0;  // BNE: desigualdade (inverte lógica)
					//sem aluOp
					opULA		= 4'b0000; //ADD
					PCSource = 2'b10;
				end
			6'b010011: //Tipo JR
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;         // NÃO é jump de imediato
					regDst 	= 1'b0;       // Não importa (não escreve)
					regWrite = 1'b0;     // Não escreve em registrador
					ALUSrc 	= 1'b0;       // Lê do registrador (rs)
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					opULA		= 4'b0010; //ADD
					PCSource = 2'b11;		// NOVO: Sinal de jump register
					isJr 		= 1'b1;           // NOVO: Sinal de jump register
				end
			6'b010101: //Tipo IN
				begin
					isOut     = 1'b0;       // não é OUT
					isIN      = 1'b1;       // <<< AQUI: sinalizando instrução IN
					jump      = 1'b0;       // não altera PC
					regDst    = 1'b0;       // destino é rt
					regWrite  = 1'b1;       // vai gravar no registrador
					ALUSrc    = 1'b0;       // não importa
					memRead   = 1'b0;       
					memWrite  = 1'b0;
					memToReg  = 1'b0;       // dado NÃO vem da memória
					opULA     = 4'b0000;    // não importa (ULAs são ignoradas)
					PCSource  = 2'b00;      // PC normal (PC+4)
				end
			6'b010110: //Tipo OUT
				begin
					isOut 	= 1'b1;
					jump 		= 1'b0;
					regDst 	= 1'b0;
					regWrite = 1'b0;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b1;
					memToReg = 1'b0;
					opULA		= 4'b0010; //ADD
				end
			6'b011000: //Tipo MOVE
				begin
					isOut 	= 1'b0;
					jump   	= 1'b0;
					regDst 	= 1'b0; //Para pegar do registrador $rt
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					opULA		= 4'b1000; // Tipo MOVE
				end
			6'b011001: //Tipo DIV immediato
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;
					regDst 	= 1'b1;
					regWrite = 1'b1;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					opULA		= 4'b0100; //DIV
				end
			6'b010111: //Tipo HALT
				begin
					isOut 	= 1'b0;
					jump 		= 1'b0;         // NÃO é jump de imediato
					regDst 	= 1'b0;
					regWrite = 1'b0;
					ALUSrc 	= 1'b0;
					memRead 	= 1'b0;
					memWrite = 1'b0;
					memToReg = 1'b0;
					opULA		= 4'b0010; //ADD
					isHalt 	= 1'b1;
				end
         default: begin
               // instrução não reconhecida → sinais de NOP
            end
		endcase
	end
endmodule