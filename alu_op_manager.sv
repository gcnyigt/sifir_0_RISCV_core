`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2026 08:05:51 PM
// Design Name: 
// Module Name: alu_op_manager
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


module alu_op_manager(
input alu_opM_en,

input logic[31:0]   rs2_in,
input logic[31:0]   rs1_in,
input logic[31:0]   pc_in,
input logic[31:0]   imm_in,

output logic        done,
output logic[31:0]  op1_out,
output logic[31:0]  op2_out,

input logic[1:0]    op_type

    );
    always_comb begin
        if (!alu_opM_en) begin
            done <= 1'b0;
        end else begin
            case (op_type)
                2'b00:begin
                    op1_out = rs1_in;
                    op2_out = rs2_in;
                end
                2'b01:begin
                    op1_out = rs1_in;
                    op2_out = imm_in;
                end
                2'b10:begin
                    op1_out = {32{1'b0}};
                    op2_out = imm_in;
                end 
                2'b11:begin
                    op1_out = pc_in;
                    op2_out = imm_in;
                end
                default begin
                    op1_out = rs1_in;
                    op2_out = rs2_in;
                end
            endcase
            done <= 1'b1;
        end
    end
endmodule
