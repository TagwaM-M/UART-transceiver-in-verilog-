`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2026 04:34:40 PM
// Design Name: 
// Module Name: uart_rx
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


module uart_rx #(parameter CK_PER_BIT = 10417)(
    input clk,
    input rst_n,
    input rx_serial,
    output reg rx_done,
    output reg rx_busy,
    output reg [7:0] rx_out

    );
    
    //tick generation 
    localparam COUNTER_SIZE = $clog2(CK_PER_BIT);  
    reg [COUNTER_SIZE-1:0] counter;
    reg baud_tick;
    reg sync1, sync2;
    // synchronizing using 2 ff
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            sync1 <= 1;
            sync2 <= 1;  
        end else begin 
            sync1 <= rx_serial;
            sync2 <= sync1;
        end
    end
    // tick generation using counter
    always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin
            counter <= 0;
            baud_tick <= 1'b0;
        end else if (!rx_busy) begin
            counter <= 0;
            baud_tick <= 1'b0;
        end else begin 
            if (counter == CK_PER_BIT -1) begin
                counter <= 0;
                baud_tick <= 1'b1;
            end else begin 
                counter <= counter + 1'b1;
                baud_tick <= 1'b0;
            end
        end
    end
    //edge detection 
    reg rx_prev;
    always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) 
            rx_prev <= 1'b1; // because start bit is low so  the default is high 
        else 
            rx_prev <= sync2;
    end
    
    wire start_edge = rx_prev & ~sync2; // to detect the edge change 
    
   //half tick detector
    wire mid_sample = (counter == CK_PER_BIT/2);
    
    localparam IDLE = 2'd0;
    localparam START = 2'd1;
    localparam DATA = 2'd2;
    localparam STOP = 2'd3;
    
    reg [1:0] state;
    reg [2:0] bit_index;

     always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin 
            state <= IDLE;
            bit_index <= 3'd0;
            rx_out <= 8'd0;
            rx_done <= 1'b0;
            rx_busy <= 1'b0;
        end else begin 
            rx_done <= 1'b0;
            case (state) 
                IDLE : begin 
                    if(start_edge) begin
                        rx_busy <= 1'b1;
                        bit_index <= 0;
                        state <= START;
                    end
                end
                START : begin 
                    if(mid_sample ) begin
                        if (sync2 == 1'b0) 
                            state <= DATA;
                         else begin 
                            rx_busy <= 1'b0;
                            state <= IDLE;
                         end
                    end
                end
                DATA : begin 
                    if(mid_sample) begin
                        rx_out <= {sync2, rx_out[7:1]};
                        if (bit_index == 7)
                            state  <= STOP;
                        else 
                            bit_index <= bit_index + 1;
                    end
                end
                STOP : begin
                    if (mid_sample) begin 
                        rx_done <= 1'b1;
                        rx_busy <= 1'b0;
                        state <= IDLE;
                    end
                end
               default : state <= IDLE;
            endcase
     end
    end      
endmodule
