`include "pio.svh"

module tb_pio_isr;

    logic clk;

    initial
    begin
        clk = '0;

        forever
            # 5 clk = ~ clk;
    end

    logic rst;

    //------------------------------------------------------------------------

    logic        exec;
    logic        is_in;
    logic        is_push;
    logic [ 2:0] arg_hi;
    logic [ 4:0] arg_lo;
    logic        push_iffull;
    logic        push_block;
    logic        shift_right;
    logic [ 4:0] push_thresh;
    logic [31:0] in_pins;
    logic [31:0] x;
    logic [31:0] y;
    logic [31:0] osr;
    logic        rx_full;

    wire  [31:0] isr;
    wire  [ 5:0] isr_cnt;
    wire         stall;
    wire         rx_push;
    wire  [31:0] rx_data;

    pio_isr dut (.*);

    //------------------------------------------------------------------------

    task automatic run
    (
        input string       name,
        input logic        e,
        input logic        i,
        input logic        p,
        input logic        blk,
        input logic        ifull,
        input logic [ 2:0] src,
        input logic [ 4:0] n,
        input logic        exp_stall,
        input logic        exp_rx_push,
        input logic [31:0] exp_rx_data,
        input logic [31:0] exp_isr,
        input logic [ 5:0] exp_isr_cnt
    );

        @ (negedge clk);

        exec        = e;
        is_in       = i;
        is_push     = p;
        push_block  = blk;
        push_iffull = ifull;
        arg_hi      = src;
        arg_lo      = n;

        # 1;

        if (   (stall   !== exp_stall)
            || (rx_push !== exp_rx_push)
            || (exp_rx_push && rx_data !== exp_rx_data))
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => %s", name);

            $display ("++ EXPECTED => stall %b rx_push %b rx_data %h",
                exp_stall, exp_rx_push, exp_rx_data);

            $display ("++ ACTUAL   => stall %b rx_push %b rx_data %h",
                stall, rx_push, rx_data);

            $finish (1);
        end

        @ (posedge clk);
        # 1;

        if (   (isr     !== exp_isr)
            || (isr_cnt !== exp_isr_cnt))
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => %s", name);
            $display ("++ EXPECTED => isr %h isr_cnt %0d", exp_isr, exp_isr_cnt);
            $display ("++ ACTUAL   => isr %h isr_cnt %0d", isr, isr_cnt);
            $finish (1);
        end

    endtask

    //------------------------------------------------------------------------

    initial
    begin
        rst         = 1'b1;
        exec        = 1'b0;
        is_in       = 1'b0;
        is_push     = 1'b0;
        arg_hi      = '0;
        arg_lo      = '0;
        push_iffull = 1'b0;
        push_block  = 1'b1;
        shift_right = 1'b1;
        push_thresh = '0;
        in_pins     = '0;
        x           = '0;
        y           = '0;
        osr         = '0;
        rx_full     = 1'b0;

        repeat (2) @ (negedge clk);
        rst = 1'b0;

        run ("after reset",                  0, 0, 0, 1, 0, `PIO_SRC_PINS,  0, 0, 0, 'x,    32'h0,          0);

        in_pins = 32'h1;

        run ("in pins 1, pin 1",             1, 1, 0, 1, 0, `PIO_SRC_PINS,  1, 0, 0, 'x,    32'h8000_0000,  1);

        in_pins = 32'h0;

        run ("in pins 1, pin 0",             1, 1, 0, 1, 0, `PIO_SRC_PINS,  1, 0, 0, 'x,    32'h4000_0000,  2);

        x = 32'h5;
        y = 32'hFFFF_FFF3;

        run ("in x 3",                       1, 1, 0, 1, 0, `PIO_SRC_X,     3, 0, 0, 'x,    32'hA800_0000,  5);
        run ("in y 4",                       1, 1, 0, 1, 0, `PIO_SRC_Y,     4, 0, 0, 'x,    32'h3A80_0000,  9);

        push_thresh = 5'd16;

        run ("push iffull, below thresh",    1, 0, 1, 1, 1, `PIO_SRC_PINS,  0, 0, 0, 'x,    32'h3A80_0000,  9);
        run ("in null 24, count saturates",  1, 1, 0, 1, 0, `PIO_SRC_NULL, 24, 0, 0, 'x,    32'h0000_003A, 32);
        run ("push iffull, at thresh",       1, 0, 1, 1, 1, `PIO_SRC_PINS,  0, 0, 1, 32'h3A, 32'h0,          0);

        shift_right = 1'b0;
        push_thresh = '0;
        osr         = 32'h1234_56AB;
        in_pins     = 32'hC3;

        run ("in osr 8, left",               1, 1, 0, 1, 0, `PIO_SRC_OSR,   8, 0, 0, 'x,    32'h0000_00AB,  8);
        run ("in isr 8, left",               1, 1, 0, 1, 0, `PIO_SRC_ISR,   8, 0, 0, 'x,    32'h0000_ABAB, 16);
        run ("in pins 32, left",             1, 1, 0, 1, 0, `PIO_SRC_PINS,  0, 0, 0, 'x,    32'h0000_00C3, 32);

        rx_full = 1'b1;

        run ("push block, rx full",          0, 0, 1, 1, 0, `PIO_SRC_PINS,  0, 1, 0, 'x,    32'h0000_00C3, 32);
        run ("push noblock, rx full, lost",  1, 0, 1, 0, 0, `PIO_SRC_PINS,  0, 0, 0, 'x,    32'h0,          0);

        in_pins     = 32'hF;

        run ("in pins 4, left",              1, 1, 0, 1, 0, `PIO_SRC_PINS,  4, 0, 0, 'x,    32'h0000_000F,  4);

        push_thresh = 5'd16;

        run ("push iffull, below, rx full",  1, 0, 1, 1, 1, `PIO_SRC_PINS,  0, 0, 0, 'x,    32'h0000_000F,  4);

        rx_full     = 1'b0;
        push_thresh = '0;

        run ("push block",                   1, 0, 1, 1, 0, `PIO_SRC_PINS,  0, 0, 1, 32'hF,  32'h0,          0);

        x = 32'hFF;

        run ("in without exec",              0, 1, 0, 1, 0, `PIO_SRC_X,     8, 0, 0, 'x,    32'h0,          0);

        $display ("PASS %s", `__FILE__);
        $finish;
    end

    //------------------------------------------------------------------------

    initial
    begin
        repeat (10000) @ (posedge clk);
        $display ("FAIL %s: timeout reached!", `__FILE__);
        $finish;
    end

endmodule
