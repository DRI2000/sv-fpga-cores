module counter #(
    parameter int unsigned WIDTH = 8
) (
    input  logic             clk_i,
    input  logic             rstn_i,
    input  logic             en_i,
    output logic [WIDTH-1:0] count_o
);

  timeunit 1ns; timeprecision 1ps;

  always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
      count_o <= '0;
    end else if (en_i) begin
      count_o <= count_o + 1'b1;
    end
  end

endmodule
