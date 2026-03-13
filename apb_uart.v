`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.03.2026 17:46:19
// Design Name: 
// Module Name: apb_uart
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


module apb_uart (
    input  wire        rx,
    output reg         tx,
    input  wire        rst,
    input  wire        pclk,
    input  wire        presetn,
    input  wire        psel,
    input  wire [31:0] paddr,
    input  wire [7:0]  pwdata,
    input  wire        penable,
    input  wire        pwrite,
    output reg  [7:0]  prdata,
    output reg         pready,
    output reg         pwakeup
);

parameter idle=0, check_op=1, write_data=2, read_data=3,
          send_ready=4, send_start=5, transfer=6, send_wakeup=7;

reg [2:0] state = idle;
reg [7:0] wdata;
reg [7:0] rxdata;
reg [3:0] bitcnt = 0;

always @(posedge pclk or negedge rst) begin
    if(!rst) begin
        pready  <= 0;
        state   <= idle;
        prdata  <= 0;
        wdata   <= 0;
        pwakeup <= 0;
        tx      <= 1'b1;   // UART idle
        rxdata  <= 0;
        bitcnt  <= 0;
    end 
    else begin

        case(state)

        idle: begin
            pready <= 0;
            pwakeup <= 0;
            bitcnt <= 0;
            state <= send_wakeup;
        end

        send_wakeup: begin
            pwakeup <= 1'b1;
            state <= check_op;
        end

        check_op: begin
            if(psel && penable && pwrite) begin
                wdata <= pwdata;
                state <= send_start;
            end
            else if(psel && penable && !pwrite) begin
                if(rx == 0)
                    state <= read_data;
            end
        end

        send_start: begin
            tx <= 0;            // start bit
            bitcnt <= 0;
            state <= transfer;
        end

        transfer: begin
            if(bitcnt < 8) begin
                tx <= wdata[bitcnt];
                bitcnt <= bitcnt + 1;
            end
            else begin
                tx <= 1'b1;     // stop bit
                pready <= 1;
                bitcnt <= 0;
                state <= send_ready;
            end
        end

        read_data: begin
            if(bitcnt < 8) begin
                rxdata <= {rx,rxdata[7:1]};
                bitcnt <= bitcnt + 1;
            end
            else begin
                prdata <= rxdata;
                pready <= 1;
                bitcnt <= 0;
                state <= send_ready;
            end
        end

        send_ready: begin
            pready <= 0;
            pwakeup <= 0;
            state <= idle;
        end

        endcase
    end
end

endmodule