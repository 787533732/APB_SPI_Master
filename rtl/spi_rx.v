module spi_rx (
    input   wire                clk_i           ,
    input   wire                rstn_i          ,
    input   wire                en_i            ,
    input   wire                rx_edge_i       ,
    input   wire                sdi_i           ,
    output  wire                rx_done_o       ,
    input   wire [15:0]         rx_len_i        ,
    input   wire                rx_len_updata_i ,
    output  wire [31:0]         rx_data_o       ,
    output  wire                rx_data_vld_o   ,
    input   wire                rx_data_rdy_i   
);
    //接收模块仅有IDLE和TRANSMIT两个状态
    localparam  IDLE     = 0;
    localparam  RECIEVE  = 1;

    reg [15:0]  bit_cnt_trgt;
    reg [15:0]  bit_cnt; 
    wire        word_done;
    wire        idle2recieve;
    wire        recieve2idle;
    reg         rx_cs;
    reg         rx_ns;
    reg [31:0]  rx_data;

    //接收的bit计数器
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            bit_cnt_trgt <= 'd0;
        end else if(rx_len_updata_i) begin
            bit_cnt_trgt <= rx_len_i;
        end
    end
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            bit_cnt <= 'd0;
        end else if(idle2recieve) begin//转换为接收状态时清零
            bit_cnt <= 'd0;
        end else if( (rx_cs == RECIEVE) && rx_edge_i) begin //recieve状态且边沿到来时bit_cnt自增
            bit_cnt <= bit_cnt + 1;
        end
    end

    assign rx_done_o = (bit_cnt == bit_cnt_trgt) && rx_edge_i;//bit_cnt计满说明一个数据包接收完成
    assign word_done = (bit_cnt ==  5'b11111   ) && rx_edge_i;//bit_cnt计满32个bit
    //**********************三段式状态机***************************//
    //转移条件变量
    assign idle2recieve = (rx_cs == IDLE)    && en_i && rx_data_rdy_i;//IDLE状态且spi控制器内部可以接收数据
    assign recieve2idle = (rx_cs == RECIEVE) &&//RECIEVE状态且接收完数据或者spi控制器内部未准备好
    ((rx_done_o) || (word_done && ~rx_data_rdy_i));

    //1.状态更新
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            rx_cs <= IDLE;
        end else begin
            rx_cs <= rx_ns;
        end
    end
    //2.状态转移条件
    always @(*) begin
        case(rx_cs)
            IDLE   : rx_ns = idle2recieve ? RECIEVE : rx_cs;
            RECIEVE: rx_ns = recieve2idle ? IDLE    : rx_cs;
        endcase
    end
    //3.每个状态的输出
    assign rx_data_vld_o = rx_cs == IDLE;//返回IDLE状态说明接收完一个数据包，此时数据有效
    assign rx_data_o     = rx_data;
    
    ////移位器 
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            rx_data <= 'd0;
        end else if (en_i && rx_data_rdy_i && rx_data_vld_o) begin//握手初始化
            rx_data <= 'd0;
        end else if ((rx_cs == RECIEVE) && ~rx_done_o && rx_edge_i) begin
            rx_data <= {rx_data[30:0], sdi_i};//高位先接收
        end
    end

endmodule