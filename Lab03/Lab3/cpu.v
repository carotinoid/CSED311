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

  // ---------- Update program counter ----------
  // PC must be updated on the rising edge (positive edge) of the clock.
  wire PCWrite = ctrl_PCWrite || (PCWireNotCond && !ALUBcond);
  wire current_pc;
  PC pc(
    .reset(reset),       // input (Use reset to initialize PC. Initial value must be 0)
    .clk(clk),         // input
    .PCWrite(PCWrite),
    .next_pc(next_pc),     // input
    .current_pc(currnet_pc)   // output
  );
  
  wire [31:0] mem_address;
  mux2 AddressMUX(
    .in0(current_pc),
    .in1(ALUOut),
    .sel(ctrl_IorD),
    .out(mem_address)
  );

  // ---------- Memory ----------
  wire [31:0] MemOut;
  Memory memory(
    .reset(reset),        // input
    .clk(clk),          // input
    .addr(mem_address),         // input
    .din(B),          // input
    .mem_read(ctrl_MemRead),     // input
    .mem_write(ctrl_memWrite),    // input
    .dout(MemOut)          // output
  );

  wire [31:0] Instr;
  InstructionRegister IR(
    .in(MemOut),
    .IRWrite(ctrl_IRWrite),
    .out(Instr)
  );

  wire [31:0] Mem_Data;
  DataRegister DR(
    .in(MemOut),
    .out(MEM_Data)
  );

  // ---------- Register File ----------
  RegisterFile reg_file(
    .reset(reset),        // input
    .clk(clk),          // input
    .rs1(),          // input
    .rs2(),          // input
    .rd(),           // input
    .rd_din(),       // input
    .write_enable(),    // input
    .rs1_dout(),     // output
    .rs2_dout(),      // output
    .print_reg()     // output (TO PRINT REGISTER VALUES IN TESTBENCH)
  );


  wire ctrl_PCWriteNotCond, ctrl_PCWrite, ctrl_IorD, ctrl_MemRead, ctrl_MemWrite, ctrl_MemtoReg, ctrl_IRWrite, ctrl_PCSource, ctrl_ALUOp, ctrl_ALUSrcA, ctrl_RegWrite, ctrl_is_ecall;
  wire [1:0] ctrl_ALUSrcB;
  wire [6:0] instr;
  // ---------- Control Unit ----------
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

  // ---------- Immediate Generator ----------
  ImmediateGenerator imm_gen(
    .part_of_inst(),  // input
    .imm_gen_out()    // output
  );

  // ---------- ALU Control Unit ----------
  ALUControlUnit alu_ctrl_unit(
    .part_of_inst(),  // input
    .alu_op()         // output
  );

  // ---------- ALU ----------
  ALU alu(
    .alu_op(),      // input
    .alu_in_1(),    // input  
    .alu_in_2(),    // input
    .alu_result(),  // output
    .alu_bcond()     // output
  );

endmodule
