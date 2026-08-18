module reg_file (
    input  logic        clk,
    input  logic        we,         // Write Enable
    input  logic [4:0]  rs1_addr,   // Source Register 1 Address
    input  logic [4:0]  rs2_addr,   // Source Register 2 Address
    input  logic [4:0]  rs1_b_addr,
    input  logic [4:0]  rd_addr,    // Destination Register Address
    input  logic [31:0] rd_data,    // Data to be written
    
    output logic [31:0] rs1_data,   // Source Register 1 Data
    output logic [31:0] rs2_data,    // Source Register 2 Data
    output logic [31:0] rs1_b_data
);

    // 32 adet 32-bitlik yazmaç dizisi
    // SystemVerilog'da [31:0] genişlik, [0:31] ise derinliktir (dizi boyutu)
    logic [31:0] registers [0:31];

    // ---------------------------------------------------------
    // YAZMA İŞLEMİ (Senkron - Saat Vuruşuyla)
    // ---------------------------------------------------------
    always_ff @(posedge clk) begin
        // Yazma izni varsa VE hedef yazmaç x0 (sıfırıncı yazmaç) DEĞİLSE yaz.
        // Bu sayede donanım x0'a veri yazmaya çalışırken güç (switching power) harcamaz.
        if (we && (rd_addr != 5'b00000)) begin
            registers[rd_addr] <= rd_data;
        end
    end

    // ---------------------------------------------------------
    // OKUMA İŞLEMİ (Asenkron - Kombinasyonel)
    // ---------------------------------------------------------
    // Decode aşamasında komut geldiği an (saat vuruşunu beklemeden) veri hazır olmalıdır.
    // x0 yazmacı donanımsal olarak doğrudan 0'a topraklanır (Hardwired to 0).
    
    assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 : registers[rs2_addr];
    assign rs1_b_data = (rs1_addr == 5'b00000) ? 32'b0 : registers[rs1_b_addr];

endmodule