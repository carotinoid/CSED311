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
  reg [31:0] IF_ID_inst;           // will be used in ID stage
  /***** ID/EX pipeline registers *****/
  // From the control unit
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
  reg [31:0] MEM_WB_mem_to_reg_src_1;
  reg [31:0] MEM_WB_mem_to_reg_src_2;

  // ---------- Update program counter ----------
  wire [31:0] IF_current_pc_plus_4;
  wire [31:0] IF_next_pc;
  wire IF_PCsrc;
  assign IF_PCsrc = EX_MEM_is_branch & EX_MEM_bcond;
  Mux2 PC_mux(
    .sel(IF_PCsrc),          // input
    .in0(IF_current_pc_plus_4),         // input
    .in1(EX_MEM_branch_addr),         // input
    .out(IF_next_pc)          // output
  );

  wire [31:0] IF_current_pc;
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(IF_next_pc),     // input
    .PC_Write(PC_Write),
    .current_pc(IF_current_pc)   // output
  );
  
  Adder pc_adder(
    .in0(IF_current_pc),         // input
    .in1(4),         // input
    .out(IF_current_pc_plus_4)          // output
  );

  wire [31:0] IF_instr;
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(IF_current_pc),    // input
    .dout(IF_instr)     // output
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
      if(IF_ID_Write) begin
        IF_ID_inst <= IF_instr;
        IF_ID_PC <= IF_current_pc;
      end
      else begin
        IF_ID_inst <= IF_ID_inst;
        IF_ID_PC <= IF_ID_PC;
      end
    end
  end

  wire [4:0] ID_rs1 = (ID_ctrl_is_ecall == 0 ? IF_ID_inst[19:15] : 17);
  wire [4:0] ID_rs2 = IF_ID_inst[24:20];
  wire [31:0] WB_ID_rd_din;
  wire [31:0] ID_rs1_dout;
  wire [31:0] ID_rs2_dout;

  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (ID_rs1),          // input
    .rs2 (ID_rs2),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (WB_ID_rd_din),       // input
    .write_enable (MEM_WB_reg_write),    // input
    .rs1_dout (ID_rs1_dout),     // output
    .rs2_dout (ID_rs2_dout),      // output
    .print_reg(print_reg)
  );

  wire ID_ctrl_mem_read;
  wire ID_ctrl_mem_to_reg;
  wire ID_ctrl_mem_write;
  wire ID_ctrl_alu_src;
  wire ID_ctrl_write_enable;
  wire ID_ctrl_pc_to_reg;
  wire ID_ctrl_alu_op;
  wire ID_ctrl_is_ecall;
  wire ID_ctrl_branch;
  wire ID_is_halted;

  // ---------- Control Unit ----------
  ControlUnit ctrl_unit (
    .Instr(IF_ID_inst[6:0]),  // input
    .MemRead(ID_ctrl_mem_read),      // output
    .MemtoReg(ID_ctrl_mem_to_reg),    // output
    .MemWrite(ID_ctrl_mem_write),     // output
    .ALUSrc(ID_ctrl_alu_src),       // output
    .RegWrite(ID_ctrl_write_enable),  // output 
    .PCtoReg(ID_ctrl_pc_to_reg),     // output
    .Branch(ID_ctrl_branch),      // output
    .is_ecall(ID_ctrl_is_ecall)       // output (ecall inst)
  );

  assign ID_is_halted = ID_ctrl_is_ecall && ((forward_ecall == 0 ? ID_rs1_dout : EX_MEM_alu_out) == 10);
     
  // ---------- Hazard Detection Unit ----------
  wire PC_Write, IF_ID_Write, ID_CtrlUnitMux_sel;
  HazardDetectionUnit haz_detect_unit(
    .opcode(IF_ID_inst[6:0]),
    .ID_rs1(ID_rs1),          // input
    .ID_rs2(ID_rs2),          // input
    .ID_EX_rd(ID_EX_rd),                  // input // (TODO) EX_MEM_rd vs ID_EX_rd ??
    .ID_EX_mem_read(ID_EX_mem_read),        // input
    .ID_ctrl_is_ecall(ID_ctrl_is_ecall),
    .PC_Write(PC_Write),
    .IF_ID_Write(IF_ID_Write),
    .ID_CtrlUnitMux_sel(ID_CtrlUnitMux_sel)
  );

  wire [31:0] ID_imm_out;
  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .Instr(IF_ID_inst),  // input
    .imm_gen_out(ID_imm_out)    // output
  );

  reg ID_EX_branch;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg ID_EX_is_halted;
  reg ID_EX_ctrl_is_ecall;

  // Update ID/EX pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
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
      ID_EX_rs1 <= 0;
      ID_EX_rs2 <= 0;
      ID_EX_is_halted <= 0;
      ID_EX_ctrl_is_ecall <= 0;
    end
    else begin
      ID_EX_alu_src <= ID_ctrl_alu_src;
      ID_EX_mem_write <= (ID_CtrlUnitMux_sel == 0 ? ID_ctrl_mem_write : 0);
      ID_EX_mem_read <= ID_ctrl_mem_read;
      ID_EX_mem_to_reg <= ID_ctrl_mem_to_reg;
      ID_EX_reg_write <= (ID_CtrlUnitMux_sel == 0 ? ID_ctrl_write_enable : 0);
      ID_EX_rs1_data <= ID_rs1_dout;
      ID_EX_rs2_data <= ID_rs2_dout;
      ID_EX_imm <= ID_imm_out;
      ID_EX_ALU_ctrl_unit_input <= IF_ID_inst;
      ID_EX_rd <= IF_ID_inst[11:7];
      ID_EX_branch <= ID_ctrl_branch;
      ID_EX_PC <= IF_ID_PC;
      ID_EX_rs1 <= IF_ID_inst[19:15];
      ID_EX_rs2 <= IF_ID_inst[24:20];
      ID_EX_is_halted <= (ID_CtrlUnitMux_sel == 0 ? ID_is_halted : 0);
      ID_EX_ctrl_is_ecall <= ID_ctrl_is_ecall;
    end
  end

  wire [31:0] EX_branch_addr;
  Adder branch_adder(
    .in0(ID_EX_PC),         // input
    .in1(ID_EX_imm),         // input
    .out(EX_branch_addr)          // output
  );

  wire [7:0] EX_alu_op;
  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit (
    .instr(ID_EX_ALU_ctrl_unit_input),  // input
    .alu_op(EX_alu_op)         // output
  );

  // ---------- Data Forwarding Unit ----------
  wire [1:0] forward_a;
  wire [1:0] forward_b;
  wire forward_ecall;
  DataForwardingUnit data_fw_unit (
    .ID_EX_rs1(ID_EX_rs1),
    .ID_EX_rs2(ID_EX_rs2),
    .EX_MEM_rd(EX_MEM_rd),
    .MEM_WB_rd(MEM_WB_rd),
    .EX_MEM_reg_write(EX_MEM_reg_write),
    .MEM_WB_reg_write(MEM_WB_reg_write),
    .ID_ctrl_is_ecall(ID_ctrl_is_ecall),
    .forward_a(forward_a),
    .forward_b(forward_b),
    .forward_ecall(forward_ecall)
  );

  wire [31:0] EX_alu_in1, EX_alu_in2;
  Mux4 DataforwardA (
    .sel(forward_a),
    .in0(ID_EX_rs1_data),
    .in1(WB_ID_rd_din),
    .in2(EX_MEM_alu_out),
    .in3(0),
    .out(EX_alu_in1)
  );

  wire [31:0] EX_alu_src2;
  Mux4 DataforwardB (
    .sel(forward_b),
    .in0(ID_EX_rs2_data),
    .in1(WB_ID_rd_din),
    .in2(EX_MEM_alu_out),
    .in3(0),
    .out(EX_alu_src2)
  );
  
  Mux2 ALU_in2_mux(
    .in0(EX_alu_src2),
    .in1(ID_EX_imm),
    .sel(ID_EX_alu_src),
    .out(EX_alu_in2)
  );

  wire [31:0] EX_alu_result;
  wire EX_alu_bcond;
  // ---------- ALU ----------
  ALU alu (
    .alu_op(EX_alu_op),      // input
    .alu_in_1(EX_alu_in1),    // input  
    .alu_in_2(EX_alu_in2),    // input
    .alu_result(EX_alu_result),  // output
    .alu_bcond(EX_alu_bcond)     // output
  );

  reg EX_MEM_bcond;
  reg [31:0] EX_MEM_branch_addr;
  reg EX_MEM_is_halted;
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
      EX_MEM_is_halted <= 0;
    end
    else begin
      EX_MEM_mem_write <= ID_EX_mem_write;
      EX_MEM_mem_read <= ID_EX_mem_read;
      EX_MEM_is_branch <= ID_EX_branch;
      EX_MEM_mem_to_reg <= ID_EX_mem_to_reg;
      EX_MEM_reg_write <= ID_EX_reg_write;
      EX_MEM_alu_out <= EX_alu_result;
      EX_MEM_dmem_data <= EX_alu_src2;
      EX_MEM_rd <= ID_EX_rd;
      EX_MEM_bcond <= EX_alu_bcond;
      EX_MEM_branch_addr <= EX_branch_addr;
      EX_MEM_is_halted <= ID_EX_is_halted;
    end
  end

  wire [31:0] MEM_dout;
  // ---------- Data Memory ----------
  DataMemory dmem(
    .reset (reset),      // input
    .clk (clk),        // input
    .addr (EX_MEM_alu_out),       // input
    .din (EX_MEM_dmem_data),        // input
    .mem_read (EX_MEM_mem_read),   // input
    .mem_write (EX_MEM_mem_write),  // input
    .dout (MEM_dout)        // output
  );

  reg [4:0] MEM_WB_rd;
  reg MEM_WB_is_halted;
  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_rd <= 0;
      MEM_WB_is_halted <= 0;
    end
    else begin
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out; // 0 sel
      MEM_WB_mem_to_reg_src_2 <= MEM_dout; // 1 sel
      MEM_WB_rd <= EX_MEM_rd;
      MEM_WB_is_halted <= EX_MEM_is_halted;
    end
  end

  assign is_halted = MEM_WB_is_halted;

  Mux2 WB_mux (
    .sel(MEM_WB_mem_to_reg),          // input
    .in0(MEM_WB_mem_to_reg_src_1),         // input
    .in1(MEM_WB_mem_to_reg_src_2),         // input
    .out(WB_ID_rd_din)                        // output
  );
  
endmodule
