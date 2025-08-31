module tb_modular_reduction;
  reg clk, rst_n, start;
  reg [47:0] data_in;
  wire done;
  wire [22:0] data_out;

  // 实例化被测模块
  modular_reduction dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .done(done),
      .data_in(data_in),
      .data_out(data_out)
  );

  // 时钟生成
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // 测试序列
  initial begin
    $dumpfile("modular_reduction.vcd");
    $dumpvars(0, tb_modular_reduction);

    // 初始化
    rst_n   = 0;
    start   = 0;
    data_in = 0;

    #20;
    rst_n = 1;
    #10;

    // 测试用例1: 输入小于模数
    data_in = 48'd1000000;
    start   = 1;
    #10;
    start = 0;

    // 等待完成
    wait (done);
    $display("Test 1: Input=%d, Output=%d", 1000000, data_out);
    #20;

    // 测试用例2: 输入为8380417 (应该输出0)
    data_in = 48'd8380417;
    start   = 1;
    #10;
    start = 0;

    wait (done);
    $display("Test 2: Input=%d, Output=%d", 8380417, data_out);
    #20;

    // 测试用例3: 输入大于模数
    data_in = 48'd16760834;  // 约等于2*Q
    start   = 1;
    #10;
    start = 0;

    wait (done);
    $display("Test 3: Input=%d, Output=%d", 16760834, data_out);
    #20;

    // 测试用例4: 大数值
    data_in = 48'd70226673278976;  // 接近最大值
    start   = 1;
    #10;
    start = 0;

    wait (done);
    $display("Test 4: Input=%d, Output=%d", data_in, data_out);
    #20;

    $display("All tests completed");
    $finish;
  end

endmodule
