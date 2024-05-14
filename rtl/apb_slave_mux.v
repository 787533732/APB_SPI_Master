module apb_slave_mux 
#(
    parameter PORT0_ENABLE  = 1,
    parameter PORT1_ENABLE  = 1,
    parameter PORT2_ENABLE  = 1,
    parameter PORT3_ENABLE  = 1
)
(
    input   wire [ 1:0]  DECODE2BIT     ,
    input   wire [31:0]  PADDR          ,
    input   wire         PWRITE         ,
    input   wire         PSEL           ,
    input   wire         PENABLE        ,
    input   wire [31:0]  PWDATA         ,
    output  wire [31:0]  PRDATA         ,
    output  wire         PREADY         ,
    output  wire         PSLVERR        ,

    output  wire [31:0]  PADDR0         ,
    output  wire         PWRITE0        ,
    output  wire         PSEL0          ,
    output  wire         PENABLE0       ,
    output  wire [31:0]  PWDATA0        ,
    input   wire [31:0]  PRDATA0        ,
    input   wire         PREADY0        ,
    input   wire         PSLVERR0       ,
    
    output  wire [31:0]  PADDR1         ,
    output  wire         PWRITE1        ,
    output  wire         PSEL1          ,
    output  wire         PENABLE1       ,
    output  wire [31:0]  PWDATA1        ,
    input   wire [31:0]  PRDATA1        ,
    input   wire         PREADY1        ,
    input   wire         PSLVERR1       ,
    
    output  wire [31:0]  PADDR2         ,
    output  wire         PWRITE2        ,
    output  wire         PSEL2          ,
    output  wire         PENABLE2       ,
    output  wire [31:0]  PWDATA2        ,
    input   wire [31:0]  PRDATA2        ,
    input   wire         PREADY2        ,
    input   wire         PSLVERR2       ,
    
    output  wire [31:0]  PADDR3         ,
    output  wire         PWRITE3        ,
    output  wire         PSEL3          ,
    output  wire         PENABLE3       ,
    output  wire [31:0]  PWDATA3        ,
    input   wire [31:0]  PRDATA3        ,
    input   wire         PREADY3        ,
    input   wire         PSLVERR3
);

  wire [3:0] en  = {(PORT3_ENABLE == 1),(PORT2_ENABLE  == 1),
                    (PORT1_ENABLE == 1),(PORT0_ENABLE  == 1)};

  wire [3:0] dec = {(DECODE2BIT == 2'd3),(DECODE2BIT == 2'd2),
                    (DECODE2BIT == 2'd1),(DECODE2BIT == 2'd0)};

  assign PADDR0 = PADDR & {32{dec[0]}} & {32{en[0]}};
  assign PADDR1 = PADDR & {32{dec[1]}} & {32{en[1]}};
  assign PADDR2 = PADDR & {32{dec[2]}} & {32{en[2]}};
  assign PADDR3 = PADDR & {32{dec[3]}} & {32{en[3]}};

  assign PWRITE0 = PWRITE & dec[0] & en[0];
  assign PWRITE1 = PWRITE & dec[1] & en[1];
  assign PWRITE2 = PWRITE & dec[2] & en[2];
  assign PWRITE3 = PWRITE & dec[3] & en[3];

  assign PSEL0 = PSEL & dec[0] & en[0];
  assign PSEL1 = PSEL & dec[1] & en[1];
  assign PSEL2 = PSEL & dec[2] & en[2];
  assign PSEL3 = PSEL & dec[3] & en[3];

  assign PENABLE0 = PENABLE & dec[0] & en[0];
  assign PENABLE1 = PENABLE & dec[1] & en[1];
  assign PENABLE2 = PENABLE & dec[2] & en[2];
  assign PENABLE3 = PENABLE & dec[3] & en[3];

  assign PWDATA0 = PWDATA & {32{dec[0]}} & {32{en[0]}};
  assign PWDATA1 = PWDATA & {32{dec[1]}} & {32{en[1]}};
  assign PWDATA2 = PWDATA & {32{dec[2]}} & {32{en[2]}};
  assign PWDATA3 = PWDATA & {32{dec[3]}} & {32{en[3]}};

  assign PRDATA  = ({32{dec[0]}} & {32{en[0]}} & PRDATA0) |
                   ({32{dec[1]}} & {32{en[1]}} & PRDATA1) |
                   ({32{dec[2]}} & {32{en[2]}} & PRDATA2) |
                   ({32{dec[3]}} & {32{en[3]}} & PRDATA3);
                   
  assign PREADY  = //~PSEL |
                   (dec[0] & (PREADY0 | ~en[0])) |
                   (dec[1] & (PREADY1 | ~en[1])) |
                   (dec[2] & (PREADY2 | ~en[2])) |
                   (dec[3] & (PREADY3 | ~en[3]));

  assign PSLVERR = (PSEL0 & PSLVERR0) |
                   (PSEL1 & PSLVERR1) |
                   (PSEL2 & PSLVERR2) |
                   (PSEL3 & PSLVERR3);



endmodule