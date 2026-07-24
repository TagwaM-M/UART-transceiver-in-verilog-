`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/13/2026 11:17:42 AM
// Design Name: 
// Module Name: tb_uart_rx
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


module tb_uart_rx;
parameter CLK_PERIOD_NS = 10;
parameter CLK_PER_BIT = 10417;
parameter BIT_PERIOD = 9600;

reg clk;
reg rst_n;
//rx declaration 

reg rx_serial;
wire rx_busy;
wire rx_done;
wire [7:0] rx_out;
localparam integer BIT_TIME = 104170;
 // rx instantiation 
 uart_rx #(.CK_PER_BIT(CLK_PER_BIT)) rt  (.clk(clk),
    .rst_n(rst_n),
    .rx_out(rx_out),
    .rx_serial(rx_serial),
    .rx_busy(rx_busy),
    .rx_done(rx_done)
 );
  initial clk = 0;
 always 
    #(CLK_PERIOD_NS/2) clk = ~clk;
   task send_bit(input b);
        begin
            rx_serial = b;
            #BIT_TIME;
        end
   endtask
   task send_byte(input [7:0] data);
        integer i;
        begin
            send_bit(0);
            for (i = 0; i < 8; i = i + 1) 
                send_bit(data[i]);
            send_bit(1'b1);
        end
   endtask
   initial 
        begin
            rst_n = 0;
            rx_serial = 1;
            repeat (5) @(negedge clk);
                rst_n = 1;
            repeat (5) @(negedge clk);
            fork
                send_byte(8'h41);
                begin
                     @(posedge rx_done);
                        if (rx_out == 8'h41)
                             $display("pass: recieved %h", rx_out);
                        else 
                            $display("fail: recieved %h", rx_out);
                 end
              join
                #100000;
                $finish;
                
        end

endmodule
