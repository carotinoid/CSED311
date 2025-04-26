`include "opcodes.v"

module ControlUnit (input [6:0] Instr,
                     output MemRead,
                     output MemtoReg,
                     output MemWrite,
                     output ALUSrc,
                     output RegWrite,
                     output PCtoReg,
                     output alu_op,
                     output Branch,
                     output is_ecall);

                    //  output JAL,
                    //  output JALR,

assign MemRead = (Instr == `LOAD);
assign MemtoReg = (Instr == `LOAD);
assign MemWrite = (Instr == `STORE);
assign ALUSrc = (Instr != `ARITHMETIC) && (Instr != `BRANCH);
assign RegWrite = (Instr != `STORE) && (Instr != `BRANCH);
assign PCtoReg = (Instr == `JAL) || (Instr == `JALR);
assign alu_op = 0; // TODO
assign Branch = (Instr == `BRANCH);
assign is_ecall = (Instr == `ECALL);

// assign JAL = (Instr == `JAL);
// assign JALR = (Instr == `JALR);

endmodule
