module clk_gen (
    input   wire                clk_i           ,
    input   wire                rstn_i          ,
    input   wire                clock_en_i      ,//门控时钟
    input   wire [7:0]          clk_div_i       ,//分频系数
    input   wire                clk_div_vld_i   ,

    output  reg                 spi_clk_o       ,//给SPI_SLAVE的波特率时钟
    output  wire                rise_edge_o     ,
    output  wire                fall_edge_o              
);
    
    wire[7:0] cnt_max;
    assign cnt_max = (clk_div_i >> 1) - 1'b1;
    //分频计数器
    reg [7:0] cnt; 
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            cnt <= 'd0;
        end else if(cnt == cnt_max || !clock_en_i || !clk_div_vld_i) begin
            cnt <= 'd0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
    //波特率时钟发生器
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            spi_clk_o <= 1'b0;
        end else if(!clock_en_i || !clk_div_vld_i) begin
            spi_clk_o <= 1'b0;
        end else if(cnt == cnt_max)begin
            spi_clk_o <= ~spi_clk_o;
        end
    end

    assign rise_edge_o = ~spi_clk_o && (cnt ==cnt_max);//低电平计满，有上升沿
    assign fall_edge_o =  spi_clk_o && (cnt ==cnt_max);

endmodule