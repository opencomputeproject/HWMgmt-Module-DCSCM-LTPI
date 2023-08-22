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
// -- LTPI Top Controller Quartus Implementation 
// -------------------------------------------------------------------

`include "logic.svh" 

module ltpi_top_controller_quartus
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

    //I2C to BMC
    inout           BMC_SMB_SCL,
    inout           BMC_SMB_SDA, 

    output          LL_GPIO_0,
    output          DUT_ALIGNED

);

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
logic               clk_60m;
logic               rst_n;

assign DUT_ALIGNED  = aligned;
assign uart_rxd[0]  = UART_RX;
assign UART_TX      = uart_txd[0];
assign uart_cts     = 0;

assign LL_GPIO_0    = ll_gpio_in[0];

ltpi_top_controller ltpi_top_controller_inst(
    .CLK_25M_OSC_CPU_FPGA       (CLK_25M_OSC_CPU_FPGA           ),
    .reset_in                   (~PWRGD_P1V2_MAX10_AUX_CPU_PLD_R),
    .clk_60MHZ                  (clk_60m                        ),
    .pll_locked                 (rst_n                          ),
    //LVDS output pins
    .lvds_tx_data               (LVDS_TX_R_DP                   ),
    .lvds_tx_clk                (LVDS_CLK_TX_R_DP               ),

    // //LVDS input pins
    .lvds_rx_data               (LVDS_RX_DP                     ),
    .lvds_rx_clk                (LVDS_CLK_RX_DP                 ),

    .BMC_smb_scl                (BMC_SMB_SCL                    ),//I2C interfaces to BMC
    .BMC_smb_sda                (BMC_SMB_SDA                    ),

    .aligned                    (aligned                        ),
    .NL_gpio_stable             (normal_gpio_stable             ),

    .smb_scl                    ({ I2C_SCL, I2C_SCL,I2C_SCL,I2C_SCL,I2C_SCL,I2C_SCL}),//I2C interfaces tunneling through LVDS 
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

logic [ 31:0] count;

always_ff @(posedge clk_60m or negedge rst_n) begin
    if (~rst_n) begin
        count <= '0;
    end
    else begin
        if (count == 5000000) begin
            count <= '0;
            nl_gpio_in[0] <= 1'b0; 
            nl_gpio_in[4] <= 1'b0; 
            ll_gpio_in[0]<='0;
        end
        else begin

            count <= count + 1;
 
            if(count == 250000) begin
                nl_gpio_in[0] <= 1'b1; 
                nl_gpio_in[4] <= 1'b1; 
                ll_gpio_in[0] <='1;
            end

        end
    end
end

endmodule