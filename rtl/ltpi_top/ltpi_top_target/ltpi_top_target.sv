/////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 Intel Corporation
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////////////

// -------------------------------------------------------------------
// -- Author        : Katarzyna Krzewska 
// -- Date          : November 2022
// -- Project Name  : LTPI
// -- Description   :
// -- LTPI Top Target Implementation 
// -------------------------------------------------------------------

`include "logic.svh"
`timescale 1ns / 1ps

module ltpi_top_target
import ltpi_pkg::*;
#( 
    parameter LL_GPIO_RST_VALUE         = 16'hFF_FF, 
    parameter NL_GPIO_RST_VALUE         = { 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                            112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                            112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                            112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF},
    //1
    parameter CSR_LIGHT_VER_EN          = 0,
    parameter GPIO_EN                   = 1,
    parameter NUM_OF_NL_GPIO            = 1024,
    parameter UART_EN                   = 1,
    parameter NUM_OF_UART_DEV           = 2, // from 1 to 2 
    parameter SMBUS_EN                  = 1,
    parameter NUM_OF_SMBUS_DEV          = 6, // from 1 to 6
    parameter DATA_CHANNEL_EN           = 1,
    parameter DATA_CHANNEL_MAILBOX_EN   = 1

    //2
    // parameter CSR_LIGHT_VER_EN           = 1,
    // parameter GPIO_EN                    = 1,
    // parameter NUM_OF_NL_GPIO             = 1024,
    // parameter UART_EN                    = 1,
    // parameter NUM_OF_UART_DEV            = 1, // from 1 to 2 
    // parameter SMBUS_EN                   = 1,
    // parameter NUM_OF_SMBUS_DEV           = 6, // from 1 to 6
    // parameter DATA_CHANNEL_EN            = 1,
    // parameter DATA_CHANNEL_MAILBOX_EN    = 1

    //3
    // parameter CSR_LIGHT_VER_EN           = 1,
    // parameter GPIO_EN                    = 1,
    // parameter NUM_OF_NL_GPIO             = 1024,
    // parameter UART_EN                    = 1,
    // parameter NUM_OF_UART_DEV            = 1, // from 1 to 2 
    // parameter SMBUS_EN                   = 1,
    // parameter NUM_OF_SMBUS_DEV           = 6, // from 1 to 6
    // parameter DATA_CHANNEL_EN            = 1,
    // parameter DATA_CHANNEL_MAILBOX_EN    = 0

    //4
    // parameter CSR_LIGHT_VER_EN           = 1,
    // parameter GPIO_EN                    = 1,
    // parameter NUM_OF_NL_GPIO             = 16,
    // parameter UART_EN                    = 1,
    // parameter NUM_OF_UART_DEV            = 2, // from 1 to 2 
    // parameter SMBUS_EN                   = 1,
    // parameter NUM_OF_SMBUS_DEV           = 1, // from 1 to 6
    // parameter DATA_CHANNEL_EN            = 1,
    // parameter DATA_CHANNEL_MAILBOX_EN    = 0
)
(

    input wire                                  CLK_25M_OSC_CPU_FPGA,
    input wire                                  reset_in,
    //    
    output     [31:0]           avmm_mst_addr,  //AVMM Master interface tunneling through LVDS
    output                      avmm_mst_read,  //Only exist on ioc_slave side
    output                      avmm_mst_write,
    output     [31:0]           avmm_mst_wdata,
    output     [ 3:0]           avmm_mst_byteen,
    input      [31:0]           avmm_mst_rdata,
    input                       avmm_mst_rdvalid,
    input                       avmm_mst_waitrq,
       
    input      [31:0]           avmm_csr_addr,  //Standard AVMM interface for reading CSRs in LTPI IP
    input                       avmm_csr_read,
    input                       avmm_csr_write,
    input      [31:0]           avmm_csr_wdata,
    input      [ 3:0]           avmm_csr_byteen,
    output     [31:0]           avmm_csr_rdata,
    output                      avmm_csr_rdvalid,
    output                      avmm_csr_waitrq,

    output wire               clk_60MHZ,          
    output logic              pll_locked,




    //LVDS output pins
    output wire                                 lvds_tx_data,
    output wire                                 lvds_tx_clk,

    //LVDS input pins
    input wire                                  lvds_rx_data,
    input wire                                  lvds_rx_clk,

    output wire                                 aligned,            //Mark that LVDS link has locked
    output wire                                 NL_gpio_stable,

    inout        [(NUM_OF_SMBUS_DEV - 1):0]     smb_scl,            //I2C interfaces tunneling through LVDS 
    inout        [(NUM_OF_SMBUS_DEV - 1):0]     smb_sda,

    input  logic [  15:0]                       ll_gpio_in,
    output logic [  15:0]                       ll_gpio_out,

    input  logic [(NUM_OF_NL_GPIO - 1):0]       nl_gpio_in,        //GPIO input tunneling through LVDS
    output logic [(NUM_OF_NL_GPIO - 1):0]       nl_gpio_out,       //GPIO output tunneling through LVDS
    
    input        [(NUM_OF_UART_DEV - 1):0]      uart_rxd,          //UART interfaces tunneling through LVDS
    input        [(NUM_OF_UART_DEV - 1):0]      uart_cts,          //Clear To Send
    output reg   [(NUM_OF_UART_DEV - 1):0]      uart_txd,
    output reg   [(NUM_OF_UART_DEV - 1):0]      uart_rts           //Request To Send

);



