`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2026 12:48:57 PM
// Design Name: 
// Module Name: wb_block
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


module wb_block(
    input logic         rstn,
    
    input logic         opcode,
    input logic         valid,
    
    output logic        we
 
    
    );
    assign we = (valid|opcode)&rstn;
endmodule
