module BranchPredictUnit(
    input [31:0] current_pc,
    output[31:0] predict_pc,
    input        clk,
    input        reset,

    input        update,
    input [31:0] faux_pas_pc,
    input        actual_behavior
);

wire [24:0] tag = current_pc[31:7];
wire [4:0] index = current_pc[6:2];

reg [24:0] tag_table[0:31];
reg [31:0] BTB[0:31];
reg [4:0] BHSR;
reg [1:0] PHT[0:31];

wire [24:0] upd_tag = faux_pas_pc[31:7];
wire [4:0] upd_index = faux_pas_pc[6:2];


always @(posedge clk) begin
    if (reset) begin
        BHSR <= 5'b0;
        for (integer i = 0; i < 32; i = i + 1) begin
            tag_table[i] <= 25'b0;
            BTB[i] <= 32'b0;
            PHT[i] <= 2'b00;
        end
    end
    else if(update) begin
        BHSR <= {BHSR[3:0], actual_behavior};
        tag_table[upd_index] <= upd_tag;
        BTB[upd_index] <= faux_pas_pc;
        if (actual_behavior) begin
            if (PHT[upd_index ^ BHSR] < 2'b11) begin
                PHT[upd_index ^ BHSR] <= PHT[upd_index ^ BHSR] + 1;
            end
        end 
        else begin
            if (PHT[upd_index ^ BHSR] > 2'b00) begin
                PHT[upd_index ^ BHSR] <= PHT[upd_index ^ BHSR] - 1;
            end
        end
    end
end

assign predict_pc = (tag == tag_table[index]) && (PHT[index ^ BHSR] > 2'b01) ? BTB[index] : current_pc + 4;
// assign predict_pc = current_pc + 4; // always not taken

endmodule
