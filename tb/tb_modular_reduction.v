// 简化测试模块
module barrett_reduction_tb;
    parameter DATA_WIDTH = 32;
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
        clk = 0; rst_n = 0; start = 0;
        data_in = 0; Q = 8380417;
        
        #10 rst_n = 1;
        
        // 测试1: 大数约减
        #10 data_in = 10000000; start = 1;
        #10 start = 0;
        wait(done);
        $display("Test 1: %d mod %d = %d", 32'h10000, 3329, data_out);
        
        // // 测试2: 小数
//         #20 data_in = 1000; start = 1; 
//         #10 start = 0;
//         wait(done);
//         $display("Test 2: %d mod %d = %d", 1000, 3329, data_out);
        
        #20 $finish;
    end
    
endmodule