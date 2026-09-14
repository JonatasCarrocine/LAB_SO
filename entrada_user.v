module entrada_user (
    input  wire        clock,
    input  wire        resetCPU,

    input  wire        instr_in,
    input  wire [4:0]  instr_rt,

    input  wire        btn_confirm,
    input  wire [8:0]  switches,

    output reg         cpu_stall,
    output reg         in_valid,
    output reg [8:0]  in_data,
    output reg [4:0]   in_reg_dest
);

    // Estados da FSM
    parameter IDLE = 2'b00;
    parameter WAIT = 2'b01;
    parameter DONE = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;

    // Estado atual
    always @(posedge clock or posedge resetCPU) begin
        if (resetCPU)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Próximo estado
    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (instr_in)
                    next_state = WAIT;
            end

            WAIT: begin
                if (btn_confirm)
                    next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end
        endcase
    end

    // Saídas
    always @(*) begin
        cpu_stall   = 1'b0;
        in_valid    = 1'b0;
        in_data     = 32'b0;
        in_reg_dest = instr_rt;

        case (state)
            WAIT: begin
                cpu_stall = 1'b1;
            end

            DONE: begin
                in_valid = 1'b1;
                in_data  = switches;
            end
        endcase
    end

endmodule
