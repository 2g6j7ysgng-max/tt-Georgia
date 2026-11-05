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
    logic [ 2:0] side_base;
    logic [ 2:0] out_base;
    logic [ 3:0] out_count;
    logic        out_shift_right;
    logic [ 4:0] pull_thresh;
    logic [ 2:0] in_base;
    logic        in_shift_right;
    logic [ 4:0] push_thresh;
    logic        tx_empty;
    logic [31:0] tx_data;
    logic        rx_full;
    logic [ 7:0] in_pins;
    logic        jmp_pin;

    wire         tx_pop;
    wire         rx_push;
    wire  [31:0] rx_data;
    wire  [ 7:0] pins;
    wire  [ 4:0] pc;
    wire  [31:0] x;
    wire  [31:0] y;

    pio_sm dut (.*);

    //------------------------------------------------------------------------

    localparam n_words  = 3;
    localparam bit_time = 8;

    logic [31:0] words [0:n_words - 1];
    int          n_pushed = 0;
    int          rd_ptr   = 0;

    assign tx_empty = (rd_ptr == n_pushed);
    assign tx_data  = tx_empty ? 'x : words [rd_ptr];

    always @ (posedge clk)
        if (tx_pop)
            rd_ptr <= rd_ptr + 1;

    //------------------------------------------------------------------------

    task automatic uart_receive (input int n, output logic [7:0] data);

        wait (pins [0] === 1'b1);
        @ (negedge pins [0]);

        repeat (bit_time / 2) @ (posedge clk);

        if (pins [0] !== 1'b0)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => byte %0d, start bit", n);
            $display ("++ EXPECTED => tx 0 in the middle of the start bit");
            $display ("++ ACTUAL   => tx %b", pins [0]);
            $finish (1);
        end

        for (int i = 0; i < 8; i ++)
        begin
            repeat (bit_time) @ (posedge clk);
            data [i] = pins [0];
        end

        repeat (bit_time) @ (posedge clk);

        if (pins [0] !== 1'b1)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => byte %0d, stop bit", n);
            $display ("++ EXPECTED => tx 1 in the middle of the stop bit");
            $display ("++ ACTUAL   => tx %b", pins [0]);
            $finish (1);
        end

    endtask

    //------------------------------------------------------------------------

    logic [15:0] prog     [0:3];
    logic [ 7:0] expected [0:n_words - 1];
    logic [ 7:0] received;

    initial
    begin
        prog [0] = 16'h9FA0;
        prog [1] = 16'hF727;
        prog [2] = 16'h6001;
        prog [3] = 16'h0642;

        words [0] = 32'h0000_004B;
        words [1] = 32'hFFFF_FFE1;
        words [2] = 32'h1234_5600;

        for (int i = 0; i < n_words; i ++)
            expected [i] = words [i][7:0];

        rst             = 1'b1;
        clk_en          = 1'b1;
        imem_we         = 1'b0;
        imem_waddr      = '0;
        imem_wdata      = '0;
        wrap_top        = 5'd3;
        wrap_bottom     = 5'd0;
        sideset_count   = 3'd2;
        side_en         = 1'b1;
        side_base       = 3'd0;
        out_base        = 3'd0;
        out_count       = 4'd1;
        out_shift_right = 1'b1;
        pull_thresh     = '0;
        in_base         = '0;
        in_shift_right  = 1'b1;
        push_thresh     = '0;
        rx_full         = 1'b0;
        in_pins         = '0;
        jmp_pin         = 1'b0;

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

        repeat (20) @ (negedge clk);

        if (pins [0] !== 1'b1)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => idle line before the first byte");
            $display ("++ EXPECTED => tx 1");
            $display ("++ ACTUAL   => tx %b", pins [0]);
            $finish (1);
        end

        n_pushed = n_words;

        for (int i = 0; i < n_words; i ++)
        begin
            uart_receive (i, received);

            if (received !== expected [i])
            begin
                $display ("FAIL %s", `__FILE__);
                $display ("++ TEST     => byte %0d", i);
                $display ("++ EXPECTED => %h", expected [i]);
                $display ("++ ACTUAL   => %h", received);
                $finish (1);
            end
        end

        repeat (4 * bit_time) @ (posedge clk);

        if (pins [0] !== 1'b1 || rd_ptr != n_words)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => idle line after the last byte");
            $display ("++ EXPECTED => tx 1, pops %0d", n_words);
            $display ("++ ACTUAL   => tx %b, pops %0d", pins [0], rd_ptr);
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
