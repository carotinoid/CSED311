`include "alu_op.v"
`include "opcodes.v"

module ALUControlUnit(input [31:0] instr,
                     output reg [7:0] alu_op);

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire Instr30 = instr[30];

    wire [6:0] funct7;
    assign funct7 = {1'b0, Instr30, 5'b00000};

    always @(*) begin
        case(opcode)
            `ARITHMETIC : begin
                case(funct3) 
                    `FUNCT3_ADD : begin // with `FUNCT7_SUB
                        if(funct7 == `FUNCT7_SUB) alu_op = `SUB;
                        else alu_op = `ADD;
                    end
                    `FUNCT3_SLL : alu_op = `SLL;    
                    `FUNCT3_XOR : alu_op = `XOR;    
                    `FUNCT3_OR : alu_op = `OR;    
                    `FUNCT3_AND : alu_op = `AND;    
                    `FUNCT3_SRL : alu_op = `SRL;  
                    default: alu_op = `ADD;  
                endcase
            end
            `ARITHMETIC_IMM : begin
                case(funct3)
                    `FUNCT3_ADD : alu_op = `ADD;
                    `FUNCT3_SLL : alu_op = `SLL;
                    `FUNCT3_XOR : alu_op = `XOR;
                    `FUNCT3_OR : alu_op = `OR;
                    `FUNCT3_AND : alu_op = `AND;
                    `FUNCT3_SRL : alu_op = `SRL;
                    default: alu_op = `ADD;
                endcase
            end
            `LOAD, `STORE, `JALR : begin
                alu_op = `ADD;
            end
            `BRANCH : begin
                case(funct3)
                    `FUNCT3_BEQ : alu_op = `BEQ;
                    `FUNCT3_BNE : alu_op = `BNE;
                    `FUNCT3_BLT : alu_op = `BLT;
                    `FUNCT3_BGE : alu_op = `BGE;
                    default: alu_op = `BEQ;
                endcase
            end
            default: alu_op = `ADD;
        endcase
    end
    
endmodule
