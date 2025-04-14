`include "alu_op.v"

module ALU (input [7:0] alu_op,
            input [31:0] alu_in_1,
            input [31:0] alu_in_2,
            output reg [31:0] alu_result,
            output alu_bcond);

always @(*) begin
    alu_bcond = 0;
    alu_result = 0;
    case(alu_op) 
        `ADD : alu_result = alu_in_1 + alu_in_2;
        `SUB : alu_result = alu_in_1 - alu_in_2;
        `SLL : alu_result = alu_in_1 << alu_in_2;
        `XOR : alu_result = alu_in_1 ^ alu_in_2;
        `OR : alu_result = alu_in_1 | alu_in_2;
        `AND : alu_result = alu_in_1 & alu_in_2;
        `SRL : alu_result = alu_in_1 >> alu_in_2;
        `SRA : alu_result = alu_in_1 >>> alu_in_2;
        `BEQ : if(alu_in_1 == alu_in_2) alu_bcond = 1;
        `BNE : if(alu_in_1 != alu_in_2) alu_bcond = 1;
        `BLT : if(alu_in_1 < alu_in_2) alu_bcond = 1;
        `BGE : if(alu_in_1 >= alu_in_2) alu_bcond = 1;
        default: alu_result = 0;
    endcase
end

endmodule
