
`include "vending_machine_def.v"
	

module calculate_current_state(i_input_coin,i_select_item,item_price,coin_value,current_total,
input_total, output_total, return_total,current_total_nxt,wait_time,o_return_coin,o_available_item,o_output_item);


	
	input [`kNumCoins-1:0] i_input_coin,o_return_coin;
	input [`kNumItems-1:0]	i_select_item;			
	input [31:0] item_price [`kNumItems-1:0];
	input [31:0] coin_value [`kNumCoins-1:0];	
	input [`kTotalBits-1:0] current_total;
	input [31:0] wait_time;
	output reg [`kNumItems-1:0] o_available_item,o_output_item;
	output reg  [`kTotalBits-1:0] input_total, output_total, return_total,current_total_nxt;
	integer i;	



	
	// Combinational logic for the next states
	always @(*) begin
		// TODO: current_total_nxt
		// You don't have to worry about concurrent activations in each input vector (or array).
		// Calculate the next current_total state.
		current_total_nxt = current_total;
		if (i_input_coin) begin
			case(i_input_coin) 
				3'b000: current_total_nxt = current_total;
				3'b001: current_total_nxt = current_total + coin_value[0];
				3'b010: current_total_nxt = current_total + coin_value[1];
				3'b100: current_total_nxt = current_total + coin_value[2];
				3'b011: current_total_nxt = current_total + coin_value[0] + coin_value[1];
				3'b101: current_total_nxt = current_total + coin_value[0] + coin_value[2];
				3'b110: current_total_nxt = current_total + coin_value[1] + coin_value[2];
				3'b111: current_total_nxt = current_total + coin_value[0] + coin_value[1] + coin_value[2];
				// ToDo
			endcase
		end
		else if (i_select_item && current_total >= item_price[$clog2(i_select_item)]) begin
			current_total_nxt = current_total - item_price[$clog2(i_select_item)];
		end
	end

	
	
	// Combinational logic for the outputs
	always @(*) begin
		// TODO: o_available_item
		// TODO: o_output_item
		o_available_item = 4'b0000;
		o_output_item = 4'b0000;
		for(i = 0; i < 4; i = i + 1) begin
			if(current_total >= item_price[i]) begin
				o_available_item = o_available_item | (1 << i);
			end
		end
		if(i_select_item) begin
			o_output_item = o_available_item & i_select_item;
		end
	end

endmodule 