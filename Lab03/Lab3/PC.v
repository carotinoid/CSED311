module PC(
    input reset,
    input clk,
    input PCWrite,
    input [31:0] next_pc,
    output reg [31:0] current_pc
);

always @(posedge clk) begin
    if(reset) current_pc <= 0;
    else begin
        if(PCWrite) current_pc <= next_pc;
        else current_pc <= current_pc;
    end
end

endmodule
