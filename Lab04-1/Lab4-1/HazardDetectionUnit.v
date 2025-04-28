module HazardDetectionUnit(
    input [4:0] IF_ID_rs1,
    input [4:0] IF_ID_rs2,
    input [4:0] EX_MEM_rd,
    input ID_EX_mem_read,
    input ID_ctrl_is_ecall,
    input ID_EX_ctrl_is_ecall,
    input use_rs1,
    input use_rs2,
    output stall
);

assign stall = (ID_ctrl_is_ecall && !ID_EX_ctrl_is_ecall) || (ID_EX_mem_read && (((EX_MEM_rd == IF_ID_rs1) && (use_rs1) || ((EX_MEM_rd == IF_ID_rs2) && (use_rs2)))));

endmodule
