`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2026 10:51:14 AM
// Design Name: 
// Module Name: rdata_formatter
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


module rdata_formatter(
    input  logic [2:0]  func3,       // RISC-V komutunun funct3 kısmı
    input  logic [1:0]  addr_align,  // Adresin en alt 2 biti (addr[1:0])
    input  logic [31:0] rdata,   // AXI4'ten gelen 32-bit ham veri
    
    output logic [31:0] rdout 

    );
    logic [7:0]  extracted_byte;
    logic [15:0] extracted_half;
    
    always_comb begin
        if(addr_align[1])begin
            extracted_half = rdata[31:16];
        end else begin
            extracted_half = rdata[15:0];
        end
    end
    
    always_comb begin
        case(addr_align)
            2'b00: extracted_byte = rdata[7:0];
            2'b01: extracted_byte = rdata[15:8];
            2'b10: extracted_byte = rdata[23:16];
            2'b11: extracted_byte = rdata[31:24];
            default: extracted_byte = 8'h00;
        endcase
    end
        always_comb begin
        case (func3)
            // ----------------------------------------------------
            // LB (Load Byte - İşaretli)
            // Koparılan 8. bitin MSB'si (7. bit) neyse, kalan 24 biti onunla doldur.
            // ----------------------------------------------------
            3'b000: rdout = { {24{extracted_byte[7]}}, extracted_byte }; 
            
            // ----------------------------------------------------
            // LH (Load Halfword - İşaretli)
            // Koparılan 16. bitin MSB'si (15. bit) neyse, kalan 16 biti onunla doldur.
            // ----------------------------------------------------
            3'b001: rdout = { {16{extracted_half[15]}}, extracted_half };
            
            // ----------------------------------------------------
            // LW (Load Word - 32 Bit)
            // Zaten 32 bit, doğrudan geçir. (Hizalama adresi bu durumda 00 kabul edilir)
            // ----------------------------------------------------
            3'b010: rdout = rdata;
            
            // ----------------------------------------------------
            // LBU (Load Byte Unsigned - İşaretsiz)
            // Kalan 24 biti zorla 0 yap.
            // ----------------------------------------------------
            3'b100: rdout = { 24'b0, extracted_byte };
            
            // ----------------------------------------------------
            // LHU (Load Halfword Unsigned - İşaretsiz)
            // Kalan 16 biti zorla 0 yap.
            // ----------------------------------------------------
            3'b101: rdout = { 16'b0, extracted_half };
            
            // Varsayılan durumda gelen veriyi bozmadan geçir.
            default: rdout = rdata;
        endcase
    end
endmodule
