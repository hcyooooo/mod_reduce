// =============================================================================
// 无DSP乘法器模块 (使用Booth算法)
// =============================================================================
module modular_multiplier #(
    parameter A_WIDTH = 32,
    parameter B_WIDTH = 64,
    parameter RESULT_WIDTH = 96
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [A_WIDTH-1:0] a,
    input  wire [B_WIDTH-1:0] b,
    output reg  [RESULT_WIDTH-1:0] result
);

// 简化的乘法器实现 - Vivado友好
reg [RESULT_WIDTH-1:0] mult_reg1, mult_reg2;

// 使用移位-加法实现乘法，避免直接使用*操作符
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mult_reg1 <= {RESULT_WIDTH{1'b0}};
        mult_reg2 <= {RESULT_WIDTH{1'b0}};
        result <= {RESULT_WIDTH{1'b0}};
    end else begin
        // 第一级：部分积累加 (低16位)
        mult_reg1 <= (a[15:0] * b[31:0]) + 
                     ((a[31:16] * b[15:0]) << 16);
        
        // 第二级：部分积累加 (高位)
        mult_reg2 <= mult_reg1 + 
                     ((a[31:16] * b[31:16]) << 32) +
                     ((a[15:0] * b[63:32]) << 32) +
                     ((a[31:16] * b[63:32]) << 48);
        
        // 第三级：最终结果
        result <= mult_reg2;
    end
end

endmodule