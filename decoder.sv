`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2026 09:11:43 PM
// Design Name: 
// Module Name: decoder
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


module decoder(
    input  logic                rstn,
    input  logic                clk,
    
    input   logic               stall_i,
    input   logic               reg_file_stall_i,
    output  logic               new_instr_req,
    
    output logic[3:0]           alu_op_code,
    output logic[1:0]           alu_op_type,
    output logic                alu_en,
    output logic[31:0]          imm,
    input   logic               res_in,
    input   logic               z_flag_in,

    output logic                df_table_op,
    output logic[4:0]           rs1,
    output logic                rs1_valid,  
    output logic[4:0]           rs2,
    output logic                rs2_valid,
    output logic[4:0]           rd1,

    input   logic               ip_valid,
    input   logic [31:0]        ip_in,
    
    input   logic               predict,
    output  logic               bc_en,
    output  logic               bc,
    output  logic               je,
    output  logic [31:0]        jaddr,
    output  logic[2:0]          func3,
    output  logic               undefined_opcode,
    
    input   logic [31:0]        pc_i,
    output  logic [31:0]        pc_o,
    output  logic[1:0]          ex_opcode
    );
    assign new_instr_req = !(stall_i|reg_file_stall_i) ;
    logic            dec_valid;
    logic [31:0]     ip;
    logic[6:0] opcode,func7;
    
    assign opcode = ip_valid ? (stall_i|reg_file_stall_i) ?{{6{1'b0}},1'b1} :ip[6:0]: {7{1'b0}};
    assign func7 = ip[31:25];
    assign func3 = ip[14:12];
    assign rs1 = ip[19:15];
    assign rs2 = ip[24:20];
    typedef enum logic [6:0] {
        OP_LOAD   = 7'b0000011, // LW, LB, LH (RAM'den okuma)
        OP_IMM    = 7'b0010011, // ADDI, SLTI, ANDI vs. (Sabit sayılı işlemler)
        OP_AUIPC  = 7'b0010111, // AUIPC (PC'ye üst bitleri ekle)
        OP_STORE  = 7'b0100011, // SW, SB, SH (RAM'e yazma)
        OP_RTYPE  = 7'b0110011, // ADD, SUB, AND, OR vs. (Yazmaçtan yazmaca)
        OP_LUI    = 7'b0110111, // LUI (Üst bitleri yükle)
        OP_BRANCH = 7'b1100011, // BEQ, BNE, BLT vs. (Dallanma)
        OP_JALR   = 7'b1100111, // JALR (Yazmaca göre zıpla)
        OP_JAL    = 7'b1101111, // JAL (Doğrudan zıpla)
        OP_SYSTEM = 7'b1110011, // ECALL, EBREAK (Sistem çağrıları)
        OP_STALL  = 7'b0000001  //Bekleme durumu
    } opcode_e;
    always_comb begin
        rs1_valid           = 0;
        rs2_valid           = 0;
        df_table_op         = 0;
        ex_opcode           = 2'b00;
        alu_op_code         = 4'b0000;
        alu_op_type         = 2'b00;
        alu_en              = 0;
        imm                 = 32'b0;
        jaddr               = 32'b0;
        bc_en               = 0;
        bc                  = 0;
        je                  = 0;
        undefined_opcode    = 0;
        case(opcode)
            OP_RTYPE:begin
                rs1_valid   = 1;
                rs2_valid   = 1;
                df_table_op = 1;
                ex_opcode   = 2'b01;
                alu_op_code = {func7[5],func3};
                alu_op_type =2'b00;
                alu_en      = 1;
            end
            OP_IMM:begin
                rs1_valid   = 1;
                rs2_valid   = 0;
                df_table_op = 1;
                alu_op_type =2'b01;
                imm[4:0] = rs2;
                imm[11:5] = func7;
                imm[31:12] = {20{func7[6]}};
                alu_op_code = {((func3==3'b101)&func7[5]),func3};
                alu_en      = 1;
                ex_opcode   = 2'b01;    
            end
            OP_STORE:begin
                rs1_valid   = 1;
                rs2_valid   = 1;
                df_table_op = 0;
                alu_op_type =2'b01;
                imm[4:0] = rd1;
                imm[11:5] = func7;
                imm[31:12] = {20{func7[6]}};
                alu_op_code = 4'b0000;
                alu_en      = 1;
                ex_opcode  =2'b10;
            end
            OP_LOAD:begin
                rs1_valid   = 1;
                rs2_valid   = 0;
                df_table_op = 1;
                alu_op_type =2'b01;
                imm[4:0] = rs2;
                imm[11:5] = func7;
                imm[31:12] = {20{func7[6]}};
                alu_op_code = 4'b0000;
                alu_en      = 1;
                ex_opcode  =2'b11;
                
            end
            OP_LUI:begin
                rs1_valid   = 0;
                rs2_valid   = 0;
                df_table_op = 1;
                alu_op_type =2'b10;
                imm = {ip[31:12], 12'b0};
                alu_op_code = 4'b0000;
                ex_opcode  =2'b01;
                alu_en      = 1;
            end
            OP_AUIPC:begin
                rs1_valid   = 0;
                rs2_valid   = 0;
                df_table_op = 1;
                alu_op_type =2'b10;
                imm = {ip[31:12], 12'b0};
                alu_op_code = 4'b0000;
                alu_en      = 1;
                ex_opcode  =2'b11;
            end
            OP_BRANCH:begin
                rs1_valid   = 1;
                rs2_valid   = 1;
                df_table_op = 0;
                bc_en = 1;                
                alu_op_type =2'b00;
                alu_op_code = {!(func3[2]|func3[1]),1'b0,func3[2],func3[1]};
                alu_en      = 1;
                bc = func3[0]^(func3[2]|func3[1] ? res_in : z_flag_in);
                je = predict^bc;
                jaddr = je ? predict ? (pc_o +4) :{ {20{ip[31]}}, ip[7], ip[30:25], ip[11:8], 1'b0 } :0;
                ex_opcode  =2'b00;
                imm=0;
                
            end
            OP_JAL:begin
                jaddr = 0;
                rs1_valid   = 0;
                rs2_valid   = 0;
                df_table_op = 0;                
                alu_op_type =2'b11;
                imm = 0;
                alu_en      = 1;
                ex_opcode  =2'b01;
            end
            OP_JALR:begin
                jaddr = 0;
                rs1_valid   = 0;
                rs2_valid   = 0;
                df_table_op = 0;                
                alu_op_type =2'b11;
                imm = 0;
                alu_en      = 1;
                ex_opcode  =2'b01;
            end
            OP_STALL:begin
                jaddr = 0;
                rs1_valid   =reg_file_stall_i ? 1 :0;
                rs2_valid   =reg_file_stall_i ? 1 :0;
                df_table_op = 0;
                ex_opcode  =2'b00;
                alu_en      = 0;
                alu_op_type =2'b00;
                imm=0;
                je = 0;
                alu_op_code = 0;
                undefined_opcode = !(stall_i|reg_file_stall_i);
            end
            default:begin
                rs1_valid   = 0;
                rs2_valid   = 0;
                df_table_op = 0;
                ex_opcode   = 2'b00;
                alu_op_code = 4'b0000;
                alu_op_type = 2'b00;
                alu_en      = 0;
                imm         = 32'b0;
                jaddr       = 32'b0;
                bc_en       = 0;
                bc          = 0;
                je          = 0;
                undefined_opcode = ip_valid;
            end
        endcase
    end
    always_ff@(posedge clk or negedge rstn)begin
        if (!rstn) begin
            ip <= 32'h00000000;
        end else begin
            if(dec_valid)begin
                ip <= ip_in;
                pc_o<=pc_i;
          
            end
        end
    end
endmodule
