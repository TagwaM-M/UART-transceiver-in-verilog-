`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2026 08:29:12 PM
// Design Name: 
// Module Name: uart_top
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


module uart_top #(parameter CLK_PER_BIT = 10417) (
    //clk and reset 
    input clk,
    input rst_n,
    
    //tx signals 
    input tx_start,
    input [7:0] tx_data,
    output tx_active,
    output tx_done,
    output uart_tx,
    
    //rx signals 
    
    input uart_rx,
    output rx_busy,
    output rx_done,
    output [7:0] rx_data

    );
    
    // uart_tx instantiation 
    uart_tx #(.CK_PER_BIT(CLK_PER_BIT)) utx  (.clk(clk),
    .rst_n(rst_n),
    .start(tx_start),
    .tx_data(tx_data),
    .tx_serial_out(uart_tx),
    .tx_active(tx_active),
    .done(tx_done)
 );
 
    // uart_rx instantiation
    uart_rx #(.CK_PER_BIT(CLK_PER_BIT)) rt  (.clk(clk),
    .rst_n(rst_n),
    .rx_out(rx_data),
    .rx_serial(uart_rx),
    .rx_busy(rx_busy),
    .rx_done(rx_done)
 );
    
endmodule
