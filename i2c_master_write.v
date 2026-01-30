`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 10:13:04 AM
// Design Name: 
// Module Name: i2c_master_write
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

module i2c_master_write (
    input  wire       clk,
    input  wire       rst,
    input  wire       start,
    input  wire [6:0] slave_addr,
    input  wire [7:0] data_in,

    output reg        busy,
    output reg        ack_error,

    output wire       scl,
    output reg        sda_oe      // open-drain enable
);

    // SCL generation
    parameter CLK_DIV = 4;

    reg [15:0] clk_cnt;
    reg scl_int;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 0;
            scl_int <= 1'b1;
        end else if (clk_cnt == CLK_DIV-1) begin
            clk_cnt <= 0;
            scl_int <= ~scl_int;
        end else begin
            clk_cnt <= clk_cnt + 1;
        end
    end

    assign scl = scl_int;

    // FSM
    parameter IDLE     = 3'd0,
              START_ST = 3'd1,
              ADDR     = 3'd2,
              ADDR_ACK = 3'd3,
              DATA     = 3'd4,
              DATA_ACK = 3'd5,
              STOP_ST  = 3'd6;

    reg [2:0] state;
    reg [3:0] bit_cnt;
    reg [7:0] shift;
    reg       start_latched;

    always @(negedge scl_int or posedge rst) begin
        if (rst) begin
            state         <= IDLE;
            sda_oe        <= 0;
            busy          <= 0;
            ack_error     <= 0;
            bit_cnt       <= 0;
            shift         <= 0;
            start_latched <= 0;
        end else begin
            case (state)

                // IDLE
                IDLE: begin
                    busy   <= 0;
                    sda_oe <= 0;
                    if (start && !start_latched) begin
                        start_latched <= 1;
                        busy  <= 1;
                        state <= START_ST;
                    end
                end

                // START
                // SDA goes low BEFORE next SCL high
                START_ST: begin
                    sda_oe  <= 1'b1;                 // pull SDA low
                    shift   <= {slave_addr, 1'b0};   // load address + W
                    bit_cnt <= 7;
                    state   <= ADDR;
                end

                // ADDRESS
                ADDR: begin
                    sda_oe <= ~shift[bit_cnt];
                    if (bit_cnt == 0)
                        state <= ADDR_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end

                // ADDR ACK
                ADDR_ACK: begin
                    sda_oe <= 0;           // release SDA
                    shift   <= data_in;
                    bit_cnt <= 7;
                    state   <= DATA;
                end

                // DATA 
                DATA: begin
                    sda_oe <= ~shift[bit_cnt];
                    if (bit_cnt == 0)
                        state <= DATA_ACK;
                    else
                        bit_cnt <= bit_cnt - 1;
                end

                //  DATA ACK
                DATA_ACK: begin
                    sda_oe <= 0;
                    state  <= STOP_ST;
                end

                // STOP
                STOP_ST: begin
                    sda_oe        <= 0;   // SDA released, rises while SCL high
                    busy          <= 0;
                    start_latched <= 0;
                    state         <= IDLE;
                end

            endcase
        end
    end

endmodule

