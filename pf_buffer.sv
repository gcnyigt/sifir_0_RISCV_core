module pf_buffer#(int DEPTH = 2, int WIDTH = 32)(
input logic                 rstn,
input logic                 clk,

input logic                 w_en,
input logic                 r_en,
input logic[WIDTH-1 :0]     din,
output logic[WIDTH-1 :0]    dout,
output logic                empty,
output logic                full 
);
localparam int ptr_w = $clog2(DEPTH);
        logic[ptr_w:0] r_ptr , w_ptr;
        logic[WIDTH-1:0] mem[DEPTH-1:0];
        assign empty = (r_ptr == w_ptr);
        assign full  = ({~r_ptr[ptr_w], r_ptr[ptr_w-1:0]} == w_ptr);
        always_ff@(posedge clk or negedge rstn)begin
            if(!rstn)begin
                r_ptr <= 0;
                w_ptr <= 0;
            end else begin
                if(!empty)begin
                    dout <= mem[r_ptr[ptr_w-1:0]];
                end else begin
                    dout <= din;
                end
                if(r_en)begin
                    r_ptr <= r_ptr +1;
                    
                end
                if(w_en&!full)begin
                    w_ptr <= w_ptr +1;
                    mem[w_ptr[ptr_w-1:0]] <= din;
                end
            end
        end
    
endmodule 
