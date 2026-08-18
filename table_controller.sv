`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2026 05:11:05 PM
// Design Name: 
// Module Name: table_controller
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


module table_controller(
input logic clk,
input logic rstn,

input logic op_de,
input logic op_wb,
input logic[4:0] rd_i_de,
input logic[4:0] rd_i_wb,

output logic[31:0] next_wb_table

    );
    logic [31:0] wb_table;

    assign next_wb_table = (wb_table & ~( op_wb <<rd_i_wb ))|(op_de<<rd_i_de);
    
    always_ff @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            wb_table <= 0;
        end else begin 
            wb_table <= next_wb_table;
        end  
    end
endmodule
