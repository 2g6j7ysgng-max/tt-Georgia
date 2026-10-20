`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.10.2026 20:54:16
// Design Name: 
// Module Name: tb_pio_decode
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module tb_pio_decode;

  logic [15:0] instr;
  logic [2:0]  sideset_count;
  logic        side_en;

  logic        is_jmp, is_wait, is_in, is_out;
  logic        is_push, is_pull, is_mov, is_irq, is_set;
  logic [4:0]  delay;
  logic        side_valid;
  logic [4:0]  side_value;
  logic [2:0]  arg_hi;
  logic [4:0]  arg_lo;

  pio_decode dut (.*);

  int errors = 0;

  initial begin
    instr = 16'h9FA0; sideset_count = 3'd2; side_en = 1'b1; #1;
    if (!is_pull || is_push || delay != 5'd7 || !side_valid || side_value != 5'd1) begin
      errors++;
      $display("ERROR 9FA0: pull=%b push=%b delay=%0d sv=%b sval=%0d",
               is_pull, is_push, delay, side_valid, side_value);
    end

    instr = 16'hF727; sideset_count = 3'd2; side_en = 1'b1; #1;
    if (!is_set || delay != 5'd7 || !side_valid || side_value != 5'd0 ||
        arg_hi != 3'd1 || arg_lo != 5'd7) begin
      errors++;
      $display("ERROR F727: set=%b delay=%0d sv=%b sval=%0d hi=%0d lo=%0d",
               is_set, delay, side_valid, side_value, arg_hi, arg_lo);
    end

    instr = 16'h6001; sideset_count = 3'd2; side_en = 1'b1; #1;
    if (!is_out || delay != 5'd0 || side_valid ||
        arg_hi != 3'd0 || arg_lo != 5'd1) begin
      errors++;
      $display("ERROR 6001: out=%b delay=%0d sv=%b hi=%0d lo=%0d",
               is_out, delay, side_valid, arg_hi, arg_lo);
    end

    instr = 16'h0642; sideset_count = 3'd2; side_en = 1'b1; #1;
    if (!is_jmp || delay != 5'd6 || side_valid ||
        arg_hi != 3'd2 || arg_lo != 5'd2) begin
      errors++;
      $display("ERROR 0642: jmp=%b delay=%0d sv=%b hi=%0d lo=%0d",
               is_jmp, delay, side_valid, arg_hi, arg_lo);
    end

    instr = 16'hE101; sideset_count = 3'd0; side_en = 1'b0; #1;
    if (!is_set || delay != 5'd1 || side_valid ||
        arg_hi != 3'd0 || arg_lo != 5'd1) begin
      errors++;
      $display("ERROR E101: set=%b delay=%0d sv=%b hi=%0d lo=%0d",
               is_set, delay, side_valid, arg_hi, arg_lo);
    end

    instr = 16'h7001; sideset_count = 3'd1; side_en = 1'b0; #1;
    if (!is_out || delay != 5'd0 || !side_valid || side_value != 5'd1 ||
        arg_lo != 5'd1) begin
      errors++;
      $display("ERROR 7001: out=%b delay=%0d sv=%b sval=%0d lo=%0d",
               is_out, delay, side_valid, side_value, arg_lo);
    end

    if (errors == 0) $display("PASS: decoder, 6 vectors");
    else             $display("FAIL: %0d errors", errors);
    $finish;
  end

endmodule