`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2026 04:43:34 PM
// Design Name: 
// Module Name: ex_wb_top
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


module ex_wb_top(
input logic         rstn,
input logic         clk,

input logic         stall_i,
output logic        stall_o,

input logic[1:0]    opcode,
input logic[2:0]    func3,

input logic[4:0]    rd_i,
input logic[31:0]   data_0i,
input logic[31:0]   data_1i,

output logic[1:0]   status,

output logic        df_valid,
output logic[4:0]   rd_o,
output logic[31:0]  dout,    
output logic        we,

input logic[31:0]   pc_i,
output logic[31:0]  pc_o,

output logic[1:0]   ex_status,

axi4_if.master      axi_bus

    );
    logic        wb_opcode,req_valid;    
    ex_block ex_b(
    .clk(clk),
    .rstn(rstn),
    .opcode_i(opcode),
    .func3_i(func3),
    .stall_i(stall_i),
    .stall_o(stall_0),
    
    .data_0i(data_0i),
    .data_1i(data_1i),
    
    .pc_i(pc_i),
    .pc_o(pc_o),
    
    .data_o(dout),
    .wb_opcode(wb_opcode),
    
    .rd_o(rd_o),
    .req(status),
    .req_valid_o(req_valid),
    .df_valid(df_valid),
    
    .rd_i(rd_i),
    
    .opcode(ex_status),
    
    .axi_bus(axi_bus)
    
    );
    wb_block wb_b(
    .rstn(rstn),
    .opcode(wb_opcode),
    .valid(req_valid),
    .we(we) 
    
    );
endmodule
