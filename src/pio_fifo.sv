module pio_fifo
# (
    parameter width = 32,
              depth = 4
)
(
    input                      clk,
    input                      rst,

    input                      push,
    input        [width - 1:0] write_data,
    input                      pop,
    output       [width - 1:0] read_data,

    output logic               empty,
    output logic               full
);

    localparam pointer_width = $clog2 (depth);

    localparam [pointer_width - 1:0] max_ptr = pointer_width' (depth - 1);

    //------------------------------------------------------------------------

    logic do_push;
    logic do_pop;

    assign do_push = push & ~ full;
    assign do_pop  = pop  & ~ empty;

    //------------------------------------------------------------------------

    logic [pointer_width - 1:0] wr_ptr;
    logic [pointer_width - 1:0] rd_ptr;
    logic [pointer_width - 1:0] wr_ptr_d;
    logic [pointer_width - 1:0] rd_ptr_d;
    logic                       empty_d;
    logic                       full_d;

    always_comb
    begin
        wr_ptr_d = wr_ptr;
        rd_ptr_d = rd_ptr;

        if (do_push)
            wr_ptr_d = (wr_ptr == max_ptr) ? '0 : wr_ptr + 1'b1;

        if (do_pop)
            rd_ptr_d = (rd_ptr == max_ptr) ? '0 : rd_ptr + 1'b1;

        case ({ do_push, do_pop })
            2'b10:
            begin
                empty_d = 1'b0;
                full_d  = (wr_ptr_d == rd_ptr);
            end

            2'b01:
            begin
                empty_d = (rd_ptr_d == wr_ptr);
                full_d  = 1'b0;
            end

            default:
            begin
                empty_d = empty;
                full_d  = full;
            end
        endcase
    end

    //------------------------------------------------------------------------

    always_ff @ (posedge clk or posedge rst)
        if (rst)
        begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            empty  <= 1'b1;
            full   <= 1'b0;
        end
        else
        begin
            wr_ptr <= wr_ptr_d;
            rd_ptr <= rd_ptr_d;
            empty  <= empty_d;
            full   <= full_d;
        end

    //------------------------------------------------------------------------

    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk)
        if (do_push)
            data [wr_ptr] <= write_data;

    assign read_data = data [rd_ptr];

endmodule
