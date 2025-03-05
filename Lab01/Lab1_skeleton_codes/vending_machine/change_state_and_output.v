`include "vending_machine_def.v"

module change_state_and_output(clk, reset_n, next_total, i_select_item, i_input_coin, i_trigger_return, o_output_item, o_return_coin, o_available_item, current_total, item_price, coin_value);

	input clk;
	input reset_n;
	input [`kTotalBits-1:0] next_total;
	input [`kNumItems-1:0] i_select_item;
	input [`kNumCoins-1:0] i_input_coin;
	input i_trigger_return;
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];
	output reg [`kNumCoins-1:0] o_return_coin;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kNumItems-1:0] o_available_item;
	output reg [`kTotalBits-1:0] current_total;
	integer i;
	integer j;

	wire [`kTotalBits-1:0] required_money;
	assign required_money = (i_select_item[0] * item_price[0]
							+ i_select_item[1] * item_price[1]
							+ i_select_item[2] * item_price[2]
							+ i_select_item[3] * item_price[3]);
	wire check_return;
	assign check_return = timeout | i_trigger_return;
	wire timeout;
	wire timeset;
	assign timeset = i_input_coin | 
					((i_select_item != 3'b000) & (current_total >= required_money));


	always @(posedge clk) begin
		if (!reset_n) begin
			current_total = 0;
			o_return_coin = 0;
		end
		else begin
			current_total = next_total;
			o_output_item <= 4'b0000;
			if(i_select_item && current_total >= required_money) begin
				o_output_item <= i_select_item;
				current_total = current_total - required_money;
			end
			if(check_return) begin
				o_return_coin = o_return_coin;
				for(j = 2; j >= 0; j--) begin
					if(current_total >= coin_value[j]) begin
						o_return_coin = o_return_coin | (3'b001 << j);
						current_total = current_total - coin_value[j];
					end
				end
			end
			else o_return_coin = 0;
		end
	end

	always @(*) begin
		o_available_item = 4'b0000;
		for(i = 0; i < 4; i++) begin
			if(current_total >= item_price[i]) o_available_item = o_available_item | (4'b0001 << i);
		end
	end

	change_time change_time(
						.clk(clk),
						.reset_n(reset_n),
						.timeset(timeset),
						.timeout(timeout));

endmodule 