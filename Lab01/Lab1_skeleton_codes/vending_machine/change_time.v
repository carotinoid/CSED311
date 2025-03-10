`include "vending_machine_def.v"

module change_time(clk,reset_n,timeset,timeout);
	input clk;
	input reset_n;
    input timeset;
    output timeout;
    reg [`kTotalBits : 0] wait_time;
    assign timeout = (wait_time == 0);
	
	always @(posedge clk) begin
		if (!reset_n) wait_time <= -1;
		else if (timeset) wait_time <= `kWaitTime;
        else if (wait_time > 0) wait_time <= wait_time - 1;
        else wait_time <= 0;
	end
endmodule 