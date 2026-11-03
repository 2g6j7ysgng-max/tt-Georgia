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

    input               tx_empty,
    output              tx_pop,
    input               jmp_pin,

    output logic [ 4:0] side_out,
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
    logic jmp_taken;

    assign stall  = is_pull & arg_hi [0] & tx_empty;
    assign exec   = issue & ~ stall;
    assign tx_pop = exec & is_pull & ~ tx_empty;

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

    pio_xy i_xy
    (
        .clk           ( clk           ),
        .rst           ( rst           ),
        .exec          ( exec          ),
        .is_set        ( is_set        ),
        .is_jmp        ( is_jmp        ),
        .arg_hi        ( arg_hi        ),
        .arg_lo        ( arg_lo        ),
        .jmp_pin       ( jmp_pin       ),
        .osre          ( 1'b1          ),
        .x             ( x             ),
        .y             ( y             ),
        .jmp_taken     ( jmp_taken     )
    );

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            side_out <= '0;
        else if (issue & side_valid)
            side_out <= side_value;

endmodule
