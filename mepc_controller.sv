`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2026 08:34:14 PM
// Design Name: 
// Module Name: mepc_controller
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


module mepc_controller(
input logic         clk,
input logic         rstn,

input logic[31:0]   if_pc,
input logic         ecall,

input logic[31:0]   wb_pc,
input logic         irq,

input logic[31:0]   csr_pc,
input logic         csr,

output logic[31:0]  mepc
    );
    always_ff @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            mepc <= 0;
        end else begin
            if(csr)begin
                mepc <= csr_pc;
            end else if(irq)begin
                mepc <= wb_pc;
            end else if(ecall)begin
                mepc <= if_pc;
            end 
        end
    end    
endmodule
