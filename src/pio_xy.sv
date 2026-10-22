module pio_xy (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        exec,
  input  logic        is_set,
  input  logic        is_jmp,
  input  logic [2:0]  arg_hi,
  input  logic [4:0]  arg_lo,
  input  logic        jmp_pin,
  input  logic        osre,

  output logic [31:0] x,
  output logic [31:0] y,
  output logic        jmp_taken
);

  logic cond;

  always_comb begin
    case (arg_hi)
      3'b000: cond = 1'b1;
      3'b001: cond = (x == 32'd0);
      3'b010: cond = (x != 32'd0);
      3'b101: cond = (x != y);
            3'b011: cond = (y == 32'd0);
      3'b100: cond = (y != 32'd0);
      3'b110: cond = (jmp_pin);
      3'b111: cond = (!osre);

      default: cond = 1'b0;
    endcase
  end

  assign jmp_taken = is_jmp && cond;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      x <= 32'd0;
      y <= 32'd0;
    end else if (exec) begin
         if (is_set && arg_hi == 3'b001) x <= {27'd0, arg_lo};
      if (is_set && arg_hi == 3'b010) y <= {27'd0, arg_lo};
      if (is_jmp && arg_hi == 3'b010) x <= x - 32'd1;
      if (is_jmp && arg_hi == 3'b100) y <= y - 32'd1;
    end
  end

endmodule