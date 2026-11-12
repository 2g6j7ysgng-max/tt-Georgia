module tb_pio_fifo;

    localparam width = 32,
               depth = 4;

    //------------------------------------------------------------------------

    logic clk;

    initial
    begin
        clk = '0;

        forever
            # 5 clk = ~ clk;
    end

    logic rst;

    //------------------------------------------------------------------------

    logic               push;
    logic [width - 1:0] write_data;
    logic               pop;

    wire  [width - 1:0] read_data;
    wire                empty;
    wire                full;

    pio_fifo # (.width (width), .depth (depth)) dut (.*);

    //------------------------------------------------------------------------

    logic [width - 1:0] queue [$];
    int                 n_pushed = 0;
    int                 n_popped = 0;

    task automatic fail (input string name, input string expected, input string actual);

        $display ("FAIL %s", `__FILE__);
        $display ("++ TEST     => %s", name);
        $display ("++ EXPECTED => %s", expected);
        $display ("++ ACTUAL   => %s", actual);
        $finish (1);

    endtask

    //------------------------------------------------------------------------

    task automatic step (input string name, input logic p, input logic q);

        @ (negedge clk);

        push       = p;
        pop        = q;
        write_data = $urandom ();

        # 1;

        if (empty !== (queue.size () == 0))
            fail (name, $sformatf ("empty %b", queue.size () == 0),
                        $sformatf ("empty %b", empty));

        if (full !== (queue.size () == depth))
            fail (name, $sformatf ("full %b", queue.size () == depth),
                        $sformatf ("full %b", full));

        if (q && queue.size () != 0 && read_data !== queue [0])
            fail (name, $sformatf ("read_data %h", queue [0]),
                        $sformatf ("read_data %h", read_data));

        @ (posedge clk);

        if (q && queue.size () != 0)
        begin
            void' (queue.pop_front ());
            n_popped ++;
        end

        if (p && ! full)
        begin
            queue.push_back (write_data);
            n_pushed ++;
        end

    endtask

    //------------------------------------------------------------------------

    initial
    begin
        rst        = 1'b1;
        push       = 1'b0;
        pop        = 1'b0;
        write_data = '0;

        repeat (2) @ (negedge clk);
        rst = 1'b0;

        step ("after reset", 0, 0);

        for (int i = 0; i < depth; i ++)
            step ("fill", 1, 0);

        step ("full, check flags",          0, 0);
        step ("push into full is ignored",  1, 0);
        step ("push and pop when full",     1, 1);

        for (int i = 0; i < depth; i ++)
            step ("drain", 0, 1);

        step ("empty, check flags",         0, 0);
        step ("pop from empty is ignored",  0, 1);
        step ("push and pop when empty",    1, 1);
        step ("push and pop, one inside",   1, 1);

        for (int i = 0; i < 2000; i ++)
            step ("random", $urandom_range (0, 1), $urandom_range (0, 1));

        for (int i = 0; i < depth + 1; i ++)
            step ("final drain", 0, 1);

        step ("final empty", 0, 0);

        if (n_pushed < 500 || n_popped != n_pushed)
            fail ("statistics", "at least 500 words pushed and all popped",
                  $sformatf ("pushed %0d popped %0d", n_pushed, n_popped));

        $display ("PASS %s", `__FILE__);
        $finish;
    end

    //------------------------------------------------------------------------

    initial
    begin
        repeat (100000) @ (posedge clk);
        $display ("FAIL %s: timeout reached!", `__FILE__);
        $finish;
    end

endmodule
