`timescale 1ns / 1ps

module alu_main(
    input  logic        alu_en,   
    input  logic [3:0]  opcode,
    input  logic [31:0] op1,
    input  logic [31:0] op2,
    output logic [31:0] res,
    output logic [3:0]  flags,     
    output logic        done
);

    always_comb begin
        res   = 32'b0;
        flags = 4'b0;
        done  = 1'b0;

        if (!alu_en) begin
            done  = 1'b0;
            res   = 32'b0;
            flags = 4'b0;
        end else begin
            done = 1'b1; 
            
            case (opcode)
                4'b0000: res = op1 + op2;                                 // ADD
                4'b1000: res = op1 - op2;                                 // SUB
                4'b0001: res = op1 << op2[4:0];                           // SLL
                4'b0010: res = {31'b0, ($signed(op1) < $signed(op2))};    // SLT 
                4'b0011: res = {31'b0, (op1 < op2)};                      // SLTU
                4'b0100: res = op1 ^ op2;                                 // XOR
                4'b0101: res = op1 >> op2[4:0];                           // SRL
                4'b1101: res = $signed(op1) >>> op2[4:0];                 // SRA 
                4'b0110: res = op1 | op2;                                 // OR
                4'b0111: res = op1 & op2;                                 // AND
                default: res = 32'b0;
            endcase
            flags[0] = (res == 32'b0) ? 1'b1 : 1'b0;
            flags[1] = res[31];                      
        end
    end

endmodule