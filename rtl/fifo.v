module fifo 
#(  
    parameter DEPTH   = 4,
    parameter DEPTH_W = 2
)
(
    input   wire            clk_i           ,
    input   wire            rstn_i          ,      

    input   wire [31:0]     data_i          ,
    input   wire            data_vld_i      ,
    output  wire            data_rdy_o      ,

    output  reg  [31:0]     data_o          ,
    output  wire            data_vld_o      ,
    input   wire            data_rdy_i
);
    reg [31:0] data[0:DEPTH-1];
    //读写指针（指向下个读/写地址）(多一个bit判断空满)
    reg [DEPTH_W:0] wr_point;
    reg [DEPTH_W:0] rd_point;
    reg [2:0]       read_cnt; 
    //空满标志产生
    wire full  = (wr_point[DEPTH_W] == !rd_point[DEPTH_W]) && (wr_point[DEPTH_W-1:0] == rd_point[DEPTH_W-1:0]);//最高位相反，其他相等
    wire empty = wr_point == rd_point;//读写指令相等
    //真实的读写地址
    wire[DEPTH_W-1:0] waddr = wr_point[DEPTH_W-1:0];
    wire[DEPTH_W-1:0] raddr = rd_point[DEPTH_W-1:0];
    //为了适配spi控制器增加了1个信号
    wire data_vld_o1;
    reg  data_vld_o2;
    assign data_rdy_o = !full;
    assign data_vld_o1 = !empty;
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            data_vld_o2 <= 1'b0;
        else    
            data_vld_o2 <= data_vld_o1;
    end
    assign data_vld_o = (data_vld_o1 || data_vld_o2);

    wire wr_en = data_vld_i && data_rdy_o;
    wire rd_en = data_vld_o1 && data_rdy_i;

    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            read_cnt <= 2'd0;
        else if(data_vld_o) begin
            if(read_cnt == 3'd2)
                read_cnt <= 2'd0;
            else if(data_rdy_i)
                read_cnt <= read_cnt + 1;
        end
    end
//读写指针的维护
    //写使能时，未满可写
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) 
            wr_point <= {(DEPTH_W+1){1'b0}};
        else if(wr_en && !full) begin
            if(wr_point < {(DEPTH_W+1){1'b1}})
                wr_point <= wr_point + 1;
            else
                wr_point <= {(DEPTH_W+1){1'b0}};
        end  
    end
    //读使能时，未空可读
    always @(posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            rd_point <= {(DEPTH_W+1){1'b0}};
        end
        else if(rd_en && !empty &&(read_cnt == 2'd2)) begin
            if(rd_point < {(DEPTH_W+1){1'b1}}) begin
                rd_point <= rd_point + 1;
            end
            else begin
                rd_point <= {(DEPTH_W+1){1'b0}};
            end
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
endmodule