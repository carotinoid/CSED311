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
  wire is_data_mem_ready;
  // Reg declarations
  // You might need registers to keep the status.

  // integer -> error: not constant, so I use localparam keyword.
  localparam LINE_BIT = `CLOG2(LINE_SIZE);
  localparam SET_BIT = `CLOG2(NUM_SETS);
  localparam BLK_OFFSET_BIT = `CLOG2(LINE_SIZE);
  localparam TAG_BIT = 32 - SET_BIT - BLK_OFFSET_BIT;
  localparam WAY_BIT = `CLOG2(NUM_WAYS);

  wire [TAG_BIT - 1:0]        tag = addr[31:32 - TAG_BIT];
  wire [SET_BIT - 1:0]        set_index = addr[31 - TAG_BIT:32 - TAG_BIT - SET_BIT];
  wire [BLK_OFFSET_BIT - 1:0] block_offset = addr[31 - TAG_BIT - SET_BIT:0];

  reg [LINE_SIZE * 8 - 1:0]   cache_mem[0:NUM_SETS-1][0:NUM_WAYS-1]; // Cache memory
  reg                         valid_bits[0:NUM_SETS-1][0:NUM_WAYS-1]; // Valid bits for each way
  reg [TAG_BIT - 1:0]         tags[0:NUM_SETS-1][0:NUM_WAYS-1]; // Tags for each way
  reg                         dirty_bits[0:NUM_SETS-1][0:NUM_WAYS-1]; // Dirty bits for each way
  integer                     lru_bits[0:NUM_SETS-1]; // LRU bits for each set
  integer                     lru_counter; // Counter for LRU replacement policy

  integer i, j, k;

  assign is_ready = is_data_mem_ready;

  wire dmem_is_output_valid;
  wire [LINE_SIZE * 8 - 1:0] dmem_dout;
  wire dmem_mem_ready;

  reg hit;
  reg [WAY_BIT - 1:0] hit_way; // Way index of the hit
  always @(*) begin // Asynchronous read (hit)
    hit = 0;
    hit_way = 0;
    for (i = 0; i < NUM_WAYS; i = i + 1) begin
      if (valid_bits[set_index][i] && tags[set_index][i] == tag) begin
        hit = 1;
        hit_way = i;
        break;
      end
    end
  end

  always @(posedge clk) begin
    if(reset) begin

    end
    else begin

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
