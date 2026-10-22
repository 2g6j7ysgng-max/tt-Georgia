`timescale 1ns / 1ps

module tb_pio_xy;

  logic        clk = 1'b0;
  always #5 clk = ~clk;
  logic        rst_n;

  logic        exec, is_set, is_jmp, jmp_pin, osre;
  logic [2:0]  arg_hi;
  logic [4:0]  arg_lo;
  logic [31:0] x, y;
  logic        jmp_taken;

  pio_xy dut (.*);

  int errors = 0;

  task automatic step(input logic s, input logic j, input logic [2:0] hi, input logic [4:0] lo);
    @(negedge clk);
    is_set = s; is_jmp = j; arg_hi = hi; arg_lo = lo; exec = 1'b1;
  endtask

  task automatic expect_jt(input logic exp, input string name);
    if (jmp_taken !== exp) begin
      errors++;
      $display("ERROR %s: jmp_taken=%b expected %b (x=%0d y=%0d)", name, jmp_taken, exp, x, y);
    end
  endtask

  task automatic expect_xy(input logic [31:0 ] ex, input logic [31:0] ey, input string name);
    if (x !== ex || y !== ey) begin
      errors++;
      $display("ERROR %s: x=%0d y=%0d expected x=%0d y=%0d", name, x, y, ex, ey);
    end
  endtask

  initial begin
    rst_n = 1'b0; exec = 1'b0; is_set = 1'b0; is_jmp = 1'b0;
    arg_hi = 3'd0; arg_lo = 5'd0; jmp_pin = 1'b0; osre = 1'b1;
    repeat (2) @(negedge clk);
    rst_n = 1'b1;

    step(1, 0, 3'b001, 5'd7);  @(posedge clk); #1; expect_xy(7, 0, "set x 7");
    step(1, 0, 3'b010, 5'd31); @(posedge clk); #1; expect_xy(7, 31, "set y 31");

    step(0, 1, 3'b000, 5'd2);  #1; expect_jt(1, "jmp always");
    step(0, 1, 3'b001, 5'd2);  #1; expect_jt(0, "jmp !x, x=7");
    step(0, 1, 3'b011, 5'd2);  #1; expect_jt(0, "jmp !y, y=31");
    step(0, 1, 3'b101, 5'd2);  #1; expect_jt(1, "jmp x!=y");

    jmp_pin = 1'b0; step(0, 1, 3'b110, 5'd2); #1; expect_jt(0, "jmp pin=0");
    jmp_pin = 1'b1; step(0, 1, 3'b110, 5'd2); #1; expect_jt(1, "jmp pin=1");
    osre = 1'b1;    step(0, 1, 3'b111, 5'd2); #1; expect_jt(0, "jmp !osre, empty");
    osre = 1'b0;    step(0, 1, 3'b111, 5'd2); #1; expect_jt(1, "jmp !osre, not empty");

    step(1, 0, 3'b001, 5'd2);  @(posedge clk); #1; expect_xy(2, 31, "set x 2");
    step(0, 1, 3'b010, 5'd2);  #1; expect_jt(1, "x-- x=2");
    @(posedge clk); #1; expect_xy(1, 31, "x-- -> 1");
    step(0, 1, 3'b010, 5'd2);  #1; expect_jt(1, "x-- x=1");
    @(posedge clk); #1; expect_xy(0, 31, "x-- -> 0");
    step(0, 1, 3'b010, 5'd2);  #1; expect_jt(0, "x-- x=0 not taken");
    @(posedge clk); #1; expect_xy(32'hFFFF_FFFF, 31, "x-- -> -1 always");

    step(0, 1, 3'b100, 5'd2);  #1; expect_jt(1, "y-- y=31");
    @(posedge clk); #1; expect_xy(32'hFFFF_FFFF, 30, "y-- -> 30");

    step(1, 0, 3'b001, 5'd30); @(posedge clk); #1;
    step(0, 1, 3'b101, 5'd2);  #1; expect_jt(0, "jmp x!=y, x=y=30");

    @(negedge clk); exec = 1'b0; is_set = 1'b1; arg_hi = 3'b001; arg_lo = 5'd5;
    @(posedge clk); #1; expect_xy(30, 30, "no exec -> no write");

    if (errors == 0) $display("PASS: pio_xy");
    else             $display("FAIL: %0d errors", errors);
    $finish;
  end

endmodule