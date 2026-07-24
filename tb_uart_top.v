`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2026 08:43:56 PM
// Design Name: 
// Module Name: tb_uart_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_uart_top;
parameter CLK_PER_BIT = 10417;
//clk and reset 

    reg clk;
    reg rst_n;

//tx signals 

    reg tx_start;
    reg [7:0] tx_data;
    wire  tx_active;
    wire tx_done;
    //wire uart_tx;
// rx signals 
    //reg uart_rx;
    wire rx_busy;
    wire rx_done;
    wire [7:0] rx_data;
// loopback
    wire serial_loopback;
    
 // top instantiation 
    uart_top #(.CLK_PER_BIT(CLK_PER_BIT)) top (
        .clk     (clk),
        .rst_n  (rst_n),
        .tx_active (tx_active),
        .tx_start(tx_start),
        .tx_data (tx_data),
        .tx_done (tx_done),
        .uart_tx (serial_loopback),
        .uart_rx (serial_loopback),
        .rx_busy (rx_busy),
        .rx_done (rx_done),
        .rx_data (rx_data)
        
    );
    
    parameter CLK_PERIOD_NS = 10;
    
    initial begin
    
        clk = 1'b0;
    end 
    always #(CLK_PERIOD_NS/2) clk = ~clk;
    
    // reset initial
    
    initial begin 
        rst_n = 1'b0;
        tx_start = 1'b0;
        tx_data = 8'h00;
        repeat (5) @(negedge clk);
            rst_n = 1'b1;
    end 
    
    // transmission stimulus
    
    initial begin
        wait(rst_n == 1'b1);
        
        repeat (5) @(negedge clk);
        
        tx_data = 8'h41;
        tx_start = 1'b1;
        @(negedge clk);
        tx_start = 1'b0;
    end
    
    // ckecking reciever 
    
    initial begin 
        @(posedge rx_done);
        
        if(rx_data == 8'h41) 
            $display("pass: receieved %h", rx_data);
        
        else
            $display("Failed: receieved %h", rx_data);
        #1000;
        $finish;
    
    end
endmodule
