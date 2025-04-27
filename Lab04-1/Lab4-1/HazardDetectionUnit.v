module HazardDetectionUnit(
    input [4:0] IF_ID_rs1,
    input [4:0] IF_ID_rs2,
    input [4:0] EX_MEM_rd,
    input ID_EX_mem_read,
    input ID_is_halted,
    output stall
);

assign stall = ID_is_halted || (ID_EX_mem_read && (((EX_MEM_rd == IF_ID_rs1) && (IF_ID_rs1 != 0)) || ((EX_MEM_rd == IF_ID_rs2) && (IF_ID_rs2 != 0))));

endmodule
