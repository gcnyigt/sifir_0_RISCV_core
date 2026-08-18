`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 11:48:44 AM
// Design Name: 
// Module Name: addr_manager
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


module addr_manager(
    input logic         en,
    input logic[31:0]   pc,
    input logic[31:0]   rs1,
    input logic[31:0]   imm,
    
    input logic         source_sel,
    
    output logic[31:0]  res
    );
    always_comb begin
        if(en)begin
            if(source_sel)begin
                res = pc + imm;    
            end else begin
                res = rs1 + imm;
            end
        end else begin
            res = imm;
        end
    end
endmodule