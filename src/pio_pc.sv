module pio_pc
(
    input               clk,
    input               rst,

    input               clk_en,
    input               stall,
    input               jmp_taken,
    input        [ 4:0] jmp_target,
    input        [ 4:0] wrap_top,
    input        [ 4:0] wrap_bottom,
    input        [ 4:0] instr_delay,

    output logic [ 4:0] pc,
    output              issue
);

    logic [4:0] pc_d;
    logic [4:0] delay_cnt;
    logic [4:0] delay_cnt_d;

    assign issue = clk_en & (delay_cnt == '0);

    //------------------------------------------------------------------------

    always_comb
    begin
        pc_d        = pc;
        delay_cnt_d = delay_cnt;

        if (clk_en)
        begin
            if (delay_cnt != '0)
            begin
                delay_cnt_d = delay_cnt - 1'b1;
            end
            else if (~ stall)
            begin
                delay_cnt_d = instr_delay;

                if (jmp_taken)
                    pc_d = jmp_target;
                else if (pc == wrap_top)
                    pc_d = wrap_bottom;
                else
                    pc_d = pc + 1'b1;
            end
        end
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            pc        <= '0;
            delay_cnt <= '0;
        end
        else
        begin
            pc        <= pc_d;
            delay_cnt <= delay_cnt_d;
        end

endmodule
