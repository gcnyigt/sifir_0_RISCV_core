`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/06/2026 01:34:15 PM
// Design Name: 
// Module Name: btb
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


module btb(
    input logic         rstn,
    input logic         clk,
    input logic[17:0]   pc_j,
    input logic         btb_en,
    input logic         bc_en,
    input logic         bc,
    output logic        bias
    );
    logic[19:0] mem[1:0];
    logic bias_valid;
    logic ptr,next_ptr;
    logic new_branch[1:0];
    logic[1:0] next_bias[1:0];
    always_comb begin
        if(btb_en)begin
            if(mem[0][17:2]==pc_j)begin
                bias_valid = 1;
                next_ptr = 0;
                bias=next_bias[0][1];
            end else if(mem[1][17:2]==pc_j) begin
                bias_valid = 1;
                next_ptr = 1;
                bias=next_bias[1][1];
            end else begin
                bias_valid = 0;
                bias = 0;
                next_ptr = ~ptr;
                
            end
        end else begin
            bias_valid = 1;
            next_ptr = ptr;
            bias = 0;
        end
        if(bc_en)begin
            if(new_branch[ptr])begin
                if(bc)begin
                    next_bias[ptr] = 2'b10;
                end else begin
                    next_bias[ptr] = 2'b00;
                end
            end else begin
                if(bc)begin
                    next_bias[ptr] = mem[ptr][1:0] == 2'b11 ? 2'b11 : mem[ptr][1:0] + 2'b01;
                end else begin
                    next_bias[ptr] = mem[ptr][1:0] == 2'b00 ? 2'b00 : mem[ptr][1:0] + 2'b11;
                end
            end         
        end else begin
            next_bias[0] = mem[0][1:0];
            next_bias[1] = mem[0][1:0]; 
        end
    end
    always_ff @ (posedge clk or negedge rstn)begin
        if(!rstn)begin
            ptr <= 0;
        end else begin
            if(btb_en)begin
                ptr <= next_ptr;
                new_branch[next_ptr] = ~bias_valid;
                if(!bias_valid)begin
                    mem[next_ptr][17:2] = pc_j;
                end
            end
            if(bc)begin
                mem[ptr][1:0] <= next_bias[ptr];
            end
        end    
    end
endmodule