wire   aligned_mgtm_ltpi;
logic  reset;
logic       [ 7:0 ] tag;


logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_cntrl (
    .aclk           (clk_60MHZ),
    .areset_n       (!reset)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_trg (
    .aclk           (clk_60MHZ),
    .areset_n       (!reset)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_FPGA_inf (
    .aclk           (clk_60MHZ),
    .areset_n       (!reset)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_CSR (
    .aclk           (clk_60MHZ),
    .areset_n       (!reset)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_s (
    .aclk           (clk_60MHZ),
    .areset_n       (!reset)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_mm (
    .aclk           (clk_60MHZ),
    .areset_n       (!reset)
);

assign u_avmm_trg.address     = '0; 
assign u_avmm_trg.read        = '0;
assign u_avmm_trg.write       = '0;
assign u_avmm_trg.writedata   = '0;
assign u_avmm_trg.byteenable  = '0;


assign avmm_mst_addr                =    u_avmm_mm.address ;                                                
assign avmm_mst_read                =    u_avmm_mm.read;                                                   
assign avmm_mst_write               =    u_avmm_mm.write;                                                   
assign avmm_mst_wdata[ 7: 0]        =    u_avmm_mm.writedata[0];                                                   
assign avmm_mst_wdata[15: 8]        =    u_avmm_mm.writedata[1];                                                   
assign avmm_mst_wdata[23:16]        =    u_avmm_mm.writedata[2];                                                   
assign avmm_mst_wdata[31:24]        =    u_avmm_mm.writedata[3];                                                   
assign avmm_mst_byteen              =    u_avmm_mm.byteenable;                                               
assign u_avmm_mm.readdata[0]        =    avmm_mst_rdata[ 7: 0];                                                      
assign u_avmm_mm.readdata[1]        =    avmm_mst_rdata[15: 8];                                                      
assign u_avmm_mm.readdata[2]        =    avmm_mst_rdata[23:16];                                                      
assign u_avmm_mm.readdata[3]        =    avmm_mst_rdata[31:24];                                                      
assign u_avmm_mm.readdatavalid      =    avmm_mst_rdvalid;                                                             
assign u_avmm_mm.waitrequest        =    avmm_mst_waitrq;  
//assign u_avmm_mm.chipselect = 1;

assign u_avmm_CSR.address       = avmm_csr_addr;
assign u_avmm_CSR.read          = avmm_csr_read;
assign u_avmm_CSR.write         = avmm_csr_write;
assign u_avmm_CSR.writedata[0]  = avmm_csr_wdata[ 7: 0];
assign u_avmm_CSR.writedata[1]  = avmm_csr_wdata[15: 8];
assign u_avmm_CSR.writedata[2]  = avmm_csr_wdata[23:16];
assign u_avmm_CSR.writedata[3]  = avmm_csr_wdata[31:24];
assign u_avmm_CSR.byteenable    = avmm_csr_byteen;
assign avmm_csr_rdata[ 7: 0]    = u_avmm_CSR.readdata[0];
assign avmm_csr_rdata[15: 8]    = u_avmm_CSR.readdata[1];
assign avmm_csr_rdata[23:16]    = u_avmm_CSR.readdata[2];
assign avmm_csr_rdata[31:24]    = u_avmm_CSR.readdata[3];
assign avmm_csr_rdvalid         = u_avmm_CSR.readdatavalid;
assign avmm_csr_waitrq          = u_avmm_CSR.waitrequest;
assign u_avmm_CSR.chipselect = 1;

LTPI_CSR_In_t CSR_hw_in;
LTPI_CSR_Out_t CSR_hw_out;

logic clk_200m;
logic clk_25HMZ;

logic pll_locked_ff;

always_ff @ (posedge clk_60MHZ) pll_locked_ff <= pll_locked; 
always_ff @ (posedge clk_60MHZ) reset <= !pll_locked_ff; 

pll_cpu pll_system_target (
    .areset                     (reset_in                   ),
    .inclk0                     (CLK_25M_OSC_CPU_FPGA       ),
    .c0                         (clk_25HMZ                  ),
    .c1                         (clk_60MHZ                  ),
    .c2                         (clk_200m                   ),
    .locked                     (pll_locked                 )
    );
    

assign aligned = aligned_mgtm_ltpi & CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st;// it give only one pulse(normal give 2 pulses) for the align bit

mgmt_ltpi_top #(
    .CONTROLLER                 (0                          ),  //Set Target side with value 0
    .GPIO_EN                    (GPIO_EN                    ),
    .NUM_OF_NL_GPIO             (NUM_OF_NL_GPIO             ),
    .LL_GPIO_RST_VALUE          (LL_GPIO_RST_VALUE          ),
    .NL_GPIO_RST_VALUE          (NL_GPIO_RST_VALUE          ),
    .UART_EN                    (UART_EN                    ),
    .NUM_OF_UART_DEV            (NUM_OF_UART_DEV            ),
    .SMBUS_EN                   (SMBUS_EN                   ),
    .NUM_OF_SMBUS_DEV           (NUM_OF_SMBUS_DEV           ),
    .DATA_CHANNEL_EN            (DATA_CHANNEL_EN            ),
    .DATA_CHANNEL_MAILBOX_EN    (DATA_CHANNEL_MAILBOX_EN    )
) mgmt_ltpi_top_inst (
    .ref_clk                    (CLK_25M_OSC_CPU_FPGA       ),
    .clk                        (clk_60MHZ                  ), 
    .reset                      (reset                      ),

    .LTPI_CSR_In                (CSR_hw_in                  ),
    .LTPI_CSR_Out               (CSR_hw_out                 ),
    .aligned                    (aligned_mgtm_ltpi                    ),//Mark that LVDS link has locked
    .NL_gpio_stable             (NL_gpio_stable             ),
    //LVDS output pins
    .lvds_tx_data               (lvds_tx_data               ),
    .lvds_tx_clk                (lvds_tx_clk                ),

    //LVDS input pins
    .lvds_rx_data               (lvds_rx_data               ),
    .lvds_rx_clk                (lvds_rx_clk                ),

    .smb_scl                    (smb_scl                    ),//I2C interfaces tunneling through LVDS 
    .smb_sda                    (smb_sda                    ),

    .ll_gpio_in                 (ll_gpio_in                 ),//GPIO input tunneling through LVDS
    .ll_gpio_out                (ll_gpio_out                ),//GPIO output tunneling through LVDS
    
    .nl_gpio_in                 (nl_gpio_in                 ),//GPIO input tunneling through LVDS
    .nl_gpio_out                (nl_gpio_out                ),//GPIO output tunneling through LVDS

    .uart_rxd                   (uart_rxd                   ),//UART interfaces tunneling through LVDS
    .uart_cts                   (uart_cts                   ),//Clear To Send
    .uart_txd                   (uart_txd                   ),
    .uart_rts                   (uart_rts                   ),//Request To Send
        
    .avalon_mm_m                (u_avmm_mm                   ),//AVMM Controller interface tunneling through LVDS, Dose not exist on controller side
    .avalon_mm_s                (u_avmm_cntrl                ),//AVMM Target interface tunneling through LVDS, Only exist on controller side
    .tag_in                     (tag                         ) //Tag field only exist while DATA_CHANNEL_MAILBOX_EN = 0

);

assign tag                      = 0;


ltpi_csr_avmm #(
    .CSR_LIGHT_VER_EN(CSR_LIGHT_VER_EN)
)
ltpi_csr_avmm_inst  (
    .clk                    (clk_60MHZ              ),
    .reset_n                (!reset                 ),
    .avalon_mm_s            (u_avmm_CSR             ),
    .CSR_hw_out             (CSR_hw_out             ),
    .CSR_hw_in              (CSR_hw_in              )
);


endmodule