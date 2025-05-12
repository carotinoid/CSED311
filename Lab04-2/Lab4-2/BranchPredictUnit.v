module BranchPredictUnit(
    input [31:0] current_pc,
    output[31:0] predict_pc,
    output       taken,

    input [31:0] faux_pas_pc,
    input        actual_behavior
);

assign taken = 0;
assign predict_pc = current_pc + 4;

endmodule
