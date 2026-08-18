`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/20/2026 03:56:46 PM
// Design Name: 
// Module Name: regfile_top
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


module regfile_top(
    input  logic        clk,
    input  logic        we,         // Write Enable
    input  logic [4:0]  rs1_addr,   // Source Register 1 Address
    input  logic        rs1_valid,
    input  logic [4:0]  rs2_addr,   // Source Register 2 Address    
    input  logic        rs2_valid,
    input  logic [4:0]  rs1_b_addr,
    input  logic        rs1_b_valid,
    
    input  logic [4:0]  rd_addr,    // Destination Register Address
    input  logic [31:0] rd_data,    // Data to be written
    
    output logic [31:0] rs1_data_o,   // Source Register 1 Data
    output logic [31:0] rs2_data_o,    // Source Register 2 Data
    output logic [31:0] rs1_b_data_o,
    
    output logic        stall,
    output logic        stall_rs1_b,
    
    input  logic [31:0] wb_table,
    
    input  logic [31:0] df_d[1:0],
    input  logic [4:0]  df_id[1:0],
    input  logic        df_valid[1:0]
);  
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] rs1_b_data;
    logic stall_rs1;
    logic stall_rs2;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rs1_b;
    reg_file reg_file(
    .clk(clk),
    .we(we),         // Write Enable
    .rs1_addr(rs1),   // Source Register 1 Address
    .rs2_addr(rs2),   // Source Register 2 Address
    .rs1_b_addr(rs1_b),
    .rd_addr(rd_addr),    // Destination Register Address
    .rd_data(rd_data),    // Data to be written
    
    .rs1_data(rs1_data),   // Source Register 1 Data
    .rs2_data(rs2_data),    // Source Register 2 Data
    .rs1_b_data(rs1_b_data)
);
    assign stall = stall_rs1 | stall_rs2 ;
    always_comb begin
        if(rs1_valid)begin
            if(wb_table[rs1_addr])begin
                if(df_valid[0]&(df_id[0]==rs1_addr))begin
                    rs1_data_o = df_d[0];
                    stall_rs1 = 0;
                end else if(df_valid[1]&(df_id[1]==rs1_addr)) begin
                    rs1_data_o = df_d[1];
                    stall_rs1 = 0;
                end else begin
                    stall_rs1 = 1;
                end
            end else begin
                rs1 = rs1_addr;
                rs1_data_o = rs1_data; 
                stall_rs1 = 0;
            end
        end else begin
            rs1_data_o = rs1_data; 
            rs1 = 0;
            stall_rs1 = 0;
        end
        if(rs2_valid)begin
            if(wb_table[rs2_addr])begin
                if(df_valid[0]&(df_id[0]==rs2_addr))begin
                    rs2_data_o = df_d[0];
                    stall_rs2 = 0;
                end else if(df_valid[1]&(df_id[1]==rs2_addr)) begin
                    rs2_data_o = df_d[1];
                    stall_rs2 = 0;
                end else begin
                    stall_rs2 = 1;
                end
            end else begin
                rs2 = rs2_addr;
                rs2_data_o = rs2_data; 
                stall_rs2 = 0;
            end
        end else begin
            rs2_data_o = rs2_data; 
            rs2 = 0;
            stall_rs2 = 0;
        end
        if(rs1_b_valid)begin
            if(wb_table[rs1_b_addr])begin
                if(df_valid[0]&(df_id[0]==rs1_b_addr))begin
                    rs1_b_data_o = df_d[0];
                    stall_rs1_b = 0;
                end else if(df_valid[1]&(df_id[1]==rs1_b_addr)) begin
                    rs1_data_o = df_d[1];
                    stall_rs1_b = 0;
                end else begin
                    stall_rs1_b = 1;
                end
            end else begin
                rs1_b = rs1_b_addr;
                rs1_b_data_o = rs1_b_data; 
                stall_rs1_b = 0;
            end
        end else begin
            rs1_b_data_o = rs1_b_data; 
            rs1_b = 0;
            stall_rs1_b = 0;
        end
    end
    

endmodule