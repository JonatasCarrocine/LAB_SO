module mux_regdst(rt,       // campo rt da instrução (bits [20..16])
    rd,       // campo rd da instrução (bits [15..11])
	 regDst,   // sinal de controle
    writeReg  // registrador destino
);
	input [4:0] rt; 
	input [4:0] rd;
	input regDst;
	output reg [4:0] writeReg;

   always @(*) begin
        if (regDst)
            writeReg = rd;
        else
            writeReg = rt;
    end

endmodule