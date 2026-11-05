module tb_pio_sm_rx;

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

    localparam n_prog   = 9;
    localparam n_bytes  = 5;
    localparam n_good   = 4;
    localparam bit_time = 8;

    logic rx_line;

    assign in_pins = { 7'b0, rx_line };
    assign jmp_pin = rx_line;

    //------------------------------------------------------------------------

    logic [31:0] received [0:n_bytes - 1];
    int          n_received = 0;

    always @ (posedge clk)
        if (rx_push)
        begin
            if (n_received < n_bytes)
                received [n_received] <= rx_data;

            n_received <= n_received + 1;
        end

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

    logic [15:0] prog     [0:n_prog  - 1];
    logic [ 7:0] bytes    [0:n_bytes - 1];
    logic        stops    [0:n_bytes - 1];
    logic [31:0] expected [0:n_good  - 1];

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

        bytes [0] = 8'h4B;  stops [0] = 1'b1;
        bytes [1] = 8'hE1;  stops [1] = 1'b1;
        bytes [2] = 8'hA5;  stops [2] = 1'b0;
        bytes [3] = 8'h7E;  stops [3] = 1'b1;
        bytes [4] = 8'h80;  stops [4] = 1'b1;

        expected [0] = 32'h0000_004B;
        expected [1] = 32'h0000_00E1;
        expected [2] = 32'h0000_007E;
        expected [3] = 32'h0000_0080;

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
        pull_thresh     = '0;
        in_base         = '0;
        in_shift_right  = 1'b1;
        push_thresh     = '0;
        tx_empty        = 1'b1;
        tx_data         = '0;
        rx_full         = 1'b0;

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

        for (int i = 0; i < n_bytes; i ++)
            uart_send (bytes [i], stops [i]);

        repeat (4 * bit_time) @ (posedge clk);

        if (n_received != n_good)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => number of words pushed to RX FIFO");
            $display ("++ EXPECTED => %0d, the byte with a bad stop bit is dropped", n_good);
            $display ("++ ACTUAL   => %0d", n_received);
            $finish (1);
        end

        for (int i = 0; i < n_good; i ++)
            if (received [i] !== expected [i])
            begin
                $display ("FAIL %s", `__FILE__);
                $display ("++ TEST     => word %0d in RX FIFO", i);
                $display ("++ EXPECTED => %h", expected [i]);
                $display ("++ ACTUAL   => %h", received [i]);
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
