module barrett_reduction #(
    parameter DATA_WIDTH = 48,  // 输入数据位宽 (支持到q²级别)
    parameter Q_WIDTH    = 23   // 模数位宽 (精确支持到Dilithium的8380417)
) (
    // 时钟和控制信号
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output reg  done,

    // 数据接口
    input  wire [DATA_WIDTH-1:0] data_in,
    input  wire [   Q_WIDTH-1:0] Q,        // 模数
    output reg  [   Q_WIDTH-1:0] data_out
);

  // 简化状态定义
  localparam IDLE = 2'b00;
  localparam COMPUTE = 2'b01;
  localparam FINISH = 2'b10;

  reg [1:0] state;
  reg [1:0] cycle_count;  // 计算周期计数

  // Barrett参数
  reg [5:0] k;  // k值最大约25，需要6位
  reg [DATA_WIDTH:0] mu;  // μ位宽优化

  // 中间结果寄存器
  reg [DATA_WIDTH-1:0] x_reg;
  reg [DATA_WIDTH+Q_WIDTH-1:0] temp1, temp2;  // 调整到合适位宽
  reg [Q_WIDTH-1:0] result;

  // k值计算
  // k = ceil(log2(Q)) + 1
  function automatic [5:0] calc_k;  // 扩展到6位
    input [Q_WIDTH-1:0] q_val;
    integer i;
    begin
      calc_k = 1;
      for (i = 0; i < Q_WIDTH; i = i + 1) begin
        if (q_val > (1 << i)) calc_k = i + 2;  // ceil(log2(q)) + 1
      end
    end
  endfunction

  // μ值计算
  // μ = floor(2^(2k) / Q)
  function automatic [DATA_WIDTH:0] calc_mu;
    input [Q_WIDTH-1:0] q_val;
    input [5:0] k_val;
    reg [47:0] temp_numerator;
    reg [DATA_WIDTH:0] quotient;  // 商
    begin
      if (q_val == 0) calc_mu = 0;
      else begin
        temp_numerator = (48'h1 << (2 * k_val));
        quotient = 0;
        // 循环减法替代除法
        while (temp_numerator >= q_val) begin
          temp_numerator = temp_numerator - q_val;
          quotient = quotient + 1;
        end
        calc_mu = quotient;
      end
    end
  endfunction


  // 预计算Barrett参数
  always @(*) begin
    k  = calc_k(Q);
    mu = calc_mu(Q, k);
  end

  // 主状态机和数据路径
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      cycle_count <= 0;
      done <= 0;
      data_out <= 0;
      x_reg <= 0;
      temp1 <= 0;
      temp2 <= 0;
      result <= 0;
    end else begin
      case (state)
        IDLE: begin
          done <= 0;
          cycle_count <= 0;
          if (start) begin
            x_reg <= data_in;
            state <= COMPUTE;
          end
        end

        COMPUTE: begin
          case (cycle_count)
            2'b00: begin
              // 第1周期: t1 = x >> k, temp1 = t1 * mu
              temp1 <= (x_reg * mu) >> k;
              cycle_count <= 2'b01;
            end
            2'b01: begin
              // 第2周期: t2 = temp1 >> k, temp2 = t2 * Q
              temp2 <= (temp1 >> k) * Q;
              cycle_count <= 2'b10;
            end
            2'b10: begin
              // 第3周期: r = x - temp2, 条件约减
              result <= x_reg - temp2[Q_WIDTH-1:0];
              cycle_count <= 2'b11;
            end
            2'b11: begin
              // 第4周期: 最终约减和输出
              if (result >= Q) data_out <= result - Q;
              else data_out <= result;
              state <= FINISH;
            end
          endcase
        end

        FINISH: begin
          done  <= 1;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
