`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 10:14:39 AM
// Design Name: 
// Module Name: i2c_master_write_tb
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

module i2c_master_write_tb;

    reg clk;
    reg rst;
    reg start;
    reg [6:0] slave_addr;
    reg [7:0] data_in;

    wire scl;
    wire sda;

    wire sda_master_oe;
    reg  sda_slave_oe;

    // ------------------------------------------------------------
    // Wired-AND SDA (true open-drain behavior)
    // ------------------------------------------------------------
    assign sda = (sda_master_oe | sda_slave_oe) ? 1'b0 : 1'b1;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    i2c_master_write #(.CLK_DIV(4)) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .slave_addr(slave_addr),
        .data_in(data_in),
        .busy(),
        .ack_error(),
        .scl(scl),
        .sda_oe(sda_master_oe)
    );

    // ------------------------------------------------------------
    // System clock (10 ns)
    // ------------------------------------------------------------
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Simple ACK slave
    // ------------------------------------------------------------
    integer bit_cnt;

    always @(posedge scl or posedge rst) begin
        if (rst) begin
            bit_cnt <= 0;
            sda_slave_oe <= 0;
        end else begin
            bit_cnt <= bit_cnt + 1;

            // ACK after address (9th) and data (18th) clocks
            if (bit_cnt == 8 || bit_cnt == 17)
                sda_slave_oe <= 1;
            else
                sda_slave_oe <= 0;
        end
    end

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------
    initial begin
        clk = 0;
        rst = 1;
        start = 0;
        slave_addr = 7'h50;
        data_in = 8'hA5;

        #20 rst = 0;

        @(negedge scl);
        start = 1;
        @(negedge scl);
        start = 0;

        #600 $finish;
    end

endmodule

