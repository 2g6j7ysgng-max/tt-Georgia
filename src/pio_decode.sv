`timescale 1ns / 1ps

module pio_decode (
  input  logic [15:0] instr,
  input  logic [2:0]  sideset_count,
  input  logic        side_en,

  output logic        is_jmp, is_wait, is_in, is_out,
  output logic        is_push, is_pull, is_mov, is_irq, is_set,
  output logic [4:0]  delay,
  output logic        side_valid,
  output logic [4:0]  side_value,
  output logic [2:0]  arg_hi,
  output logic [4:0]  arg_lo
);

  assign is_jmp  = (instr[15:13] == 3'b000);
  assign is_wait = (instr[15:13] == 3'b001);
  assign is_in   = (instr[15:13] == 3'b010);
  assign is_out  = (instr[15:13] == 3'b011);
  assign is_push = (instr[15:13] == 3'b100) && !instr[7];
  assign is_pull = (instr[15:13] == 3'b100) &&  instr[7];
  assign is_mov  = (instr[15:13] == 3'b101);
  assign is_irq  = (instr[15:13] == 3'b110);
  assign is_set  = (instr[15:13] == 3'b111);

  assign arg_hi = instr[7:5];
  assign arg_lo = instr[4:0];

  assign delay = instr[12:8] & (5'b11111 >> sideset_count);

  logic [4:0] side_bits;
  assign side_bits = instr[12:8] >> (5 - sideset_count);

  assign side_valid = side_en ? instr[12] : (sideset_count != 3'd0);

  assign side_value = side_en ? (side_bits & (5'b11111 >> (6 - sideset_count)))
                              : side_bits;

endmodule