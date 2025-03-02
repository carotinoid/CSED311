`include "vending_machine_def.v"

	

module check_time_and_coin(i_input_coin,i_select_item,i_trigger_return,clk,reset_n,wait_time,o_return_coin,current_total,item_price,coin_value);
	input clk;
	input reset_n;
	input [`kNumCoins-1:0] i_input_coin;
	input [`kNumItems-1:0]	i_select_item;
	input i_trigger_return;
	input [31:0] item_price [`kNumItems-1:0];	// Price of each item
	input [31:0] coin_value [`kNumCoins-1:0];	// Value of each coin
	output reg  [`kNumCoins-1:0] o_return_coin;
	output reg [31:0] wait_time;
	inout [`kTotalBits-1:0] current_total;

	// initiate values
	initial begin
		wait_time = 0;
	end


	// // update coin return time
	// always @(i_input_coin, i_select_item) begin
	// 	// TODO: update coin return time
	// 	if (i_input_coin) wait_time = `kWaitTime;
	// 	if (i_select_item) begin
	// 		if(current_total >= item_price[$clog2(i_select_item)]) begin
	// 			wait_time = `kWaitTime;
	// 		end
	// 	end
	// end

	always @(*) begin
		// TODO: o_return_coin
		o_return_coin = 3'b000;
		if (i_trigger_return || wait_time == 0) begin // hard-coding, TODO : using "for"
			if (current_total >= coin_value[2]) begin
				o_return_coin = o_return_coin | 3'b100;
			end
			if (current_total - coin_value[2] * !!(o_return_coin & 3'b100) >= coin_value[1]) begin
				o_return_coin = o_return_coin | 3'b010;
			end
			if (current_total - coin_value[2] * !!(o_return_coin & 3'b100) - coin_value[1] * !!(o_return_coin & 3'b010) >= coin_value[0]) begin
				o_return_coin = o_return_coin | 3'b001;
			end
		end
		//TODO : 같은 종류의 코인이 여러번 들어왔을 때를 대비해서 리턴한 코인의 가치만큼 빼줘야함.
	end

	// always @(posedge clk ) begin
	// 	if (!reset_n) begin
	// 	// TODO: reset all states.
	// 		wait_time <= 0;
	// 	end
	// 	else begin
	// 	// TODO: update all states.
	// 		wait_time <= wait_time - 1;
	// 	end
	// end

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			wait_time <= 0;
		end else if (i_input_coin || (i_select_item && current_total >= item_price[$clog2(i_select_item)])) begin
			wait_time <= `kWaitTime;
		end else if (wait_time > 0) begin
			wait_time <= wait_time - 1;
		end
	end


endmodule 