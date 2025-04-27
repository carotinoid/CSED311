module DataForwardingUnit (
    input [4:0] ID_EX_rs1,
    input [4:0] ID_EX_rs2,
    input [4:0] EX_MEM_rd,
    input [4:0] MEM_WB_rd,
    input EX_MEM_reg_write,
    input MEM_WB_reg_write,
    output [1:0] forward_a,
    output [1:0] forward_b
);

    assign forward_a = (ID_EX_rs1 != 0 && ID_EX_rs1 == EX_MEM_rd && EX_MEM_reg_write) ? 2'b10 :
                       (ID_EX_rs1 != 0 && ID_EX_rs1 == MEM_WB_rd && MEM_WB_reg_write) ? 2'b01 :
                        2'b00;
    assign forward_b = (ID_EX_rs2 != 0 && ID_EX_rs2 == EX_MEM_rd && EX_MEM_reg_write) ? 2'b10 :
                       (ID_EX_rs2 != 0 && ID_EX_rs2 == MEM_WB_rd && MEM_WB_reg_write) ? 2'b01 :
                        2'b00;
endmodule
