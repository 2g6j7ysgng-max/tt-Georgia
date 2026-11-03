module tb_pio_osr;

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
    logic        is_out;
    logic        is_pull;
    logic [ 4:0] arg_lo;
    logic        pull_ifempty;
    logic        pull_block;
    logic        shift_right;
    logic [ 4:0] pull_thresh;
    logic        tx_empty;
    logic [31:0] tx_data;
    logic [31:0] x;

    wire  [31:0] osr;
    wire  [ 5:0] osr_cnt;
    wire  [31:0] out_data;
    wire         osre;
    wire         stall;
    wire         tx_pop;

    pio_osr dut (.*);

    //------------------------------------------------------------------------

    task automatic run
    (
        input string       name,
        input logic        e,
        input logic        o,
        input logic        p,
        input logic        blk,
        input logic        ife,
        input logic [ 4:0] n,
        input logic [31:0] exp_out_data,
        input logic        exp_stall,
        input logic        exp_tx_pop,
        input logic [31:0] exp_osr,
        input logic [ 5:0] exp_osr_cnt,
        input logic        exp_osre
    );

        @ (negedge clk);

        exec         = e;
        is_out       = o;
        is_pull      = p;
        pull_block   = blk;
        pull_ifempty = ife;
        arg_lo       = n;

        # 1;

        if (   (o && out_data !== exp_out_data)
            || (stall  !== exp_stall)
            || (tx_pop !== exp_tx_pop))
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => %s", name);

            $display ("++ EXPECTED => out_data %h stall %b tx_pop %b",
                exp_out_data, exp_stall, exp_tx_pop);

            $display ("++ ACTUAL   => out_data %h stall %b tx_pop %b",
                out_data, stall, tx_pop);

            $finish (1);
        end

        @ (posedge clk);
        # 1;

        if (   (osr     !== exp_osr)
            || (osr_cnt !== exp_osr_cnt)
            || (osre    !== exp_osre))
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => %s", name);

            $display ("++ EXPECTED => osr %h osr_cnt %0d osre %b",
                exp_osr, exp_osr_cnt, exp_osre);

            $display ("++ ACTUAL   => osr %h osr_cnt %0d osre %b",
                osr, osr_cnt, osre);

            $finish (1);
        end

    endtask

    //------------------------------------------------------------------------

    initial
    begin
        rst          = 1'b1;
        exec         = 1'b0;
        is_out       = 1'b0;
        is_pull      = 1'b0;
        arg_lo       = '0;
        pull_ifempty = 1'b0;
        pull_block   = 1'b1;
        shift_right  = 1'b1;
        pull_thresh  = '0;
        tx_empty     = 1'b1;
        tx_data      = '0;
        x            = '0;

        repeat (2) @ (negedge clk);
        rst = 1'b0;

        run ("after reset",                     0, 0, 0, 1,  0,  0,  'x,            0,    0,  32'h0,         32, 1);
        run ("pull block, fifo empty",          0, 0, 1, 1,  0,  0,  'x,            1,    0,  32'h0,         32, 1);

        tx_empty = 1'b0;
        tx_data  = 32'hA5;

        run ("pull",                            1, 0, 1, 1,  0,  0,  'x,            0,    1,  32'hA5,         0, 0);

        tx_empty = 1'b1;

        run ("out 1",                           1, 1, 0, 1,  0,  1,  32'h1,         0,    0,  32'h52,         1, 0);
        run ("out 1 again",                     1, 1, 0, 1,  0,  1,  32'h0,         0,    0,  32'h29,         2, 0);
        run ("out 3",                           1, 1, 0, 1,  0,  3,  32'h1,         0,    0,  32'h5,          5, 0);
        run ("out 32",                          1, 1, 0, 1,  0,  0,  32'h5,         0,    0,  32'h0,         32, 1);
        run ("out 32 on empty osr",             1, 1, 0, 1,  0,  0,  32'h0,         0,    0,  32'h0,         32, 1);

        x = 32'h1234;

        run ("pull noblock, fifo empty -> x",   1, 0, 1, 0,  0,  0,  'x,            0,    0,  32'h1234,       0, 0);

        pull_thresh = 5'd8;

        run ("pull ifempty, below thresh",      1, 0, 1, 1,  1,  0,  'x,            0,    0,  32'h1234,       0, 0);
        run ("out 8",                           1, 1, 0, 1,  0,  8,  32'h34,        0,    0,  32'h12,         8, 1);

        tx_empty = 1'b0;
        tx_data  = 32'hDEAD_BEEF;

        run ("pull ifempty, at thresh",         1, 0, 1, 1,  1,  0,  'x,            0,    1,  32'hDEAD_BEEF,  0, 0);

        shift_right = 1'b0;
        pull_thresh = '0;
        tx_data     = 32'h8000_0001;

        run ("pull for left shift",             1, 0, 1, 1,  0,  0,  'x,            0,    1,  32'h8000_0001,  0, 0);

        tx_empty = 1'b1;

        run ("out 1, left",                     1, 1, 0, 1,  0,  1,  32'h1,         0,    0,  32'h2,          1, 0);
        run ("out 4, left",                     1, 1, 0, 1,  0,  4,  32'h0,         0,    0,  32'h20,         5, 0);
        run ("out without exec",                0, 1, 0, 1,  0,  3,  32'h0,         0,    0,  32'h20,         5, 0);

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
