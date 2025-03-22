`include "opcodes.v"

module imm_gen (input [31:0] Instr,
                output reg [31:0] imm_gen_out);

wire [6:0] op = Instr[6:0];

initial begin
    imm_gen_out = 0;
end


always @(*) begin
    imm_gen_out = 0;
    case(op)
        `ARITHMETIC_IMM, `LOAD, `JALR: begin
            imm_gen_out[11:0] = Instr[31:20];
            imm_gen_out[31:12] = {20{imm_gen_out[11]}};
        end
        `STORE : begin
            imm_gen_out[4:0] = Instr[11:7];
            imm_gen_out[11:5] = Instr[31:25];
            imm_gen_out[31:12] = {20{imm_gen_out[11]}};
        end
        `JAL : begin
            imm_gen_out[10:1] = Instr[30:21];
            imm_gen_out[11] = Instr[20];
            imm_gen_out[19:12] = Instr[19:12];
            imm_gen_out[20] = Instr[31];
            imm_gen_out[31:21] = {11{imm_gen_out[20]}};
        end
        `BRANCH : begin
            imm_gen_out[4:1] = Instr[11:8];
            imm_gen_out[10:5] = Instr[30:25];
            imm_gen_out[11] = Instr[7];
            imm_gen_out[12] = Instr[31];
            imm_gen_out[31:13] = {19{imm_gen_out[12]}};
        end
        default: imm_gen_out = 0;
    endcase
end


endmodule
