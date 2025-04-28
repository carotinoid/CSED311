`include "opcodes.v"

module HazardDetectionUnit(
    input [6:0] opcode,
    input [4:0] ID_rs1,
    input [4:0] ID_rs2,
    input [4:0] EX_MEM_rd,
    input ID_EX_mem_read,
    input ID_ctrl_is_ecall,
    output PC_Write,
    output IF_ID_Write,
    output ID_CtrlUnitMux_sel
);

wire use_rs1 = ID_rs1 != 0 && ((opcode == `ARITHMETIC) || (opcode == `ARITHMETIC_IMM) || (opcode == `LOAD) || (opcode == `STORE) || (opcode == `BRANCH));
wire use_rs2 = ID_rs2 != 0 && ((opcode == `ARITHMETIC) || (opcode == `STORE) || (opcode == `BRANCH));

wire stall = (ID_ctrl_is_ecall && EX_MEM_rd == ID_rs1) || (ID_EX_mem_read && (((EX_MEM_rd == ID_rs1) && (use_rs1) || ((EX_MEM_rd == ID_rs2) && (use_rs2)))));

assign PC_Write = !stall;
assign IF_ID_Write = !stall;
assign ID_CtrlUnitMux_sel = stall;

endmodule
