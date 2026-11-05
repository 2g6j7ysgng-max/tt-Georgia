`include "pio.svh"

module pio_sm
(
    input               clk,
    input               rst,
    input               clk_en,

    input               imem_we,
    input        [ 4:0] imem_waddr,
    input        [15:0] imem_wdata,

    input        [ 4:0] wrap_top,
    input        [ 4:0] wrap_bottom,
    input        [ 2:0] sideset_count,
    input               side_en,
    input        [ 2:0] side_base,
    input        [ 2:0] out_base,
    input        [ 3:0] out_count,
    input               out_shift_right,
    input        [ 4:0] pull_thresh,
    input        [ 2:0] in_base,
    input               in_shift_right,
    input        [ 4:0] push_thresh,

    input               tx_empty,
    input        [31:0] tx_data,
    output              tx_pop,

    input               rx_full,
    output              rx_push,
    output       [31:0] rx_data,

    input        [ 7:0] in_pins,
    input               jmp_pin,

    output       [ 7:0] pins,
    output       [ 4:0] pc,
    output       [31:0] x,
    output       [31:0] y
);

    //------------------------------------------------------------------------

    logic [15:0] imem [0:31];
    logic [15:0] instr;

    always_ff @ (posedge clk)
        if (imem_we)
            imem [imem_waddr] <= imem_wdata;

    assign instr = imem [pc];

    //------------------------------------------------------------------------

    logic       is_jmp;
    logic       is_wait;
    logic       is_in;
    logic       is_out;
    logic       is_push;
    logic       is_pull;
    logic       is_mov;
    logic       is_irq;
    logic       is_set;

    logic [4:0] delay;
    logic       side_valid;
    logic [4:0] side_value;
    logic [2:0] arg_hi;
    logic [4:0] arg_lo;

    pio_decode i_decode
    (
        .instr         ( instr         ),
        .sideset_count ( sideset_count ),
        .side_en       ( side_en       ),
        .is_jmp        ( is_jmp        ),
        .is_wait       ( is_wait       ),
        .is_in         ( is_in         ),
        .is_out        ( is_out        ),
        .is_push       ( is_push       ),
        .is_pull       ( is_pull       ),
        .is_mov        ( is_mov        ),
        .is_irq        ( is_irq        ),
        .is_set        ( is_set        ),
        .delay         ( delay         ),
        .side_valid    ( side_valid    ),
        .side_value    ( side_value    ),
        .arg_hi        ( arg_hi        ),
        .arg_lo        ( arg_lo        )
    );

    //------------------------------------------------------------------------

    logic issue;
    logic exec;
    logic stall;
    logic pull_stall;
    logic push_stall;
    logic jmp_taken;

    assign stall = pull_stall | push_stall;
    assign exec  = issue & ~ stall;

    //------------------------------------------------------------------------

    pio_pc i_pc
    (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .clk_en        ( clk_en        ),
        .stall         ( stall         ),
        .jmp_taken     ( jmp_taken     ),
        .jmp_target    ( arg_lo        ),
        .wrap_top      ( wrap_top      ),
        .wrap_bottom   ( wrap_bottom   ),
        .instr_delay   ( delay         ),
        .pc            ( pc            ),
        .issue         ( issue         )
    );

    //------------------------------------------------------------------------

    logic [31:0] osr;
    logic [31:0] out_data;
    logic        osre;

    pio_osr i_osr
    (
        .clk           ( clk             ),
        .rst           ( rst             ),
        .exec          ( exec            ),
        .is_out        ( is_out          ),
        .is_pull       ( is_pull         ),
        .arg_lo        ( arg_lo          ),
        .pull_ifempty  ( arg_hi [1]      ),
        .pull_block    ( arg_hi [0]      ),
        .shift_right   ( out_shift_right ),
        .pull_thresh   ( pull_thresh     ),
        .tx_empty      ( tx_empty        ),
        .tx_data       ( tx_data         ),
        .x             ( x               ),
        .osr           ( osr             ),
        .osr_cnt       (                 ),
        .out_data      ( out_data        ),
        .osre          ( osre            ),
        .stall         ( pull_stall      ),
        .tx_pop        ( tx_pop          )
    );

    //------------------------------------------------------------------------

    logic [15:0] in_rot;
    logic [31:0] in_word;

    assign in_rot  = { in_pins, in_pins } >> in_base;
    assign in_word = { 24'b0, in_rot [7:0] };

    pio_isr i_isr
    (
        .clk           ( clk             ),
        .rst           ( rst             ),
        .exec          ( exec            ),
        .is_in         ( is_in           ),
        .is_push       ( is_push         ),
        .arg_hi        ( arg_hi          ),
        .arg_lo        ( arg_lo          ),
        .push_iffull   ( arg_hi [1]      ),
        .push_block    ( arg_hi [0]      ),
        .shift_right   ( in_shift_right  ),
        .push_thresh   ( push_thresh     ),
        .in_pins       ( in_word         ),
        .x             ( x               ),
        .y             ( y               ),
        .osr           ( osr             ),
        .rx_full       ( rx_full         ),
        .isr           (                 ),
        .isr_cnt       (                 ),
        .stall         ( push_stall      ),
        .rx_push       ( rx_push         ),
        .rx_data       ( rx_data         )
    );

    //------------------------------------------------------------------------

    pio_xy i_xy
    (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .exec          ( exec          ),
        .is_set        ( is_set        ),
        .is_jmp        ( is_jmp        ),
        .is_out        ( is_out        ),
        .arg_hi        ( arg_hi        ),
        .arg_lo        ( arg_lo        ),
        .out_data      ( out_data      ),
        .jmp_pin       ( jmp_pin       ),
        .osre          ( osre          ),
        .x             ( x             ),
        .y             ( y             ),
        .jmp_taken     ( jmp_taken     )
    );

    //------------------------------------------------------------------------

    logic       out_pins_we;
    logic       side_we;
    logic [2:0] side_count;

    assign out_pins_we = exec  & is_out & (arg_hi == `PIO_DST_PINS);
    assign side_we     = issue & side_valid;
    assign side_count  = sideset_count - { 2'b0, side_en };

    pio_pins i_pins
    (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .out_we        ( out_pins_we   ),
        .out_data      ( out_data      ),
        .out_base      ( out_base      ),
        .out_count     ( out_count     ),
        .side_we       ( side_we       ),
        .side_value    ( side_value    ),
        .side_base     ( side_base     ),
        .side_count    ( side_count    ),
        .pins          ( pins          )
    );

endmodule
