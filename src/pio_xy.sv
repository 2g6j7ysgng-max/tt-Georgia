`include "pio.svh"

module pio_xy
(
    input               clk,
    input               rst,

    input               exec,
    input               is_set,
    input               is_jmp,
    input        [ 2:0] arg_hi,
    input        [ 4:0] arg_lo,
    input               jmp_pin,
    input               osre,

    output logic [31:0] x,
    output logic [31:0] y,
    output              jmp_taken
);

    logic cond;

    always_comb
        case (arg_hi)
            default            : cond = 1'b1;
            `PIO_COND_ALWAYS   : cond = 1'b1;
            `PIO_COND_NOT_X    : cond = (x == '0);
            `PIO_COND_X_DEC    : cond = (x != '0);
            `PIO_COND_NOT_Y    : cond = (y == '0);
            `PIO_COND_Y_DEC    : cond = (y != '0);
            `PIO_COND_X_NE_Y   : cond = (x != y);
            `PIO_COND_PIN      : cond =   jmp_pin;
            `PIO_COND_NOT_OSRE : cond = ~ osre;
        endcase

    assign jmp_taken = is_jmp & cond;

    //------------------------------------------------------------------------

    logic [31:0] x_d;
    logic [31:0] y_d;

    always_comb
    begin
        x_d = x;
        y_d = y;

        if (exec & is_set)
            case (arg_hi)
                `PIO_DST_X : x_d = { 27'b0, arg_lo };
                `PIO_DST_Y : y_d = { 27'b0, arg_lo };
            endcase

        if (exec & is_jmp)
            case (arg_hi)
                `PIO_COND_X_DEC : x_d = x - 1'b1;
                `PIO_COND_Y_DEC : y_d = y - 1'b1;
            endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            x <= '0;
            y <= '0;
        end
        else
        begin
            x <= x_d;
            y <= y_d;
        end

endmodule
