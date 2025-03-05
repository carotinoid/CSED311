`include "vending_machine_def.v"

module calc_total(current_total, i_input_coin, coin_value, next_total);

    input [`kTotalBits-1:0] current_total;
    input [`kNumCoins-1:0] i_input_coin;
    input [31:0] coin_value [`kNumCoins-1:0];
    output [`kTotalBits-1:0] next_total;

    assign next_total = current_total + coin_value[0] * i_input_coin[0] + coin_value[1] * i_input_value[1] + coin_value[2] * i_input_coin[2];

endmodule