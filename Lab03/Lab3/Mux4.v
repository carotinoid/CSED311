module Mux4(input [31:0] in0, 
           input [31:0] in1, 
           input [31:0] in2,
           input [31:0] in3,
           input [1:0] sel,
           output [31:0] out);
           
    assign out = !sel[1]?!sel[0]?in0:in1
                        :!sel[0]?in2:in3;
    
endmodule
