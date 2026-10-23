`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.10.2026 16:06:54
// Design Name: 
// Module Name: pio_pc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pio_pc (
  input  logic       clk,
  input  logic       rst_n,

  input  logic       clk_en,       // шаг от делителя
  input  logic       stall,        // инструкция застряла
  input  logic       jmp_taken,    //  jmp / mov pc / out pc
  input  logic [4:0] jmp_target,   //  прыгать
  input  logic [4:0] wrap_top,     // wrap
  input  logic [4:0] wrap_bottom,
  input  logic [4:0] instr_delay,  // задержка [12:8]

  output logic [4:0] pc,
    output logic       issue
);

  logic [4:0] pc_next;
  logic [4:0] delay_cnt, delay_cnt_next;


  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pc        <= 5'd0;
      delay_cnt <= 5'd0;
    end else begin
      pc        <= pc_next;
      delay_cnt <= delay_cnt_next;
    end
    
  end
  always_comb begin
   
    pc_next        = pc;
    delay_cnt_next = delay_cnt;

 
    if (!clk_en) begin
      pc_next        = pc;
      delay_cnt_next = delay_cnt;
    end

 
    else if (delay_cnt != 5'd0) begin
      pc_next        = pc;
      delay_cnt_next = delay_cnt - 5'd1;
    end

    else if (stall) begin
     pc_next        = pc;
    delay_cnt_next = delay_cnt;
    end

    else if (jmp_taken) begin
      pc_next        = jmp_target;
      delay_cnt_next = instr_delay;
    end

    else if (pc == wrap_top) begin
      pc_next        = wrap_bottom;
      delay_cnt_next = instr_delay;
    end

   
    else begin
      pc_next        = pc + 5'd1;
      delay_cnt_next = instr_delay;
    end

  end  
    assign issue = clk_en && (delay_cnt == 5'd0);

endmodule