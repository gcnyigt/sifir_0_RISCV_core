`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/30/2026 12:10:40 PM
// Design Name: 
// Module Name: sdata_controller
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


module sdata_controller(
    input  logic [2:0]  func3,       // RISC-V komutu funct3 (sb, sh, sw)
    input  logic [31:0] addr,        // RAM'e yazılacak 32-bit adres
    input  logic [31:0] rs2_data,    // Register'dan gelen ham veri (yazılacak veri)
    
    // AXI Çıkışları
    output logic [3:0]  axi_wstrb,   // AXI Hangi baytlar yazılacak
    output logic [31:0] axi_wdata    // AXI Hizalanmış yazma verisi
    );
    logic [1:0] align;
    assign align = addr[1:0];
    always_comb begin
        // Varsayılan (SW - Store Word) değerleri
        axi_wstrb = 4'b1111; 
        axi_wdata = rs2_data;

        case (func3[1:0])
            // --------------------------------------------------
            // SB (Store Byte - 1 Bayt)
            // --------------------------------------------------
            2'b00: begin
                axi_wstrb = 4'b0001 << align; // İlgili baytın strb bitini 1 yap
                case (align)
                    2'b00: axi_wdata = {24'b0, rs2_data[7:0]};
                    2'b01: axi_wdata = {16'b0, rs2_data[7:0], 8'b0};
                    2'b10: axi_wdata = {8'b0,  rs2_data[7:0], 16'b0};
                    2'b11: axi_wdata = {       rs2_data[7:0], 24'b0};
                endcase
            end
            
            // --------------------------------------------------
            // SH (Store Halfword - 2 Bayt)
            // --------------------------------------------------
            2'b01: begin
                if (align[1] == 1'b0) begin
                    axi_wstrb = 4'b0011; // Alt 2 bayt
                    axi_wdata = {16'b0, rs2_data[15:0]}; 
                end else begin
                    axi_wstrb = 4'b1100; // Üst 2 bayt
                    axi_wdata = {rs2_data[15:0], 16'b0}; 
                end
            end
            
            // SW (Store Word) durumu zaten varsayılan atamada halledildi.
            default: ; 
        endcase
    end

endmodule