module out_device (
    input wire        out_en,        // ativa quando opcode == OUT
    input wire [13:0] out_data, // dado a ser exibido
	 output wire [13:0] saida_dado
);

    assign saida_dado = out_en ? out_data : 14'b0;

endmodule