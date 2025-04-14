`include "opcodes"
module ControlUnit(
    input reset,
    input clk,
    input [6:0] Instr,
    input ALUBcond,
    output PCWriteNotCond,
    output PCWrite,
    output IorD,
    output MemRead,
    output MemWrite,
    output MemtoReg,
    output IRWrite,
    output PCSource,
    output ALUOp,
    output [1:0] ALUSrcB,
    output ALUSrcA,
    output RegWrite,
    output is_ecall
);

    reg [2:0] state;

    always @(posedge clk) begin
        if(reset) begin
            state <= 1;
        end
        else begin
            case(Instr)
                `JAL, `JALR: begin
                    if(state == 3) state <= 1;
                    else state <= state + 1;
                end
                `ARITHMETIC, `ARITHMETIC_IMM, `STORE: begin
                    if(state == 4) state <= 1;
                    else state <= state + 1;
                end
                `LOAD: begin
                    if(state == 5) state <= 1;
                    else state <= state + 1;
                end
                `BRANCH: begin
                    if(state == 4) state <= 1;
                    else if(state == 3 && !ALUBcond) state <= 1;
                    else state <= state + 1;
                end
                default: state <= state;
            endcase
        end
end

    wire to_IR_from_MEM_PC    = (state == 1);                                 // 1
    wire to_A_from_RF_RS1     = (state == 2);                                 // 2
    wire to_B_from_RF_RS2     = (state == 2);                                 // 2
    wire to_ALUOut_from_PCp4  = (state == 2);                                 // 2
    wire to_ALUOut_from_ApB   = (state == 3 && Instr == `ARITHMETIC);         // R3
    wire to_RF_rd_from_ALUOut = ((state == 4 && Instr == `ARITHMETIC)
                                || (state == 3 && Instr == `JAL)
                                || (state == 3 && Instr == `JALR)
                                || (state == 4 && Instr == `ARITHMETIC_IMM));   // R4, JAL3, JALR3, I4
    wire to_PC_from_PCp4      = ((state == 4 && Instr == `ARITHMETIC)
                                || (state == 5 && Instr == `LOAD)
                                || (state == 4 && Instr == `STORE)
                                || (state == 4 && Instr == `ARITHMETIC_IMM));   // R4, LD5, SD4, I4
    wire to_ALUOut_from_Apimm = ((state == 3 && Instr == `LOAD)
                                || (state == 3 && Instr == `STORE)
                                || (state == 3 && Instr == `ARITHMETIC_IMM));   // LD3, SD3, I3
    wire to_MDR_from_MEM_ALUOut = (state == 4 && Instr == `LOAD);             // LD4
    wire to_RF_rd_from_MDR    = (state == 5 && Instr == `LOAD);               // LD5
    wire to_MEM_ALUOut_from_B = (state == 4 && Instr == `STORE);              // SD4
    wire to_PC_from_ALUOut    = (state == 3 && Instr == `BRANCH);   // B3
    wire to_PC_from_PCpimm    = ((state == 4 && Instr == `BRANCH)
                                || (state == 3 && Instr == `JAL));              // B4, JAL3
    wire to_PC_from_Apimm     = (state == 3 && Instr == `JALR);               // JALR3

    assign is_ecall = (Instr == `ECALL);
    assign ALUOp = !(state == 3 && (Instr == `ARITHMETIC || Instr == `ARITHMETIC_IMM));

    ROM ROM(
        .to_IR_from_MEM_PC(to_IR_from_MEM_PC),
        .to_A_from_RF_RS1(to_A_from_RF_RS1),
        .to_B_from_RF_RS2(to_B_from_RF_RS2),
        .to_ALUOut_from_PCp4(to_ALUOut_from_PCp4),
        .to_ALUOut_from_ApB(to_ALUOut_from_ApB),
        .to_RF_rd_from_ALUOut(to_RF_rd_from_ALUOut),
        .to_PC_from_PCp4(to_PC_from_PCp4),
        .to_ALUOut_from_Apimm(to_ALUOut_from_Apimm),
        .to_MDR_from_MEM_ALUOut(to_MDR_from_MEM_ALUOut),
        .to_RF_rd_from_MDR(to_RF_rd_from_MDR),
        .to_MEM_ALUOut_from_B(to_MEM_ALUOut_from_B),
        .to_PC_from_ALUOut(to_PC_from_ALUOut),
        .to_PC_from_PCpimm(to_PC_from_PCpimm),
        .to_PC_from_Apimm(to_PC_from_Apimm),
        .PCWriteNotCond(PCWriteNotCond),
        .PCWrite(PCWrite),
        .IorD(IorD),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .MemtoReg(MemtoReg),
        .IRWrite(IRWrite),
        .PCSource(PCSource),
        .ALUSrcB(ALUSrcB),
        .ALUSrcA(ALUSrcA),
        .RegWrite(RegWrite)
    );

endmodule
