`include "CLOG2.v"

module Cache #(parameter LINE_SIZE = 16,
               parameter NUM_SETS = 32, /* Your choice */
               parameter NUM_WAYS = 2 /* Your choice */) (
    input reset,
    input clk,

    input is_input_valid,
    input [31:0] addr,
    input mem_read,
    input mem_write,
    input [31:0] din,

    output is_ready,
    output is_output_valid,
    output [31:0] dout,
    output is_hit
);
  // Wire declarations
  // wire is_data_mem_ready;
  // assign is_ready = is_data_mem_ready;
  // Reg declarations
  // You might need registers to keep the status.

  reg [31:0]                  _dout;
  reg                         _is_output_valid;
  reg                         _is_hit;
  assign                      is_output_valid  = _is_output_valid;
  assign                      is_hit           = _is_hit;
  assign                      dout             = _dout;

  localparam                  SET_BIT          = `CLOG2(NUM_SETS);
  localparam                  BLK_OFFSET_BIT   = `CLOG2(LINE_SIZE);
  localparam                  TAG_BIT          = 32 - SET_BIT - BLK_OFFSET_BIT;
  localparam                  WAY_BIT          = `CLOG2(NUM_WAYS);
   
  wire [TAG_BIT - 1:0]        tag              = addr[31:32 - TAG_BIT];
  wire [SET_BIT - 1:0]        set_index        = addr[31 - TAG_BIT:32 - TAG_BIT - SET_BIT];
  wire [BLK_OFFSET_BIT - 1:0] block_offset     = addr[31 - TAG_BIT - SET_BIT:0];
   
  reg [LINE_SIZE * 8 - 1:0]   cache_mem        [0:NUM_SETS-1][0:NUM_WAYS-1]; 
  reg                         valid_bits       [0:NUM_SETS-1][0:NUM_WAYS-1];
  reg [TAG_BIT - 1:0]         tags             [0:NUM_SETS-1][0:NUM_WAYS-1];
  reg                         dirty_bits       [0:NUM_SETS-1][0:NUM_WAYS-1];
  integer                     lru_bits         [0:NUM_SETS-1][0:NUM_WAYS-1];
  integer                     lru_counter; 

  integer i, j, k;

  wire                        dmem_is_output_valid;
  wire [LINE_SIZE * 8 - 1:0]  dmem_dout;
  wire                        dmem_mem_ready;

  reg hit;
  reg [WAY_BIT - 1:0]         hit_way;

  assign is_ready = (state == 0);

  always @(*) begin
    hit = 0;
    hit_way = 0;
    if(state == 1) begin
      for (i = 0; i < NUM_WAYS; i = i + 1) begin
        if (valid_bits[set_index][i] && tags[set_index][i] == tag) begin
          hit = 1;
          hit_way = i[WAY_BIT - 1:0];
          break;
        end
      end
    end
  end

  integer victim;
  reg flag;

  wire v = valid_bits[set_index][victim];
  always @(*) begin
    victim = 0;
    flag = 0;
    for (i = 0; i < NUM_WAYS; i = i + 1) begin
      if (!valid_bits[set_index][i]) begin
        victim = i;
        flag = 1;
        break;
      end
    end
    if (!flag) begin
      for (i = 0; i < NUM_WAYS; i = i + 1) begin
        if (lru_bits[set_index][victim] > lru_bits[set_index][i]) begin
          victim = i;
        end
      end
    end
  end


  reg [2:0] state;

  always @(posedge clk) begin
    if(reset) begin
      for (i = 0; i < NUM_SETS; i = i + 1) begin
        for (j = 0; j < NUM_WAYS; j = j + 1) begin
          valid_bits[i][j] <= 0;
          dirty_bits[i][j] <= 0;
          tags[i][j] <= 0;
          cache_mem[i][j]<= 0;
          lru_bits[i][j] <= 0;
        end
        lru_counter <= 0;
      end

      _dout <= 0;
      _is_hit <= 0;
      _is_output_valid <= 0;

      state <= 0;
      dmem_is_input_valid <= 0;
      dmem_addr <= 0;
      dmem_mem_read <= 0;
      dmem_mem_write <= 0;
      dmem_din <= 0;
    end
    else begin
      if(state == 0) begin // IDLE
        dmem_is_input_valid <= 0;
        // _is_output_valid <= 0;
        if(is_input_valid) state <= 1;
      end
      else if(state == 1) begin // COMPARE TAG
        begin
          /////////////// HIT ///////////////
          if(hit && mem_read) begin
            _dout <= cache_mem[set_index][hit_way][block_offset * 8 +: 32];
            _is_hit <= 1;
            _is_output_valid <= 1;
            lru_bits[set_index][hit_way] <= lru_counter;
            lru_counter <= lru_counter + 1;
            state <= 6; // Go back to IDLE state
          end
          else if(hit && mem_write) begin
            _is_hit <= 1;
            _is_output_valid <= 1;
            cache_mem[set_index][hit_way][block_offset * 8 +: 32] <= din;
            dirty_bits[set_index][hit_way] <= 1; 
            lru_bits[set_index][hit_way] <= lru_counter;
            lru_counter <= lru_counter + 1;
            state <= 6; // Go back to IDLE state
          end
          /////////////// MISS ///////////////
          else if(!hit) begin
            _is_hit <= 0;
            _is_output_valid <= 0;

            if(valid_bits[set_index][victim] && dirty_bits[set_index][victim]) begin
              dmem_is_input_valid <= 1;
              dmem_addr <= {tags[set_index][victim], set_index, block_offset} >> BLK_OFFSET_BIT;
              dmem_mem_read <= 0;
              dmem_mem_write <= 1;
              dmem_din <= cache_mem[set_index][victim];
              state <= 4;
            end
            else begin
              dmem_is_input_valid <= 1;
              dmem_addr <= {tag, set_index, block_offset} >> BLK_OFFSET_BIT;
              dmem_mem_read <= 1;
              dmem_mem_write <= 0;
              dmem_din <= 0; // No data to write
              state <= 5;
            end
          end
        end
      end
      else if(state == 4) state <= 2;
      else if(state == 5) state <= 3;
      else if(state == 2) begin 
        // Valid + evict + dirty --> memwrite
        dmem_is_input_valid <= 0;
        if(dmem_mem_ready) begin //TODO
          state <= 5;
          dmem_is_input_valid <= 1;
          dmem_addr <= {tag, set_index, block_offset} >> BLK_OFFSET_BIT;
          dmem_mem_read <= 1;
          dmem_mem_write <= 0;
          dmem_din <= 0; // No data to write
        end 
      end
      else if(state == 3) begin // READ
        dmem_is_input_valid <= 0;
        if(dmem_is_output_valid) begin
          cache_mem[set_index][victim] <= dmem_dout;
          valid_bits[set_index][victim] <= 1;
          dirty_bits[set_index][victim] <= 0;
          tags[set_index][victim] <= tag;
          _dout <= dmem_dout[block_offset * 8 +: 32];
          _is_output_valid <= 1;
          _is_hit <= 0;
          lru_bits[set_index][victim] <= lru_counter;
          lru_counter <= lru_counter + 1;
          state <= 6; 
          if(mem_read) begin
          end
          else if(mem_write) begin
            cache_mem[set_index][victim][block_offset * 8 +: 32] <= din;
            dirty_bits[set_index][victim] <= 1;
          end
        end
      end
      else if(state == 6) begin
        _is_output_valid <= 0;
        state <= 0;
      end
    end
  end

  reg dmem_is_input_valid;
  reg [31:0] dmem_addr;
  reg dmem_mem_read;
  reg dmem_mem_write;
  reg [LINE_SIZE * 8 - 1:0] dmem_din;

  // Instantiate data memory
  DataMemory #(.BLOCK_SIZE(LINE_SIZE)) data_mem(
    .reset(reset),
    .clk(clk),

    .is_input_valid(dmem_is_input_valid),
    .addr(dmem_addr),        // NOTE: address must be shifted by CLOG2(LINE_SIZE)
    .mem_read(dmem_mem_read),
    .mem_write(dmem_mem_write),
    .din(dmem_din),

    // is output from the data memory valid?
    .is_output_valid(dmem_is_output_valid),
    .dout(dmem_dout),
    // is data memory ready to accept request?
    .mem_ready(dmem_mem_ready)
  );
endmodule
