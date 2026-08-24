module sync_fifo #(
    parameter int unsigned DataWidth = 8,
    parameter int unsigned FifoDepth = 8
) (
    input logic clk_i,
    input logic rstn_i,
    input logic wr_en_i,
    input logic rd_en_i,
    input logic [DataWidth-1:0] wr_data_i,
    output logic [DataWidth-1:0] rd_data_o,
    output logic full_o,
    output logic empty_o
);

  timeunit 1ns; timeprecision 1ps;

  localparam int unsigned PtrWidth = $clog2(FifoDepth);

  logic [DataWidth-1:0] fifo_mem[FifoDepth];
  logic [PtrWidth:0] wr_ptr;
  logic [PtrWidth:0] rd_ptr;

  // Write process
  always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
      wr_ptr   <= '0;
      fifo_mem <= '{default: '0};
    end else if (wr_en_i & ~full_o) begin
      fifo_mem[wr_ptr[PtrWidth-1:0]] <= wr_data_i;
      wr_ptr <= wr_ptr + 1;
    end
  end

  // Read process
  always_ff @(posedge clk_i) begin
    if (!rstn_i) begin
      rd_ptr <= '0;
      rd_data_o <= '0;
    end else if (rd_en_i & ~empty_o) begin
      rd_data_o <= fifo_mem[rd_ptr[PtrWidth-1:0]];
      rd_ptr <= rd_ptr + 1;
    end
  end

  // Full and empty conditions
  assign full_o  = (wr_ptr[PtrWidth-1:0] == rd_ptr[PtrWidth-1:0]) &
                   (wr_ptr[PtrWidth] != rd_ptr[PtrWidth]);
  assign empty_o = (wr_ptr == rd_ptr);

endmodule
