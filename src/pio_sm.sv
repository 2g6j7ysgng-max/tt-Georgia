`timescale 1ns / 1ps

module pio_sm (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        clk_en,

  input  logic        imem_we,
  input  logic [4:0]  imem_waddr,
  input  logic [15:0] imem_wdata,

  input  logic [4:0]  wrap_top,
  input  logic [4:0]  wrap_bottom,
  input  logic [2:0]  sideset_count,
  input  logic        side_en,

  input  logic        tx_empty,
  output logic        tx_pop,
  input  logic        jmp_pin,

  output logic [4:0]  side_out,
  output logic [4:0]  pc,
  output logic [31:0] x,
  output logic [31:0] y
);

  logic [15:0] imem [32];
  logic [15:0] instr;

  always_ff @(posedge clk)
    if (imem_we) imem[imem_waddr] <= imem_wdata;

  assign instr = imem[pc];

  logic       is_jmp, is_wait, is_in, is_out, is_push, is_pull, is_mov, is_irq, is_set;
  logic [4:0] delay, side_value, arg_lo;
  logic [2:0] arg_hi;
  logic       side_valid;

  pio_decode u_dec (.*);

  logic issue, exec, stall, jmp_taken;

  assign stall  = is_pull && instr[5] && tx_empty;
  assign exec   = issue && !stall;
  assign tx_pop = exec && is_pull && !tx_empty;

  pio_pc u_pc (
    .clk, .rst_n, .clk_en, .stall, .jmp_taken,
    .jmp_target  (arg_lo),
    .wrap_top, .wrap_bottom,
    .instr_delay (delay),
    .pc, .issue
  );

  pio_xy u_xy (
    .clk, .rst_n, .exec, .is_set, .is_jmp, .arg_hi, .arg_lo, .jmp_pin,
    .osre (1'b1),
    .x, .y, .jmp_taken
  );

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)                   side_out <= 5'd0;
    else if (issue && side_valid) side_out <= side_value;

endmodule