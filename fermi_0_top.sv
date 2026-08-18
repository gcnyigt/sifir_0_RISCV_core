`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/17/2026 01:26:26 PM
// Design Name: 
// Module Name: fermi_0_top
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

module fermi_0_top(
    input logic         clk,
    input logic         rstn,

    input logic         irq,
    input logic[4:0]    mecause,
    output logic        irq_ready,

    axi4_if.master      axi_dbus,
    axi4_if.master      axi_ibus
);  
    logic           stall_rs1_b;
    logic[31:0]     i_jaddr;
    logic[31:0]     jaddr;
    logic[31:0]     dec_jaddr;
    logic           je;
    logic           dec_je;
    logic           irq_je;

    assign je = dec_je | irq_je;
    assign jaddr = irq_je ? i_jaddr : dec_jaddr;

    logic [4:0]  rs1_addr;   // Source Register 1 Address
    logic        rs1_valid;
    logic [4:0]  rs2_addr;   // Source Register 2 Address   
    logic        rs2_valid;
    logic [4:0]  rs1_b_addr;
    logic        rs1_b_valid;

    if_block_top i_block(
        .clk(clk),
        .rstn(rstn),
        
        .pc(dec_pc_i),
        .ip(dec_ip_i),
        .ip_valid(ip_valid),
       
        .interrupt_req(je),
        .interrupt_jaddr(jaddr),
        
        .new_instr_req(new_instr_req & !stall_rs1_b),
        
        .rs1_i(rs1_b_data),
        .rs1_valid(!stall_rs1_b),
        .rs1_ready(rs1_b_valid),
        .rs1_o(rs1_b_addr),
        
        .bc_en(bc_en),
        .bc(bc),
        .branch_bias(branch_bias),
        
        .mepc(mepc),
        //output logic        mret,
        .mtvec(mtvec),
        .ecall(ecall),
        .axi_bus(axi_ibus)
    );

    logic               ip_valid;
    logic [31:0]        dec_ip_i;
    logic [31:0]        dec_pc_i;
    logic               bc_en;
    logic               bc;
    logic               branch_bias;
    logic               dec_reg_file_stall_i;
    logic[4:0]          dec_rd1_o; 

    decoder dec(
        .rstn(!irq_je&rstn),
        .clk(clk),
        
        .stall_i(ex_stall_o),
        .reg_file_stall_i(dec_reg_file_stall_i),
        .new_instr_req(new_instr_req),
        
        .alu_op_code(alu_op_code),
        .alu_op_type(alu_op_type),
        .alu_en(alu_opM_en),
        .imm(imm),
        .res_in(alu_res[0]),
        .z_flag_in(flags[0]),
    
        .df_table_op(op_de),
        .rs1(rs1_addr),
        .rs1_valid(rs1_valid),  
        .rs2(rs2_addr),
        .rs2_valid(rs2_valid),
        .rd1(dec_rd1_o),
    
        .ip_valid(ip_valid),
        .ip_in(dec_ip_i),
        
        .predict(branch_bias),
        .bc_en(bc_en),
        .bc(bc),
        .je(dec_je),
        .jaddr(dec_jaddr),
        .func3(func3),
        //output  logic               undefined_opcode,
        
        .pc_i(dec_pc_i),
        .pc_o(dec_pc_o),
        .ex_opcode(ex_opcode)
    );

    logic[31:0]   imm;
    logic[2:0]          func3;
    logic [31:0]        dec_pc_o;
    logic[31:0]  mepc;
    logic         ecall;
    logic         irq;   

    mepc_controller _mepc_controller(
        .clk(clk),
        .rstn(rstn),
        
        .if_pc(dec_pc_i),
        .ecall(ecall),
        
        .wb_pc(wb_pc_o),
        .irq(irq),
        
        //input logic[31:0]   csr_pc,
        .csr(0),
        
        .mepc(mepc)
    );

    logic[31:0]  mtvec;
    assign mtvec = 32'h1000_1000;

    irq_client irq_client(
        .clk(clk),
        .rstn(rstn),
        .mtvec(mtvec),
        .irq(irq),
        .mecause(mecause),
        .mem_op(ex_status[1]),
        .ready(irq_ready),
        .jaddr(i_jaddr),
        //output logic[4:0]   mecause_pend,
        .irq_je(irq_je)
    );

    logic[1:0]          ex_opcode;
    logic[1:0]          ex_status;
    logic               ex_stall_o;

    // DÜZELTME: Modül isimlendirildi (u_ex_wb_top)
    ex_wb_top u_ex_wb_top (
        .rstn(rstn&!irq_je),
        .clk(clk),

        .stall_i(1'b0),
        .stall_o(ex_stall_o),
        .opcode(ex_opcode),
        .func3(func3),

        .rd_i(dec_rd1_o),
        .data_0i(alu_res),
        .data_1i(rs2_data),

        //output logic        df_valid,
        .rd_o(wb_rd1),
        .dout(wb_dout),   
        .we(we),

        .pc_i(dec_pc_o),
        .pc_o(wb_pc_o),
        .ex_status(ex_status),
        .axi_bus(axi_dbus)
    );

    logic[4:0] wb_rd1;
    logic[31:0]  wb_dout;
    logic        we;
    logic[31:0]  wb_pc_o;
    logic        df_valid[1:0];
    logic [31:0] df_d[1:0];

    assign df_d[1] = wb_dout;
    assign df_d[0] = alu_res;


    logic [4:0]  df_id[1:0];
    
    assign df_id[0] = dec_rd1_o;
    assign df_id[1] = wb_rd1;
    
    assign df_valid[0] =   ex_opcode == 2'b01;
    assign df_valid[1] =   we;

    regfile_top u_regfile_top (
        .clk(clk),
        .we(we),         // Write Enable
        .rs1_addr(rs1_addr),   // Source Register 1 Address
        .rs1_valid(rs1_valid),
        .rs2_addr(rs2_addr),   // Source Register 2 Address   
        .rs2_valid(rs2_valid),
        .rs1_b_addr(rs1_b_addr),
        .rs1_b_valid(rs1_b_valid),
        
        .rd_addr(wb_rd1),    // Destination Register Address
        .rd_data(wb_dout),    // Data to be written
        
        .rs1_data_o(rs1_data),   // Source Register 1 Data
        .rs2_data_o(rs2_data),    // Source Register 2 Data
        .rs1_b_data_o(rs1_b_data),
        
        .stall(dec_reg_file_stall_i),
        .stall_rs1_b(stall_rs1_b),
        
        .wb_table(next_wb_table),
        
        .df_d(df_d),
        .df_id(df_id),
        .df_valid(df_valid)
    );

    logic [31:0] rs1_b_data,rs1_data,rs2_data;
    logic[1:0]    alu_op_type;
    logic alu_opM_en;

    alu_op_manager alu_opm(
        .alu_opM_en(alu_opM_en),
        .rs2_in(rs2_data),
        .rs1_in(rs1_data),
        .pc_in(dec_pc_i),
        .imm_in(imm),

        //output logic        done,
        .op1_out(op1),
        .op2_out(op2),

        .op_type(alu_op_type)
    );

    logic [31:0] op1,op2;

    alu_main alu(
        .alu_en(alu_opM_en),   
        .opcode(alu_op_code),
        .op1(op1),
        .op2(op2),
        .res(alu_res),
        .flags(flags)   
        //output logic        done
    );

    logic [3:0]  flags;
    logic [31:0] alu_res;

    table_controller u_table_controller (
        .clk(clk),
        .rstn(rstn&!irq_je),

        .op_de(op_de),
        .op_wb(we),
        .rd_i_de(dec_rd1_o),
        .rd_i_wb(wb_rd1),

        .next_wb_table(next_wb_table)
    );

    logic op_de;
    logic[31:0] next_wb_table;

endmodule