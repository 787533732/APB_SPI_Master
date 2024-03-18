module fifo (
    input   wire            clk_i           ,
    input   wire            rstn_i          ,      

    input   wire [31:0]     data_i          ,
    input   wire            data_vld_i      ,
    output  wire            data_rdy_o      ,

    output  reg  [31:0]     data_o          ,
    output  wire            data_vld_o      ,
    input   wire            data_rdy_i
);
    reg  [31:0] data[0:15];
    //读写指针（指向下个读/写地址）
    reg  [4:0] wr_point;
    reg  [4:0] rd_point;
    reg wait_next;
    reg  [2:0]read_cnt; 
    //空满标志产生
    wire      full;
    wire      empty;
    assign    full  = (wr_point[4] == !rd_point[4]) && (wr_point[3:0] == rd_point[3:0]);//最高位相反，其他相等
    assign    empty = wr_point == rd_point;//读写指令相等
    //真实的读写地址
    wire [3:0] waddr;
    wire [3:0] raddr;
    assign waddr = wr_point[3:0];
    assign raddr = rd_point[3:0];
    //为了适配spi控制器增加了两个信号
    wire data_vld_o1;
    reg  data_vld_o2;
    reg  data_vld_o3;
    assign   data_rdy_o = !full;
    assign   data_vld_o1 = !empty;
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            data_vld_o2 <= 1'b0;
        else    
            data_vld_o2 <= data_vld_o1;
    end
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            data_vld_o3 <= 1'b0;
        else    
            data_vld_o3 <= data_vld_o2;
    end
    assign data_vld_o = (data_vld_o1 || data_vld_o2/* || data_vld_o3*/) ;//&& (!wait_next);
    

    



    wire     wr_en;
    wire     rd_en;
    assign   wr_en = data_vld_i && data_rdy_o;
    assign   rd_en = data_vld_o1 && data_rdy_i;



    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            read_cnt <= 2'b0;
        else if(read_cnt == 3'd2)
            read_cnt <= 2'b0;
        else
            read_cnt <= read_cnt + 1;

    end


    //写使能时，未满可写
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) 
            wr_point <= 5'b0;
        else if(wr_en && !full) begin
            if(wr_point < 5'b1_1111) 
                wr_point <= wr_point + 1;
            else
                wr_point <= 5'b0;
        end  
    end



    //读使能时，未空可读
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            rd_point <= 5'b0;
       //     wait_next <= 1'b0;
        end
        else if(rd_en && !empty &&(read_cnt == 1'b1)) begin
            if(rd_point < 5'b1_1111) begin
                rd_point <= rd_point + 1;
        //        wait_next <= 1'b1;
            end
            else begin
        //        wait_next <= 1'b0;
                rd_point <= 5'b0;
            end
        end
        else begin
            rd_point <= rd_point;
        //    wait_next <= 1'b0;
        end
    end
    
    //写操作
    always @(posedge clk_i) begin//不用复位
        if(wr_en && !full)
            data[waddr] <= data_i;
        else
            data[waddr] <= data[waddr];
    end
    //读操作
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            data_o <= 'd0;
        else if(rd_en && !empty)
            data_o <= data[raddr];
        else
            data_o<= data_o;
    end
  /*  assign data_o = data[raddr];*/
endmodule