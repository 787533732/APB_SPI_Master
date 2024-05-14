`define CMD   4'd0//0x00
`define ADDR  4'd1//0x04
`define LEN   4'd2//0x08
`define WDATA 4'd3//0x0c
`define RDATA 4'd4//0x10
`define CTRL  4'd5//0x14

module apb_interface (
    input   wire            pclk_i              ,
    input   wire            prstn_i             ,  
    //apb_interface     
    input   wire [31:0]     paddr_i             ,
    input   wire            pwrite_i            ,
    input   wire            psel_i              ,
    input   wire            penable_i           ,
    input   wire [31:0]     pwdata_i            ,
    output  reg  [31:0]     prdata_o            ,
    output  wire            pready_o            ,
    output  wire            pslverr_o           ,
    //spi
    input   wire [31:0]     spi_data_rx_i       ,
    input   wire            spi_data_rx_vld_i   ,
    output  wire [31:0]     stream_data_o       ,
    output  wire            stream_data_vld_o   ,
    input   wire            stream_data_rdy_i   ,//反压信号
    output  wire [7:0]      spi_clk_div_o       ,
    output  wire            spi_clk_div_vld_o   ,
    
    input   wire            eot_i           
);
    
    wire wr_en = psel_i && penable_i && pwrite_i && stream_data_rdy_i;//fifo未满
    wire rd_en = psel_i && penable_i && ~pwrite_i;
    assign pready_o = wr_en || rd_en;//反压信号

    reg  [31:0] regs[0:5];
    wire [2:0]  addr_offset;
    assign addr_offset = paddr_i[31:2];//除以4
    //write
    always @(posedge pclk_i or negedge prstn_i) begin
        if(!prstn_i) begin            
            regs[`CMD  ] <= 'h0;    
            regs[`ADDR ] <= 'h0;    
            regs[`LEN  ] <= 'h0;    
            regs[`WDATA] <= 'h0;   
            regs[`CTRL ] <= 'h0;
        end else if(eot_i) begin
            regs[`CTRL][0] <= 1'b0;
        end else if(wr_en) begin
            case (addr_offset)
                `CMD   : regs[`CMD  ] <= pwdata_i;
                `ADDR  : regs[`ADDR ] <= pwdata_i;
                `LEN   : regs[`LEN  ] <= pwdata_i;
                `WDATA : regs[`WDATA] <= pwdata_i;
                `CTRL  : regs[`CTRL ] <= pwdata_i;
            endcase
        end
    end
    //read
    always @(posedge pclk_i or negedge prstn_i) begin
        if(!prstn_i) begin
            regs[`RDATA] <= 'h0; 
        end else if(spi_data_rx_vld_i) begin
            regs[`RDATA] <= spi_data_rx_i;
        end
    end
    //寄存器操作
    always @(posedge pclk_i or negedge prstn_i) begin
        if(!prstn_i) begin
            prdata_o <= 32'h00ad_da7a;
        end else if(rd_en) begin
            case (addr_offset)
            `CMD   :  prdata_o <= regs[`CMD  ];
            `ADDR  :  prdata_o <= regs[`ADDR ];
            `LEN   :  prdata_o <= regs[`LEN  ];
            `RDATA :  prdata_o <= regs[`RDATA];
            `WDATA :  prdata_o <= regs[`WDATA];
            `CTRL  :  prdata_o <= regs[`CTRL ];
            endcase
        end
    end

    //output to spi_tx
    assign stream_data_o = {regs[`CMD][3:0], regs[`ADDR][3:0], regs[`LEN][7:0], regs[`WDATA][15:0]};

    reg  valid ;
    wire valid_last;
    assign  valid_last = regs[`CTRL][0];

    always @(posedge pclk_i or negedge prstn_i) begin
        if(!prstn_i)
            valid <= 1'b0;
        else    //让输出给发送模块的数据有效信号多保持一个时钟，让FIFO捕获
            valid <= valid_last;
    end
    assign stream_data_vld_o = ~valid && valid_last;//上升沿检测


    assign spi_clk_div_o = regs[`CTRL][15:8];
    assign spi_clk_div_vld_o = 1'b1;

    assign pslverr_o = 1'b0;
endmodule