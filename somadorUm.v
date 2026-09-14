module somadorUm (in, mais);
		input wire [31:0] in;
		
		
		output wire [31:0] mais;
		
		assign mais = in + 1;
endmodule