module tb_pio_sm;

    logic clk;

    initial
    begin
        clk = '0;

        forever
            # 5 clk = ~ clk;
    end

    logic rst;

    //------------------------------------------------------------------------

    logic        clk_en;
    logic        imem_we;
    logic [ 4:0] imem_waddr;
    logic [15:0] imem_wdata;
    logic [ 4:0] wrap_top;
    logic [ 4:0] wrap_bottom;
    logic [ 2:0] sideset_count;
    logic        side_en;
    logic        tx_empty;
    logic        jmp_pin;

    wire         tx_pop;
    wire  [ 4:0] side_out;
    wire  [ 4:0] pc;
    wire  [31:0] x;
    wire  [31:0] y;

    pio_sm dut (.*);

    //------------------------------------------------------------------------

    logic push;

    always @ (posedge clk)
        if (tx_pop)
            tx_empty <= 1'b1;
        else if (push)
            tx_empty <= 1'b0;

    //------------------------------------------------------------------------

    time t_fall = 0;
    time t_rise = 0;
    int  n_pops = 0;

    always @ (negedge side_out [0])
        if (rst === 1'b0)
            t_fall = $time;

    always @ (posedge side_out [0])
        if ((rst === 1'b0) & (t_fall != 0))
            t_rise = $time;

    always @ (posedge clk)
        if (tx_pop)
            n_pops ++;

    //------------------------------------------------------------------------

    logic [15:0] prog [0:3];

    initial
    begin
        prog [0] = 16'h9FA0;
        prog [1] = 16'hF727;
        prog [2] = 16'h6001;
        prog [3] = 16'h0642;

        rst           = 1'b1;
        clk_en        = 1'b1;
        imem_we       = 1'b0;
        imem_waddr    = '0;
        imem_wdata    = '0;
        wrap_top      = 5'd3;
        wrap_bottom   = 5'd0;
        sideset_count = 3'd2;
        side_en       = 1'b1;
        tx_empty      = 1'b1;
        jmp_pin       = 1'b0;
        push          = 1'b0;

        for (int i = 0; i < 4; i ++)
        begin
            @ (negedge clk);

            imem_we    = 1'b1;
            imem_waddr = i [4:0];
            imem_wdata = prog [i];
        end

        @ (negedge clk);

        imem_we = 1'b0;
        rst     = 1'b0;

        repeat (10) @ (negedge clk);
        push = 1'b1;

        @ (negedge clk);
        push = 1'b0;

        repeat (150) @ (negedge clk);

        if (   (t_fall == 0)
            || (t_rise - t_fall != 720)
            || (n_pops != 1)
            || (x !== 32'hFFFF_FFFF))
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => uart_tx from hex, one word");
            $display ("++ EXPECTED => tx low 720, pops 1, x ffffffff");
            $display ("++ ACTUAL   => tx low %0d, pops %0d, x %h", t_rise - t_fall, n_pops, x);
            $finish (1);
        end

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
