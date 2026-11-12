module tb_pio_unit_tx;

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

    localparam n_words  = 8;
    localparam bit_time = 8;

    logic [31:0] words [0:n_words - 1];
    int          n_host_pushed = 0;
    int          n_full_waits  = 0;

    task automatic host_send_all;

        for (int i = 0; i < n_words; i ++)
        begin
            @ (negedge clk);

            while (tx_full)
            begin
                n_full_waits ++;
                @ (negedge clk);
            end

            tx_push  = 1'b1;
            tx_wdata = words [i];

            @ (negedge clk);

            tx_push  = 1'b0;
            tx_wdata = 'x;
            n_host_pushed ++;
        end

    endtask

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
        words [3] = 32'h0000_00FF;
        words [4] = 32'hA5A5_A55A;
        words [5] = 32'h0000_0001;
        words [6] = 32'h0000_0080;
        words [7] = 32'hDEAD_BE3C;

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
        tx_push         = 1'b0;
        tx_wdata        = '0;
        rx_pop          = 1'b0;
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

        fork
            host_send_all;

            for (int i = 0; i < n_words; i ++)
            begin
                uart_receive (i, received);

                if (received !== words [i][7:0])
                begin
                    $display ("FAIL %s", `__FILE__);
                    $display ("++ TEST     => byte %0d", i);
                    $display ("++ EXPECTED => %h", words [i][7:0]);
                    $display ("++ ACTUAL   => %h", received);
                    $finish (1);
                end
            end
        join

        repeat (4 * bit_time) @ (posedge clk);

        if (pins [0] !== 1'b1 || n_full_waits == 0 || tx_full !== 1'b0)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => idle line after the last byte, TX FIFO back pressure");
            $display ("++ EXPECTED => tx 1, host waited on tx_full at least once, tx_full 0 at the end");
            $display ("++ ACTUAL   => tx %b, waits %0d, tx_full %b", pins [0], n_full_waits, tx_full);
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
