module memInstrucao_semPreemp(
    clock, 
    endereco, 
    instrucao,
	 posMem,
    prog_sel,      // Novo: seletor de programa
    prog_load_en   // Novo: habilita carregamento
);
    input clock;
    input [31:0] endereco;
    input [1:0] prog_sel;
    input prog_load_en;
    output [31:0] instrucao;
	 output [31:0] posMem; //reg atualiza em always
    
    reg [31:0] mem [255:0];
    
    // Armazena o programa atual carregado
    reg [1:0] current_prog = 2'b00;
    
    // Inicialização padrão (Programa 0)
    //initial begin
    //     mem[1] = 32'b000001_00000_01000_0000000000000101;// addi 5
	//		mem[2] = 32'b000001_00000_01001_0000000000000111;// addi 7
	//		mem[3] = 32'b000000_01000_01001_01010_00000_100000;// add
	//		mem[4] = 32'b000001_01010_00100_0000000000000000;   //addi $a0, $t2, 0
	//		mem[5] = 32'b010111_00000_00000_0000000000000000;   //halt
   // end
    
    // Carrega programa selecionado quando habilitado
    always @(posedge clock) begin
        if (prog_load_en && prog_sel != current_prog) begin
            current_prog <= prog_sel;
            
            case (prog_sel)
                2'b00: begin  // Programa 1
                    // Carrega instruções do programa 1
                    mem[1] = 32'b000001_00000_01000_0000000000000101;// addi 5
							mem[2] = 32'b000001_00000_01001_0000000000000111;// addi 7
							mem[3] = 32'b000000_01000_01001_01010_00000_100000;// add
							mem[4] = 32'b000001_01010_00100_0000000000000000;   //addi $a0, $t2, 0
							mem[5] = 32'b010111_00000_00000_0000000000000000;   //halt
                end
                
                2'b01: begin  // Programa 2
                    // Carrega instruções do programa 2
                    mem[1] = 32'b000001_00000_01000_0000000000001101;// addi 13
							mem[2] = 32'b000001_00000_01001_0000000000001111;// addi 15
							mem[3] = 32'b000000_01000_01001_01010_00000_100000;// add
							mem[4] = 32'b000001_01010_00100_0000000000000000;   //addi $a0, $t2, 0
							mem[5] = 32'b010111_00000_00000_0000000000000000;   //halt
                end
                
                2'b10: begin  // Programa 3
                    // Carrega instruções do programa 3
                    mem[1] = 32'b000001_00000_01000_0000000000010101;// addi 21
							mem[2] = 32'b000001_00000_01001_0000000000000011;// addi 3
							mem[3] = 32'b000000_01000_01001_01010_00000_100000;// add
							mem[4] = 32'b000001_01010_00100_0000000000000000;   //addi $a0, $t2, 0
							mem[5] = 32'b010111_00000_00000_0000000000000000;   //halt
                end
                
                default: begin
                    // Mantém programa atual
                end
            endcase
        end
    end
    
    // Leitura assíncrona
    assign instrucao = mem[endereco];
	 assign posMem = endereco;
    
endmodule
