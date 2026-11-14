module tb_pio_unit_autopush;

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

    localparam n_bytes  = 5;
    localparam bit_time = 8;

    logic rx_line;

    assign in_pins = { 7'b0, rx_line };
    assign jmp_pin = rx_line;

    //------------------------------------------------------------------------

    task automatic uart_send (input logic [7:0] data);

        @ (posedge clk);
        rx_line <= 1'b0;
        repeat (bit_time) @ (posedge clk);

        for (int i = 0; i < 8; i ++)
        begin
            rx_line <= data [i];
            repeat (bit_time) @ (posedge clk);
        end

        rx_line <= 1'b1;
        repeat (3 * bit_time) @ (posedge clk);

    endtask

    //------------------------------------------------------------------------

    task automatic host_receive (input int n, input logic [7:0] expected);

        @ (negedge clk);

        while (rx_empty)
            @ (negedge clk);

        if (rx_rdata !== { expected, 24'b0 })
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => word %0d, byte in bits [31:24]", n);
            $display ("++ EXPECTED => %h", { expected, 24'b0 });
            $display ("++ ACTUAL   => %h", rx_rdata);
            $finish (1);
        end

        rx_pop = 1'b1;
        @ (negedge clk);
        rx_pop = 1'b0;

    endtask

    //------------------------------------------------------------------------

    logic [15:0] prog  [0:3];
    logic [ 7:0] bytes [0:n_bytes - 1];

    initial
    begin
        prog [0] = 16'h00C0;
        prog [1] = 16'hEA27;
        prog [2] = 16'h4001;
        prog [3] = 16'h0642;

        bytes [0] = 8'h4B;
        bytes [1] = 8'hE1;
        bytes [2] = 8'h7E;
        bytes [3] = 8'h80;
        bytes [4] = 8'h00;

        rst             = 1'b1;
        rx_line         = 1'b1;
        clk_en          = 1'b1;
        imem_we         = 1'b0;
        imem_waddr      = '0;
        imem_wdata      = '0;
        wrap_top        = 5'd3;
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
        autopush        = 1'b1;
        push_thresh     = 5'd8;
        tx_push         = 1'b0;
        tx_wdata        = '0;
        rx_pop          = 1'b0;

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

        repeat (20) @ (posedge clk);

        fork
            for (int i = 0; i < n_bytes; i ++)
                uart_send (bytes [i]);

            for (int i = 0; i < n_bytes; i ++)
                host_receive (i, bytes [i]);
        join

        repeat (4 * bit_time) @ (posedge clk);

        if (rx_empty !== 1'b1)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => RX FIFO at the end");
            $display ("++ EXPECTED => rx_empty 1, no extra pushes");
            $display ("++ ACTUAL   => rx_empty %b", rx_empty);
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
