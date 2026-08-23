module counter_tb;

  timeunit 1ns; timeprecision 1ps;

  // Parameters
  localparam time ClkPeriod = 10ns;
  localparam int unsigned WIDTH = 4;

  // DUT inputs
  logic clk_i;
  logic rstn_i;
  logic en_i;

  // DUT outputs
  logic [WIDTH-1:0] count_o;

  // Reference outputs
  logic [WIDTH-1:0] expected_count;

  // Clock generation
  always begin
    #(ClkPeriod / 2);
    clk_i = ~clk_i;
  end

  // DUT instantiation
  counter #(
      .WIDTH(WIDTH)
  ) dut (
      .clk_i(clk_i),
      .rstn_i(rstn_i),
      .en_i(en_i),
      .count_o(count_o)
  );

  // Run a cycle of the counter and compare results
  task automatic compare_results(input logic enable);
    en_i = enable;

    @(posedge clk_i);

    if (rstn_i) begin
      expected_count = '0;
    end else if (enable) begin
      expected_count = expected_count + 1'b1;
    end

    @(negedge clk_i);

    assert (count_o === expected_count)
    else begin
      $fatal(1, "Counter mismatch: expected %0d, got %0d", expected_count, count_o);
    end
  endtask

  // Test sequence
  initial begin

    // Dump waveform
    $dumpfile("build/waves/counter.vcd");
    $dumpvars(0, counter_tb);

    // Initialize inputs and expected outputs
    clk_i = 1'b0;
    rstn_i = 1'b0;
    en_i = 1'b0;
    expected_count = '0;

    // Reset release
    #(ClkPeriod * 3);
    rstn_i = 1'b1;

    // Count enabled
    repeat (5) begin
      run_cycle(1'b1);
    end

    // Count disabled
    repeat (3) begin
      run_cycle(1'b0);
    end

    // Wrap-around condition
    repeat (20) begin
      run_cycle(1'b1);
    end

    // Reset during operation
    rstn_i = 1'b0;
    run_cycle(1'b1);

    rstn_i = 1'b1;
    run_cycle(1'b1);

    $display("PASS: counter_tb");
    $finish;
  end

endmodule
