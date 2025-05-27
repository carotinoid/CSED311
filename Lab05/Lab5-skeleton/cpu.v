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
  wire [31:0] IF_pred_pc;
  wire [31:0] IF_next_pc;

  // ---------- Bubble Generator Unit ----------
  wire IF_is_bubble, ID_is_bubble;
  BubbleGen bubblegen(
    .IF_wrong(IF_pred_wrong),
    .ID_wrong(ID_pred_wrong),
    .EX_wrong(EX_pred_wrong),

    .IF_is_bubble(IF_is_bubble),
    .ID_is_bubble(ID_is_bubble)
  );

  // ---------- Branch Prediction Unit ----------
  BranchPredictUnit branch_pred_unit(
    .current_pc(IF_current_pc),
    .predict_pc(IF_pred_pc),
    .clk(clk),
    .reset(reset),

    .update(EX_predictor_update), // TODO: update
    .faux_pas_pc(ID_EX_PC),
    .actual_behavior(EX_actual_behavior)
  );

  wire [1:0] IF_PCsrc;

  assign IF_PCsrc = EX_pred_wrong? 3 : ID_pred_wrong? 2: IF_pred_wrong? 1 : 0;
  Mux4 PC_mux(
    .sel(IF_PCsrc),          // input
    .in0(IF_pred_pc),         // input
    .in1(IF_next_addr),
    .in2(ID_next_addr),
    .in3(EX_next_addr),         // input

    .out(IF_next_pc)          // output
  );

  wire [31:0] IF_current_pc;
  // PC must be updated on the rising edge (positive edge) of the clock.
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .next_pc(IF_next_pc),     // input
    .PC_Write(PC_Write && !cache_wait),
    .current_pc(IF_current_pc)   // output
  );
  
  wire [31:0] IF_instr;
  // ---------- Instruction Memory ----------
  InstMemory imem(
    .reset(reset),   // input
    .clk(clk),     // input
    .addr(IF_current_pc),    // input
    .dout(IF_instr)     // output
  );
  
  wire IF_is_ctrlflow;
  ControlflowDetectUnit ctrlflow_detect_unit(
    .Instr(IF_instr[6:0]),
    .is_ctrlflow(IF_is_ctrlflow)
  );
  
  wire [31:0] IF_next_addr = IF_current_pc + 4;
  wire IF_pred_wrong = !IF_is_ctrlflow && (IF_pred_pc != IF_next_addr);

  reg [31:0] IF_ID_PC;
  reg IF_ID_is_bubble;
  // Update IF/ID pipeline registers here
  always @(posedge clk) begin
    if (IF_is_bubble || reset) begin
      IF_ID_is_bubble <= 1;
      IF_ID_inst <= 0;
      IF_ID_PC <= (reset?0:IF_current_pc);
    end
    else if(cache_wait) begin
      IF_ID_is_bubble <= IF_ID_is_bubble;
      IF_ID_inst <= IF_ID_inst;
      IF_ID_PC <= IF_ID_PC;
    end
    else begin
      if(IF_ID_Write) begin
        IF_ID_is_bubble <= 0;
        IF_ID_inst <= IF_instr;
        IF_ID_PC <= IF_current_pc;
      end
      else begin
        IF_ID_is_bubble <= 0;
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

  wire [31:0] rd_din = (MEM_WB_pc_to_reg ? MEM_WB_PC + 4 : WB_ID_rd_din);
  // ---------- Register File ----------
  RegisterFile reg_file (
    .reset (reset),        // input
    .clk (clk),          // input
    .rs1 (ID_rs1),          // input
    .rs2 (ID_rs2),          // input
    .rd (MEM_WB_rd),           // input
    .rd_din (rd_din),       // input
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
  wire ID_ctrl_JAL;
  wire ID_ctrl_JALR;
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
    .JAL(ID_ctrl_JAL),
    .JALR(ID_ctrl_JALR),
    .is_ecall(ID_ctrl_is_ecall)       // output (ecall inst)
  );

  assign ID_is_halted = ID_ctrl_is_ecall && ((forward_ecall == 0 ? ID_rs1_dout : EX_MEM_alu_out) == 10);
     
  // ---------- Hazard Detection Unit ----------
  wire PC_Write, IF_ID_Write, ID_CtrlUnitMux_sel;
  HazardDetectionUnit haz_detect_unit(
    .opcode(IF_ID_inst[6:0]),
    .ID_rs1(ID_rs1),          // input
    .ID_rs2(ID_rs2),          // input
    .ID_EX_rd(ID_EX_rd),                  // input
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

  wire [31:0] ID_next_addr = 0;
  // when we move the pc produce to ID stage, then 0 must be ousted, and the branch condition be there. 
  wire ID_pred_wrong = !IF_ID_is_bubble && (0 && (IF_current_pc != ID_next_addr));

  reg [31:0] ID_EX_PC;
  reg ID_EX_branch;
  reg ID_EX_JAL;
  reg ID_EX_JALR;
  reg [4:0] ID_EX_rs1;
  reg [4:0] ID_EX_rs2;
  reg ID_EX_is_stall;
  reg ID_EX_is_halted;
  reg ID_EX_ctrl_is_ecall;
  reg ID_EX_pc_to_reg;

  // Update ID/EX pipeline registers here
  reg ID_EX_is_bubble;
  always @(posedge clk) begin
    if (ID_is_bubble || reset) begin
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
      ID_EX_PC <= (reset?0:IF_ID_PC);
      ID_EX_rs1 <= 0;
      ID_EX_rs2 <= 0;
      ID_EX_JAL <= 0;
      ID_EX_JALR <= 0;
      ID_EX_is_halted <= 0;
      ID_EX_ctrl_is_ecall <= 0;

      ID_EX_is_stall <= 0;
      ID_EX_is_bubble <= 1;
      ID_EX_pc_to_reg <= 0;
    end
    else if(cache_wait) begin
      ID_EX_alu_src <= ID_EX_alu_src; 
      ID_EX_mem_write <= ID_EX_mem_write; 
      ID_EX_mem_read <= ID_EX_mem_read; 
      ID_EX_mem_to_reg <= ID_EX_mem_to_reg; 
      ID_EX_reg_write <= ID_EX_reg_write; 
      ID_EX_rs1_data <= ID_EX_rs1_data; 
      ID_EX_rs2_data <= ID_EX_rs2_data; 
      ID_EX_imm <= ID_EX_imm; 
      ID_EX_ALU_ctrl_unit_input <= ID_EX_ALU_ctrl_unit_input; 
      ID_EX_rd <= ID_EX_rd; 
      ID_EX_branch <= ID_EX_branch; 
      ID_EX_PC <= ID_EX_PC; 
      ID_EX_rs1 <= ID_EX_rs1; 
      ID_EX_rs2 <= ID_EX_rs2; 
      ID_EX_JAL <= ID_EX_JAL; 
      ID_EX_JALR <= ID_EX_JALR; 
      ID_EX_is_halted <= ID_EX_is_halted; 
      ID_EX_ctrl_is_ecall <= ID_EX_ctrl_is_ecall; 

      ID_EX_is_stall <= ID_EX_is_stall; 
      ID_EX_is_bubble <= ID_EX_is_bubble; 
      ID_EX_pc_to_reg <= ID_EX_pc_to_reg; 
    end
    else begin
      ID_EX_alu_src <= ID_ctrl_alu_src;
      ID_EX_is_stall <= ID_CtrlUnitMux_sel;
      ID_EX_is_bubble <= IF_ID_is_bubble;
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
      ID_EX_JAL <= ID_ctrl_JAL;
      ID_EX_JALR <= ID_ctrl_JALR;
      ID_EX_is_halted <= (ID_CtrlUnitMux_sel == 0 ? ID_is_halted : 0);
      ID_EX_ctrl_is_ecall <= ID_ctrl_is_ecall;
      ID_EX_pc_to_reg <= ID_ctrl_pc_to_reg;
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

  wire [31:0] EX_next_addr = (ID_EX_JAL || (ID_EX_branch && EX_alu_bcond)) ? EX_branch_addr 
                                                         : (ID_EX_JALR) ? EX_alu_result : ID_EX_PC + 4;
  wire EX_pred_wrong = !IF_ID_is_bubble && !ID_EX_is_bubble && !ID_EX_is_stall && (IF_ID_PC != EX_next_addr);
  wire EX_actual_behavior = (ID_EX_JAL || (ID_EX_branch && EX_alu_bcond) || ID_EX_JALR);
  wire EX_predictor_update = (ID_EX_JAL || ID_EX_branch || ID_EX_JALR);

  reg EX_MEM_bcond;
  reg [31:0] EX_MEM_branch_addr;
  reg EX_MEM_is_halted;
  // Update EX/MEM pipeline registers here
  reg EX_MEM_is_bubble;
  reg EX_MEM_pc_to_reg;
  reg [31:0] EX_MEM_PC;

  always @(posedge clk) begin
    if (reset) begin
      EX_MEM_is_bubble <= 1;
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

      EX_MEM_pc_to_reg <= 0;
      EX_MEM_PC <= 0;
    end
    else if (cache_wait) begin
      EX_MEM_is_bubble <= EX_MEM_is_bubble;
      EX_MEM_mem_write <= EX_MEM_mem_write;
      EX_MEM_mem_read <= EX_MEM_mem_read;
      EX_MEM_is_branch <= EX_MEM_is_branch;
      EX_MEM_mem_to_reg <= EX_MEM_mem_to_reg;
      EX_MEM_reg_write <= EX_MEM_reg_write;
      EX_MEM_alu_out <= EX_MEM_alu_out;
      EX_MEM_dmem_data <= EX_MEM_dmem_data;
      EX_MEM_rd <= EX_MEM_rd;
      EX_MEM_bcond <= EX_MEM_bcond;
      EX_MEM_branch_addr <= EX_MEM_branch_addr;
      EX_MEM_is_halted <= EX_MEM_is_halted;

      EX_MEM_pc_to_reg <= EX_MEM_pc_to_reg;
      EX_MEM_PC <= EX_MEM_PC;
    end
    else begin
      EX_MEM_is_bubble <= ID_EX_is_bubble;
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

      EX_MEM_pc_to_reg <= ID_EX_pc_to_reg;
      EX_MEM_PC <= ID_EX_PC;
    end
  end

  // // ---------- Data Memory ----------
  // DataMemory dmem(
  //   .reset (reset),      // input
  //   .clk (clk),        // input
  //   .addr (EX_MEM_alu_out),       // input
  //   .din (EX_MEM_dmem_data),        // input
  //   .mem_read (EX_MEM_mem_read),   // input
  //   .mem_write (EX_MEM_mem_write),  // input
  //   .dout (MEM_dout)        // output
  // );


  wire cache_is_ready;
  wire [31:0] MEM_dout;
  wire cache_is_output_valid;
  wire cache_is_hit;

  Cache cache(
    .reset(reset),
    .clk(clk),

    .is_input_valid(EX_MEM_mem_read || EX_MEM_mem_write), // TODO <-- is this right?
    .addr(EX_MEM_alu_out),
    .mem_read(EX_MEM_mem_read),
    .mem_write(EX_MEM_mem_write),
    .din(EX_MEM_dmem_data),

    .is_ready(cache_is_ready),
    .dout(MEM_dout),
    .is_output_valid(cache_is_output_valid),
    .is_hit(cache_is_hit)
  );

  wire is_ready = 1;
  // useless due to different cache design (rw / read, write)

  wire cache_wait = ((EX_MEM_mem_read || EX_MEM_mem_write) && (!is_ready || !cache_is_output_valid));
  
  integer access_cnt;
  integer hit_cnt;
  
  always @(posedge clk) begin
    if(reset) begin
      access_cnt <= 0;
      hit_cnt <= 0;
    end
    else begin
      if((EX_MEM_mem_read || EX_MEM_mem_write) && cache_is_output_valid) begin
        access_cnt <= access_cnt + 1;
      end

      if((EX_MEM_mem_read || EX_MEM_mem_write) && cache_is_output_valid && cache_is_hit) begin
        hit_cnt <= hit_cnt + 1;
      end
    end
  end

  

  reg [4:0] MEM_WB_rd;
  reg MEM_WB_is_halted;
  reg MEM_WB_is_bubble;

  reg MEM_WB_pc_to_reg;
  reg [31:0] MEM_WB_PC;

  // Update MEM/WB pipeline registers here
  always @(posedge clk) begin
    if (reset) begin
      MEM_WB_is_bubble <= 1;
      MEM_WB_mem_to_reg <= 0;
      MEM_WB_reg_write <= 0;
      MEM_WB_mem_to_reg_src_1 <= 0;
      MEM_WB_mem_to_reg_src_2 <= 0;
      MEM_WB_rd <= 0;
      MEM_WB_is_halted <= 0;

      MEM_WB_pc_to_reg <= 0;
      MEM_WB_PC <= 0;
    end
    else if (cache_wait) begin
      MEM_WB_is_bubble <= MEM_WB_is_bubble;
      MEM_WB_mem_to_reg <= MEM_WB_mem_to_reg;
      MEM_WB_reg_write <= MEM_WB_reg_write;
      MEM_WB_mem_to_reg_src_1 <= MEM_WB_mem_to_reg_src_1;
      MEM_WB_mem_to_reg_src_2 <= MEM_WB_mem_to_reg_src_2;
      MEM_WB_rd <= MEM_WB_rd;
      MEM_WB_is_halted <= MEM_WB_is_halted;
      MEM_WB_pc_to_reg <= MEM_WB_pc_to_reg;
      MEM_WB_PC <= MEM_WB_PC;
    end
    else begin
      MEM_WB_is_bubble <= EX_MEM_is_bubble;
      MEM_WB_mem_to_reg <= EX_MEM_mem_to_reg;
      MEM_WB_reg_write <= EX_MEM_reg_write;
      MEM_WB_mem_to_reg_src_1 <= EX_MEM_alu_out; // 0 sel
      MEM_WB_mem_to_reg_src_2 <= MEM_dout; // 1 sel
      MEM_WB_rd <= EX_MEM_rd;
      MEM_WB_is_halted <= EX_MEM_is_halted;

      MEM_WB_pc_to_reg <= EX_MEM_pc_to_reg;
      MEM_WB_PC <= EX_MEM_PC;
    end

    if(!reset && EX_MEM_is_halted) begin
      $display("Cache Access Count: %d", access_cnt);
      $display("Cache Hit Count: %d", hit_cnt);
      $display("Cache Hit Rate: %f", hit_cnt * 1.0 / access_cnt);
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
