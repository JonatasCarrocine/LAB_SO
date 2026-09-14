module in_user (
    input  wire clk,
    input  wire reset,
    input  wire isIN,
    input  wire valid,   // botão do usuário
    output reg  cpu_en,
    output reg  in_done  // indica que o IN foi consumido
);

    // Estados
    localparam IDLE    = 2'b00;
    localparam WAIT_IN = 2'b01;

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state   <= IDLE;
            cpu_en  <= 1'b1;
            in_done <= 1'b0;
        end else begin
            in_done <= 1'b0;

            case (state)
                IDLE: begin
                    cpu_en <= 1'b1;
                    if (isIN) begin
                        state  <= WAIT_IN;
                        cpu_en <= 1'b0; // congela
                    end
                end

                WAIT_IN: begin
                    cpu_en <= 1'b0;
                    if (valid) begin
                        cpu_en  <= 1'b1;
                        in_done <= 1'b1; // consome o botão
                        state   <= IDLE;
                    end
                end
					 
					 default: begin
                    state  <= IDLE;
                    cpu_en <= 1'b1;
                end
            endcase
        end
    end

endmodule
