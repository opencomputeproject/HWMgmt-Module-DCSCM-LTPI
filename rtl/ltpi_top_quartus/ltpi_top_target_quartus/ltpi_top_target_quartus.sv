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
// -- Date          : September 2022
// -- Project Name  : LTPI
// -- Description   :
// -- LTPI Top Target Quartus Implementation 
// -------------------------------------------------------------------

module ltpi_top_target_quartus
(
    input           CLK_25M_OSC_CPU_FPGA,
    input           PWRGD_P1V2_MAX10_AUX_CPU_PLD_R, //Reset_N_EXT

    // LVDS Link to SMC FPGA
    input           LVDS_CLK_RX_DP,
    output          LVDS_CLK_TX_R_DP,
    input           LVDS_RX_DP,
    output          LVDS_TX_R_DP,

    //UART
    output reg      UART_TX,
    output reg      UART_RTS,
    input           UART_RX,
    input           UART_CTS,

    //I2C over LVDS
    inout           I2C_SCL,
    inout           I2C_SDA, 

    output          NL_GPIO_0,
    output          LL_GPIO_0,
    output          DUT_ALIGNED

);

wire                rst_n;
wire                aligned;
wire                normal_gpio_stable; 

wire        [ 5:0]  smb_scl;
wire        [ 5:0]  smb_sda;

logic     [1023:0]  nl_gpio_in;
wire      [1023:0]  nl_gpio_out;
logic       [15:0]  ll_gpio_in;
logic       [15:0]  ll_gpio_out;

wire        [ 1:0]  uart_rxd;
wire        [ 1:0]  uart_cts;
wire        [ 1:0]  uart_txd;
wire        [ 1:0]  uart_rts;

assign uart_rxd[0]  = UART_RX;
assign UART_TX      = uart_txd[0];
assign uart_cts     = 0;

assign DUT_ALIGNED  = aligned;
assign NL_GPIO_0    = nl_gpio_out[0];
assign LL_GPIO_0    = ll_gpio_out[0];

ltpi_top_target ltpi_top_target_inst(
    .CLK_25M_OSC_CPU_FPGA       (CLK_25M_OSC_CPU_FPGA           ),
    .reset_in                   (~PWRGD_P1V2_MAX10_AUX_CPU_PLD_R),

    //LVDS output pins
    .lvds_tx_data               (LVDS_TX_R_DP                   ),
    .lvds_tx_clk                (LVDS_CLK_TX_R_DP               ),

    //LVDS input pins
    .lvds_rx_data               (LVDS_RX_DP                     ),
    .lvds_rx_clk                (LVDS_CLK_RX_DP                 ),

    .aligned                    (aligned                        ),

    .smb_scl                    ({ I2C_SCL, I2C_SCL,I2C_SCL,I2C_SCL,I2C_SCL,I2C_SCL}), //I2C interfaces tunneling through LVDS 
    .smb_sda                    ({ I2C_SDA, I2C_SDA,I2C_SDA,I2C_SDA,I2C_SDA,I2C_SDA}),

    .ll_gpio_in                 (ll_gpio_in                     ),//GPIO input tunneling through LVDS
    .ll_gpio_out                (ll_gpio_out                    ),//GPIO output tunneling through LVDS
    
    .nl_gpio_in                 (nl_gpio_in                     ),//GPIO input tunneling through LVDS
    .nl_gpio_out                (nl_gpio_out                    ),//GPIO output tunneling through LVDS

    .uart_rxd                   (uart_rxd                       ),//UART interfaces tunneling through LVDS
    .uart_cts                   (uart_cts                       ),//Clear To Send
    .uart_txd                   (uart_txd                       ),
    .uart_rts                   (uart_rts                       ) //Request To Send
);

endmodule