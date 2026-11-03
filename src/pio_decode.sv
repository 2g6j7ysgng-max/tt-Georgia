`include "pio.svh"

module pio_decode
(
    input        [15:0] instr,
    input        [ 2:0] sideset_count,
    input               side_en,

    output              is_jmp,
    output              is_wait,
    output              is_in,
    output              is_out,
    output              is_push,
    output              is_pull,
    output              is_mov,
    output              is_irq,
    output              is_set,

    output       [ 4:0] delay,
    output              side_valid,
    output       [ 4:0] side_value,
    output       [ 2:0] arg_hi,
    output       [ 4:0] arg_lo
);

    logic [2:0] cmd_op;

    assign cmd_op = instr [15:13];
    assign arg_hi = instr [ 7: 5];
    assign arg_lo = instr [ 4: 0];

    //------------------------------------------------------------------------

    assign is_jmp  = (cmd_op == `PIO_OP_JMP       );
    assign is_wait = (cmd_op == `PIO_OP_WAIT      );
    assign is_in   = (cmd_op == `PIO_OP_IN        );
    assign is_out  = (cmd_op == `PIO_OP_OUT       );
    assign is_push = (cmd_op == `PIO_OP_PUSH_PULL ) & ~ instr [7];
    assign is_pull = (cmd_op == `PIO_OP_PUSH_PULL ) &   instr [7];
    assign is_mov  = (cmd_op == `PIO_OP_MOV       );
    assign is_irq  = (cmd_op == `PIO_OP_IRQ       );
    assign is_set  = (cmd_op == `PIO_OP_SET       );

    //------------------------------------------------------------------------

    logic [4:0] side_bits;

    assign delay      = instr [12:8] & (5'b11111 >> sideset_count);
    assign side_bits  = instr [12:8] >> (5 - sideset_count);
    assign side_valid = side_en ? instr [12] : (sideset_count != '0);

    assign side_value = side_en ? (side_bits & (5'b11111 >> (6 - sideset_count)))
                                :  side_bits;

endmodule
