`ifndef PIO_SVH
`define PIO_SVH

`define PIO_OP_JMP         3'b000
`define PIO_OP_WAIT        3'b001
`define PIO_OP_IN          3'b010
`define PIO_OP_OUT         3'b011
`define PIO_OP_PUSH_PULL   3'b100
`define PIO_OP_MOV         3'b101
`define PIO_OP_IRQ         3'b110
`define PIO_OP_SET         3'b111

`define PIO_COND_ALWAYS    3'b000
`define PIO_COND_NOT_X     3'b001
`define PIO_COND_X_DEC     3'b010
`define PIO_COND_NOT_Y     3'b011
`define PIO_COND_Y_DEC     3'b100
`define PIO_COND_X_NE_Y    3'b101
`define PIO_COND_PIN       3'b110
`define PIO_COND_NOT_OSRE  3'b111

`define PIO_DST_PINS       3'b000
`define PIO_DST_X          3'b001
`define PIO_DST_Y          3'b010
`define PIO_DST_NULL       3'b011
`define PIO_DST_PINDIRS    3'b100
`define PIO_DST_PC         3'b101
`define PIO_DST_ISR        3'b110
`define PIO_DST_EXEC       3'b111

`define PIO_SRC_PINS       3'b000
`define PIO_SRC_X          3'b001
`define PIO_SRC_Y          3'b010
`define PIO_SRC_NULL       3'b011
`define PIO_SRC_ISR        3'b110
`define PIO_SRC_OSR        3'b111

`endif
