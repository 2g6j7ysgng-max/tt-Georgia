module tb_pio_pins;

    logic clk;

    initial
    begin
        clk = '0;

        forever
            # 5 clk = ~ clk;
    end

    logic rst;

    //------------------------------------------------------------------------

    logic        out_we;
    logic [31:0] out_data;
    logic [ 2:0] out_base;
    logic [ 3:0] out_count;
    logic        side_we;
    logic [ 4:0] side_value;
    logic [ 2:0] side_base;
    logic [ 2:0] side_count;

    wire  [ 7:0] pins;

    pio_pins dut (.*);

    //------------------------------------------------------------------------

    task automatic run
    (
        input string       name,
        input logic        o_we,
        input logic [31:0] o_data,
        input logic [ 2:0] o_base,
        input logic [ 3:0] o_count,
        input logic        s_we,
        input logic [ 4:0] s_value,
        input logic [ 2:0] s_base,
        input logic [ 2:0] s_count,
        input logic [ 7:0] exp_pins
    );

        @ (negedge clk);

        out_we     = o_we;
        out_data   = o_data;
        out_base   = o_base;
        out_count  = o_count;
        side_we    = s_we;
        side_value = s_value;
        side_base  = s_base;
        side_count = s_count;

        @ (posedge clk);
        # 1;

        if (pins !== exp_pins)
        begin
            $display ("FAIL %s", `__FILE__);
            $display ("++ TEST     => %s", name);
            $display ("++ EXPECTED => pins %b", exp_pins);
            $display ("++ ACTUAL   => pins %b", pins);
            $finish (1);
        end

    endtask

    //------------------------------------------------------------------------

    initial
    begin
        rst        = 1'b1;
        out_we     = 1'b0;
        out_data   = '0;
        out_base   = '0;
        out_count  = '0;
        side_we    = 1'b0;
        side_value = '0;
        side_base  = '0;
        side_count = '0;

        repeat (2) @ (negedge clk);
        rst = 1'b0;

        run ("after reset",                0, 32'h0,         3'd0, 4'd0, 0, 5'h00, 3'd0, 3'd0, 8'h00);
        run ("out 1 bit at 0",             1, 32'h1,         3'd0, 4'd1, 0, 5'h00, 3'd0, 3'd0, 8'h01);
        run ("out 3 bits at 2",            1, 32'h5,         3'd2, 4'd3, 0, 5'h00, 3'd0, 3'd0, 8'h15);
        run ("out 8 bits at 0",            1, 32'hFFFF_FFA5, 3'd0, 4'd8, 0, 5'h00, 3'd0, 3'd0, 8'hA5);
        run ("side 1 bit at 7",            0, 32'h0,         3'd0, 4'd0, 1, 5'h00, 3'd7, 3'd1, 8'h25);
        run ("out and side, side wins",    1, 32'h3,         3'd0, 4'd2, 1, 5'h00, 3'd1, 3'd1, 8'h25);
        run ("nothing written",            0, 32'hFF,        3'd0, 4'd8, 0, 5'h1F, 3'd0, 3'd5, 8'h25);
        run ("out count 0",                1, 32'hFF,        3'd0, 4'd0, 0, 5'h00, 3'd0, 3'd0, 8'h25);
        run ("out off the top",            1, 32'hF,         3'd6, 4'd4, 0, 5'h00, 3'd0, 3'd0, 8'hE5);
        run ("side 2 bits at 3",           0, 32'h0,         3'd0, 4'd0, 1, 5'h1E, 3'd3, 3'd2, 8'hF5);

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
