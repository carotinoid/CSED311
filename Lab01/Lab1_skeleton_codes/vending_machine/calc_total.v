`include "vending_machine_def.v"

module calc_total(current_total, i_input_coin, i_select_item, coin_value, item_price,
                  next_total, output_item, return_coin, return_total, flag_inserted, flag_output_item);

    input [`kTotalBits-1:0] current_total;
    input [`kNumItems-1:0] i_select_item;
    input [`kNumCoins-1:0] i_input_coin;
    input [31:0] coin_value [`kNumCoins-1:0];
	input [31:0] item_price [`kNumItems-1:0];

    output reg [`kTotalBits-1:0] next_total; 

	wire [`kTotalBits-1:0] required_money;
	assign required_money = (i_select_item[0] * item_price[0]
							+ i_select_item[1] * item_price[1]
							+ i_select_item[2] * item_price[2]
							+ i_select_item[3] * item_price[3]);

    output reg [`kNumItems-1:0] output_item;
	output reg [`kNumCoins-1:0] return_coin;
	output flag_inserted = (i_input_coin != `kNumCoins'b0);
	output flag_output_item = ((i_select_item != `kNumItems'b0) && (current_total >= required_money));    
    output reg [`kTotalBits-1:0] return_total;
    integer i;

	always @(*) begin
		output_item = `kNumItems'b0;
        next_total = current_total 
                + coin_value[0] * i_input_coin[0] 
                + coin_value[1] * i_input_coin[1] 
                + coin_value[2] * i_input_coin[2];

		if(next_total >= required_money) begin
			output_item = i_select_item;
			next_total = next_total - required_money;
		end

        return_total = next_total;
        return_coin = `kNumCoins'b0;        
  
        for(i = `kNumCoins-1; i >= 0; i--) begin
            if(return_total >= coin_value[i]) begin
                return_coin = return_coin | (`kNumCoins'b001 << i);
                return_total =  return_total - coin_value[i];
            end
        end
	end

endmodule