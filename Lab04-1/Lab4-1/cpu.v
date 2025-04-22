// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify modules (except InstMemory, DataMemory, and RegisterFile)
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted, // Whehther to finish simulation
           output [31:0]print_reg[0:31]); // Whehther to finish simulation
  /***** Wire declarations *****/
  /***** Register declarations *****/
  // You need to modify the width of registers
  // In addition, 
  // 1. You might need other pipeline registers that are not described below
  // 2. You might not need registers described below
  /***** IF/ID pipeline registers *****/
  reg IF_ID_inst;           // will be used in ID stage
  /***** ID/EX pipeline registers *****/
  // From the control unit
  reg ID_EX_alu_op;         // will be used in EX stage
  reg ID_EX_alu_src;        // will be used in EX stage
  reg ID_EX_mem_write;      // will be used in MEM stage
  reg ID_EX_mem_read;       // will be used in MEM stage
  reg ID_EX_mem_to_reg;     // will be used in WB stage
  reg ID_EX_reg_write;      // will be used in WB stage
  // From others
  reg [31:0] ID_EX_rs1_data;
  reg [31:0] ID_EX_rs2_data;
  reg [31:0] ID_EX_imm;
  reg [31:0] ID_EX_ALU_ctrl_unit_input;
  reg [4:0] ID_EX_rd;

  /***** EX/MEM pipeline registers *****/
  // From the control unit
  reg EX_MEM_mem_write;     // will be used in MEM stage
  reg EX_MEM_mem_read;      // will be used in MEM stage
  reg EX_MEM_is_branch;     // will be used in MEM stage
  reg EX_MEM_mem_to_reg;    // will be used in WB stage
  reg EX_MEM_reg_write;     // will be used in WB stage
  // From others
  reg [31:0] EX_MEM_alu_out;
  reg [31:0] EX_MEM_dmem_data;
  reg [4:0] EX_MEM_rd;

  /***** MEM/WB pipeline registers *****/
  // From the control unit
  reg MEM_WB_mem_to_reg;    // will be used in WB stage
  reg MEM_WB_reg_write;     // will be used in WB stage
  // From others
  reg MEM_WB_mem_to_reg_src_1;
  reg MEM_WB_mem_to_reg_src_2;

  // ---------- Update program counter ----------
  wire current_pc_plus_4;
  wire next_pc;
  wire PCsrc;
  assign PCsrc = EX_MEM_is_branch & EX_MEM_bcond;
  mux PC_mux(
    .sel(PCsrc),          // input
    .in0(current_pc_plus_4),         // input
    .in1(EX_MEM_branch_addr),         // input
    .out(next_pc)          // output
  );

  wire current_pc;
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  adder pc_adder(
    .in0(current_pc),         // input
    .in1(4),         // input
    .out(current_pc_plus_4)          // output
  );

  wire instr;
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(current_pc),    // input
    .dout(instr)     // output
  );

  reg [31:0] IF_ID_PC;
  reg [31:0] ID_EX_PC;
  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      IF_ID_inst <= 0;
      IF_ID_PC <= 0;
    end
    else begin
      IF_ID_inst <= instr;
      IF_ID_PC <= current_pc;
    end
  end

  wire rd_din, rs1_dout, rs2_dout;
  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (IF_ID_inst[19:15]),          // input
    .rs2 (IF_ID_inst[24:20]),          // input
    .rd (IF_ID_inst[11:7]),           // input
    .rd_din (rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (rs1_dout),     // output
    .rs2_dout (rs2_dout),      // output
    .print_reg(print_reg)
  );

  wire ctrl_mem_read, ctrl_mem_to_reg, ctrl_mem_write, ctrl_alu_src, ctrl_write_enable, ctrl_pc_to_reg, ctrl_alu_op, ctrl_is_ecall, branch;
  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .part_of_inst(IF_ID_inst[6:0]),  // input
    .mem_read(ctrl_mem_read),      // output
    .mem_to_reg(ctrl_mem_to_reg),    // output
    .mem_write(ctrl_mem_write),     // output
    .alu_src(ctrl_alu_src),       // output
    .write_enable(ctrl_write_enable),  // output 
    .pc_to_reg(ctrl_pc_to_reg),     // output
    .alu_op(ctrl_alu_op),        // output
    .branch(ctrl_branch),      // output
    .is_ecall(ctrl_is_ecall)       // output (ecall inst)
  );

  wire imm_out;
  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(IF_ID_inst),  // input
    .imm_gen_out(imm_out)    // output
  );

  reg ID_EX_branch;
  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      ID_EX_alu_op <= 0;
      ID_EX_alu_src <= 0;
      ID_EX_mem_write <= 0;
      ID_EX_mem_read <= 0;
      ID_EX_mem_to_reg <= 0;
      ID_EX_reg_write <= 0;
      ID_EX_rs1_data <= 0;
      ID_EX_rs2_data <= 0;
      ID_EX_imm <= 0;
      ID_EX_ALU_ctrl_unit_input <= 0;
      ID_EX_rd <= 0;
      ID_EX_branch <= 0;
      ID_EX_PC <= 0;
    end
    else begin
      ID_EX_alu_op <= ctrl_alu_op;
      ID_EX_alu_src <= ctrl_alu_src;
      ID_EX_mem_write <= ctrl_mem_write;
      ID_EX_mem_read <= ctrl_mem_read;
      ID_EX_mem_to_reg <= ctrl_mem_to_reg;
      ID_EX_reg_write <= ctrl_write_enable;
      ID_EX_rs1_data <= rs1_dout;
      ID_EX_rs2_data <= rs2_dout;
      ID_EX_imm <= imm_out;
      ID_EX_ALU_ctrl_unit_input <= IF_ID_inst;
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_branch <= branch;
      ID_EX_PC <= IF_ID_PC;
    end
  end

  wire branch_addr;
  adder branch_adder(
    .in0(ID_EX_PC),         // input
    .in1(ID_EX_imm),         // input
    .out(branch_addr)          // output
  );




  wire alu_op;
  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .part_of_inst(ID_EX_ALU_ctrl_unit_input),  // input
    .alu_op(alu_op)         // output
  );

  wire alu_src1, alu_src2;
  assign alu_src1 = ID_EX_rs1_data;
  mux ALU_src2_mux (
    .sel(ID_EX_alu_src),          // input
    .in0(ID_EX_rs2_data),         // input
    .in1(ID_EX_imm),              // input
    .out(alu_src2)                        // output
  );

  wire alu_result, alu_bcond;
  // ---------- ALU ----------
  ALU alu (
    .alu_op(ID_EX_alu_op),      // input
    .alu_in_1(alu_src1),    // input  
    .alu_in_2(alu_src2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(alu_bcond)     // output
  );

  reg EX_MEM_bcond;
  reg EX_MEM_branch_addr;
  // Update EX/MEM pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_mem_write <= 0;
      EX_MEM_mem_read <= 0;
      EX_MEM_is_branch <= 0;
      EX_MEM_mem_to_reg <= 0;
      EX_MEM_reg_write <= 0;
      EX_MEM_alu_out <= 0;
      EX_MEM_dmem_data <= 0;
      EX_MEM_rd <= 0;
      EX_MEM_bcond <= 0;
      EX_MEM_branch_addr <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_mem_read <= ID_EX_mem_read;
      EX_MEM_is_branch <= ID_EX_branch;
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_reg_write <= ID_EX_reg_write;
      EX_MEM_alu_out <= alu_result;
      EX_MEM_dmem_data <= ID_EX_rs2_data;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_bcond <= alu_bcond;
      EX_MEM_branch_addr <= branch_addr;
    end
  end

  wire dout;
  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (dout)        // output
  );

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out; // 0 sel
      MEM_WB_mem_to_reg_src_2 <= dout; // 1 sel
    end
  end

  mux WB_mux (
    .sel(MEM_WB_mem_to_reg),          // input
    .in0(MEM_WB_mem_to_reg_src_1),         // input
    .in1(MEM_WB_mem_to_reg_src_2),         // input
    .out(rd_din)                        // output
  );
  
endmodule
