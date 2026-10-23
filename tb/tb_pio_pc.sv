`timescale 1ns / 1ps

module tb_pio_pc;

  logic clk = 1'b0;
  always #5 clk = ~clk;
  logic rst_n;

  logic       clk_en, stall, jmp_taken;
  logic [4:0] jmp_target, wrap_top, wrap_bottom, instr_delay, pc;

  pio_pc dut (.*);

  always_comb begin
    case (pc)
      5'd0:    instr_delay = 5'd7;
      5'd1:    instr_delay = 5'd7;
      5'd2:    instr_delay = 5'd0;
      5'd3:    instr_delay = 5'd6;
      default: instr_delay = 5'd0;
    endcase
  end

  assign clk_en      = 1'b1;
  assign jmp_target  = 5'd2;
  assign wrap_top    = 5'd3;
  assign wrap_bottom = 5'd0;

  logic        fifo_empty;
  logic        push;
  logic [31:0] x;
  logic        issue, exec;

  assign stall     = (pc == 5'd0) && fifo_empty;
  assign exec      = issue && !stall;
  assign jmp_taken = (pc == 5'd3) && (x != 32'd0);

  always @(posedge clk) begin
    if (exec && pc == 5'd1) x <= 32'd7;
    if (exec && pc == 5'd3) x <= x - 32'd1;
    if (exec && pc == 5'd0) fifo_empty <= 1'b1;
    else if (push)          fifo_empty <= 1'b0;
  end

  int         cyc = 0;
  logic       prev_stalled = 1'b0;
  int         last_edge = -1;
  logic [4:0] last_pc;
  int         bits = 0, errors = 0;

  always @(posedge clk) cyc <= cyc + 1;

  always @(posedge clk) begin
    if (rst_n) begin
      if (issue && !prev_stalled && pc <= 5'd2) begin
        if (last_edge >= 0 && last_pc != 5'd0) begin
          bits++;
          if (cyc - last_edge != 8) begin
            errors++;
            $display("ERROR: cycle %0d pc=%0d bit lasted %0d cycles, expected 8",
                     cyc, pc, cyc - last_edge);
          end
        end
        last_edge = cyc;
        last_pc   = pc;
      end
      prev_stalled <= issue && stall;
      $display("%4d  pc=%0d  delay=%0d  stall=%b  exec=%b  x=%0d",
               cyc, pc, dut.delay_cnt, stall, exec, x);
    end
  end

  initial begin
    rst_n = 1'b0; push = 1'b0; fifo_empty = 1'b1; x = 32'd0;
    repeat (3)   @(negedge clk);
    rst_n = 1'b1;
    repeat (10)  @(negedge clk);
    push = 1'b1;
    @(negedge clk);
    push = 1'b0;
    repeat (120) @(negedge clk);

    if (errors == 0 && bits == 9) $display("PASS: 9 bits, 8 cycles each");
    else                          $display("FAIL: bits=%0d errors=%0d", bits, errors);
    $finish;
  end

endmodule