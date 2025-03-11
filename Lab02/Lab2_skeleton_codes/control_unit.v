`include opcodes.v

module control_unit (input [6:0] Instr,
                     output JAL,
                     output JALR,
                     output Branch,
                     output MemRead,
                     output MemtoReg,
                     output MemWrite,
                     output ALUSrc,
                     output RegWrite,
                     output PCtoReg,
                     output is_ecall)

assign JAL = (Instr == `JAL);
assign JALR = (Instr == `JALR);
assign RegWrite = (Instr )


endmodule
