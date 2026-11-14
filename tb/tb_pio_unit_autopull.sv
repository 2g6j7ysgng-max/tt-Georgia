module tb_pio_unit_autopull;

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
    logic [ 2:0] side_base;
    logic [ 2:0] out_base;
    logic [ 3:0] out_count;
    logic        out_shift_right;
    logic        autopull;
    logic [ 4:0] pull_thresh;
    logic [ 2:0] in_base;
    logic        in_shift_right;
    logic        autopush;
    logic [ 4:0] push_thresh;
    logic        tx_push;
    logic [31:0] tx_wdata;
    logic        rx_pop;
    logic [ 7:0] in_pins;
    logic        jmp_pin;

    wire         tx_full;
    wire  [31:0] rx_rdata;
    wire         rx_empty;
    wire  [ 7:0] pins;
    wire  [ 4:0] pc;
    wire  [31:0] x;
    wire  [31:0] y;

    pio_unit dut (.*);

    //------------------------------------------------------------------------

    localparam n_words = 6;

    logic [31:0] words [0:n_words - 1];
    logic [ 7:0] bits_got [0:n_words - 1];
    int          n_bits = 0;

    always @ (posedge pins [1])
        if (rst === 1'b0)
        begin
            if (n_bits < 8 * n_words)
                bits_got [n_bits / 8][n_bits % 8] = pins [0];

            n_bits ++;
        end

    //------------------------------------------------------------------------

    task automatic host_push (input logic [31:0] data);

        @ (negedge clk);

        while (tx_full)
            @ (negedge clk);

        tx_push  = 1'b1;
        tx_wdata = data;

        @ (negedge clk);

        tx_push  = 1'b0;
        tx_wdata = 'x;

    endtask

    //------------------------------------------------------------------------

    logic [15:0] prog [0:1];

    initial
    begin
        prog [0] = 16'h6001;
        prog [1] = 16'h1000;

        words [0] = 32'hFFFF_FF4B;
        words [1] = 32'h0000_00E1;
        words [2] = 32'h1234_567E;
        words [3] = 32'h0000_0080;
        words [4] = 32'hFFFF_FF01;
        words [5] = 32'hABCD_EF3C;

        rst             = 1'b1;
        clk_en          = 1'b1;
        imem_we         = 1'b0;
        imem_waddr      = '0;
        imem_wdata      = '0;
        wrap_top        = 5'd1;
        wrap_bottom     = 5'd0;
        sideset_count   = 3'd1;
        side_en         = 1'b0;
        side_base       = 3'd1;
        out_base        = 3'd0;
        out_count       = 4'd1;
        out_shift_right = 1'b1;
        autopull        = 1'b1;
        pull_thresh     = 5'd8;
        in_base         = '0;
        in_shift_right  = 1'b1;
        autopush        = 1'b0;
        push_thresh     = '0;
        tx_push         = 1'b0;
        tx_wdata        = '0;
        rx_pop          = 1'b0;
        in_pins         = '0;
        jmp_pin         = 1'b0;

        for (int i = 0; i < 2; i ++)
        begin
            @ (negedge clk);

            imem_we    = 1'b1;
            imem_waddr = i [4:0];
            imem_wdata = prog [i];
        end

        @ (negedge clk);

        imem_we = 1'b0;
        rst     = 1'b0;

        repeat (30) @ (negedge clk);

        if (n_bits != 0 || pins [1] !== 1'b0)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => no data in TX FIFO, OUT stalls with clock low");
            $display ("++ EXPECTED => 0 clock edges, clock 0");
            $display ("++ ACTUAL   => %0d clock edges, clock %b", n_bits, pins [1]);
            $finish (1);
        end

        for (int i = 0; i < 3; i ++)
            host_push (words [i]);

        repeat (100) @ (negedge clk);

        if (n_bits != 24)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => 3 words, then the FIFO runs dry");
            $display ("++ EXPECTED => exactly 24 clock edges, 8 bits per word");
            $display ("++ ACTUAL   => %0d clock edges", n_bits);
            $finish (1);
        end

        for (int i = 3; i < n_words; i ++)
            host_push (words [i]);

        repeat (100) @ (negedge clk);

        if (n_bits != 8 * n_words)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => all words shifted out");
            $display ("++ EXPECTED => %0d clock edges", 8 * n_words);
            $display ("++ ACTUAL   => %0d clock edges", n_bits);
            $finish (1);
        end

        for (int i = 0; i < n_words; i ++)
            if (bits_got [i] !== words [i][7:0])
            begin
                $display ("FAIL %s", `__FILE__);
                $display ("++ TEST     => byte %0d, LSB first", i);
                $display ("++ EXPECTED => %h", words [i][7:0]);
                $display ("++ ACTUAL   => %h", bits_got [i]);
                $finish (1);
            end

        $display ("PASS %s", `__FILE__);
        $finish;
    end

    //------------------------------------------------------------------------

    initial
    begin
        repeat (20000) @ (posedge clk);
        $display ("FAIL %s: timeout reached!", `__FILE__);
        $finish;
    end

endmodule
