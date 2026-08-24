module sync_fifo_tb;

  timeunit 1ns; timeprecision 1ps;

  // Parameters
  localparam time ClkPeriod = 10ns;
  localparam int unsigned DataWidth = 8;
  localparam int unsigned FifoDepth = 4;

  // DUT inputs
  logic clk_i;
  logic rstn_i;
  logic wr_en_i;
  logic rd_en_i;
  logic [DataWidth-1:0] wr_data_i;

  // DUT outputs
  logic [DataWidth-1:0] rd_data_o;
  logic full_o;
  logic empty_o;

  // Reference signals
  logic [DataWidth-1:0] fifo_mem[$];
  logic [DataWidth-1:0] expected_rd_data;

  // Clock generation
  always begin
    #(ClkPeriod / 2);
    clk_i <= ~clk_i;
  end

  // DUT instantiation
  sync_fifo #(
      .DataWidth(DataWidth),
      .FifoDepth(FifoDepth)
  ) dut (
      .clk_i(clk_i),
      .rstn_i(rstn_i),
      .wr_en_i(wr_en_i),
      .rd_en_i(rd_en_i),
      .wr_data_i(wr_data_i),
      .rd_data_o(rd_data_o),
      .full_o(full_o),
      .empty_o(empty_o)
  );

  // Run a cycle and compare data outputs (FIFO model)
  task automatic run_cycle(input logic wr_en, input logic rd_en,
                           input logic [DataWidth-1:0] wr_data);
    wr_en_i   = wr_en;
    rd_en_i   = rd_en;
    wr_data_i = wr_data;

    @(posedge clk_i);

    if (!rstn_i) begin
      expected_rd_data = '0;
      fifo_mem.delete();
    end

    if (rd_en & !(fifo_mem.size() == 0)) begin
      expected_rd_data = fifo_mem.pop_front();
    end

    if (wr_en & (fifo_mem.size() < FifoDepth)) begin
      fifo_mem.push_back(wr_data);
    end

    @(negedge clk_i);
    assert (rd_data_o == expected_rd_data)
    else begin
      $display("================================");
      $display("FAIL: sync_fifo_tb");
      $display("================================");
      $fatal(1, "Data output mismatch: expected %0d, got %0d", expected_rd_data, rd_data_o);
    end
  endtask

  // Full and empty assertions
  always begin
    @(negedge clk_i);
    if (rstn_i) begin
      assert (full_o == (fifo_mem.size() == FifoDepth))
      else begin
        $display("================================");
        $display("FAIL: sync_fifo_tb");
        $display("================================");
        $fatal(1, "Full flag mismatch: expected %0d, got %0d", (fifo_mem.size() == FifoDepth),
               full_o);
      end

      assert (empty_o == (fifo_mem.size() == 0))
      else begin
        $display("================================");
        $display("FAIL: sync_fifo_tb");
        $display("================================");
        $fatal(1, "Empty flag mismatch: expected %0d, got %0d", (fifo_mem.size() == 0), empty_o);
      end
    end
  end

  // Test sequence
  initial begin

    // Dump waveform
    $dumpfile("sync_fifo.vcd");
    $dumpvars(0, sync_fifo_tb);

    // Initialize inputs and expected outputs
    clk_i = 1'b0;
    rstn_i = 1'b0;
    wr_en_i = 1'b0;
    rd_en_i = 1'b0;
    wr_data_i = '0;
    fifo_mem = '{default: '0};
    expected_rd_data = '0;

    // Reset release
    #(ClkPeriod * 3);
    rstn_i = 1'b1;

    // Write data, consume all data and try to read from empty FIFO
    repeat (FifoDepth / 2) begin
      run_cycle(1'b1, 1'b0, DataWidth'($urandom_range(0, 2 ** DataWidth - 1)));
    end

    repeat ((FifoDepth / 2) + 1) begin
      run_cycle(1'b0, 1'b1, '0);
    end

    // Write until full and try to write to full FIFO
    repeat (FifoDepth + 1) begin
      run_cycle(1'b1, 1'b0, DataWidth'($urandom_range(0, 2 ** DataWidth - 1)));
    end

    // Read until empty and try to write and read simultaneously
    repeat (FifoDepth) begin
      run_cycle(1'b0, 1'b1, '0);
    end
    run_cycle(1'b1, 1'b1, DataWidth'($urandom_range(0, 2 ** DataWidth - 1)));

    #(ClkPeriod * 3);

    $display("================================");
    $display("PASS: sync_fifo_tb");
    $display("================================");
    $finish;
  end

endmodule
