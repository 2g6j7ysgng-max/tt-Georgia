module tb_pio_pc;

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
    logic        stall;
    logic        jmp_taken;
    logic [ 4:0] jmp_target;
    logic [ 4:0] wrap_top;
    logic [ 4:0] wrap_bottom;
    logic [ 4:0] instr_delay;

    wire  [ 4:0] pc;
    wire         issue;

    pio_pc dut (.*);

    //------------------------------------------------------------------------

    always_comb
        case (pc)
            5'd0    : instr_delay = 5'd7;
            5'd1    : instr_delay = 5'd7;
            5'd3    : instr_delay = 5'd6;
            default : instr_delay = 5'd0;
        endcase

    assign clk_en      = 1'b1;
    assign jmp_target  = 5'd2;
    assign wrap_top    = 5'd3;
    assign wrap_bottom = 5'd0;

    //------------------------------------------------------------------------

    logic        fifo_empty;
    logic        push;
    logic [31:0] x;
    logic        exec;

    assign stall     = (pc == 5'd0) & fifo_empty;
    assign exec      = issue & ~ stall;
    assign jmp_taken = (pc == 5'd3) & (x != '0);

    always @ (posedge clk)
    begin
        if (exec & (pc == 5'd1))
            x <= 32'd7;

        if (exec & (pc == 5'd3))
            x <= x - 1'b1;

        if (exec & (pc == 5'd0))
            fifo_empty <= 1'b1;
        else if (push)
            fifo_empty <= 1'b0;
    end

    //------------------------------------------------------------------------

    int         cycle        = 0;
    int         last_edge    = -1;
    int         n_bits       = 0;
    logic [4:0] last_pc;
    logic       prev_stalled = 1'b0;

    always @ (posedge clk)
        cycle <= cycle + 1;

    always @ (posedge clk)
        if (~ rst)
        begin
            if (issue & ~ prev_stalled & (pc <= 5'd2))
            begin
                if ((last_edge >= 0) & (last_pc != 5'd0))
                begin
                    n_bits ++;

                    if (cycle - last_edge != 8)
                    begin
                        $display ("FAIL %s", `__FILE__);
                        $display ("++ TEST     => bit %0d, pc %0d, cycle %0d", n_bits, pc, cycle);
                        $display ("++ EXPECTED => 8 cycles per bit");
                        $display ("++ ACTUAL   => %0d cycles", cycle - last_edge);
                        $finish (1);
                    end
                end

                last_edge = cycle;
                last_pc   = pc;
            end

            prev_stalled <= issue & stall;
        end

    //------------------------------------------------------------------------

    initial
    begin
        rst        = 1'b1;
        push       = 1'b0;
        fifo_empty = 1'b1;
        x          = '0;

        repeat (3) @ (negedge clk);
        rst = 1'b0;

        repeat (10) @ (negedge clk);
        push = 1'b1;

        @ (negedge clk);
        push = 1'b0;

        repeat (120) @ (negedge clk);

        if (n_bits != 9)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => uart_tx timing, one word");
            $display ("++ EXPECTED => 9 bits");
            $display ("++ ACTUAL   => %0d bits", n_bits);
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
