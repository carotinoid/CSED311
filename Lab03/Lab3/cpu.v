// Submit this file with other files you created.
// Do not touch port declarations of the module 'CPU'.

// Guidelines
// 1. It is highly recommened to `define opcodes and something useful.
// 2. You can modify the module.
// (e.g., port declarations, remove modules, define new modules, ...)
// 3. You might need to describe combinational logics to drive them into the module (e.g., mux, and, or, ...)
// 4. `include files if required

module cpu(input reset,       // positive reset signal
           input clk,         // clock signal
           output is_halted,
           output [31:0]print_reg[0:31]
           ); // Whehther to finish simulation
  /***** Wire declarations *****/

  /***** Register declarations *****/
  reg [31:0] IR; // instruction register
  reg [31:0] MDR; // memory data register
  reg [31:0] A; // Read 1 data register
  reg [31:0] B; // Read 2 data register
  reg [31:0] ALUOut; // ALU output register
  // Do not modify and use registers declared above.

  // ---------- Control Unit ----------
  wire ctrl_PCWriteNotCond, ctrl_PCWrite, ctrl_IorD, ctrl_MemRead, ctrl_MemWrite, ctrl_MemtoReg, ctrl_IRWrite, ctrl_PCSource, ctrl_ALUOp, ctrl_ALUSrcA, ctrl_RegWrite, ctrl_is_ecall;
  wire [1:0] ctrl_ALUSrcB;
  wire [6:0] instr;
  
  ControlUnit ctrl_unit(
    .reset(reset),
    .clk(clk),
    .Instr(instr[6:0]),           // input
    .PCWriteNotCond(ctrl_PCWriteNotCond), // output
    .PCWrite(ctrl_PCWrite),       // output
    .IorD(ctrl_IorD),             // output
    .MemRead(ctrl_MemRead),       // output
    .MemWrite(ctrl_MemWrite),     // output
    .MemtoReg(ctrl_MemtoReg),     // output
    .IRWrite(ctrl_IRWrite),       // output
    .PCSource(ctrl_PCSource),     // output
    .ALUOp(ctrl_ALUOp),           // output
    .ALUSrcB(ctrl_ALUSrcB),       // output
    .ALUSrcA(ctrl_ALUSrcA),       // output
    .RegWrite(ctrl_RegWrite),     // output
    .is_ecall(ctrl_is_ecall)      // output (ecall inst)
  );
  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  wire PCWrite = ctrl_PCWrite || (ctrl_PCWriteNotCond && !ALUBcond);
  wire [31:0] current_pc;
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .PCWrite(PCWrite),
    .next_pc(next_pc),     // input
    .current_pc(current_pc)   // output
  );
  
  wire [31:0] addr_mux_out;
  Mux2 addr_mux(
    .in0(current_pc),
    .in1(ALUOut),
    .sel(ctrl_IorD),
    .out(addr_mux_out)
  );

  // ---------- Memory ----------
  wire [31:0] mem_out;
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(addr_mux_out),         // input
    .din(B),          // input
    .mem_read(ctrl_MemRead),     // input
    .mem_write(ctrl_MemWrite),    // input
    .dout(mem_out)          // output
  );

  always @(posedge clk) begin
    if(ctrl_IRWrite) begin
      IR <= mem_out;
      MDR <= MDR;
    end
    else begin
      MDR <= mem_out;
      IR <= IR;
    end
  end

  // ---------- Register File ----------

  wire [31:0] reg_mux_out;
  Mux2 reg_mux(
    .in0(ALUOut),
    .in1(MDR),
    .sel(ctrl_MemtoReg),
    .out(reg_mux_out)
  );

  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(IR[19:15]),          // input
    .rs2(IR[24:20]),          // input
    .rd(IR[11:7]),           // input
    .rd_din(reg_mux_out),       // input
    .write_enable(ctrl_RegWrite),    // input
    .rs1_dout(A),     // output
    .rs2_dout(B),      // output
    .print_reg(print_reg)     // output (TO PRINT REGISTER VALUES IN TESTBENCH)
  );



  // ---------- Immediate Generator ----------
  wire [31:0] imm_gen_out;
  ImmediateGenerator imm_gen(
    .Instr(IR),  // input
    .imm_gen_out(imm_gen_out)    // output
  );

  // ---------- ALU Control Unit ----------

  wire [7:0] alu_op;
  ALUControlUnit alu_ctrl_unit(
    .Instr30(IR[30]),       // input
    .funct3(IR[14:12]),      // input
    .opcode(IR[6:0]),       // input
    .NoInst(ctrl_ALUOp),   // input
    .alu_op(alu_op)         // output
  );

  // ---------- ALU ----------
  wire [31:0] alu_in_1;
  Mux2 ALUMux1(
    .in0(current_pc),
    .in1(A),
    .sel(ctrl_ALUSrcA),
    .out(alu_in_1)
  );

  wire [31:0] alu_in_2;
  Mux4 ALUMux2(
    .in0(B),
    .in1(4),
    .in2(imm_gen_out),
    .in3(0),
    .sel(ctrl_ALUSrcB),
    .out(alu_in_2)
  );

  wire [31:0] alu_result;
  wire ALUBcond;
  ALU alu(
    .alu_op(alu_op),      // input
    .alu_in_1(alu_in_1),    // input  
    .alu_in_2(alu_in_2),    // input
    .alu_result(alu_result),  // output
    .alu_bcond(ALUBcond)     // output
  );

  always @(posedge clk) begin
    ALUOut <= alu_result;
  end

  wire [31:0] next_pc;
  Mux2 next_pc_mux(
    .in0(alu_result),
    .in1(ALUOut),
    .sel(ctrl_PCSource),
    .out(next_pc)
  );
endmodule
