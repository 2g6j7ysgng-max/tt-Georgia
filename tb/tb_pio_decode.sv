module tb_pio_decode;

    logic [15:0] instr;
    logic [ 2:0] sideset_count;
    logic        side_en;

    wire         is_jmp;
    wire         is_wait;
    wire         is_in;
    wire         is_out;
    wire         is_push;
    wire         is_pull;
    wire         is_mov;
    wire         is_irq;
    wire         is_set;

    wire  [ 4:0] delay;
    wire         side_valid;
    wire  [ 4:0] side_value;
    wire  [ 2:0] arg_hi;
    wire  [ 4:0] arg_lo;

    pio_decode dut (.*);

    //------------------------------------------------------------------------

    task automatic run
    (
        input logic [15:0] i,
        input logic [ 2:0] count,
        input logic        en,
        input logic [ 8:0] exp_cmd,
        input logic [ 4:0] exp_delay,
        input logic        exp_side_valid,
        input logic [ 4:0] exp_side_value,
        input logic [ 2:0] exp_arg_hi,
        input logic [ 4:0] exp_arg_lo
    );

        logic [8:0] cmd;

        instr         = i;
        sideset_count = count;
        side_en       = en;

        # 1;

        cmd = { is_jmp, is_wait, is_in, is_out, is_push,
                is_pull, is_mov, is_irq, is_set };

        if (   cmd        !== exp_cmd
            || delay      !== exp_delay
            || side_valid !== exp_side_valid
            || (exp_side_valid && side_value !== exp_side_value)
            || arg_hi     !== exp_arg_hi
            || arg_lo     !== exp_arg_lo)
        begin
            $display ("FAIL %s", `__FILE__);

            $display ("++ TEST     => instr %h sideset_count %0d side_en %b",
                i, count, en);

            $display ("++ EXPECTED => cmd %b delay %0d side %b/%0d arg %0d/%0d",
                exp_cmd, exp_delay, exp_side_valid, exp_side_value,
                exp_arg_hi, exp_arg_lo);

            $display ("++ ACTUAL   => cmd %b delay %0d side %b/%0d arg %0d/%0d",
                cmd, delay, side_valid, side_value, arg_hi, arg_lo);

            $finish (1);
        end

    endtask

    //------------------------------------------------------------------------

    initial
    begin
        run (16'h9FA0, 3'd2, 1'b1, 9'b000001000, 5'd7, 1'b1, 5'd1, 3'd5, 5'd0);
        run (16'hF727, 3'd2, 1'b1, 9'b000000001, 5'd7, 1'b1, 5'd0, 3'd1, 5'd7);
        run (16'h6001, 3'd2, 1'b1, 9'b000100000, 5'd0, 1'b0, 5'd0, 3'd0, 5'd1);
        run (16'h0642, 3'd2, 1'b1, 9'b100000000, 5'd6, 1'b0, 5'd0, 3'd2, 5'd2);

        run (16'hE101, 3'd0, 1'b0, 9'b000000001, 5'd1, 1'b0, 5'd0, 3'd0, 5'd1);
        run (16'h7001, 3'd1, 1'b0, 9'b000100000, 5'd0, 1'b1, 5'd1, 3'd0, 5'd1);

        run (16'h8020, 3'd0, 1'b0, 9'b000010000, 5'd0, 1'b0, 5'd0, 3'd1, 5'd0);
        run (16'h2080, 3'd0, 1'b0, 9'b010000000, 5'd0, 1'b0, 5'd0, 3'd4, 5'd0);
        run (16'h4001, 3'd0, 1'b0, 9'b001000000, 5'd0, 1'b0, 5'd0, 3'd0, 5'd1);
        run (16'hA042, 3'd0, 1'b0, 9'b000000100, 5'd0, 1'b0, 5'd0, 3'd2, 5'd2);
        run (16'hC000, 3'd0, 1'b0, 9'b000000010, 5'd0, 1'b0, 5'd0, 3'd0, 5'd0);

        $display ("PASS %s", `__FILE__);
        $finish;
    end

endmodule
