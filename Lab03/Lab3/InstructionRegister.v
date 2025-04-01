module InstructionRegister(
    input clk,
    input [31:0] in,
    input IRWrite,
    output reg [31:0] out
);

always @(posedge clk) begin
    if(IRWrite) out <= in;
    else out <= out;
end

endmodule