module pc (input reset,
           input clk,
           input [31:0] next_pc,
           output reg [31:0] current_pc);

always @(posedge clk) begin
    current_pc <= next_pc;
end

endmodule