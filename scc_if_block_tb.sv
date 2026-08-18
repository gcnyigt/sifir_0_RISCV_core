`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2026 12:30:19 PM
// Design Name: 
// Module Name: scc_if_block_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
//////////////////////////////////////////////////////////////////////////////////

module scc_if_block_tb(); // Testbench'lerin port listesi boş olur

    logic              rstn;
    logic              clk;
    
    reg              je;
    logic [31:0]       jaddr;

    logic [31:0]       ip;
    logic              ip_valid;
    logic [31:0]       pc;

    logic              stall_i;
    logic              stall_o;

    logic              if_block_err_int;

    // ÇÖZÜM 1: Arayüz (Interface) bir modül gibi yaratılır (Yön belirtilmez!)
    axi4_if axi_bus(
        .aclk(clk),
        .aresetn(rstn)
    );

    logic data_send_succes;
    logic [31:0] word_data;
    logic [7:0] mem[1023:0];

    // ÇÖZÜM 2: Boşluk eklendi
    always #5 clk = ~clk;

    // DUT (Test Edilecek Cihaz) Çağırımı
    scc_if_block dut(
        .rstn(rstn),
        .clk(clk),
        .je(je),
        .jaddr(jaddr),
        .ip(ip),
        .ip_valid(ip_valid),
        .pc(pc),
        .stall_i(stall_i),
        .stall_o(stall_o),
        .if_block_err_int(if_block_err_int),
        .axi_bus(axi_bus) // Arayüz kablosunu bağladık, o kendi "master" olduğunu anlayacak
    );

    logic [31:0] addr;

    assign data_send_succes = (word_data == ip);
    
    // Canvas'taki bellek okuma mantığı başarıyla uygulandı
    assign word_data = {mem[addr+3], mem[addr+2], mem[addr+1], mem[addr]};

    initial begin
        for (int i = 0; i < 1024; i++) begin
            // $urandom 32-bit sayı üretir, sadece alt 8-biti mem[i]'ye yazılır
            mem[i] = $urandom(); 
        end
        
        clk = 0;
        rstn = 0;
        stall_i = 0;
        je = 0;
        jaddr = '0;
        
        #25; // ÇÖZÜM 3: Noktalı virgül eklendi
        $display("sistem başlatıldı");
        rstn = 1;
        
        #40; // Noktalı virgül eklendi
        je = 1;
        jaddr = 32'h0000_0040;
        
        #5;  // Noktalı virgül eklendi
        je = 0;
        
        #200;
        $finish;
    end

    // Basit RAM Simülasyonu (Slave Davranışı)
    always @(posedge clk) begin
        if (rstn) begin
            // Master adres yolladığında kabul et
            if (axi_bus.arvalid) begin
                axi_bus.arready <= 1'b1;
                addr <= axi_bus.araddr;
            end else begin
                axi_bus.arready <= 1'b0;
            end
            
            // Master veri almaya hazırsa ve adres okunduysa veriyi yolla
            if (axi_bus.rready) begin
                axi_bus.rvalid <= 1'b1;
                axi_bus.rdata  <= word_data;
                // AXI Kuralları gereği burst bitişi ve response
                axi_bus.rlast  <= 1'b1; 
                axi_bus.rresp  <= 2'b00;
            end else begin
                axi_bus.rvalid <= 1'b0;
            end
        end else begin
            axi_bus.arready <= 1'b0;
            axi_bus.rvalid  <= 1'b0;
        end
    end

    // Monitör (Gözlemci)
    always @(posedge clk) begin 
        if (rstn) begin
            $display("Mevcut PC : 0x%08h", pc);
            $display("Mevcut IP Geçerli %b Mevcut IP : 0x%08h", ip_valid, ip);
            
            if (ip_valid) begin
                if (data_send_succes) begin
                    $display("Veri başarı ile gönderildi");
                end else begin
                    $display("Veri gönderme başarısız");
                end
            end
        end
    end

endmodule