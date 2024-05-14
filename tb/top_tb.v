module top_tb();

reg         pclk_i;
reg         prstn_i;
reg  [ 1:0] DECODE2BIT;
reg  [31:0] paddr_i;  
reg         pwrite_i; 
reg         psel_i;   
reg         penable_i;
reg  [31:0] pwdata_i;
wire [31:0] prdata_o;
wire        pready_o;
wire        pslverr_o;
wire        sck;
wire        nss;
wire        mosi; 
reg         miso;
//时钟复位产生
initial
    begin
        pclk_i  = 1'b0; 
        prstn_i = 1'b1;
        DECODE2BIT = 2'd0;
        miso    = 1'b0;
        #40
        prstn_i = 1'b0;
        #20
        prstn_i = 1'b1;
        #96090
        //repeat(200) #400 miso = $random / 2;//模拟输入
        miso = 1'b1;
        #400
        miso = 1'b1;
        #400
        miso = 1'b1;
        #400
        miso = 1'b1;
        #400
        miso = 1'b0;
        #400
        miso = 1'b0;
        #400
        miso = 1'b0;
        #400
        miso = 1'b0;
        #400
        miso = 1'b0;
        #400
        miso = 1'b0;
        #400
        miso = 1'b0;
        #400
        miso = 1'b0;
        #400
        miso = 1'b1;
        #400
        miso = 1'b1;
        #400
        miso = 1'b1;
        #400
        miso = 1'b1;
        #400
        miso = 1'b0;

    end
always #10 pclk_i = ~pclk_i;
//写操作
task write_op(input [3:0]offset, input [31:0]data);
begin
    fork
        paddr_i  = {{26{1'b0}}, offset,{2{1'b0}}};
        pwrite_i = 1'b1;
        psel_i   = 1'b1;
        pwdata_i = data;   
    join
    @(posedge pclk_i);   
    penable_i= 1'b1;
    //反压
    wait(pready_o == 1); 

    @(posedge pclk_i);
    penable_i= 1'b0;
    psel_i   = 1'b0;
end
endtask
//写具体数据
task write_num(input [31:0]data);begin
    #100
    @(posedge pclk_i); 
    //通过regs[CTRL] 设置波特率 最低位为1时传输开始
    write_op(4'd5, 32'h0000_1400);
    @(posedge pclk_i); 
    //通过regs[CMD] 传输命令(4bit) 
    write_op(4'd0, 32'h0000_000b);//写数据时，cmd=4'1011 读数据时，cmd=4'1010
    @(posedge pclk_i); 
    //通过regs[ADDR] 传输地址(4bit)
    write_op(4'd1, 32'h0000_0003);
    @(posedge pclk_i); 
    //通过regs[LEN] 设置wdata的位宽
    write_op(4'd2, 32'h0000_0010);
    @(posedge pclk_i);
    //通过regs[WDATA] 传输需要写入的数据
    write_op(4'd3, data);
    @(posedge pclk_i);    
    //regs[CTRL ]最低位设置为1，读取设置并写入数据
    write_op(4'd5, 32'h0000_1401);
    #100;
end
endtask
//读操作
task read_op(input [3:0]offset);begin
    fork
        paddr_i  = {{26{1'b0}}, offset,{2{1'b0}}};
        pwrite_i = 1'b0;
        psel_i   = 1'b1;  
    join
    @(posedge pclk_i);   
    penable_i= 1'b1;
    @(posedge pclk_i); 
    penable_i= 1'b0;
    psel_i   = 1'b0;
end
endtask
//读具体数据
task read_num(); begin
    @(posedge pclk_i); 
    //设置波特率
    write_op(4'd5, 32'h0000_1400);
    @(posedge pclk_i);
    //命令
    write_op(4'd0, 32'h0000_000a);//读数据时，cmd=4'1010
    @(posedge pclk_i); 
    //地址
    write_op(4'd1, 32'h0000_0003);
    @(posedge pclk_i); 
    //数据位宽
    write_op(4'd2, 32'h0000_0010);
    @(posedge pclk_i);
    //读取设置
    write_op(4'd5, 32'h0000_1401);
    wait(u_top.u_apb_spi_master.u_spi_master_controller.eot_o == 1);
    //等待数据写入完成   
    @(posedge pclk_i);
    read_op(32'h4);
end
endtask

initial begin
    paddr_i   = 32'h0;
    pwrite_i  =  1'b0;
    psel_i    =  1'b0;
    penable_i =  1'b0;
    pwdata_i  = 32'h0;
    //写测试
    write_num(32'h0000_0000);
    write_num(32'h0000_1111);
    write_num(32'h0000_2222);
    write_num(32'h0000_3333);
    write_num(32'h0000_4444);
    write_num(32'h0000_5555);
  /*write_num(32'h0000_6666);
    write_num(32'h0000_7777);
    write_num(32'h0000_8888);
    write_num(32'h0000_9999);*/
    //读测试
    #80000

    read_num;
    #10000
    read_num;
    #10000
    read_num;
    #10000
    read_num;
    #200000  
    $finish;
end


top
#(
    .PORT0_ENABLE (1),
    .PORT1_ENABLE (0),
    .PORT2_ENABLE (0),
    .PORT3_ENABLE (0), 
    .FIFO_DEPTH   (4),
    .FIFO_DEPTH_W (2)
)
u_top
(
    .PCLK        (pclk_i ),
    .PRSTN       (prstn_i),

    .DECODE2BIT  (DECODE2BIT),
    .PADDR       (paddr_i  ),
    .PWRITE      (pwrite_i ),
    .PSEL        (psel_i   ),
    .PENABLE     (penable_i),
    .PWDATA      (pwdata_i ),
    .PRDATA      (prdata_o ),
    .PREADY      (pready_o ),
    .PSLVERR     (pslverr_o),

    .sck         (sck ),
    .mosi        (mosi),
    .miso        (miso),
    .nss         (nss )   
);

initial begin
    $fsdbDumpfile("top.fsdb");
    $fsdbDumpvars(0);
    $fsdbDumpMDA();
end

endmodule