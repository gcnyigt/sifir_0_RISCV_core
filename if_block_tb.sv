/*`timescale 1ns / 1ps

module scc_if_block_tb();

    // 1. Sinyal Tanımlamaları
    logic        clk = 0;
    logic        rstn;

    logic [31:0] pc;
    logic [31:0] ip;
    logic        ip_valid;

    logic        jreq;
    logic [31:0] jaddr;

    logic        stall_i;
    logic        stall_o;
        logic ar_fire,r_fire;
    logic[31 :0]  c_pc,n_pc;
    logic trash_state;
    logic[1:0] trash_cnt,outstnd_cnt,next_outstnd_cnt;

    // AXI Bus Arayüzü Çağırımı
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) axi_bus (.aclk(clk), .aresetn(rstn));

    // 1KB'lık Sahte Bellek (1024 Bayt)
    logic [7:0] mem [0:1023];

    // Saat Üretimi (100 MHz -> 10ns periyot)
    always #5 clk = ~clk;

    // 2. DUT (Test Edilecek Tasarım) Çağırımı
    if_block dut(
        .clk(clk),
        .rstn(rstn),
        .pc(pc),
        .ip(ip),
        .ip_valid(ip_valid),
        .jreq(jreq),
        .jaddr(jaddr),
        .stall_i(stall_i),
        .stall_o(stall_o),
        .axi_bus(axi_bus),
        .ar_fire(ar_fire),
        .r_fire(r_fire),
        .c_pc(c_pc),
        .n_pc(n_pc),
        .trash_state(trash_state),
        .trash_cnt(trash_cnt),
        .outstnd_cnt(outstnd_cnt),
        .next_outstnd_cnt(next_outstnd_cnt)
    );

    // =========================================================
    // 3. AXI SLAVE (RAM) MANTIĞI: TAM 1-CYCLE GECİKMELİ YANIT
    // =========================================================
    // Bu blok, adres geldiğinde onu alır ve tam 1 clock cycle 
    // sonra rvalid ile veriyi yollar.
    always_ff @(posedge clk) begin
        if (!rstn) begin
            axi_bus.arready <= 1'b1; // RAM başlangıçta adres almaya hazır
            axi_bus.rvalid  <= 1'b0;
            axi_bus.rdata   <= 32'h0;
            axi_bus.rlast   <= 1'b0;
            axi_bus.rresp   <= 2'b00;
        end else begin
            
            // EĞER R KANALINDAKİ VERİ İŞLEMCİ TARAFINDAN ALINDYSA (Handshake bitti)
            if (axi_bus.rvalid && axi_bus.rready) begin
                axi_bus.rvalid  <= 1'b0;
                axi_bus.arready <= 1'b1; // Yeni adres için tekrar hazır ol
            end

            // EĞER ADRES İSTEĞİ GELDİYSE (ARVALID & ARREADY)
            if (axi_bus.arvalid && axi_bus.arready) begin
                axi_bus.arready <= 1'b0; // Veriyi yollayana kadar yeni adres alma
                
                // TAM 1 SAAT VURUŞU SONRASI İÇİN VERİYİ HAZIRLA (Non-blocking atama)
                axi_bus.rvalid <= 1'b1;
                axi_bus.rdata  <= { mem[axi_bus.araddr+3], 
                                    mem[axi_bus.araddr+2], 
                                    mem[axi_bus.araddr+1], 
                                    mem[axi_bus.araddr] };
                axi_bus.rlast  <= 1'b1;
                axi_bus.rresp  <= 2'b00;
            end
            
        end
    end

    // =========================================================
    // 4. TEST SENARYOSU (STIMULUS)
    // =========================================================
    initial begin
        $display("---------------------------------------------------");
        $display("[%0t] SİMÜLASYON BAŞLATILDI", $time);
        
        // Belleği sırayla doldur (Adres 0 -> 0x03020100)
        for (int i = 0; i < 1024; i++) begin
            mem[i] = i; 
        end

        // Başlangıç Değerleri
        rstn    = 0;
        stall_i = 0;
        jreq    = 0;
        jaddr   = 0;

        // Reset beklemesi ve uyandırma
        #35;
        rstn = 1;
        $display("[%0t] RESET KALDIRILDI. Fetch Başlıyor...", $time);

        // İşlemcinin normal akışta birkaç komut okumasını bekle
        #150;
        
        // ==========================================
        // ZIPLAMA (JUMP) İŞLEMİ
        // ==========================================
        $display("\n[%0t] === JUMP TETİKLENİYOR -> Hedef Adres: 0x40 ===", $time);
        @(posedge clk);
        jreq  = 1;
        jaddr = 32'h0000_0040; // 64. adrese zıpla
        
        // Sadece 1 çevrim jreq ver
        @(posedge clk);
        jreq  = 0;

        // Zıplamadan sonraki akışı izle
        #200;

        // Bitiş
        $display("\n[%0t] SİMÜLASYON TAMAMLANDI.", $time);
        $display("---------------------------------------------------");
        $finish;
    end

    // =========================================================
    // 5. GÖZLEMCİ (MONITOR)
    // =========================================================
    always_ff @(posedge clk) begin
        if (rstn && ip_valid && !stall_i) begin
            $display("[%0t] GECERLI KOMUT (IP) -> PC: %08h | VERI: %08h", $time, pc, ip);
        end
    end

endmodule
*/
`timescale 1ns / 1ps

module scc_if_block_tb();
    logic                bempty;
    // 1. Sinyal Tanımlamaları
    logic        clk = 0;
    logic        rstn;

    logic [31:0] pc;
    logic [31:0] ip;
    logic        ip_valid;

    logic        jreq;
    logic [31:0] jaddr;

    logic        new_instr_req;
    logic        stall_o;
    logic ar_fire,r_fire;
    logic[31 :0]  c_pc,n_pc;
    logic trash_state;
    logic[1:0] trash_cnt,outstnd_cnt,next_outstnd_cnt;
    

    // AXI Bus Arayüzü
    axi4_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) axi_bus (.aclk(clk), .aresetn(rstn));

    // 1KB'lık Sahte Bellek (1024 Bayt)
    logic [7:0] mem [0:1023];

    // Saat Üretimi (100 MHz -> 10ns periyot)
    always #5 clk = ~clk;

    // 2. DUT (Test Edilecek Tasarım) Çağırımı
    if_block dut(
        .bempty(bempty),
        .clk(clk),
        .rstn(rstn),
        .pc(pc),
        .ip(ip),
        .ip_valid(ip_valid),
        .jreq(jreq),
        .jaddr(jaddr),
        .new_instr_req(new_instr_req),
        .stall_o(stall_o),
        .axi_bus(axi_bus)
    );

    // =========================================================
    // 3. AXI SLAVE (RAM) MANTIĞI: KESİNTİSİZ STREAMING (PIPELINED)
    // =========================================================
    // RAM her zaman adres almaya hazırdır (arready=1). 
    // Sadece işlemci veriyi henüz çekmediyse (!rready) ve hatta veri varsa adres almayı durdurur.
    assign axi_bus.arready = (!axi_bus.rvalid || axi_bus.rready);

    always_ff @(posedge clk) begin
        if (!rstn) begin
            axi_bus.rvalid <= 1'b0;
            axi_bus.rdata  <= 32'h0;
            axi_bus.rlast  <= 1'b0;
            axi_bus.rresp  <= 2'b00;
        end else begin
            
            // Eğer master veriyi o an çekiyorsa (rvalid & rready), bayrağı indir.
            // Fakat hemen alttaki if bloğu yeni adres geldiyse bayrağı tekrar havada tutacak!
            if (axi_bus.rvalid && axi_bus.rready) begin
                axi_bus.rvalid <= 1'b0; 
            end

            // EĞER ADRES GELDİYSE, BİR SONRAKİ VURUŞ İÇİN VERİYİ HAZIRLA
            // Streaming'in sırrı buradadır: Eski veri okunurken aynı anda yeni adres alınabilir.
            if (axi_bus.arvalid && axi_bus.arready) begin
                axi_bus.rvalid <= 1'b1; // Veri 1 saat vuruşu sonra hazır!
                axi_bus.rdata  <= { mem[axi_bus.araddr+3], 
                                    mem[axi_bus.araddr+2], 
                                    mem[axi_bus.araddr+1], 
                                    mem[axi_bus.araddr] };
                axi_bus.rlast  <= 1'b1;
                axi_bus.rresp  <= 2'b00;
            end
            
        end
    end

    // =========================================================
    // 4. TEST SENARYOSU (STIMULUS)
    // =========================================================
    initial begin
        $display("---------------------------------------------------");
        $display("[%0t] SİMÜLASYON BAŞLATILDI", $time);
        
        // Belleği sırayla doldur (Örn: Adres 0 -> 0x03020100)
        for (int i = 0; i < 1024; i++) begin
            mem[i] = i; 
        end

        // Başlangıç Değerleri
        rstn    = 0;
        new_instr_req = 1;
        jreq    = 0;
        jaddr   = 0;

        // Reset beklemesi ve uyandırma
        #35;
        rstn = 1;
        $display("[%0t] RESET KALDIRILDI. Streaming Fetch Başlıyor...", $time);
        #60;
        new_instr_req = 0;
        #30;
        new_instr_req = 1;
        // İşlemcinin normal akışta birkaç komut akıtmasını bekle
        #150;
        
        // ==========================================
        // ZIPLAMA (JUMP) İŞLEMİ
        // ==========================================
        $display("\n[%0t] === JUMP TETİKLENİYOR -> Hedef Adres: 0x40 ===", $time);
        @(posedge clk);
        jreq  = 1;
        jaddr = 32'h0000_0040; // 64. adrese zıpla
        
        // Sadece 1 çevrim jreq ver
        @(posedge clk);
        jreq  = 0;

        // Zıplamadan sonraki yeni adres akışını izle
        #150;
        new_instr_req = 0;
        @(posedge clk);
        
        jreq  = 1;
        jaddr = 32'h0000_0090; // 64. adrese zıpla
         @(posedge clk);
        jreq  = 0;
        #10;
        new_instr_req = 1;
        #150
        // Bitiş
        $display("\n[%0t] SİMÜLASYON TAMAMLANDI.", $time);
        $display("---------------------------------------------------");
        $finish;
    end

    // =========================================================
    // 5. GÖZLEMCİ (MONITOR)
    // =========================================================
    always_ff @(posedge clk) begin
        if (rstn && ip_valid &&new_instr_req ) begin
            $display("[%0t] GECERLI KOMUT (IP) -> PC: %08h | VERI: %08h", $time, pc, ip);
        end
        
        // Çöp verilerin yakalanmasını da ekrana basalım
        if (rstn && dut.r_fire && dut.trash_state) begin
            $display("[%0t] ---> UYARI: RAM'den gelen bayat veri çöpe atıldı! Kalan çöp: %0d", $time, dut.trash_cnt-1);
        end
    end

endmodule