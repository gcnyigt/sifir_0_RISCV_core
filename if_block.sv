`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/17/2026 02:39:02 PM
// Design Name: 
// Module Name: if_block
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


module if_block(
    input logic         clk,
    input logic         rstn,
    
    output logic[31:0]  pc,
    output logic[31:0]  ip,
    output logic        ip_valid,
    
    input logic         jreq,
    input logic[31:0]   jaddr,
    
    
    input logic         new_instr_req,
    
    output logic        stall_o,
    axi4_if.master      axi_bus
    );
    assign axi_bus.awvalid = 1'b0;
    assign axi_bus.awid    = '0;
    assign axi_bus.awaddr  = '0;
    assign axi_bus.awlen   = '0;
    assign axi_bus.awsize  = '0;
    assign axi_bus.awburst = '0;
    assign axi_bus.awcache = '0;
    assign axi_bus.awprot  = 3'b000;
    assign axi_bus.awqos   = '0;
    assign axi_bus.awregion= '0;
    assign axi_bus.awuser  = '0;
    
    assign axi_bus.wvalid  = 1'b0;
    assign axi_bus.wdata   = '0;
    assign axi_bus.wstrb   = '0;
    assign axi_bus.wlast   = 1'b0;
    assign axi_bus.wuser   = '0;
    
    assign axi_bus.bready  = 1'b0;
    
    // AXI Okuma (Read) Sabitleri
    assign axi_bus.arid    = 4'b0000;
    assign axi_bus.arlen   = 8'h00;  
    assign axi_bus.arsize  = 3'b010; 
    assign axi_bus.arburst = 2'b00;  
    assign axi_bus.arcache = 4'b0000;
    assign axi_bus.arprot  = 3'b000;
    assign axi_bus.arqos   = 4'b0000;
    assign axi_bus.arregion= 4'b0000;
    assign axi_bus.aruser  = '0;
    logic                 b_rstn;

    logic                w_en;
    logic                r_en;
    logic[31 :0]         din;
    logic[31 :0]         dout;
    logic                bempty;
    logic                bfull;     
    
    pf_buffer#(.DEPTH (2),.WIDTH(32))prefetch_buffer(

    .clk(clk),

    .rstn(b_rstn),

    .r_en(r_en),

    .w_en(w_en),

    .din(din),

    .dout(ip),

    .empty(bempty),

    .full(bfull)

    );
    logic ar_fire,r_fire;
    logic[31 :0]  c_pc,n_pc;
    logic trash_state;
    logic[1:0] trash_cnt,outstnd_cnt,next_outstnd_cnt;
    assign ar_fire = axi_bus.arvalid&axi_bus.arready;
    assign r_fire = axi_bus.rvalid&axi_bus.rready;
    assign trash_state = trash_cnt != 0;
    assign axi_bus.rready = !bfull&rstn; 
    assign din = axi_bus.rdata;
    assign ip = dout;
    assign w_en = r_fire&!trash_state&rstn;
    assign axi_bus.araddr = c_pc;
    assign r_en = new_instr_req&((r_fire|!bempty)&!trash_state&!jreq);
    logic new_instr_req_d;
    always_comb begin
        if(ar_fire&!r_fire)begin
            next_outstnd_cnt = outstnd_cnt+1;
        end else if(!ar_fire&r_fire)begin
            next_outstnd_cnt = outstnd_cnt-1;
        end else begin
             next_outstnd_cnt = outstnd_cnt;
        end
    end
    always_ff@(posedge clk or negedge rstn)begin
        if(!rstn)begin
            outstnd_cnt<=0;
            trash_cnt <= 0;
            pc <= 0;
            n_pc <= 4;
            c_pc <= 0;
            ip_valid <= 0;
            axi_bus.arvalid <= 0;
            b_rstn <= 0;
            new_instr_req_d <= 1;
        end else begin
            new_instr_req_d <=new_instr_req;
            ip_valid <= (r_fire|!bempty)&!trash_state&!jreq;
            outstnd_cnt<=next_outstnd_cnt;
            if(ar_fire)begin
                if(jreq)begin
                    c_pc <= jaddr;
                end else begin
                    c_pc <= n_pc;
                end
                
                if(next_outstnd_cnt<3)begin
                    axi_bus.arvalid <= 1;
                end else begin
                    axi_bus.arvalid <= 0;
                end
            end else begin
                axi_bus.arvalid <= 1;    
            end
            if(jreq)begin
                b_rstn <= 0;
                n_pc <= jaddr+4;
                pc <= jaddr;
                if(trash_state)begin
                    trash_cnt<= 0;
                end else begin
                    trash_cnt<= next_outstnd_cnt;
                end
            end else begin
               
                b_rstn <= 1;
                if(ip_valid&new_instr_req_d)begin
                        pc <= pc+4;

                    
                end
                if(ar_fire)begin
                    n_pc <= n_pc +4;
                end
                if(r_fire&trash_state)begin
                    trash_cnt <= trash_cnt-1;
                end
            end 
        
        end
    end
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
