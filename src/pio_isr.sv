`include "pio.svh"

module pio_isr
(
    input               clk,
    input               rst,

    input               exec,
    input               is_in,
    input               is_push,
    input        [ 2:0] arg_hi,
    input        [ 4:0] arg_lo,
    input               push_iffull,
    input               push_block,

    input               shift_right,
    input        [ 4:0] push_thresh,

    input        [31:0] in_pins,
    input        [31:0] x,
    input        [31:0] y,
    input        [31:0] osr,

    input               rx_full,

    output logic [31:0] isr,
    output logic [ 5:0] isr_cnt,
    output              stall,
    output              rx_push,
    output       [31:0] rx_data
);

    logic [5:0] n;
    logic [5:0] thresh;
    logic [6:0] cnt_sum;

    assign n       = (arg_lo      == '0) ? 6'd32 : { 1'b0, arg_lo      };
    assign thresh  = (push_thresh == '0) ? 6'd32 : { 1'b0, push_thresh };
    assign cnt_sum = isr_cnt + n;

    //------------------------------------------------------------------------

    logic push_nop;
    logic do_push;
    logic do_in;

    assign push_nop = push_iffull & (isr_cnt < thresh);
    assign stall    = is_push & push_block & rx_full & ~ push_nop;
    assign do_push  = exec & is_push & ~ push_nop;
    assign do_in    = exec & is_in;
    assign rx_push  = do_push & ~ rx_full;
    assign rx_data  = isr;

    //------------------------------------------------------------------------

    logic [31:0] src;
    logic [31:0] in_bits;
       always_comb
        case (arg_hi)
            default       : src = '0;
            `PIO_SRC_PINS : src = in_pins;
            `PIO_SRC_X    : src = x;
            `PIO_SRC_Y    : src = y;
            `PIO_SRC_NULL : src = '0;
            `PIO_SRC_ISR  : src = isr;
            `PIO_SRC_OSR  : src = osr;
        endcase

    assign in_bits = src & (32'hFFFF_FFFF >> (6'd32 - n));

    //------------------------------------------------------------------------

    logic [31:0] isr_d;
    logic [ 5:0] isr_cnt_d;

    always_comb
    begin
        isr_d     = isr;
        isr_cnt_d = isr_cnt;

        if (do_push)
        begin
            isr_d     = '0;
            isr_cnt_d = '0;
        end
                else if (do_in)
        begin
            isr_d     = shift_right ? ((isr >> n) | (in_bits << (6'd32 - n)))
                                    : ((isr << n) |  in_bits);
            isr_cnt_d = (cnt_sum > 7'd32) ? 6'd32 : cnt_sum [5:0];
        end
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            isr     <= '0;
            isr_cnt <= '0;
        end
        else
        begin
            isr     <= isr_d;
            isr_cnt <= isr_cnt_d;
        end

endmodule
