`include "opcodes"
module ControlUnit(
    input reset,
    input clk,
    input [6:0] Instr,
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

reg state;

always @(posedge clk) begin
    if(reset) begin
        state <= 0;
    end
    else begin
        case(Instr)
        `JAL, `JALR: begin
            if(state == 3) state <= 0;
            
        end
        `ARITHMETIC, `ARITHMETIC_IMM, `LOAD, `STORE: if(state == 4) state <= 0;
        `LOAD: if(state == 5) state <= 0;
        default: state <= state;
        endcase
        state <= state + 1;
    end
end

// assign PCWriteNotCond = 
// assign PCWrite = 
// assign MemRead = (Instr == `LOAD);
// assign MemtoReg = (Instr == `LOAD);
// assign MemWrite = (Instr == `STORE);
// assign IorD = 
// assign IRWrite = 
// assign PCSource = 
// assign ALUOp = 
// assign ALUSrcB = 
// assign ALUSrcA = 
// assign RegWrite = 
// assign is_ecall = 
endmodule