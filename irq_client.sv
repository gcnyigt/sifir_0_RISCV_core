`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2026 12:48:11 PM
// Design Name: 
// Module Name: irq_client
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


module irq_client(
    input logic         clk,
    input logic         rstn,
    input logic[31:0]   mtvec,
    input logic         irq,
    input logic[4:0]    mecause,
    input logic         mem_op,
    output logic        ready,
    output logic[31:0]  jaddr,
    output logic[4:0]   mecause_pend,
    output logic        irq_je
    );
    assign ready = rstn &!mem_op;
    assign jaddr = mtvec[0]? mtvec +(mecause<<2): mtvec;
    always_ff @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            mecause_pend <= 0;
            irq_je <= 0;
        end else begin
            if(irq &!mem_op)begin
                irq_je <= 1;  
                mecause_pend <= mecause;      
            end else begin
                irq_je <= 0;
            end
        end
    end
endmodule
