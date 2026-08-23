module counter_tb;

  timeunit 1ns; timeprecision 1ps;

  // Parameters
  localparam time ClkPeriod = 10ns;
  localparam int unsigned WIDTH = 4;

  // DUT inputs
  logic clk_i;
  logic rstn_i;
  logic en_i;
  logic up_count_i;
  logic load_i;
  logic [WIDTH-1:0] load_value_i;

  // DUT outputs
  logic [WIDTH-1:0] count_o;

  // Reference outputs
  logic [WIDTH-1:0] expected_count;

  // Clock generation
  always begin
    #(ClkPeriod / 2);
    clk_i <= ~clk_i;
  end

  // DUT instantiation
  counter #(
      .WIDTH(WIDTH)
  ) dut (
      .clk_i(clk_i),
      .rstn_i(rstn_i),
      .en_i(en_i),
      .up_count_i(up_count_i),
      .load_i(load_i),
      .load_value_i(load_value_i),
      .count_o(count_o)
  );

  // Run a cycle of the counter and compare results
  task automatic run_cycle(input logic enable, input logic up_count, input logic load,
                           input logic [WIDTH-1:0] load_value);
    en_i = enable;
    up_count_i = up_count;
    load_i = load;
    load_value_i = load_value;

    @(posedge clk_i);

    if (!rstn_i) begin
      expected_count = '0;
    end else if (load) begin
      expected_count = load_value;
    end else if (enable) begin
      if (up_count) begin
        expected_count = expected_count + 1'b1;
      end else begin
        expected_count = expected_count - 1'b1;
      end
    end

    @(negedge clk_i);
    assert (count_o == expected_count)
    else begin
      $display("================================");
      $display("FAIL: counter_tb");
      $display("================================");
      $fatal(1, "Counter mismatch: expected %0d, got %0d", expected_count, count_o);
    end
  endtask

  // Test sequence
  initial begin

    // Dump waveform
    $dumpfile("counter.vcd");
    $dumpvars(0, counter_tb);

    // Initialize inputs and expected outputs
    clk_i = 1'b0;
    rstn_i = 1'b0;
    en_i = 1'b0;
    up_count_i = 1'b0;
    load_i = 1'b0;
    load_value_i = '0;
    expected_count = '0;

    // Reset release
    #(ClkPeriod * 3);
    rstn_i = 1'b1;

    // Count enabled (upwards)
    repeat (5) begin
      run_cycle(1'b1, 1'b1, 1'b0, '0);
    end

    // Count disabled
    repeat (3) begin
      run_cycle(1'b0, 1'b0, 1'b0, '0);
    end

    // Count enabled (downwards)
    repeat (5) begin
      run_cycle(1'b1, 1'b0, 1'b0, '0);
    end

    // Wrap-around condition (overflow)
    repeat (20) begin
      run_cycle(1'b1, 1'b1, 1'b0, '0);
    end

    // Wrap-around condition (underflow)
    repeat (20) begin
      run_cycle(1'b1, 1'b0, 1'b0, '0);
    end

    // Reset during operation
    rstn_i = 1'b0;
    run_cycle(1'b1, 1'b0, 1'b0, '0);
    rstn_i = 1'b1;

    // Load value while enable is high
    run_cycle(1'b1, 1'b1, 1'b1, 4'hA);

    #(ClkPeriod * 3);

    $display("================================");
    $display("PASS: counter_tb");
    $display("================================");
    $finish;
  end

endmodule
