`include "alu_op.v"
`include "opcodes.v"

module alu_ctrl_unit(input Instr30,
                     input [2:0] funct3,
                     input [6:0] opcode,
                     output reg [7:0] alu_op);

wire [6:0] funct7;
assign funct7 = {1'b0, Instr30, 5'b00000};

always @(*) begin
    case(opcode)
        `ARITHMETIC : begin
            case(funct3) 
                `FUNCT3_ADD : alu_op = `ADD;    
                `FUNCT3_SUB : alu_op = `SUB;    // func7 에 따라 달라짐
                `FUNCT3_SLL : alu_op = `SLL;    
                `FUNCT3_XOR : alu_op = `XOR;    
                `FUNCT3_OR : alu_op = `OR;    
                `FUNCT3_AND : alu_op = `AND;    
                `FUNCT3_SRL : alu_op = `SRL;  
                default: alu_op = `ADD;  
            endcase
        end
        `LOAD, `STORE, `JALR, `BRANCH : begin
            alu_op = `ADD;
        end
    endcase

end

endmodule