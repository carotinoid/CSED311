module mux4(input [31:0] in0, 
           input [31:0] in1, 
           input [31:0] in2,
           input [31:0] in3,
           input [1:0] sel,
           output [31:0] out);
           
    assign out = sel[0]?sel[1]?in3:in1
                       :sel[1]?in2:in0;
    
endmodule
