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

	wire check_return;
	wire timeout;
	wire timeset;
	assign check_return = timeout | i_trigger_return;
	assign timeset = i_input_coin | 
					((i_select_item != 3'b000) & (current_total >= 
					(i_select_item[0] * item_price[0]
					+ i_select_item[1] * item_price[1]
					+ i_select_item[2] * item_price[2]
					+ i_select_item[3] * item_price[3])));

	change_time change_time(
						.clk(clk),
						.reset_n(reset_n),
						.timeset(timeset),
						.timeout(timeout));

	always @(posedge clk) begin
		if (!reset_n) begin
			current_total <= 0;
			o_return_coin <= 0;
		end
		else begin
			current_total <= next_total;
			o_output_item <= 4'b0000;
			o_return_coin <= o_return_coin;
			if(i_select_item) begin

			end
			if(check_return) begin
				$display(":::", current_total);
				// if(current_total >= coin_value[2]) begin
				// 	current_total <= current_total - coin_value[2];
				// 	o_return_coin <= o_return_coin | 3'b100;
				// end
				// if(current_total >= coin_value[1]) begin
				// 	current_total <= current_total - coin_value[1];
				// 	o_return_coin <= o_return_coin | 3'b010;
				// end
				// if(current_total >= coin_value[0]) begin
				// 	current_total <= current_total - coin_value[0];
				// 	o_return_coin <= o_return_coin | 3'b001;
				// end
				case(current_total)
					0: begin
						current_total <= current_total - 0;
						o_return_coin <= 3'b000;
					end
					100: begin
						current_total <= current_total - 100;
						o_return_coin <= 3'b001;
					end
					500: begin
						current_total <= current_total - 500;
						o_return_coin <= 3'b010;
					end
					1000: begin
						current_total <= current_total - 1000;
						o_return_coin <= 3'b100;
					end
					600: begin
						current_total <= current_total - 600;
						o_return_coin <= 3'b011;
					end
					1100: begin
						current_total <= current_total - 1100;
						o_return_coin <= 3'b101;
					end
					1500: begin
						current_total <= current_total - 1500;
						o_return_coin <= 3'b110;
					end
					1600: begin
						current_total <= current_total - 1600;
						o_return_coin <= 3'b111;
					end

				endcase
			end
		end
	end

	always @(*) begin
		o_available_item = 4'b0000;
		for(i = 0; i < 4; i++) begin
			if(current_total >= item_price[i]) o_available_item = o_available_item | (4'b0001 << i);
		end
	end


endmodule 