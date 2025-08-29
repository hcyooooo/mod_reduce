module barrett_reduction_tb;
  parameter DATA_WIDTH = 48;
  parameter Q_WIDTH = 23;

  reg clk, rst_n, start;
  reg [DATA_WIDTH-1:0] data_in;
  reg [Q_WIDTH-1:0] Q;
  wire [Q_WIDTH-1:0] data_out;
  wire done;

  barrett_reduction #(
      .DATA_WIDTH(DATA_WIDTH),
      .Q_WIDTH(Q_WIDTH)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .start(start),
      .done(done),
      .data_in(data_in),
      .Q(Q),
      .data_out(data_out)
  );

  // 时钟生成
  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst_n = 0;
    start = 0;
    data_in = 0;
    Q = 3329;

    #10 rst_n = 1;

    // 测试1: Kyber模数
    #10 data_in = 32'h10000;
    Q = 3329;
    start = 1;
    #10 start = 0;
    wait (done);
    $display("Kyber Test: %d mod %d = %d", 32'h10000, 3329, data_out);

    // 测试2: Dilithium模数  
    #20 data_in = 32'h1000000;
    Q = 8380417;
    start = 1;
    #10 start = 0;
    wait (done);
    $display("Dilithium Test: %d mod %d = %d", 32'h1000000, 8380417, data_out);

    // 测试3: NTRU模数
    #20 data_in = 10000;
    Q = 4591;
    start = 1;
    #10 start = 0;
    wait (done);
    $display("NTRU Test: %d mod %d = %d", 10000, 4591, data_out);

    #20 $finish;
  end

endmodule
