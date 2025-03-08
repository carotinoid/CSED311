`include "vending_machine_def.v"

module change_state_and_output(clk, reset_n, next_total, output_item, return_coin, return_total, flag_inserted, flag_output_item, i_trigger_return, item_price,
 							   o_output_item, o_return_coin, o_available_item, current_total);

	input clk;
	input reset_n;
	input [`kTotalBits-1:0] next_total;

	input [`kNumItems-1:0] output_item;
    input [`kNumCoins-1:0] return_coin; 
    input [`kTotalBits-1:0] return_total;

	input flag_inserted;
	input flag_output_item;

	input i_trigger_return;
	
	input [31:0] item_price [`kNumItems-1:0];

	output reg [`kNumCoins-1:0] o_return_coin;
	output reg [`kNumItems-1:0] o_output_item;
	output reg [`kNumItems-1:0] o_available_item;

	output reg [`kTotalBits-1:0] current_total;
	integer i;

	wire timeout;

	wire timeset;
	assign timeset = flag_inserted || flag_output_item;
	
	reg flag_return;
	initial begin
		flag_return = 0;
	end

	always @(posedge clk, negedge reset_n) begin
		if (!reset_n) begin
			current_total <= 0;
			o_output_item <= 0;
			flag_return <= 0;
		end
		else begin
			current_total <= next_total;
			o_output_item <= output_item;

			if(timeout) begin
				o_return_coin <= return_coin;
				current_total <= return_total;
			end
			else begin
				if(i_trigger_return) begin
					o_return_coin <= return_coin;
					flag_return <= 1;
				end
				else begin
					o_return_coin <= 0;
					if(flag_return) begin
						current_total <= return_total;
						flag_return <= 0;
					end
				end
			end
		end
	end

	always @(*) begin
		o_available_item = 4'b0000;
		for(i = 0; i < 4; i++) begin
			if(current_total >= item_price[i]) 
				o_available_item = o_available_item | (4'b0001 << i);
		end
	end

	change_time change_time(
						.clk(clk),
						.reset_n(reset_n),
						.timeset(timeset),
						.timeout(timeout));

endmodule 