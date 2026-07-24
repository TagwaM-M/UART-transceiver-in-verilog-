`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2026 11:39:13 AM
// Design Name: 
// Module Name: tb_uart_tx
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


module tb_uart_tx;
parameter CLK_PERIOD_NS = 10;
parameter CLK_PER_BIT = 10417;
parameter BIT_PERIOD = 9600;

reg clk;
reg rst_n;
reg start;
reg [7:0] tx_data;
wire tx_serial_out;
wire tx_active;
wire tx_done;

//rx declaration 

// tx instantiation
 uart_tx #(.CLK_PER_BIT(CLK_PER_BIT)) ut  (.clk(clk),
    .rst_n(rst_n),
    .start(start),
    .tx_data(tx_data),
    .tx_serial_out(tx_serial_out),
    .tx_active(tx_active),
    .done(tx_done)
 );
 // rx instantiation 
  initial clk = 0;
 always 
    #(CLK_PERIOD_NS/2) clk = ~clk;
    
    initial 
        begin
        rst_n = 0;
        start = 0;
        tx_data = 8'h00;
        repeat (5) @(negedge clk);
            rst_n = 1;
              
        repeat(5)    @(negedge clk);
            tx_data <= 8'h41;
            start <= 1'b1;
            @(negedge clk);
            start <= 0;
         #1_100_000;
         $display("transmission done");
         $finish;
        end
endmodule
