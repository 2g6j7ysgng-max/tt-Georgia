module pio_pins
# (
    parameter n_pins = 8,
              w_base = $clog2 (n_pins),
              w_cnt  = $clog2 (n_pins + 1)
)
(
    input                       clk,
    input                       rst,

    input                       out_we,
    input        [        31:0] out_data,
    input        [w_base - 1:0] out_base,
    input        [w_cnt  - 1:0] out_count,

    input                       side_we,
    input        [         4:0] side_value,
    input        [w_base - 1:0] side_base,
    input        [         2:0] side_count,

    output logic [n_pins - 1:0] pins
);

    logic [n_pins - 1:0] out_mask;
    logic [n_pins - 1:0] out_val;
    logic [n_pins - 1:0] side_mask;
    logic [n_pins - 1:0] side_val;

    assign out_mask  = ~ ({ n_pins { 1'b1 } } << out_count ) << out_base;
    assign side_mask = ~ ({ n_pins { 1'b1 } } << side_count) << side_base;

    assign out_val   = out_data [n_pins - 1:0] << out_base;
    assign side_val  = n_pins' (side_value)    << side_base;

    //------------------------------------------------------------------------

    logic [n_pins - 1:0] pins_d;

    always_comb
    begin
        pins_d = pins;

        if (out_we)
            pins_d = (pins_d & ~ out_mask ) | (out_val  & out_mask );

        if (side_we)
            pins_d = (pins_d & ~ side_mask) | (side_val & side_mask);
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            pins <= '0;
        else
            pins <= pins_d;

endmodule