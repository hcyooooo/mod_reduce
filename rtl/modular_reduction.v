// 模约减模块 (针对固定模数8380417优化的Barrett Reduction，无DSP版)
module modular_reduction #(
    parameter DATA_WIDTH = 48,  // 输入数据位宽
    parameter Q_WIDTH    = 23   // 模数位宽
) (
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    output reg  done,
    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [Q_WIDTH-1:0]    data_out
);

  // 固定模数和预计算的Barrett参数
  localparam [22:0] Q = 23'd8380417;      // 固定模数
  localparam [5:0]  K = 6'd24;            // k = ceil(log2(Q)) + 1 = 24

  // 状态定义
  localparam IDLE    = 2'b00;
  localparam COMPUTE = 2'b01;
  localparam FINISH  = 2'b10;

  reg [1:0] state;
  reg [1:0] cycle_count;

  // 中间寄存器
  reg [DATA_WIDTH-1:0] x_reg;
  reg [47:0] temp1;  // (x>>K)*MU 替代乘法
  reg [47:0] temp2;  // (temp1>>K)*Q 替代乘法
  reg [47:0] result;

  // MU = 0x200801C = 28位
  // 分解为移位加法: MU = 2^25 + 2^21 + 2^20 + 2^2 + 2^1 + 1
  function [47:0] mul_mu;
    input [21:0] x;  // x >> K后最大22位
    begin
      mul_mu = (x << 25) + (x << 21) + (x << 20) + (x << 2) + (x << 1) + x;
    end
  endfunction

  // Q = 8380417 = 2^23 + 1
  function [47:0] mul_q;
    input [23:0] x;
    begin
      mul_q = (x << 23) + x;
    end
  endfunction

  // 主状态机
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
              // 第1周期: temp1 = (x >> K) * MU (移位加法实现)
              temp1 <= mul_mu(x_reg >> K);
              cycle_count <= 2'b01;
            end
            2'b01: begin
              // 第2周期: temp2 = (temp1 >> K) * Q (移位加法实现)
              temp2 <= mul_q(temp1 >> K);
              cycle_count <= 2'b10;
            end
            2'b10: begin
              // 第3周期: result = x - temp2
              result <= x_reg - temp2;
              cycle_count <= 2'b11;
            end
            2'b11: begin
              // 第4周期: 最终条件约减
              if (result >= Q) begin
                result <= result - Q;
              end else begin
                data_out <= result;
                state <= FINISH;
              end
            end
          endcase
        end

        FINISH: begin
          done <= 1;
          state <= IDLE;
        end
      endcase
    end
  end
endmodule
