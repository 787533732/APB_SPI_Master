module apb_spi_master (
       
    input   wire            pclk_i      ,
    input   wire            prstn_i     ,
    //apb接口
    input   wire [31:0]     paddr_i     ,
    input   wire            pwrite_i    ,//1为写，0为读
    input   wire            psel_i      ,
    input   wire            penable_i   ,
    input   wire [31:0]     pwdata_i    ,
    output  wire [31:0]     prdata_o    ,
    output  wire            pready_o    ,
    //spi接口
    output  wire            sck         ,
    output  wire            mosi        ,
    input   wire            miso        ,
    output  wire            nss            
);   

    wire [7:0]  spi_clk_div_o;    
    wire        spi_clk_div_vld_o;
    wire        eot_o;
    wire [31:0] spi_data_rx_o;    
    wire        spi_data_rx_vld_o;
    wire [31:0] stream_data_o;    
    wire        stream_data_vld_o;
    wire [31:0] fifo_data_o;
    wire        fifo_data_vld_o;
    wire        fifo_data_rdy_i;
    
    apb_interface u_apb_interface(
        .pclk_i              (pclk_i            ),
        .prstn_i             (prstn_i           ),  
        //apb
        .paddr_i             (paddr_i           ),
        .pwrite_i            (pwrite_i          ),
        .psel_i              (psel_i            ),
        .penable_i           (penable_i         ),
        .pwdata_i            (pwdata_i          ),
        .prdata_o            (prdata_o          ),
        .pready_o            (pready_o          ),
        //spi
        .spi_data_rx_i       (spi_data_rx_o     ),
        .spi_data_rx_vld_i   (spi_data_rx_vld_o ),
        .stream_data_o       (stream_data_o     ),
        .stream_data_vld_o   (stream_data_vld_o ),
        .spi_clk_div_o       (spi_clk_div_o     ),
        .spi_clk_div_vld_o   (spi_clk_div_vld_o ),
        
        .eot_i               (eot_o             )
    );
    fifo tx_fifo(
        .clk_i               (pclk_i            ),
        .rstn_i              (prstn_i           ),      
         
        .data_i              (stream_data_o     ),
        .data_vld_i          (stream_data_vld_o ),
        .data_rdy_o          (                  ),
         
        .data_o              (fifo_data_o       ),
        .data_vld_o          (fifo_data_vld_o   ),
        .data_rdy_i          (fifo_data_rdy_i   )
    );
    //SPI_controller和APB无握手，APB通过SPI发送数据时有FIFO缓冲
    spi_master_controller u_spi_master_controller(
        .clk_i               (pclk_i            ),
        .rstn_i              (prstn_i           ),
        .spi_clk_div_i       (spi_clk_div_o     ),
        .spi_clk_div_vld_i   (spi_clk_div_vld_o ),
    
        .stream_data_i       (fifo_data_o       ),//数据至少保持2个时钟周期
        .stream_data_vld_i   (fifo_data_vld_o   ),
        .stream_data_rdy_o   (fifo_data_rdy_i   ),    
    
        .spi_data_rx_o       (spi_data_rx_o     ),
        .spi_data_rx_vld_o   (spi_data_rx_vld_o ),
        .spi_data_rx_rdy_i   (1'b1              ),
        //SPI主机<->SPI从机
        .spi_clk_o           (sck               ),
        .spi_cs_n_o          (nss               ),
        .spi_sdo_o           (mosi              ),
        .spi_sdi_i           (miso              ),
    
        .eot_o               (eot_o             )//end of transmission            
    );

endmodule