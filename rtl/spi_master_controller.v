module spi_master_controller (
    input   wire                clk_i               ,
    input   wire                rstn_i              ,
    //分频模块接口
    input   wire [7:0]          spi_clk_div_i       ,
    input   wire                spi_clk_div_vld_i   ,
    //发送模块接口
    input   wire [31:0]         stream_data_i       ,//数据至少保持2个时钟周期
    input   wire                stream_data_vld_i   ,
    output  wire                stream_data_rdy_o   ,
    //接收模块接口
    output  wire [31:0]         spi_data_rx_o       ,
    output  wire                spi_data_rx_vld_o   ,
    input   wire                spi_data_rx_rdy_i   ,
    //SPI主机<->SPI从机
    output  wire                spi_clk_o           ,
    output  reg                 spi_cs_n_o          ,
    output  wire                spi_sdo_o           ,
    input   wire                spi_sdi_i           ,
    //传输完成标志
    output  reg                 eot_o                //end of transmission            
);
    //APB总线发出的CMD
    localparam WR_REQ  = 4'b1011;
    localparam RD_REQ  = 4'b1010;
    //SPI控制器的不同传输状态
    localparam IDLE    = 3'd0;
    localparam CMD     = 3'd1;        
    localparam ADDR    = 3'd2;
    localparam DUMMY   = 3'd3;//暂停状态
    localparam TX_DATA = 3'd4;
    localparam RX_DATA = 3'd5;
    localparam EOT     = 3'd6;//传输结束状态
    //转移条件变量声明
    wire       idle2cmd;
    wire       cmd2addr;
    wire       addr2dum;
    wire       dum2tx;
    wire       dum2rx;
    wire       txrx2eot;
    wire       eot2idle;

    reg        spi_clock_en;
    reg        spi_tx_en;
    reg        spi_rx_en;

    reg [15:0] tx_len;
    reg        tx_len_vld;
    reg [15:0] rx_len;
    reg        rx_len_vld;

    reg [31:0] data_tx;
    reg        data_tx_vld;

    reg [7:0]  dummy_cnt;

    wire       rx_done;
    wire       tx_done;
    reg [2:0]  master_cs;
    reg [2:0]  master_ns;

    wire       spi_rise_edge;
    wire       spi_fall_edge; 

    reg [3:0]  cmd;
    reg [3:0]  addr;
    reg [7:0]  wr_rd_len;
    reg [15:0] wr_data;
    wire       spi_rd_req;
    wire       spi_wr_req;

    reg        stream_data_vld_1;
    wire       stream_data_vld_dly;

    //来自APB接口的数据初始化
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            {cmd, addr, wr_rd_len, wr_data} <= 32'h0;
        end else if(eot_o) begin
            {cmd, addr, wr_rd_len, wr_data} <= 32'h0;
        end else if((master_cs == IDLE) && stream_data_vld_i) begin
            {cmd, addr, wr_rd_len, wr_data} <= stream_data_i;
        end
    end
    assign stream_data_rdy_o = master_cs == IDLE;
    assign spi_wr_req = cmd == WR_REQ;
    assign spi_rd_req = cmd == RD_REQ;

    clk_gen u_clk_gen(
        .clk_i           (clk_i             ),
        .rstn_i          (rstn_i            ),
        .clock_en_i      (spi_clock_en      ),
        .clk_div_i       (spi_clk_div_i     ),
        .clk_div_vld_i   (spi_clk_div_vld_i ),  

        .spi_clk_o       (spi_clk_o         ),
        .rise_edge_o     (spi_rise_edge     ),
        .fall_edge_o     (spi_fall_edge     )        
    );
    spi_tx u_spi_tx(
        .clk_i           (clk_i             ),
        .rstn_i          (rstn_i            ),
        .en_i            (spi_tx_en         ),
        .tx_edge_i       (spi_fall_edge     ),//下降沿发送数据
        .sdo_o           (spi_sdo_o         ),
        .tx_done_o       (tx_done           ),//一个数据包传输完成
        .tx_len_i        (tx_len            ),
        .tx_len_updata_i (tx_len_vld        ),
        .tx_data_i       (data_tx           ),
        .tx_data_vld_i   (data_tx_vld       ),
        .tx_data_rdy_o   (                  )//握手信号不支持反压
    );  
    spi_rx u_spi_rx(
        .clk_i           (clk_i             ),
        .rstn_i          (rstn_i            ),
        .en_i            (spi_rx_en         ),
        .rx_edge_i       (spi_rise_edge     ),//上升沿接收数据
        .sdi_i           (spi_sdi_i         ),
        .rx_done_o       (rx_done           ),//一个数据包传输完成
        .rx_len_i        (rx_len            ),
        .rx_len_updata_i (rx_len_vld        ),
        .rx_data_o       (spi_data_rx_o     ),
        .rx_data_vld_o   (spi_data_rx_vld_o ),
        .rx_data_rdy_i   (spi_data_rx_rdy_i )//默认为1
    );
    ////////转移条件变量////////下个时钟到来时就会变成次态
    assign idle2cmd = (master_cs == IDLE   ) && (stream_data_vld_i) && (spi_rd_req || spi_wr_req);//读写请求比fifo读的数据满一个时钟，这里用了延迟的vld信号
    assign cmd2addr = (master_cs == CMD    ) && tx_done;
    assign addr2dum = (master_cs == ADDR   ) && tx_done;
    assign dum2tx   = (master_cs == DUMMY  ) && (dummy_cnt == 'd2) && (spi_wr_req);
    assign dum2rx   = (master_cs == DUMMY  ) && (dummy_cnt == 'd2) && (spi_rd_req);
    assign txrx2eot =((master_cs == TX_DATA) && tx_done) ||
                     ((master_cs == RX_DATA) && rx_done);
    assign eot2idle = (master_cs == EOT    ) && spi_fall_edge;//传输完成后等待下个下降沿进入IDLE

    //**********************三段式状态机***************************//
    //1.状态更新
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            master_cs <= IDLE;
        end else begin
            master_cs <= master_ns;
        end
    end
    //2.状态转移条件
    always @(*) begin
        case (master_cs)
            IDLE    : master_ns = idle2cmd ? CMD   : master_cs;
            CMD     : master_ns = cmd2addr ? ADDR  : master_cs;
            ADDR    : master_ns = addr2dum ? DUMMY : master_cs;
            DUMMY   : if(dum2tx) begin
                        master_ns = TX_DATA;
                      end else if(dum2rx) begin
                        master_ns = RX_DATA;
                      end else begin
                        master_ns = master_cs;
                      end
            TX_DATA : master_ns = txrx2eot ? EOT   : master_cs;
            RX_DATA : master_ns = txrx2eot ? EOT   : master_cs;
            EOT     : master_ns = eot2idle ? IDLE  : master_cs;
            default : master_ns = IDLE;
        endcase
    end
    //3.每个状态的输出
    //clk_gen enable
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            spi_clock_en <= 1'b0; 
        end else if(idle2cmd) begin
            spi_clock_en <= 1'b1;
        end else if(eot2idle) begin
            spi_clock_en <= 1'b0; 
        end
    end
    //spi_tx enable
    always @(posedge clk_i or negedge rstn_i ) begin
        if(!rstn_i) begin
            spi_tx_en <= 1'b0;
        end else if(idle2cmd || cmd2addr || dum2tx) begin
            spi_tx_en <= 1'b1;
        end else if(addr2dum || txrx2eot) begin
            spi_tx_en <= 1'b0;
        end
    end
    //spi_rx enable
    always @(posedge clk_i or negedge rstn_i ) begin
        if(!rstn_i) begin
            spi_rx_en <= 1'b0;
        end else if(dum2rx) begin
            spi_rx_en <= 1'b1;
        end else if(txrx2eot) begin
            spi_rx_en <= 1'b0;
        end
    end
    //tx_length enable
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            tx_len     <= 'd0;
            tx_len_vld <= 'd0;
        end else if((master_cs == CMD) || (master_cs == ADDR)) begin
            tx_len     <= 'd4;//CMD ADDR长度为4
            tx_len_vld <= 'd1;
        end else if(master_cs == TX_DATA) begin
            tx_len     <= wr_rd_len;//
            tx_len_vld <= 'd1;
        end else begin
            tx_len     <= 'd0;
            tx_len_vld <= 'd0; 
        end
    end
    //rx_length enable
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            rx_len     <= 'd0;
            rx_len_vld <= 'd0;
        end else if(master_cs == RX_DATA) begin
            rx_len     <= wr_rd_len;//
            rx_len_vld <= 'd1;
        end else begin
            rx_len     <= 'd0;
            rx_len_vld <= 'd0; 
        end
    end
    //决定哪些数据让tx发
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            data_tx     <= 'd0;
            data_tx_vld <= 'd0;
        end else if(idle2cmd) begin
            data_tx     <= {cmd, 28'h0};
            data_tx_vld <= 'd1;
        end else if(cmd2addr) begin
            data_tx     <= {addr, 28'h0};
            data_tx_vld <= 'd1;  
        end else if(dum2tx) begin
            data_tx     <= {wr_data, 16'h0};
            data_tx_vld <= 'd1;
        end else if(addr2dum || txrx2eot || eot2idle) begin
            data_tx     <= 'd0;
            data_tx_vld <= 'd1;
        end
    end
    //dummy cnt
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            dummy_cnt <= 'd0;
        end else if(addr2dum) begin
            dummy_cnt <= 'd0;//刚进入DUMMY状态时清零
        end else if((master_cs == DUMMY) && spi_fall_edge) begin
            dummy_cnt <= dummy_cnt + 1'd1;
        end
    end
    //spi_cs_n
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            spi_cs_n_o <= 1'b1;
        end else if(idle2cmd) begin
            spi_cs_n_o <= 1'b0;//刚进入CMD状态时片选信号有效
        end else if(txrx2eot) begin
            spi_cs_n_o <= 1'b1;//刚进入EOT状态时片选信号无效
        end
    end
    //eot_output
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            eot_o <= 1'b0;
        end else if(master_cs == EOT) begin
            eot_o <= 1'b1;//慢一个周期
        end else begin
            eot_o <= 1'b0;
        end
    end
    
endmodule