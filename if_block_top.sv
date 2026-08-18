`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/04/2026 04:35:37 PM
// Design Name: 
// Module Name: if_block_top
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


module if_block_top(
    input logic         clk,
    input logic         rstn,
    
    output logic[31:0]  pc,
    output logic[31:0]  ip,
    output logic        ip_valid,
   
    input  logic        interrupt_req,
    input  logic[31:0]  interrupt_jaddr,
    
    input logic         new_instr_req,
    
    input  logic[31:0]  rs1_i,
    input  logic        rs1_valid,
    output logic        rs1_ready,
    output logic[4:0]   rs1_o,
    
    input logic         bc_en,
    input logic         bc,
    output logic        branch_bias,
    
    input logic[31:0]   mepc,
    output logic        mret,
    input logic[31:0]   mtvec,
    output logic        ecall,
    axi4_if.master      axi_bus
    );
    logic jreq;
    logic p_jreq;
    logic btb_en;
    logic[31:0] jaddr;
    logic[31:0] p_jaddr;
    logic new_instr_i;
    assign jaddr = interrupt_req ? interrupt_jaddr:p_jaddr;
    assign jreq = interrupt_req | p_jreq;
    J_pre_dec predec(
        .ip_valid(ip_valid),
        .new_instr_req_i(new_instr_req),
        .ip(ip),
        .pc(pc),
        .mtvec(mtvec),
        .mepc(mepc),
        .int_req(interrupt_req),
        .mret(mret),
        .ecall(ecall),
        .jreq(p_jreq),
        .jaddr(p_jaddr),
        
        .rs1_o(rs1_o),
        .rs1_ready(rs1_ready),
        
        .rs1_i(rs1_i),
        .rs1_valid(rs1_valid),
        .new_instr_req_o(new_instr_i),
        .btb_en(btb_en),
        .branch_bias(branch_bias)
    );
    if_block prefetcher(
        .clk(clk),
        .rstn(rstn),
        
        .pc(pc),
        .ip(ip),
        .ip_valid(ip_valid),
        
        .jreq(jreq),
        .jaddr(jaddr),
        
        
        .new_instr_req(new_instr_i),
        .axi_bus(axi_bus)
    );
    btb b_predict(
    .rstn(rstn),
    .clk(clk),
    .pc_j({pc[31:28],pc[15:2]}),
    .btb_en(btb_en),
    .bc_en(bc_en),
    .bc(bc),
    .bias(branch_bias)
    );
endmodule