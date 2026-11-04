`include "pio.svh"

module tb_pio_xy;

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
    logic        is_set;
    logic        is_jmp;
    logic        is_out;
    logic [ 2:0] arg_hi;
    logic [ 4:0] arg_lo;
    logic [31:0] out_data;
    logic        jmp_pin;
    logic        osre;

    wire  [31:0] x;
    wire  [31:0] y;
    wire         jmp_taken;

    pio_xy dut (.*);

    //------------------------------------------------------------------------

    task automatic step
    (
        input logic       s,
        input logic       j,
        input logic [2:0] hi,
        input logic [4:0] lo
    );

        @ (negedge clk);

        exec   = 1'b1;
        is_set = s;
        is_jmp = j;
        is_out = 1'b0;
        arg_hi = hi;
        arg_lo = lo;

    endtask

    //------------------------------------------------------------------------

    task automatic step_out (input logic [2:0] hi, input logic [31:0] data);

        @ (negedge clk);

        exec     = 1'b1;
        is_set   = 1'b0;
        is_jmp   = 1'b0;
        is_out   = 1'b1;
        arg_hi   = hi;
        arg_lo   = '0;
        out_data = data;

    endtask

    //------------------------------------------------------------------------

    task automatic check_jmp (input string name, input logic exp);

        # 1;

        if (jmp_taken !== exp)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => %s", name);
            $display ("++ EXPECTED => jmp_taken %b", exp);
            $display ("++ ACTUAL   => jmp_taken %b, x %h, y %h", jmp_taken, x, y);
            $finish (1);
        end

    endtask

    //------------------------------------------------------------------------

    task automatic check_xy (input string name, input logic [31:0] exp_x, input logic [31:0] exp_y);

        @ (posedge clk);
        # 1;

        if ((x !== exp_x) | (y !== exp_y))
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => %s", name);
            $display ("++ EXPECTED => x %h, y %h", exp_x, exp_y);
            $display ("++ ACTUAL   => x %h, y %h", x, y);
            $finish (1);
        end

    endtask

    //------------------------------------------------------------------------

    initial
    begin
        rst      = 1'b1;
        exec     = 1'b0;
        is_set   = 1'b0;
        is_jmp   = 1'b0;
        is_out   = 1'b0;
        arg_hi   = '0;
        arg_lo   = '0;
        out_data = '0;
        jmp_pin  = 1'b0;
        osre     = 1'b1;

        repeat (2) @ (negedge clk);
        rst = 1'b0;

        step (1, 0, `PIO_DST_X, 5'd7);   check_xy ("set x 7", 7, 0);
        step (1, 0, `PIO_DST_Y, 5'd31);  check_xy ("set y 31", 7, 31);

        step (0, 1, `PIO_COND_ALWAYS, 5'd2);  check_jmp ("jmp always", 1);
        step (0, 1, `PIO_COND_NOT_X,  5'd2);  check_jmp ("jmp !x, x 7", 0);
        step (0, 1, `PIO_COND_NOT_Y,  5'd2);  check_jmp ("jmp !y, y 31", 0);
        step (0, 1, `PIO_COND_X_NE_Y, 5'd2);  check_jmp ("jmp x != y", 1);

        jmp_pin = 1'b0;  step (0, 1, `PIO_COND_PIN,      5'd2);  check_jmp ("jmp pin 0", 0);
        jmp_pin = 1'b1;  step (0, 1, `PIO_COND_PIN,      5'd2);  check_jmp ("jmp pin 1", 1);
        osre    = 1'b1;  step (0, 1, `PIO_COND_NOT_OSRE, 5'd2);  check_jmp ("jmp !osre, empty", 0);
        osre    = 1'b0;  step (0, 1, `PIO_COND_NOT_OSRE, 5'd2);  check_jmp ("jmp !osre, not empty", 1);

        step (1, 0, `PIO_DST_X, 5'd2);  check_xy ("set x 2", 2, 31);

        step (0, 1, `PIO_COND_X_DEC, 5'd2);  check_jmp ("x--, x 2", 1);
        check_xy ("x-- -> 1", 1, 31);

        step (0, 1, `PIO_COND_X_DEC, 5'd2);  check_jmp ("x--, x 1", 1);
        check_xy ("x-- -> 0", 0, 31);

        step (0, 1, `PIO_COND_X_DEC, 5'd2);  check_jmp ("x--, x 0, not taken", 0);
        check_xy ("x-- -> -1, always", 32'hFFFF_FFFF, 31);

        step (0, 1, `PIO_COND_Y_DEC, 5'd2);  check_jmp ("y--, y 31", 1);
        check_xy ("y-- -> 30", 32'hFFFF_FFFF, 30);

        step (1, 0, `PIO_DST_X, 5'd30);  check_xy ("set x 30", 30, 30);
        step (0, 1, `PIO_COND_X_NE_Y, 5'd2);  check_jmp ("jmp x != y, x = y = 30", 0);

        step_out (`PIO_DST_X,    32'hDEAD_BEEF);  check_xy ("out x",    32'hDEAD_BEEF, 30);
        step_out (`PIO_DST_Y,    32'h1234_5678);  check_xy ("out y",    32'hDEAD_BEEF, 32'h1234_5678);
        step_out (`PIO_DST_NULL, 32'hFFFF_FFFF);  check_xy ("out null", 32'hDEAD_BEEF, 32'h1234_5678);
        step_out (`PIO_DST_PINS, 32'hFFFF_FFFF);  check_xy ("out pins", 32'hDEAD_BEEF, 32'h1234_5678);

        @ (negedge clk);

        exec   = 1'b0;
        is_set = 1'b1;
        arg_hi = `PIO_DST_X;
        arg_lo = 5'd5;

        check_xy ("no exec, no write", 32'hDEAD_BEEF, 32'h1234_5678);

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
