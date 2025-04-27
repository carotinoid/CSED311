module PC (input reset,
           input clk,
           input [31:0] next_pc,
           input stall,
           output reg [31:0] current_pc);

always @(posedge clk) begin
    if(reset) current_pc <= 0;
    else if(!stall) current_pc <= next_pc;
end

endmodule
