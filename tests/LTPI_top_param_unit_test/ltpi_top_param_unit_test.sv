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

`include "svunit_defines.svh"
`timescale 1 ns / 1 ps

module ltpi_top_param_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 
import I2C_controller_bridge_pkg::*;

string name = "ltpi_top_param_unit_test";
string test_name;
int test_nb =0;
svunit_testcase svunit_ut;

localparam BASE_ADDR = 16'h200;
localparam MM_BASE_ADDR = 16'h400;
localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);
localparam real CLOCK_10  = (TIME_BASE / 10.00);

logic clk_25 ;

//LVDS test
logic lvds_tx_clk_ctrl;
logic lvds_tx_data_ctrl;
logic lvds_rx_data_ctrl;
logic lvds_rx_clk_ctrl;

logic aligned_ctrl;
logic aligned_trg;

logic clk_25_controller;
logic clk_25_target;

assign clk_25 = clk_25_controller;

initial begin
    clk_25_controller = 0;
    #5
    forever begin
        #(19) clk_25_controller = ~clk_25_controller;
    end
end

initial begin
    clk_25_target = 0;
    #15
    forever begin
        #(21) clk_25_target = ~clk_25_target;
    end
end


logic reset_controller = 0;
logic reset_target = 0;

logic [1023:0] CTRL_nl_gpio_in = '0;
logic [1023:0] CTRL_nl_gpio_out;
logic [1023:0] TRG_nl_gpio_in = '0;
logic [1023:0] TRG_nl_gpio_out;

logic [15:0] CTRL_ll_gpio_in = '0;
logic [15:0] CTRL_ll_gpio_out;
logic [15:0] TRG_ll_gpio_in = '0;
logic [15:0] TRG_ll_gpio_out;


logic [1:0] CTRL_uart_tx;
logic [1:0] CTRL_uart_rx = 0;
logic [1:0] TRG_uart_tx;
logic [1:0] TRG_uart_rx =0;


//I2C
tri1 [ 5:0] CTRL_smb_scl;
tri1 [ 5:0] CTRL_smb_sda;

tri1 [ 5:0] TRG_smb_scl;
tri1 [ 5:0] TRG_smb_sda;

tri1        BMC_smb_scl;
tri1        BMC_smb_sda;

logic             i2c_serial_scl_in;
logic             i2c_serial_sda_in;
logic             i2c_serial_scl_oe;
logic             i2c_serial_sda_oe;

assign i2c_serial_scl_in = BMC_smb_scl;
assign BMC_smb_scl = i2c_serial_scl_oe ? 1'b0 : 1'bz;

assign i2c_serial_sda_in = BMC_smb_sda;
assign BMC_smb_sda = i2c_serial_sda_oe ? 1'b0 : 1'bz;

ltpi_top_controller #(
    .CSR_LIGHT_VER_EN(0)
) ltpi_top_controller(
    .CLK_25M_OSC_CPU_FPGA        ( clk_25_controller             ),
    .reset_in          ( ~reset_controller             ),

    //LVDS output pins
    .lvds_tx_data   ( lvds_tx_data_ctrl          ),
    .lvds_tx_clk    ( lvds_tx_clk_ctrl           ),

    // //LVDS input pins
    .lvds_rx_data   (lvds_rx_data_ctrl           ),
    .lvds_rx_clk    (lvds_rx_clk_ctrl            ),

    .BMC_smb_scl    (BMC_smb_scl                ),            //I2C interfaces to BMC
    .BMC_smb_sda    (BMC_smb_sda                ),
    .aligned        (aligned_ctrl                ),

    .smb_scl        (CTRL_smb_scl                ),        //I2C interfaces tunneling through LVDS 
    .smb_sda        (CTRL_smb_sda                ),

    .ll_gpio_in     (CTRL_ll_gpio_in             ),        //GPIO input tunneling through LVDS
    .ll_gpio_out    (CTRL_ll_gpio_out            ),       //GPIO output tunneling through LVDS
    
    .nl_gpio_in     (CTRL_nl_gpio_in             ),        //GPIO input tunneling through LVDS
    .nl_gpio_out    (CTRL_nl_gpio_out            ),       //GPIO output tunneling through LVDS

    .uart_rxd       (CTRL_uart_rx                ),       //UART interfaces tunneling through LVDS
    .uart_cts       ('0                         ),       //Clear To Send
    .uart_txd       (CTRL_uart_tx                ),
    .uart_rts       ()       //Request To Send

);

ltpi_top_target #(
    .CSR_LIGHT_VER_EN(0)
) ltpi_top_target(
    .CLK_25M_OSC_CPU_FPGA        ( clk_25_target             ),
    .reset_in          ( ~reset_target             ),

     //LVDS output pins
    .lvds_tx_data   ( lvds_rx_data_ctrl          ),
    .lvds_tx_clk    ( lvds_rx_clk_ctrl           ),

    // //LVDS input pins
    .lvds_rx_data   ( lvds_tx_data_ctrl          ),
    .lvds_rx_clk    ( lvds_tx_clk_ctrl           ),

    .aligned        ( aligned_trg               ),
    
    //interfaces
    .smb_scl        ( TRG_smb_scl               ),//(CTRL_smb_scl),        //I2C interfaces tunneling through LVDS 
    .smb_sda        ( TRG_smb_sda               ),//(CTRL_smb_sda),

    .ll_gpio_in     ( TRG_ll_gpio_in            ),        //GPIO input tunneling through LVDS
    .ll_gpio_out    ( TRG_ll_gpio_out           ),

    .nl_gpio_in     ( TRG_nl_gpio_in            ),        //GPIO input tunneling through LVDS
    .nl_gpio_out    ( TRG_nl_gpio_out           ),       //GPIO output tunneling through LVDS

    .uart_rxd       ( TRG_uart_rx               ),       //UART interfaces tunneling through LVDS
    .uart_cts       ( '0                        ),       //Clear To Send
    .uart_txd       ( TRG_uart_tx               ),//TRG_uart_rx
    .uart_rts       (                           )       //Request To Send

);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);



function void build();
    svunit_ut = new (name);
endfunction

task setup();
    svunit_ut.setup();

    reset_controller = 0; 
    reset_target = 0;

    repeat(10) @(posedge clk_25); 
    reset_controller = 1; 
    reset_target = 1;

endtask

task teardown();
    svunit_ut.teardown();
    reset_controller = 0; 
    reset_target = 0;
endtask

`SVUNIT_TESTS_BEGIN


    `SVTEST(aligne)

        wait(aligned_ctrl == 1 & aligned_trg == 1 );

        repeat(100000)@(posedge clk_25);


    `SVTEST_END

    

`SVUNIT_TESTS_END

endmodule