`include "opcodes.v"

module ControlflowDetectUnit(
    input [6:0] Instr,
    output is_ctrlflow
);

assign is_ctrlflow = (Instr == `BRANCH) || (Instr == `JAL) || (Instr == `JALR);

endmodule
