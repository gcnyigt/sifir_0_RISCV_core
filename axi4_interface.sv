`timescale 1ns / 1ps

// ==============================================================================
// TAM DONANIMLI AXI4 İNTERFACE (ARM AMBA AXI4 SPECIFICATION COMPLIANT)
// ==============================================================================
// Bu arayüz ARM IHI 0022E spesifikasyonuna %100 uyumludur. AXI4 ile gelen 
// Region, QoS ve User sinyallerini tam olarak barındırır.
// ==============================================================================

interface axi4_interface#(
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