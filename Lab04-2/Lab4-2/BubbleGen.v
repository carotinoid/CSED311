module BubbleGen(
    // input taken,
    // input hit,
    input IF_wrong,
    input ID_wrong,
    input EX_wrong,
    output IF_is_bubble,
    output ID_is_bubble
);

assign ID_is_bubble = EX_wrong;
assign IF_is_bubble = EX_wrong || ID_wrong;
// assign isbubble = taken ^ hit;

endmodule
