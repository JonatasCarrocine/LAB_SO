module extensorSinal (entrada, extendido);
	input wire [15:0] entrada;
	output wire [31:0] extendido;
	
	assign extendido = {{16{entrada[15]}},entrada};
endmodule