`timescale 1ns / 1ps

module tb_pio_sm;

  logic clk = 1'b0;
  always #5 clk = ~clk;

  logic        rst_n;
  logic        clk_en;
  logic        imem_we;
  logic [4:0]  imem_waddr;
  logic [15:0] imem_wdata;
  logic [4:0]  wrap_top, wrap_bottom;
  logic [2:0]  sideset_count;
  logic        side_en;
  logic        tx_empty, tx_pop, jmp_pin;
  logic [4:0]  side_out, pc;
  logic [31:0] x, y;

  pio_sm dut (.*);

  logic [15:0] prog [4];
  logic push = 1'b0;

  always @(posedge clk)
    if (tx_pop)    tx_empty <= 1'b1;
    else if (push) tx_empty <= 1'b0;

  time t_fall = 0, t_rise = 0;
  int  pops = 0;

  always @(negedge side_out[0]) if (rst_n === 1'b1) t_fall = $time;
  always @(posedge side_out[0]) if (rst_n === 1'b1 && t_fall != 0) t_rise = $time;
  always @(posedge clk) if (tx_pop) pops++;

  initial begin
    prog[0] = 16'h9FA0;
    prog[1] = 16'hF727;
    prog[2] = 16'h6001;
    prog[3] = 16'h0642;

    rst_n = 1'b0; clk_en = 1'b1; imem_we = 1'b0; imem_waddr = 5'd0; imem_wdata = 16'd0;
    wrap_top = 5'd3; wrap_bottom = 5'd0; sideset_count = 3'd2; side_en = 1'b1;
    tx_empty = 1'b1; jmp_pin = 1'b0;

    for (int i = 0; i < 4; i++) begin
      @(negedge clk);
      imem_we = 1'b1; imem_waddr = i[4:0]; imem_wdata = prog[i];
    end
    @(negedge clk);
    imem_we = 1'b0;
    rst_n = 1'b1;

    repeat (10) @(negedge clk);
    push = 1'b1;
    @(negedge clk);
    push = 1'b0;

    repeat (150) @(negedge clk);

    $display("TX low from %0t to %0t = %0d cycles, pops=%0d, x=%h",
             t_fall, t_rise, (t_rise - t_fall) / 10, pops, x);

    if (t_fall != 0 && (t_rise - t_fall) == 720 && pops == 1 && x == 32'hFFFF_FFFF)
      $display("PASS: pio_sm runs uart_tx from hex");
    else
      $display("FAIL");
    $finish;
  end

endmodule