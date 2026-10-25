`default_nettype none

module tt_um_kmukhutdinov_protoemu (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  reg [23:0] sr;
  always @(posedge clk or negedge rst_n)
    if (!rst_n)        sr <= 24'd0;
    else if (ui_in[1]) sr <= {sr[22:0], ui_in[0]};

  reg [4:0] wrap_top, wrap_bottom;
  reg [2:0] sideset_count;
  reg       side_en;
  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      wrap_top <= 5'd31; wrap_bottom <= 5'd0; sideset_count <= 3'd0; side_en <= 1'b0;
    end else if (ui_in[3]) begin
      wrap_top <= sr[4:0]; wrap_bottom <= sr[9:5]; sideset_count <= sr[12:10]; side_en <= sr[13];
    end

  wire        tx_pop;
  wire [4:0]  side_out, pc;
  wire [31:0] x, y;

  pio_sm u_sm (
    .clk(clk), .rst_n(rst_n), .clk_en(ui_in[6]),
    .imem_we(ui_in[2]), .imem_waddr(sr[20:16]), .imem_wdata(sr[15:0]),
    .wrap_top(wrap_top), .wrap_bottom(wrap_bottom),
    .sideset_count(sideset_count), .side_en(side_en),
    .tx_empty(ui_in[4]), .tx_pop(tx_pop), .jmp_pin(ui_in[5]),
    .side_out(side_out), .pc(pc), .x(x), .y(y)
  );

  assign uo_out  = {^x, ^y, tx_pop, side_out};
  assign uio_out = {3'b000, pc};
  assign uio_oe  = 8'h1F;

  wire _unused = &{ena, ui_in[7], uio_in, 1'b0};

endmodule