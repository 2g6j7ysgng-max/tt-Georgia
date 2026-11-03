module pio_osr
(
    input               clk,
    input               rst,

    input               exec,
    input               is_out,
    input               is_pull,
    input        [ 4:0] arg_lo,
    input               pull_ifempty,
    input               pull_block,

    input               shift_right,
    input        [ 4:0] pull_thresh,

    input               tx_empty,
    input        [31:0] tx_data,
    input        [31:0] x,

    output logic [31:0] osr,
    output logic [ 5:0] osr_cnt,
    output       [31:0] out_data,
    output              osre,
    output              stall,
    output              tx_pop
);

    logic [5:0] n;
    logic [5:0] thresh;
    logic [6:0] cnt_sum;

    assign n       = (arg_lo      == '0) ? 6'd32 : { 1'b0, arg_lo      };
    assign thresh  = (pull_thresh == '0) ? 6'd32 : { 1'b0, pull_thresh };
    assign cnt_sum = osr_cnt + n;
    assign osre    = (osr_cnt >= thresh);

    //------------------------------------------------------------------------

    logic pull_nop;
    logic do_pull;
    logic do_out;

    assign pull_nop = pull_ifempty & ~ osre;
    assign stall    = is_pull & pull_block & tx_empty & ~ pull_nop;
    assign do_pull  = exec & is_pull & ~ pull_nop;
    assign do_out   = exec & is_out;
    assign tx_pop   = do_pull & ~ tx_empty;

    //------------------------------------------------------------------------

    assign out_data = shift_right ? (osr & (32'hFFFF_FFFF >> (6'd32 - n)))
                                  : (osr >> (6'd32 - n));

    //------------------------------------------------------------------------

    logic [31:0] osr_d;
    logic [ 5:0] osr_cnt_d;

    always_comb
    begin
        osr_d     = osr;
        osr_cnt_d = osr_cnt;

        if (do_pull)
        begin
            osr_d     = tx_empty ? x : tx_data;
            osr_cnt_d = '0;
        end
        else if (do_out)
        begin
            osr_d     = shift_right ? (osr >> n) : (osr << n);
            osr_cnt_d = (cnt_sum > 7'd32) ? 6'd32 : cnt_sum [5:0];
        end
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            osr     <= '0;
            osr_cnt <= 6'd32;
        end
        else
        begin
            osr     <= osr_d;
            osr_cnt <= osr_cnt_d;
        end

endmodule