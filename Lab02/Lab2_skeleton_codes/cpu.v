module cpu(input reset,                     // positive reset signal
           input clk,                       // clock signal
           output is_halted,                // Whehther to finish simulation
           output [31:0] print_reg [0:31]); // TO PRINT REGISTER VALUES IN TESTBENCH (YOU SHOULD NOT USE THIS)

  /***** Wire declarations *****/
  wire [31:0] next_instr_addr_1;
  wire [31:0] next_instr_addr_2;
  wire PCSrc1 = ctrl_JAL || (ctrl_Branch && bcond);
  wire [31:0] next_instr_addr_3;
  wire PCSrc2 = ctrl_JALR;
  wire [31:0] next_instr_addr;
  wire [31:0] instr_addr;
  wire [31:0] instr;
  wire [31:0] rs1_val;
  wire [31:0] rs2_val;
  wire [31:0] reg_mux_out;
  wire ctrl_JAL, ctrl_JALR, ctrl_Branch;
  wire ctrl_MemRead, ctrl_MemtoReg, ctrl_MemWrite;
  wire ctrl_ALUSrc, ctrl_RegWrite, ctrl_PCtoReg, ctrl_is_ecall;
  wire [31:0] imm_gen_out;
  wire [7:0] alu_op;
  wire [31:0] alu_mux_out;
  wire bcond;
  wire [31:0] alu_out;
  wire [31:0] alu_in_1 = rs1_val;
  wire [31:0] alu_in_2 = alu_mux_out;
  wire [31:0] mem_out;
  wire [31:0] data_mux_out;

  /***** Register declarations *****/

  // ---------- Update program counter ----------

  adder pc_adder1(
    .in0(instr_addr),             // input
    .in1(4),                      // input
    .out(next_instr_addr_1)       // output
  );

  adder pc_adder2(
    .in0(instr_addr),             // input  
    .in1(imm_gen_out),            // input
    .out(next_instr_addr_2)       // output
  );

  mux pc_mux1(
    .in0(next_instr_addr_1),      // input
    .in1(next_instr_addr_2),      // input
    .sel(PCSrc1),                 // input
    .out(next_instr_addr_3)       // output
  );

  mux pc_mux_2(
    .in0(next_instr_addr_3),      // input
    .in1(alu_out),                // input
    .sel(PCSrc2),                 // input 
    .out(next_instr_addr)         // output
  );

  pc pc(
    .reset(reset),                // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),                    // input
    .next_pc(next_instr_addr),    // input
    .current_pc(instr_addr)       // output
  );
  
  // ---------- Instruction Memory ----------

  instruction_memory imem(
    .reset(reset),                // input
    .clk(clk),                    // input
    .addr(instr_addr),            // input
    .dout(instr)                  // output
  );

  // ---------- Register File ----------

  mux reg_mux(
    .in0(data_mux_out),           // input
    .in1(next_instr_addr_1),      // input
    .sel(ctrl_PCtoReg),           // input
    .out(reg_mux_out)             // output
  );

  register_file reg_file (
    .reset (reset),               // input
    .clk (clk),                   // input
    .rs1 (instr[19:15]),          // input
    .rs2 (instr[24:20]),          // input
    .rd (instr[11:7]),            // input
    .rd_din (reg_mux_out),        // input
    .write_enable (ctrl_RegWrite),// input
    .is_ecall (ctrl_is_ecall),    // input
    .rs1_dout (rs1_val),          // output
    .rs2_dout (rs2_val),          // output
    .print_reg (print_reg),       // output // DO NOT TOUCH THIS
    .is_halted (is_halted)        // output
  );

  // ---------- Control Unit ----------

  control_unit ctrl_unit (
    .Instr(instr[6:0]),           // input
    .JAL(ctrl_JAL),               // output
    .JALR(ctrl_JALR),             // output
    .Branch(ctrl_Branch),         // output
    .MemRead(ctrl_MemRead),       // output
    .MemtoReg(ctrl_MemtoReg),     // output
    .MemWrite(ctrl_MemWrite),     // output
    .ALUSrc(ctrl_ALUSrc),         // output
    .RegWrite(ctrl_RegWrite),     // output
    .PCtoReg(ctrl_PCtoReg),       // output
    .is_ecall(ctrl_is_ecall)      // output (ecall inst)
  );

  // ---------- Immediate Generator ----------

  imm_gen imm_gen(
    .Instr(instr),                // input
    .imm_gen_out(imm_gen_out)     // output
  );

  // ---------- ALU Control Unit ----------

  alu_ctrl_unit alu_ctrl_unit (
    .Instr30(instr[30]),          // input
    .funct3(instr[14:12]),        // input
    .opcode(instr[6:0]),          // input
    .alu_op(alu_op)               // output
  );

  // ---------- ALU ----------

  mux alu_mux(
    .in0(rs2_val),                // input
    .in1(imm_gen_out),            // input
    .sel(ctrl_ALUSrc),            // input
    .out(alu_mux_out)             // output
  );


  alu alu (
    .alu_op(alu_op),              // input
    .alu_in_1(alu_in_1),          // input  
    .alu_in_2(alu_in_2),          // input
    .alu_result(alu_out),         // output
    .alu_bcond(bcond)             // output
  );

  // ---------- Data Memory ----------

  data_memory dmem(
    .reset (reset),               // input
    .clk (clk),                   // input
    .addr (alu_out),              // input
    .din (rs2_val),               // input
    .mem_read (ctrl_MemRead),     // input
    .mem_write (ctrl_MemWrite),   // input
    .dout (mem_out)               // output
  );

  mux data_mux(
    .in0(alu_out),                // input
    .in1(mem_out),                // input
    .sel(ctrl_MemtoReg),          // input
    .out(data_mux_out)            // output
  );
endmodule
