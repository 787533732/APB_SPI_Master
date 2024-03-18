/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Expert(TM) in wire load mode
// Version   : O-2018.06-SP1
// Date      : Mon Mar 18 20:28:04 2024
/////////////////////////////////////////////////////////////


module apb_spi_master ( pclk_i, prstn_i, paddr_i, pwrite_i, psel_i, penable_i, 
        pwdata_i, prdata_o, pready_o, sck, mosi, miso, nss );
  input [31:0] paddr_i;
  input [31:0] pwdata_i;
  output [31:0] prdata_o;
  input pclk_i, prstn_i, pwrite_i, psel_i, penable_i, miso;
  output pready_o, sck, mosi, nss;
  wire   eot_o, spi_data_rx_vld_o, stream_data_vld_o, fifo_data_vld_o,
         fifo_data_rdy_i;
  wire   [7:0] spi_clk_div_o;
  wire   [31:0] spi_data_rx_o;
  wire   [31:0] stream_data_o;
  wire   [31:0] fifo_data_o;
  assign pready_o = 1'b1;

  apb_interface u_apb_interface ( .pclk_i(pclk_i), .prstn_i(prstn_i), 
        .paddr_i(paddr_i), .pwrite_i(pwrite_i), .psel_i(psel_i), .penable_i(
        penable_i), .pwdata_i(pwdata_i), .prdata_o(prdata_o), .spi_data_rx_i(
        spi_data_rx_o), .spi_data_rx_vld_i(spi_data_rx_vld_o), .stream_data_o(
        stream_data_o), .stream_data_vld_o(stream_data_vld_o), .spi_clk_div_o(
        spi_clk_div_o), .eot_i(eot_o) );
  fifo tx_fifo ( .clk_i(pclk_i), .rstn_i(prstn_i), .data_i(stream_data_o), 
        .data_vld_i(stream_data_vld_o), .data_o(fifo_data_o), .data_vld_o(
        fifo_data_vld_o), .data_rdy_i(fifo_data_rdy_i) );
  spi_master_controller u_spi_master_controller ( .clk_i(pclk_i), .rstn_i(
        prstn_i), .spi_clk_div_i(spi_clk_div_o), .spi_clk_div_vld_i(1'b1), 
        .stream_data_i(fifo_data_o), .stream_data_vld_i(fifo_data_vld_o), 
        .stream_data_rdy_o(fifo_data_rdy_i), .spi_data_rx_o(spi_data_rx_o), 
        .spi_data_rx_vld_o(spi_data_rx_vld_o), .spi_data_rx_rdy_i(1'b1), 
        .spi_clk_o(sck), .spi_cs_n_o(nss), .spi_sdo_o(mosi), .spi_sdi_i(miso), 
        .eot_o(eot_o) );
endmodule

