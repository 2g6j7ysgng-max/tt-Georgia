module tb_pio_unit_rx;

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

    localparam n_prog   = 9;
    localparam bit_time = 8;

    logic rx_line;

    assign in_pins = { 7'b0, rx_line };
    assign jmp_pin = rx_line;

    //------------------------------------------------------------------------

    task automatic fail (input string name, input string expected, input string actual);

        $display ("FAIL %s", `__FILE__);
        $display ("++ TEST     => %s", name);
        $display ("++ EXPECTED => %s", expected);
        $display ("++ ACTUAL   => %s", actual);
        $finish (1);

    endtask

    //------------------------------------------------------------------------

    task automatic uart_send (input logic [7:0] data, input logic stop);

        @ (posedge clk);
        rx_line <= 1'b0;
        repeat (bit_time) @ (posedge clk);

        for (int i = 0; i < 8; i ++)
        begin
            rx_line <= data [i];
            repeat (bit_time) @ (posedge clk);
        end

        rx_line <= stop;
        repeat (bit_time) @ (posedge clk);

        rx_line <= 1'b1;
        repeat (3 * bit_time) @ (posedge clk);

    endtask

    //------------------------------------------------------------------------

    task automatic host_receive (input string name, input logic [7:0] expected);

        @ (negedge clk);

        while (rx_empty)
            @ (negedge clk);

        if (rx_rdata !== { 24'b0, expected })
            fail (name, $sformatf ("%h", { 24'b0, expected }),
                        $sformatf ("%h", rx_rdata));

        rx_pop = 1'b1;
        @ (negedge clk);
        rx_pop = 1'b0;

    endtask

    //------------------------------------------------------------------------

    logic [15:0] prog [0:n_prog - 1];

    initial
    begin
        prog [0] = 16'h00C0;
        prog [1] = 16'hEA27;
        prog [2] = 16'h4001;
        prog [3] = 16'h0642;
        prog [4] = 16'h00C7;
        prog [5] = 16'h00C0;
        prog [6] = 16'h0005;
        prog [7] = 16'h4078;
        prog [8] = 16'h8020;

        rst             = 1'b1;
        rx_line         = 1'b1;
        clk_en          = 1'b1;
        imem_we         = 1'b0;
        imem_waddr      = '0;
        imem_wdata      = '0;
        wrap_top        = 5'd8;
        wrap_bottom     = 5'd0;
        sideset_count   = 3'd0;
        side_en         = 1'b0;
        side_base       = '0;
        out_base        = '0;
        out_count       = '0;
        out_shift_right = 1'b1;
        autopull        = 1'b0;
        pull_thresh     = '0;
        in_base         = '0;
        in_shift_right  = 1'b1;
        autopush        = 1'b0;
        push_thresh     = '0;
        tx_push         = 1'b0;
        tx_wdata        = '0;
        rx_pop          = 1'b0;

        for (int i = 0; i < n_prog; i ++)
        begin
            @ (negedge clk);

            imem_we    = 1'b1;
            imem_waddr = i [4:0];
            imem_wdata = prog [i];
        end

        @ (negedge clk);

        imem_we = 1'b0;
        rst     = 1'b0;

        repeat (20) @ (posedge clk);

        uart_send (8'h4B, 1'b1);
        uart_send (8'hE1, 1'b1);
        uart_send (8'hA5, 1'b0);
        uart_send (8'h7E, 1'b1);
        uart_send (8'h80, 1'b1);

        @ (negedge clk);

        if (rx_empty !== 1'b0 || dut.rx_full !== 1'b1)
            fail ("RX FIFO after 4 good bytes without host reads",
                  "rx_empty 0, full 1",
                  $sformatf ("rx_empty %b, full %b", rx_empty, dut.rx_full));

        host_receive ("word 0", 8'h4B);
        host_receive ("word 1", 8'hE1);
        host_receive ("word 2", 8'h7E);
        host_receive ("word 3", 8'h80);

        if (rx_empty !== 1'b1)
            fail ("RX FIFO after 4 host reads", "rx_empty 1",
                  $sformatf ("rx_empty %b", rx_empty));

        fork
            begin
                uart_send (8'h3C, 1'b1);
                uart_send (8'h5A, 1'b1);
            end

            begin
                host_receive ("word 4, read while receiving", 8'h3C);
                host_receive ("word 5, read while receiving", 8'h5A);
            end
        join

        repeat (4 * bit_time) @ (posedge clk);

        if (rx_empty !== 1'b1)
            fail ("RX FIFO at the end", "rx_empty 1",
                  $sformatf ("rx_empty %b", rx_empty));

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
