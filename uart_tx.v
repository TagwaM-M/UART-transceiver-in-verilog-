`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2026 08:32:38 PM
// Design Name: 
// Module Name: uart_tx
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


module uart_tx #(parameter CK_PER_BIT = 10417)(
    //clk and reset 
    input clk,
    input rst_n,
    input start,
    input [7:0] tx_data,
    output reg tx_active,
    output reg tx_serial_out,
    output reg done

    );
    // using counter to create a pulse every decided freq/baud rate
    localparam COUNTER_SIZE = $clog2(CK_PER_BIT);    
    reg [COUNTER_SIZE-1:0] counter;
    reg baud_tick;
    
    always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin
            counter <= 0;
            baud_tick <= 1'b0;
        end else if (!tx_active) begin
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
    
    // transimitter FSM
    
    localparam IDLE = 2'd0;
    localparam START = 2'd1;
    localparam DATA = 2'd2;
    localparam STOP = 2'd3;
    
    reg [1:0] state;
    reg [2:0] bit_index;
    reg [7:0] shift_bits;
    
    always @(posedge clk or negedge rst_n) begin 
        if(!rst_n) begin 
            state <= IDLE;
            bit_index <= 3'd0;
            shift_bits <= 8'd0;
            tx_serial_out <= 1'b1;
            tx_active <= 1'b0;
            done <= 1'b0;
        end else begin 
            done <= 1'b0;
            case (state) 
                IDLE : begin
                    tx_serial_out <= 1; 
                    if (start == 1'b1) begin
                        shift_bits <= tx_data;
                        tx_active <= 1'b1;
                        state <= START;
                    end
                end
                START : begin
                  tx_serial_out <= 1'b0;
                  if (baud_tick) begin
                    state <= DATA;
                    bit_index <= 0;
                  end
                end
                DATA : begin
                    tx_serial_out <= shift_bits[0];
                    if (baud_tick) begin
                        shift_bits <= shift_bits >> 1;
                        bit_index <= bit_index + 1'b1;
                        if ( bit_index == 7 ) begin
                            state <= STOP;
                            bit_index <= 0;
                        end
                    end
                end
                STOP : begin
                    tx_serial_out <= 1'b1;
                    if (baud_tick) begin
                        done <= 1'b1;
                        tx_active <= 1'b0;
                        state <= IDLE;
                    end
                end
                default : 
                    state <= IDLE;
            endcase
        end
    end
endmodule
