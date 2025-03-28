`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/03/2025 03:15:41 PM
// Design Name: 
// Module Name: I2C_TOP_LEVEL
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


module I2C_TOP_LEVEL(
    input wire [7:0] p_din, 
    input wire [6:0] p_addr,
    output wire [7:0] p_dout,
    
    input wire [7:0] MCU_din,
    output wire [7:0] MCU_dout,
    output wire done, READY,
    
    input wire clk,
    input wire GO, 
    input wire MCU_WR
    );
    
    wire SCL, SDA, reg1_we, reg2_we, MCU_READY, P_READY; 
    wire [7:0] reg1_din,  reg2_din; 
    
    pullup(SCL); 
    pullup(SDA); 
    
    I2C_FSM MCU(
        .addr(p_addr), 
        .GO(GO), 
        .clk(clk), 
        .wr(MCU_WR),
        .din(MCU_din),
        .WE(reg2_we), 
        .READY(MCU_READY),
        .dout(reg2_din),
        .SDA(SDA), 
        .SCL(SCL)); 
    
    Lab_5_4_bit_register MCU_reg(
        .clk(clk),
        .Enter(reg2_we),
        .D(reg2_din),
        .Q(MCU_dout)); 
     
    I2C_peripheral peripheral(
        .din(p_din),
        .addr(p_addr),
        .WE(reg1_we),
        .READY(P_READY),
        .dout(reg1_din),
        .SDA(SDA), 
        .SCL(SCL), 
        .clk(clk));
    
    Lab_5_4_bit_register p_reg(
        .clk(clk),
        .Enter(reg1_we),
        .D(reg1_din),
        .Q(p_dout)); 
    
    assign done = reg1_we|reg2_we; 
    assign READY = MCU_READY && P_READY; 
    
endmodule
