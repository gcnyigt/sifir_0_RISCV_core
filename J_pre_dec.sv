`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/05/2026 10:16:38 AM
// Design Name: 
// Module Name: J_pre_dec
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

module J_pre_dec(
    input logic         ip_valid,
    input logic         new_instr_req_i,
    input logic[31:0]   ip,
    input logic[31:0]   pc,
    
    input logic[31:0]   mepc,
    output logic        mret,
    input logic[31:0]   mtvec,
    output logic        ecall,
    
    input logic         int_req,
    
    output logic        jreq,
    output logic[31:0]  jaddr,
    
    output logic[4:0]   rs1_o,
    output logic        rs1_ready,
    
    input logic[31:0]   rs1_i,
    input logic         rs1_valid,
    output logic        new_instr_req_o,
    
    output logic        btb_en,
    input  logic        branch_bias
    );
    logic source_sel;
    logic en;
    logic[31:0] imm;
    logic[1:0] j_op;
    logic[2:0] j_func;
    addr_manager addr_manager(
    .en(en),
    .pc(pc),
    .rs1(rs1_i),
    .imm(imm),
    
    .source_sel(source_sel),
    
    .res(jaddr)
    );
    assign rs1_o = ip[19:15];
    assign new_instr_req_o = new_instr_req_i & (!rs1_ready|rs1_valid);
    assign j_func = ip[4:2];
    assign j_op = {ip[6:5]};
    always_comb begin
        if(ip_valid&new_instr_req_i&!int_req&(j_op == 2'b11))begin
                        btb_en = 0;
                        rs1_ready = 0;
                        jreq= 0;
                        en = 0;
                        imm = 0;
                        source_sel = 0;
                        ecall = 0;
                        mret = 0;
            case (j_func)
                    3'b011:begin
                        imm = { {12{ip[31]}}, ip[19:12], ip[20], ip[30:21], 1'b0 };
                        jreq = 1;
                    end
                    3'b000:begin
                        btb_en = 1;
                        jreq = branch_bias;
                        en = branch_bias;
                        source_sel = 1;
                        imm = { {20{ip[31]}}, ip[7], ip[30:25], ip[11:8], 1'b0 };
                    end
                    3'b100:begin
                        jreq = 1;
                        imm = ip[20]? mepc: mtvec;
                        mret = ip[20];
                        ecall = !ip[20];
                    end
                    3'b001:begin
                        rs1_ready = 1;
                        jreq = rs1_valid;
                        imm = {{21{ip[31]}},ip[30:20]};
                        en = 1;
                        source_sel = 0;
                    end
                    default:begin
                        btb_en = 0;
                        rs1_ready = 0;
                        jreq= 0;
                        en = 0;
                        imm = 0;
                        source_sel = 0;
                        ecall = 0;
                        mret = 0;
                    end
                endcase        
        end else begin
                rs1_ready = 0;
                jreq= 0;
                en = 0;
                imm = 0;
                rs1_ready= 0;
                source_sel = 0;
        end          

    end
endmodule
