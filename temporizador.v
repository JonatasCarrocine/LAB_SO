module temporizador (
    input  wire clock,
    output wire reduzclock
);
    reg [24:0] contador = 25'b0;  // inicializa com zero
	//Voltar para [25:0] contador = 26'b0;
    always @(posedge clock) begin
        contador <= contador + 1'b1;
    end

    assign reduzclock = contador[24]; //reduzclock = contador[25];
endmodule
