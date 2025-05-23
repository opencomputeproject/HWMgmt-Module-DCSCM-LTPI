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
// -- LTPI Top Controller Implementation 
// -------------------------------------------------------------------

//`include "logic.svh"
`timescale 1ns / 1ps
`include "logic.svh" 

module ltpi_top_controller 
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
    
    output wire                                 clk_60MHZ,
    output logic                                pll_locked,

    //LVDS output pins
    output wire                                 lvds_tx_data,
    output wire                                 lvds_tx_clk,

    //LVDS input pins
    input wire                                  lvds_rx_data,
    input wire                                  lvds_rx_clk,
    
    inout                                       BMC_smb_scl,        //I2C interfaces to BMC
    inout                                       BMC_smb_sda,
// avmm_______________

    input       [                    15:0]      avmm_slv_addr,  //AVMM
    input                                       avmm_slv_read,  //Only
    input                                       avmm_slv_write,
    input       [                    31:0]      avmm_slv_wdata,
    input       [                     3:0]      avmm_slv_byteen,
    output      [                    31:0]      avmm_slv_rdata,
    output                                      avmm_slv_rdvalid,
    output                                      avmm_slv_waitrq,

    input       [                    15:0]      avmm_csr_addr,
    input                                       avmm_csr_read,
    input                                       avmm_csr_write,
    input       [                    31:0]      avmm_csr_wdata,
    input       [                     3:0]      avmm_csr_byteen,
    output      [                    31:0]      avmm_csr_rdata,
    output                                      avmm_csr_rdvalid,
    output                                      avmm_csr_waitrq,

    output logic                                data_channel_timeout, //timeout indecate that transmision through data channel was invalid - only exist on controller side

//____________
    output wire                                 aligned,            //Mark that LVDS link has locked
    output wire                                 NL_gpio_stable,

    inout        [(NUM_OF_SMBUS_DEV - 1):0]     smb_scl,            //I2C interfaces tunneling through LVDS 
    inout        [(NUM_OF_SMBUS_DEV - 1):0]     smb_sda,

    input  logic [                    15:0]     ll_gpio_in,
    output logic [                    15:0]     ll_gpio_out,

    input  logic [  (NUM_OF_NL_GPIO - 1):0]     nl_gpio_in,        //GPIO input tunneling through LVDS
    output logic [  (NUM_OF_NL_GPIO - 1):0]     nl_gpio_out,       //GPIO output tunneling through LVDS
    
    input        [ (NUM_OF_UART_DEV - 1):0]     uart_rxd,          //UART interfaces tunneling through LVDS
    input        [ (NUM_OF_UART_DEV - 1):0]     uart_cts,          //Clear To Send
    output reg   [ (NUM_OF_UART_DEV - 1):0]     uart_txd,
    output reg   [ (NUM_OF_UART_DEV - 1):0]     uart_rts           //Request To Send
);


wire        [31:0]  avmm_bmc_addr;
wire                avmm_bmc_read;
wire                avmm_bmc_write;
wire        [31:0]  avmm_bmc_wdata;
wire        [ 3:0]  avmm_bmc_byteen;
wire        [31:0]  avmm_bmc_rdata;
wire                avmm_bmc_rdvalid;
wire                avmm_bmc_waitrq;
logic       [ 7:0 ] tag;

LTPI_CSR_In_t       CSR_hw_in;
LTPI_CSR_Out_t      CSR_hw_out;

logic               clk_200m;
logic               clk_25HMZ;

logic               reset;

wire aligned_mgtm_ltpi;

logic pll_locked_ff;

always_ff @ (posedge clk_60MHZ) pll_locked_ff <= pll_locked; 
always_ff @ (posedge clk_60MHZ) reset <= !pll_locked_ff; 

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_bmc (
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

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_cntrl (
    .aclk           (clk_60MHZ),
    .areset_n       (!reset)
);



assign u_avmm_mm.address       = avmm_slv_addr;
assign u_avmm_mm.read          = avmm_slv_read;
assign u_avmm_mm.write         = avmm_slv_write;
assign u_avmm_mm.writedata[0]  = avmm_slv_wdata[ 7: 0];
assign u_avmm_mm.writedata[1]  = avmm_slv_wdata[15: 8];
assign u_avmm_mm.writedata[2]  = avmm_slv_wdata[23:16];
assign u_avmm_mm.writedata[3]  = avmm_slv_wdata[31:24];
assign u_avmm_mm.byteenable    = avmm_slv_byteen;
assign avmm_slv_rdata[ 7: 0]    = u_avmm_mm.readdata[0];
assign avmm_slv_rdata[15: 8]    = u_avmm_mm.readdata[1];
assign avmm_slv_rdata[23:16]    = u_avmm_mm.readdata[2];
assign avmm_slv_rdata[31:24]    = u_avmm_mm.readdata[3];
assign avmm_slv_rdvalid         = u_avmm_mm.readdatavalid;
assign avmm_slv_waitrq          = u_avmm_mm.waitrequest;
assign u_avmm_mm.chipselect    = 1;

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
assign u_avmm_CSR.chipselect=1;






assign u_avmm_cntrl.readdata      = '0;
assign u_avmm_cntrl.waitrequest   = '0;
assign u_avmm_cntrl.readdatavalid = '0;

assign tag                      = 0;

pll_cpu pll_system_controller (
    .areset                     (reset_in                   ),
    .inclk0                     (CLK_25M_OSC_CPU_FPGA       ),
    .c0                         (clk_25HMZ                  ),
    .c1                         (clk_60MHZ                  ),
    .c2                         (clk_200m                   ),
    .locked                     (pll_locked                 )
    );


assign aligned = aligned_mgtm_ltpi & CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st;// it give only one pulse(normal give 2 pulses) for the align bit

    
mgmt_ltpi_top #(
    .CONTROLLER                 (1                          ),  //Set Controller side with value 1
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
    .aligned                    (aligned_mgtm_ltpi          ),//Mark that LVDS link has locked
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
        
    .avalon_mm_m                (u_avmm_cntrl               ),//AVMM Controller interface tunneling through LVDS, Dose not exist on controller side
    .avalon_mm_s                (u_avmm_mm                  ),//AVMM Target interface tunneling through LVDS, Only exist on controller side
    .data_channel_timeout       (data_channel_timeout       ),
    .tag_in                     (tag                        ) //Tag field only exist while DATA_CHANNEL_MAILBOX_EN = 0
);


ltpi_csr_avmm  #(
    .CSR_LIGHT_VER_EN(CSR_LIGHT_VER_EN)
)ltpi_csr_avmm_inst
(
    .clk                        (clk_60MHZ                  ),
    .reset_n                    (!reset                     ),
    .avalon_mm_s                (u_avmm_CSR                 ),
    .CSR_hw_out                 (CSR_hw_out                 ),
    .CSR_hw_in                  (CSR_hw_in                  )
);

endmodule