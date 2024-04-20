module top
#(
    parameter PORT0_ENABLE  = 1,
    parameter PORT1_ENABLE  = 1,
    parameter PORT2_ENABLE  = 1,
    parameter PORT3_ENABLE  = 1, 
    parameter FIFO_DEPTH    = 4,
    parameter FIFO_DEPTH_W  = 2
)
(
    input   wire            PCLK        ,
    input   wire            PRSTN       ,

    input   wire [ 1:0]     DECODE2BIT  ,
    input   wire [31:0]     PADDR       ,
    input   wire            PWRITE      ,
    input   wire            PSEL        ,
    input   wire            PENABLE     ,
    input   wire [31:0]     PWDATA      ,
    output  wire [31:0]     PRDATA      ,
    output  wire            PREADY      ,
    output  wire            PSLVERR     ,

    output  wire            sck         ,
    output  wire            mosi        ,
    input   wire            miso        ,
    output  wire            nss            
);

    wire [31:0] PADDR0;   
    wire        PWRITE0;  
    wire        PSEL0;    
    wire        PENABLE0; 
    wire [31:0] PWDATA0;  
    wire [31:0] PRDATA0;  
    wire        PREADY0;  
    wire        PSLVERR0; 

apb_slave_mux
#(
    .PORT0_ENABLE(PORT0_ENABLE),
    .PORT1_ENABLE(PORT1_ENABLE),
    .PORT2_ENABLE(PORT2_ENABLE),
    .PORT3_ENABLE(PORT3_ENABLE)
)
u_apb_slave_mux 
(
    .DECODE2BIT     (DECODE2BIT),
    .PADDR          (PADDR     ),
    .PWRITE         (PWRITE    ),
    .PSEL           (PSEL      ),
    .PENABLE        (PENABLE   ),
    .PWDATA         (PWDATA    ),
    .PRDATA         (PRDATA    ),
    .PREADY         (PREADY    ),
    .PSLVERR        (PSLVERR   ),

    .PADDR0         (PADDR0    ),
    .PWRITE0        (PWRITE0   ),
    .PSEL0          (PSEL0     ),
    .PENABLE0       (PENABLE0  ),
    .PWDATA0        (PWDATA0   ),
    .PRDATA0        (PRDATA0   ),
    .PREADY0        (PREADY0   ),
    .PSLVERR0       (PSLVERR0  ),
    
    .PADDR1         (),
    .PWRITE1        (),
    .PSEL1          (),
    .PENABLE1       (),
    .PWDATA1        (),
    .PRDATA1        (),
    .PREADY1        (),
    .PSLVERR1       (),
    
    .PADDR2         (),
    .PWRITE2        (),
    .PSEL2          (),
    .PENABLE2       (),
    .PWDATA2        (),
    .PRDATA2        (),
    .PREADY2        (),
    .PSLVERR2       (),
    
    .PADDR3         (),
    .PWRITE3        (),
    .PSEL3          (),
    .PENABLE3       (),
    .PWDATA3        (),
    .PRDATA3        (),
    .PREADY3        (),
    .PSLVERR3       ()
);

apb_spi_master 
#(  
    .FIFO_DEPTH  (FIFO_DEPTH  ),
    .FIFO_DEPTH_W(FIFO_DEPTH_W)
)
u_apb_spi_master
(   
    .pclk_i      (PCLK      ),
    .prstn_i     (PRSTN     ),

    .paddr_i     (PADDR0   ),
    .pwrite_i    (PWRITE0  ),
    .psel_i      (PSEL0    ),
    .penable_i   (PENABLE0 ),
    .pwdata_i    (PWDATA0  ),
    .prdata_o    (PRDATA0  ),
    .pready_o    (PREADY0  ),
    .pslverr_o   (PSLVERR0 ),

    .sck         (sck ),
    .mosi        (mosi),
    .miso        (miso),
    .nss         (nss )   
);
endmodule