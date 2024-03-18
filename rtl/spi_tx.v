module spi_tx (
    input   wire                clk_i           ,
    input   wire                rstn_i          ,
    input   wire                en_i            ,
    input   wire                tx_edge_i       ,
    output  wire                sdo_o           ,
    output  wire                tx_done_o       ,//一个数据包传输完成标志
    input   wire [15:0]         tx_len_i        ,
    input   wire                tx_len_updata_i ,
    input   wire [31:0]         tx_data_i       ,
    input   wire                tx_data_vld_i   ,
    output  wire                tx_data_rdy_o 
);
    //发送模块仅有IDLE和TRANSMIT两个状态
    localparam IDLE     = 0;
    localparam TRANSMIT = 1;

    reg [15:0] bit_cnt_trgt;
    reg [15:0] bit_cnt;
    wire       word_done;
    wire       idle2transmit;
    wire       transmit2idle;
    reg        tx_cs;
    reg        tx_ns;
    reg [31:0] tx_data;

    //传输的bit计数器
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            bit_cnt_trgt <= 'd0;
        end else if(tx_len_updata_i) begin
            bit_cnt_trgt <= tx_len_i;
        end
    end
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            bit_cnt <= 'd0;
        end else if(idle2transmit) begin//转换为传输状态时清零
            bit_cnt <= 'd0;
        end else if( (tx_cs == TRANSMIT) && tx_edge_i) begin //transmit状态且边沿到来时bit_cnt自增
            bit_cnt <= bit_cnt + 1;
        end
    end

    assign tx_done_o = (bit_cnt == (bit_cnt_trgt - 1)) && tx_edge_i;//bit_cnt计满说明一个数据包传输完成
    assign word_done = (bit_cnt ==  5'b11111         ) && tx_edge_i;//bit_cnt计满32个bit
    //**********************三段式状态机***************************//
    //转移条件变量
    assign idle2transmit = (tx_cs == IDLE)     && en_i && tx_data_vld_i;//使能且数据有效
    assign transmit2idle = (tx_cs == TRANSMIT) && 
    ((tx_done_o) || (word_done && ~tx_data_vld_i));//传输完成或 传完数据后数据无效

    //1.状态更新
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            tx_cs <= IDLE;
        end else begin
            tx_cs <= tx_ns;
        end
    end
    //2.状态转移条件
    always @(*) begin
        case(tx_cs)
            IDLE    : tx_ns = idle2transmit ? TRANSMIT : tx_cs;
            TRANSMIT: tx_ns = transmit2idle ? IDLE     : tx_cs;
            default : tx_ns = IDLE;//可以不写
        endcase
    end
    //3.每个状态的输出
    assign tx_data_rdy_o = tx_cs == IDLE;//只在IDLE状态准备好接收数据
    assign sdo_o         = tx_data[31];//高位优先传输

    //移位器     
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            tx_data <= 'd0;
        end else if ((en_i && tx_data_vld_i && tx_data_rdy_o) ||//发送模块使能且握手
                      (word_done && tx_data_vld_i )) begin//传完32bit，且有新数据
            tx_data <= tx_data_i;//更新要发送的数据   !!!!!发送数据需要保持一段时间，不然可能采集不到
        end else if ((tx_cs == TRANSMIT) && ~tx_done_o && tx_edge_i) begin//transmit状态，还没传输完且上升沿到来
            tx_data <= {tx_data[30:0], tx_data[31]};
        end
    end

endmodule