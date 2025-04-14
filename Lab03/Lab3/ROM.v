`include "opcodes"
module ROM(
    input to_IR_from_MEM_PC,       // 1
    input to_A_from_RF_RS1,        // 2
    input to_B_from_RF_RS2,        // 2
    input to_ALUOut_from_PCp4,     // 2
    input to_ALUOut_from_ApB,      // R3
    input to_RF_rd_from_ALUOut,    // R4, JAL3, JALR3
    input to_PC_from_PCp4,         // R4, LD5, SD4
    input to_ALUOut_from_Apimm,    // LD3, SD3
    input to_MDR_from_MEM_ALUOut,  // LD4
    input to_RF_rd_from_MDR,       // LD5
    input to_MEM_ALUOut_from_B,    // SD4
    input to_PC_from_ALUOut,       // B3
    input to_PC_from_PCpimm,       // B4, JAL3
    input to_PC_from_Apimm,        // JALR3
    output PCWriteNotCond,
    output PCWrite,
    output IorD,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output IRWrite,
    output PCSource,
    output [1:0] ALUSrcB,
    output ALUSrcA,
    output RegWrite
);

assign PCWriteNotCond   = to_PC_from_ALUOut; 
assign PCWrite          = to_PC_from_PCp4 || to_PC_from_PCpimm || to_PC_from_Apimm;
assign IorD             = !to_IR_from_MEM_PC;
assign MemRead          = to_IR_from_MEM_PC || to_MDR_from_MEM_ALUOut;
assign MemWrite         = to_MEM_ALUOut_from_B;
assign MemtoReg         = to_RF_rd_from_MDR;
assign IRWrite          = to_IR_from_MEM_PC;
assign PCSource         = to_PC_from_ALUOut; // <--?
assign ALUSrcB          = (to_ALUOut_from_ApB || to_PC_from_ALUOut ? 0 : 
                          (to_ALUOut_from_PCp4 || to_PC_from_PCp4) ? 1 :
                          (to_ALUOut_from_Apimm || to_PC_from_PCpimm || to_PC_from_Apimm) ? 2 : 3);
assign ALUSrcA          = !(to_ALUOut_from_PCp4 || to_PC_from_PCp4 || to_PC_from_PCpimm);
assign RegWrite         = to_RF_rd_from_ALUOut || to_RF_rd_from_MDR;

endmodule
