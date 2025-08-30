// 模约减模块 (针对固定模数8380417优化的Barrett Reduction)
module modular_reduction_fixed #(
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
    output reg  [Q_WIDTH-1:0]    data_out
);

  // 固定模数和预计算的Barrett参数
  localparam [22:0] Q = 23'd8380417;  // 固定模数
  localparam [5:0] K = 6'd24;  // k = ceil(log2(8380417)) + 1 = 24
  localparam [48:0] MU = 49'h200801C;  // μ = floor(2^48 / 8380417)

  // 状态定义
  localparam IDLE = 2'b00;
  localparam COMPUTE = 2'b01;
  localparam FINISH = 2'b10;

  reg [           1:0] state;
  reg [           1:0] cycle_count;

  // 中间结果寄存器
  reg [DATA_WIDTH-1:0] x_reg;
  reg [          47:0] temp1;  // (x>>k) * mu
  reg [          47:0] temp2;  // (temp1>>k) * Q
  reg [          47:0] result;  // 中间结果

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
              // 第1周期: temp1 = (x >> k) * mu
              temp1 <= (x_reg >> K) * MU;
              // temp1 <= (x_reg * MU) >> K;
              cycle_count <= 2'b01;
            end
            2'b01: begin
              // 第2周期: temp2 = (temp1 >> K) * Q
              temp2 <= (temp1 >> K) * Q;
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
          done  <= 1;
          state <= IDLE;
        end
      endcase
    end
  end

endmodule
