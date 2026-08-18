`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/25/2026 02:54:33 PM
// Design Name: 
// Module Name: ex_block
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
typedef enum logic [1:0] {
    IDLE  = 2'b00,
    WRITE = 2'b01,
    STORE = 2'b10, // Dikkat: Orijinal kodda WRITE ile aynıydı (2'b01), 2'b10 yapıldı.
    LOAD  = 2'b11
} opcode_t;

module ex_block(
    input logic         clk,
    input logic         rstn,
    input opcode_t    opcode_i,
    input logic[2:0]    func3_i,
    input logic         stall_i,
    output logic        stall_o,
    
    input logic[31:0]   data_0i,
    input logic[31:0]   data_1i,
    
    input logic[31:0]   pc_i,
    output logic[31:0]  pc_o,
    
    output logic[31:0]  data_o,
    output logic        wb_opcode,
    
    output logic[4:0]   rd_o,
    output logic[1:0]   req,
    output logic        req_valid_o,
    output logic        df_valid,
    
    input logic[4:0]    rd_i,
    
    output opcode_t    opcode,
    
    axi4_if.master      axi_bus
    
    );
assign stall_o = !req[1];
    logic        req_valid;
    logic[2:0]    func3;
   
     
    logic stall;
     
    logic ar_fire,r_fire,aw_fire,w_fire;
     
    logic[31:0] data_0,data_1;
    
    logic[31:0] ldata;
    
    rdata_formatter d_formatter(
    .func3(func3),       // RISC-V komutunun funct3 kısmı
    .addr_align(data_0[1:0]),  // Adresin en alt 2 biti (addr[1:0])
    .rdata(axi_bus.rdata),   // AXI4'ten gelen 32-bit ham veri
    
    .rdout(ldata) 
    );
    sdata_controller(
    .func3(func3),       // RISC-V komutu funct3 (sb, sh, sw)
    .addr(data_0),        // RAM'e yazılacak 32-bit adres
    .rs2_data(data_1),    // Register'dan gelen ham veri (yazılacak veri)
    
    // AXI Çıkışları
    .axi_wstrb(axi_bus.wstrb),   // AXI Hangi baytlar yazılacak
    .axi_wdata(axi_bus.wdata)    // AXI Hizalanmış yazma verisi
    );
    
    assign df_valid = opcode == WRITE | (opcode == LOAD & req_valid); 
     
    assign axi_bus.araddr = {data_0[31:2],2'b00};
    assign axi_bus.awaddr = {data_0[31:2],2'b00};
     
    assign axi_bus.arvalid = opcode == LOAD & !req[0];
    assign axi_bus.rready = opcode == LOAD & (req[0]|ar_fire);
    assign axi_arsize = 3'b011;
     
    assign axi_bus.awvalid = opcode == STORE & !req[0];
    assign axi_bus.wvalid = opcode == STORE & (req[0]|aw_fire);
    assign axi_awsize = 3'b011;
         
    assign ar_fire = axi_bus.arvalid &axi_bus.arready;
    assign r_fire = axi_bus.rvalid &axi_bus.rready;
     
    assign aw_fire = axi_bus.awvalid &axi_bus.awready;
    assign w_fire = axi_bus.wvalid &axi_bus.wready;
     
    assign req_valid = (opcode==STORE & w_fire)|(opcode==LOAD & r_fire); 
    assign data_o = opcode == LOAD ? ldata : data_0; 
    assign wb_opcode = opcode == WRITE;      
    assign req_valid_o = opcode == LOAD&req_valid;
    always_ff @(posedge clk or negedge rstn)begin
        if(!rstn)begin
            opcode <= IDLE;
            req[0]<=0;
            req[1]<=1;
        end else begin         
            if(req[1]|(!req[1]&req_valid))begin
                pc_o <= pc_i;
                opcode <= opcode_i;
                if(opcode != IDLE)begin
                    func3 <= func3_i; 
                    rd_o<=rd_i;
                    data_0 <= data_0i;
                    data_1 <= data_1i;
                end
            end
            if(opcode == LOAD)begin
                if(!req[0])begin
                    req[1]<=0;
                    if(!ar_fire)begin
                        req[0]<=0;
                    end else begin
                        req[0]<=1;
                    end
                end else begin
                    if(r_fire)begin
                        req[0]<=0;
                        req[1]<=1;
                    end else begin
                        req[0]<=1;
                        req[1]<=0;
                    end
                end
            end else if(opcode == STORE)begin
                if(!req[0])begin
                    req[1]<=0;
                    if(!aw_fire)begin
                        req[0] <= 0;
                    end else begin
                        req[0] <= 1;
                    end
                end else begin
                    if(w_fire)begin
                        req[0]<=0;
                        req[1]<=1;
                        
                    end else begin
                        req[0]<=1;
                        req[1]<=0;
                    end
                end
            end
        end
     end
         // AW Kanalı (Adres Yazma)
    assign axi_awlen   = 8'h00;   // Sadece 1 paket (beat) veri gönderilecek
    assign axi_awburst = 2'b01;   // INCR modu (Tek paket için de standart budur)
    assign axi_awlock  = 1'b0;    // Normal erişim (Özel kilit yok)
    assign axi_awcache = 4'b0000; // Önbellek kullanmıyoruz (Non-cacheable)
    assign axi_awprot  = 3'b000;  // Standart veri erişimi (Güvenlik zırhı yok)
    assign axi_awqos   = 4'b0000; // QoS (Önceliklendirme) yok
    
    // W Kanalı (Veri Yazma)
    assign axi_wlast   = 1'b1;    // Gönderdiğimiz tek veri her zaman "son (last)" veridir.
    
    assign axi_arlen   = 8'h00;   // Sadece 1 paket veri okunacak
    assign axi_arburst = 2'b01;   // INCR modu
    assign axi_arlock  = 1'b0;    
    assign axi_arcache = 4'b0000; 
    assign axi_arprot  = 3'b000;  
    assign axi_arqos   = 4'b0000;
endmodule
interface axi4_if #(
    parameter int ADDR_WIDTH = 32, // Adres Genişliği
    parameter int DATA_WIDTH = 32, // Veri Genişliği (Burst'lerde genelde 64/128/256 olur)
    parameter int ID_WIDTH   = 4,  // İşlem Kimliği (ID) Genişliği
    parameter int USER_WIDTH = 1   // Kullanıcı tanımlı sinyallerin (USER) genişliği
)(
    input logic aclk,    // AXI Saati
    input logic aresetn  // AXI Aktif Düşük Reset
);

    // ---------------------------------------------------------
    // 1. YAZMA ADRESİ KANALI (AW - Address Write)
    // ---------------------------------------------------------
    logic [ID_WIDTH-1:0]   awid;     // İşlem kimliği
    logic [ADDR_WIDTH-1:0] awaddr;   // Başlangıç adresi
    logic [7:0]            awlen;    // Burst Uzunluğu (AXI4'te 8-bit: 1-256 aktarım)
    logic [2:0]            awsize;   // Her bir aktarımın boyutu (000: 1 Byte, 010: 4 Byte)
    logic [1:0]            awburst;  // Burst Tipi (00: Fixed, 01: INCR, 10: WRAP)
    logic                  awlock;   // Özel erişim (AXI4'te 1-bit: Exclusive access)
    logic [3:0]            awcache;  // Hafıza tipi (Önbelleklenebilir mi?)
    logic [2:0]            awprot;   // Koruma tipi (Güvenli/Normal/Ayrıcalıklı)
    logic [3:0]            awqos;    // Quality of Service (Öncelik)
    logic [3:0]            awregion; // Adres Bölgesi tanımlayıcı (AXI4 eklentisi)
    logic [USER_WIDTH-1:0] awuser;   // Kullanıcı tanımlı sinyal
    logic                  awvalid;  // Master adresi hatta koydu
    logic                  awready;  // Slave adresi almaya hazır

    // ---------------------------------------------------------
    // 2. YAZMA VERİSİ KANALI (W - Write Data)
    // ---------------------------------------------------------
    // Not: AXI4'te 'wid' sinyali kaldırılmıştır, veriler sıralı gitmek zorundadır.
    logic [DATA_WIDTH-1:0]     wdata;    // Yazılacak veri
    logic [(DATA_WIDTH/8)-1:0] wstrb;    // Byte seçici
    logic                      wlast;    // Burst'ün SON verisi olduğunu belirtir
    logic [USER_WIDTH-1:0]     wuser;    // Kullanıcı tanımlı sinyal
    logic                      wvalid;   // Master veriyi hatta koydu
    logic                      wready;   // Slave veriyi almaya hazır

    // ---------------------------------------------------------
    // 3. YAZMA CEVAP KANALI (B - Write Response)
    // ---------------------------------------------------------
    logic [ID_WIDTH-1:0]   bid;      // Hangi ID'li işlemin cevabı?
    logic [1:0]            bresp;    // Yazma sonucu (00: OKAY, 01: EXOKAY, 10: SLVERR, 11: DECERR)
    logic [USER_WIDTH-1:0] buser;    // Kullanıcı tanımlı sinyal
    logic                  bvalid;   // Slave cevabı hatta koydu
    logic                  bready;   // Master cevabı almaya hazır

    // ---------------------------------------------------------
    // 4. OKUMA ADRESİ KANALI (AR - Address Read)
    // ---------------------------------------------------------
    logic [ID_WIDTH-1:0]   arid;     // İşlem kimliği
    logic [ADDR_WIDTH-1:0] araddr;   // Başlangıç adresi
    logic [7:0]            arlen;    // Burst Uzunluğu
    logic [2:0]            arsize;   // Her paketin boyutu
    logic [1:0]            arburst;  // Burst Tipi
    logic                  arlock;   // Özel erişim (AXI4'te 1-bit)
    logic [3:0]            arcache;  // Hafıza tipi
    logic [2:0]            arprot;   // Koruma tipi
    logic [3:0]            arqos;    // Quality of Service
    logic [3:0]            arregion; // Adres Bölgesi tanımlayıcı
    logic [USER_WIDTH-1:0] aruser;   // Kullanıcı tanımlı sinyal
    logic                  arvalid;  // Master adresi hatta koydu
    logic                  arready;  // Slave adresi almaya hazır

    // ---------------------------------------------------------
    // 5. OKUMA VERİSİ KANALI (R - Read Data)
    // ---------------------------------------------------------
    logic [ID_WIDTH-1:0]   rid;      // Hangi ID'li isteğin verisi?
    logic [DATA_WIDTH-1:0] rdata;    // Okunan veri
    logic [1:0]            rresp;    // Okuma durumu (00: OKAY, 01: EXOKAY, 10: SLVERR, 11: DECERR)
    logic                  rlast;    // Burst'ün SON paketi mi?
    logic [USER_WIDTH-1:0] ruser;    // Kullanıcı tanımlı sinyal
    logic                  rvalid;   // Slave veriyi hatta koydu
    logic                  rready;   // Master veriyi almaya hazır

    // =========================================================
    // MODPORTS (YÖNLENDİRİCİLER)
    // =========================================================
    
    // Master Cihazı (İşlemci, DMA, Cache Controller)
    modport master (
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid, 
               wdata, wstrb, wlast, wuser, wvalid, bready, 
               arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid, rready,
        
        input  awready, wready, bid, bresp, buser, bvalid, arready, rid, rdata, rresp, rlast, ruser, rvalid
    );

    // Slave Cihazı (RAM, Çevre Birimleri)
    modport slave (
        input  awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awqos, awregion, awuser, awvalid, 
               wdata, wstrb, wlast, wuser, wvalid, bready, 
               arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arqos, arregion, aruser, arvalid, rready,
        
        output awready, wready, bid, bresp, buser, bvalid, arready, rid, rdata, rresp, rlast, ruser, rvalid
    );

endinterface