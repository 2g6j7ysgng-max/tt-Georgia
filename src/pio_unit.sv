module pio_unit
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
    input               autopull,
    input        [ 4:0] pull_thresh,
    input        [ 2:0] in_base,
    input               in_shift_right,
    input               autopush,
    input        [ 4:0] push_thresh,

    input               tx_push,
    input        [31:0] tx_wdata,
    output              tx_full,

    input               rx_pop,
    output       [31:0] rx_rdata,
    output              rx_empty,

    input        [ 7:0] in_pins,
    input               jmp_pin,

    output       [ 7:0] pins,
    output       [ 4:0] pc,
    output       [31:0] x,
    output       [31:0] y
);

    //------------------------------------------------------------------------

    logic        tx_empty;
    logic [31:0] tx_data;
    logic        tx_pop;

    pio_fifo i_tx_fifo
    (
        .clk        ( clk      ),
        .rst        ( rst      ),
        .push       ( tx_push  ),
        .write_data ( tx_wdata ),
        .pop        ( tx_pop   ),
        .read_data  ( tx_data  ),
        .empty      ( tx_empty ),
        .full       ( tx_full  )
    );

    //------------------------------------------------------------------------

    logic        rx_full;
    logic        rx_push;
    logic [31:0] rx_data;

    pio_fifo i_rx_fifo
    (
        .clk        ( clk      ),
        .rst        ( rst      ),
        .push       ( rx_push  ),
        .write_data ( rx_data  ),
        .pop        ( rx_pop   ),
        .read_data  ( rx_rdata ),
        .empty      ( rx_empty ),
        .full       ( rx_full  )
    );

    //------------------------------------------------------------------------

    pio_sm i_sm
    (
        .clk             ( clk             ),
        .rst             ( rst             ),
        .clk_en          ( clk_en          ),
        .imem_we         ( imem_we         ),
        .imem_waddr      ( imem_waddr      ),
        .imem_wdata      ( imem_wdata      ),
        .wrap_top        ( wrap_top        ),
        .wrap_bottom     ( wrap_bottom     ),
        .sideset_count   ( sideset_count   ),
        .side_en         ( side_en         ),
        .side_base       ( side_base       ),
        .out_base        ( out_base        ),
        .out_count       ( out_count       ),
        .out_shift_right ( out_shift_right ),
        .autopull        ( autopull        ),
        .pull_thresh     ( pull_thresh     ),
        .in_base         ( in_base         ),
        .in_shift_right  ( in_shift_right  ),
        .autopush        ( autopush        ),
        .push_thresh     ( push_thresh     ),
        .tx_empty        ( tx_empty        ),
        .tx_data         ( tx_data         ),
        .tx_pop          ( tx_pop          ),
        .rx_full         ( rx_full         ),
        .rx_push         ( rx_push         ),
        .rx_data         ( rx_data         ),
        .in_pins         ( in_pins         ),
        .jmp_pin         ( jmp_pin         ),
        .pins            ( pins            ),
        .pc              ( pc              ),
        .x               ( x               ),
        .y               ( y               )
    );

endmodule
