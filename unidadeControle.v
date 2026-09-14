module unidadeControle (opcode, regDst, aluSrc, memToReg, regWrite, memRead, memWrite, branch, jump, aluOp);
	input [5:0] opcode; //instr[31:26]
	output reg regDst, aluSrc, memToReg, regWrite, memRead, memWrite, branch, jump;
	output reg [1:0] aluOp;
	
	always @(*) begin
		// valores padrão (NOP)
		regDst   = 1'b0;
      aluSrc   = 1'b0;
      memToReg = 1'b0;
      regWrite = 1'b0;
      memRead  = 1'b0;
      memWrite = 1'b0;
      branch   = 1'b0;
      jump     = 1'b0;
      aluOp    = 2'b00;
		
		case (opcode)
			6'b000000: //Tipo R
				begin
					regDst   = 1'b1;
               regWrite = 1'b1;
               aluOp    = 2'b10;
				end
			6'b100011: //LW
				begin
					aluSrc   = 1'b1;
               memToReg = 1'b1;
               regWrite = 1'b1;
               memRead  = 1'b1;
               aluOp    = 2'b00; // ADD
				end
			6'b101011: // SW
				begin 
               aluSrc   = 1'b1;
               memWrite = 1'b1;
               aluOp    = 2'b00; // ADD
            end
         6'b000100: begin // BEQ
               branch   = 1'b1;
               aluOp    = 2'b01; // SUB
            end
         6'b001000: begin // ADDI
               aluSrc   = 1'b1;
               regWrite = 1'b1;
               aluOp    = 2'b00; // ADD
            end
         6'b010010: begin // JUMP
               jump     = 1'b1;
            end
         default: begin
               // instrução não reconhecida → sinais de NOP
            end
		endcase
	end
endmodule