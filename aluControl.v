module aluControl(
    input [1:0] aluOp,
    output reg [3:0] alu_control
);
    always @(*) begin
        case (aluOp)
            2'b00: alu_control = 4'b0010; // LW/SW/ADDI → ADD
            2'b01: alu_control = 4'b0110; // BEQ → SUB
            2'b10: alu_control = 4'b1000; // Tipo MOVE
            default: alu_control = 4'b0000;
        endcase
    end
endmodule