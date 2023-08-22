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

module ltpi_top_BMC_com_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 
import I2C_controller_bridge_pkg::*;

string name = "ltpi_top_BMC_com_unit_test";
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

logic CTRL_aligned;
logic TRG_aligned;

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

ltpi_top_controller ltpi_top_controller(
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

ltpi_top_target ltpi_top_target(
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

I2C_controller_bridge_driver u_I2C_controller_driver = new (u_avmm);

i2c_controller_avmm_bridge i2c_controller_avmm_bridge_BMC (
    .i2c_clock_clk      (clk_25_controller         ), 
    .i2c_csr_address    (u_avmm.address[3:0]   ),
    .i2c_csr_read       (u_avmm.read           ),
    .i2c_csr_write      (u_avmm.write          ),
    .i2c_csr_writedata  (u_avmm.writedata      ),
    .i2c_csr_readdata   (u_avmm.readdata       ), 

    .i2c_irq_irq        (), 
    .i2c_reset_reset_n  (reset_controller           ),
    .i2c_serial_sda_in  (i2c_serial_sda_in      ),
    .i2c_serial_scl_in  (i2c_serial_scl_in      ),
    .i2c_serial_sda_oe  (i2c_serial_sda_oe      ),
    .i2c_serial_scl_oe  (i2c_serial_scl_oe      )
);

function void build();
    svunit_ut = new (name);
endfunction

task setup();
    svunit_ut.setup();

    reset_controller = 0; 
    reset_target = 0;
    u_I2C_controller_driver.reset();
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


    `SVTEST(BMC_write_clear_status_reg)
        logic [15: 0] addr_offset = 16'h04;

        u_I2C_controller_driver.i2c_controller_setup();

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR , '1);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Status.link_lost_error            , 0);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Status.frm_CRC_error              , 0);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Status.unknown_comma_error        , 0);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Status.link_speed_timeout_error   , 0);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Status.link_cfg_acpt_timeout_error, 0);

    `SVTEST_END

    `SVTEST(BMC_write_link_speed_capab)
        logic [15: 0] addr_offset = 16'h04;

        logic [31: 0] data_write  = '0;
        logic [15: 0] link_Speed_capab;

        link_Speed_capab = $urandom_range(16'hFFFF,0);
        data_write[23: 8] = link_Speed_capab;

        u_I2C_controller_driver.i2c_controller_setup();

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        `FAIL_UNLESS_EQUAL(link_Speed_capab, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Detect_Capab_local.Link_Speed_capab);
    `SVTEST_END

    `SVTEST(BMC_write_advertise_reg)
        logic [15:0] addr_offset = 16'h14;

        logic [ 4:0] supported_channel;
        logic [ 9:0] NL_GPIO_nb;
        logic [ 5:0] I2C_channel_en;
        logic        I2C_Echo_support;

        logic [5:0]  I2C_channel_cpbl;
        logic [1:0]  UART_channel_en;
        logic        UART_Flow_ctrl;
        logic [3:0]  UART_channel_cpbl;
        logic [15:0] OEM_cpbl;

        logic [31:0] data_write        = '0;
        bit   [31:0] data_read         = '0;

        supported_channel  = $urandom_range(5'h1F,0);
        NL_GPIO_nb         = $urandom_range(10'h3FF,0);
        I2C_channel_en     = $urandom_range(6'h3F,0);
        I2C_Echo_support   = $urandom_range(1'h1,0);

        data_write[ 4: 0] = supported_channel;
        data_write[17: 8] = NL_GPIO_nb;
        data_write[29:24] = I2C_channel_en;
        data_write[30:30] = I2C_Echo_support;
        
        u_I2C_controller_driver.i2c_controller_setup();

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset,data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        `FAIL_UNLESS_EQUAL(supported_channel, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.supported_channel);
        `FAIL_UNLESS_EQUAL(NL_GPIO_nb, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.NL_GPIO_nb);
        `FAIL_UNLESS_EQUAL(I2C_channel_en, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_en);
        `FAIL_UNLESS_EQUAL(I2C_Echo_support, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.I2C_Echo_support);

        addr_offset         = 16'h18;
        I2C_channel_cpbl    = $urandom_range(6'h3F, 0);
        UART_channel_cpbl   = $urandom_range(4'hF, 0);
        UART_Flow_ctrl      = $urandom_range(1'h1, 0);
        UART_channel_en     = $urandom_range(2'h3, 0);
        OEM_cpbl            = $urandom_range(16'hFFFF, 0);

        data_write[ 5: 0] = I2C_channel_cpbl;
        data_write[11: 8] = UART_channel_cpbl;
        data_write[   12] = UART_Flow_ctrl;
        data_write[14:13] = UART_channel_en;
        data_write[31:16] = OEM_cpbl;

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        `FAIL_UNLESS_EQUAL(I2C_channel_cpbl, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_cpbl);
        `FAIL_UNLESS_EQUAL(UART_channel_cpbl, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_cpbl);
        `FAIL_UNLESS_EQUAL(UART_Flow_ctrl, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.UART_Flow_ctrl);
        `FAIL_UNLESS_EQUAL(UART_channel_en, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_en);
        `FAIL_UNLESS_EQUAL(OEM_cpbl[15:8], ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte1);
        `FAIL_UNLESS_EQUAL(OEM_cpbl[7:0], ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte0);
        
    `SVTEST_END

    `SVTEST(BMC_write_read_link_speed_capab)
        logic [15: 0] addr_offset = 16'h04;
        bit   [31: 0] data_read;
        logic [31: 0] data_write  = '0;
        logic [15: 0] link_Speed_capab;

        link_Speed_capab = $urandom_range(16'hFFFF,0);
        data_write[23: 8] = link_Speed_capab;

        u_I2C_controller_driver.i2c_controller_setup();

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        `FAIL_UNLESS_EQUAL(link_Speed_capab, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Detect_Capab_local.Link_Speed_capab);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        `FAIL_UNLESS_EQUAL(link_Speed_capab, data_read[23:8]);
    `SVTEST_END

    `SVTEST(BMC_write_read_advertise_reg)
        logic [15: 0] addr_offset = 16'h14;
        bit   [31: 0] data_read;
        logic [ 4:0] supported_channel;
        logic [ 9:0] NL_GPIO_nb;
        logic [ 5:0] I2C_channel_en;
        logic        I2C_Echo_support;

        logic [5:0]  I2C_channel_cpbl;
        logic [1:0]  UART_channel_en;
        logic        UART_Flow_ctrl;
        logic [3:0]  UART_channel_cpbl;
        logic [15:0] OEM_cpbl;

        logic [31:0] data_write        = '0;

        supported_channel  = $urandom_range(5'h1F,0);
        NL_GPIO_nb         = $urandom_range(10'h3FF,0);
        I2C_channel_en     = $urandom_range(6'h3F,0);
        I2C_Echo_support   = $urandom_range(1'h1,0);

        data_write[ 4: 0] = supported_channel;
        data_write[17: 8] = NL_GPIO_nb;
        data_write[29:24] = I2C_channel_en;
        data_write[30:30] = I2C_Echo_support;

        u_I2C_controller_driver.i2c_controller_setup();
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);

        repeat(10)@(posedge clk_25);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        `FAIL_UNLESS_EQUAL(data_read,data_write);
        repeat(100) @(posedge clk_25); 
 
        addr_offset         = 16'h18;
        I2C_channel_cpbl    = $urandom_range(6'h3F, 0);
        UART_channel_cpbl   = $urandom_range(4'hF, 0);
        UART_Flow_ctrl      = $urandom_range(1'h1, 0);
        UART_channel_en     = $urandom_range(2'h3, 0);
        OEM_cpbl            = $urandom_range(16'hFFFF, 0);
        data_write = 0;
        data_write[ 5: 0] = I2C_channel_cpbl;
        data_write[11: 8] = UART_channel_cpbl;
        data_write[   12] = UART_Flow_ctrl;
        data_write[14:13] = UART_channel_en;
        data_write[31:16] = OEM_cpbl;

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        `FAIL_UNLESS_EQUAL(data_read,data_write);
        repeat(100) @(posedge clk_25); 
    `SVTEST_END

    `SVTEST(BMC_read_link_training_RX_TX_counter)
        logic [15: 0] addr_offset = 16'h44;
        bit   [31: 0] data_read;

        u_I2C_controller_driver.i2c_controller_setup();
        //rx link training frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);

        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st)
        //rx link training frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        
        addr_offset = 16'h4C;//tx link training frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);

        addr_offset = 16'h48;//rx advertise frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);

        addr_offset = 16'h50;//tx advertise frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);

        addr_offset = 16'h54;//rx operational frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);

        addr_offset = 16'h58;//tx operational frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
    `SVTEST_END

    `SVTEST(BMC_software_reset)
        logic [15: 0] addr_offset = 16'h80;
        bit   [31: 0] data_read;
        logic [31: 0] data_write  = '0;
        logic [15: 0] link_Speed_capab;
        logic software_reset = 1;
        data_write[0] = software_reset;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, 0);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(1000)@(posedge clk_25);

        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state, advertise_st);
        `FAIL_UNLESS_EQUAL(ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state, advertise_st);
    `SVTEST_END

    `SVTEST(BMC_retraining)
        logic [15: 0] addr_offset = 16'h04;

        logic [31: 0] data_write  = '0;
        logic [15: 0] link_Speed_capab;
        logic retraining_request;

        link_Speed_capab = 16'h00_02;
        data_write[23: 8] = link_Speed_capab;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        addr_offset         = 16'h80;
        retraining_request  = 1; 
        data_write          = '0;
        data_write[1]       = retraining_request;
        data_write[11]      = 1;//trigger_config_st;
        
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(10)@(posedge clk_25);

        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == advertise_st);
        wait(ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == advertise_st);

        repeat(500)@(posedge clk_25);
        `FAIL_UNLESS_EQUAL(ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.link_speed, base_freq_x2);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.link_speed, base_freq_x2);
    `SVTEST_END

    `SVTEST(BMC_i2c_channel_reset)
        logic [15: 0] addr_offset = 16'h80;
        bit   [31: 0] data_read;
        logic [31: 0] data_write  = '0;
        logic [5:0] I2C_channel_reset;

        I2C_channel_reset = '1;
        data_write[8:2] = I2C_channel_reset;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        `FAIL_UNLESS_EQUAL(data_read[8:2], I2C_channel_reset); 
    `SVTEST_END

    `SVTEST(BMC_auto_trigger_config)
        logic [15: 0] addr_offset = 16'h80;
        bit   [31: 0] data_read;
        logic [31: 0] data_write  = '0;
        logic auto_move_config;
        logic trigger_config_st;

        auto_move_config    = 0;
        trigger_config_st   = 0;

        data_write[10] = auto_move_config;
        data_write[11] = trigger_config_st;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        
        `FAIL_UNLESS_EQUAL(auto_move_config, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Ctrl.auto_move_config);
        `FAIL_UNLESS_EQUAL(trigger_config_st, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Ctrl.trigger_config_st);
        
        auto_move_config    = 1;
        trigger_config_st   = 1;

        data_write[10] = auto_move_config;
        data_write[11] = trigger_config_st;

        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, data_write);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);

        `FAIL_UNLESS_EQUAL(auto_move_config, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Ctrl.auto_move_config);
        `FAIL_UNLESS_EQUAL(trigger_config_st, ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Link_Ctrl.trigger_config_st);
    `SVTEST_END

    `SVTEST(BMC_write_clear_rcv_link_training_counter)
        logic [15: 0] addr_offset = 16'h44;
        bit   [31: 0] data_read;

        u_I2C_controller_driver.i2c_controller_setup();
        //rx link training frames
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);
    
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, '1);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(500)@(posedge clk_25);
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        `FAIL_UNLESS_EQUAL(data_read, 0);
    `SVTEST_END

    `SVTEST(BMC_write_clear_rcv_advertise_counter)
        logic [15: 0] addr_offset = 16'h48;
        bit   [31: 0] data_read;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, '1);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        `FAIL_UNLESS_EQUAL(data_read, 0);
    `SVTEST_END

    `SVTEST(BMC_write_clear_rcv_operational_counter)
        logic [15: 0] addr_offset = 16'h54;
        bit   [31: 0] data_read;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, '1);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(5)@(posedge clk_25);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt, 0);
    `SVTEST_END

    `SVTEST(BMC_write_clear_snt_link_training_counter)
        logic [15: 0] addr_offset = 16'h4C;
        bit   [31: 0] data_read;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, '1);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(5)@(posedge clk_25);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low, 0);
    `SVTEST_END

    `SVTEST(BMC_write_clear_snt_advertise_counter)
        logic [15: 0] addr_offset = 16'h50;
        bit   [31: 0] data_read;
        
        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, '1);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(5)@(posedge clk_25);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high, 0);
    `SVTEST_END

    `SVTEST(BMC_write_clear_snt_operational_counter)
        logic [15: 0] addr_offset = 16'h58;
        bit   [31: 0] data_read;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.i2c_controller_read(BASE_ADDR + addr_offset, data_read);
        u_I2C_controller_driver.i2c_controller_write(BASE_ADDR + addr_offset, '1);
        wait(ltpi_top_controller.ltpi_csr_avmm_inst.wr_reg);
        repeat(5)@(posedge clk_25);
        `FAIL_UNLESS_EQUAL(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_counter.operational_frm_snt_cnt, 0);
    `SVTEST_END

    `SVTEST(BMC_MM_read_write)
        
        int size;
        int i = 2; 
        bit [31:0] req_addr [];
        bit [31:0] req_data [];
        bit [ 7:0] req_tag  [];

        bit [ 7:0] resp_cmd;
        bit [ 7:0] resp_status;
        bit [ 7:0] resp_tag;
        bit [31:0] resp_address;
        bit [31:0] resp_data;
        bit [ 7:0] resp_ben;

        logic [31:0] status;

        //size = 15;
        size = 4;
        //VCS

        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });

        //MODELSI & VCS
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);

        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = MM_BASE_ADDR + i*4;

        u_I2C_controller_driver.i2c_controller_setup();
        wait(ltpi_top_controller.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(ltpi_top_target.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        
        foreach (req_addr[i]) begin
            u_I2C_controller_driver.mm_request_read(req_addr[i], 4'hF, req_tag[i]);
            u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
            $display("TEST %h: resp_addr: %h , req_addr: %h" ,  i, resp_address ,req_addr[i]);
            #1000;
            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, i)
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
        end

        foreach (req_addr[i]) begin
            u_I2C_controller_driver.mm_request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
            u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
         end

        foreach (req_addr[i]) begin
            u_I2C_controller_driver.mm_request_read(req_addr[i], 4'hF, req_tag[i]);
            u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
        end
    `SVTEST_END

    `SVTEST(BMC_read_HPM_link_training_RX_TX_counter)
        logic [15: 0]  addr_offset = 16'h44;
        bit   [31: 0]  data_read;
        int            size;
        int            i;

        bit   [ 7: 0]  resp_cmd;
        bit   [ 7: 0]  resp_status;
        bit   [ 7: 0]  resp_tag;
        bit   [31: 0]  resp_address;
        bit   [31: 0]  resp_data;
        bit   [ 7: 0]  resp_ben;
        bit   [ 7: 0]  req_tag  [];

        size = 15;
        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);
        
        u_I2C_controller_driver.i2c_controller_setup();

        wait(ltpi_top_controller.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(ltpi_top_target.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);

        //rx link training frames
        addr_offset = 16'h44;
        i = 0;
        u_I2C_controller_driver.mm_request_read(BASE_ADDR + addr_offset, 4'hF, req_tag[i]);
        u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

        $display("TEST: resp_addr: %h , resp_data: %h" , resp_address , resp_data);

        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
        `FAIL_UNLESS_EQUAL(resp_address, BASE_ADDR + addr_offset)
        `FAIL_UNLESS_EQUAL(resp_data, ltpi_top_target.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low)
        `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
        `FAIL_UNLESS_EQUAL(resp_status, 0)
        `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])

        addr_offset = 16'h4C;//tx link training frames
        i = 1;
        u_I2C_controller_driver.mm_request_read(BASE_ADDR + addr_offset, 4'hF, req_tag[i]);
        u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
        $display("TEST: resp_addr: %h , resp_data: %h" , resp_address , resp_data);

        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
        `FAIL_UNLESS_EQUAL(resp_address, BASE_ADDR + addr_offset)
        `FAIL_UNLESS_EQUAL(resp_data, ltpi_top_target.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low)
        `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
        `FAIL_UNLESS_EQUAL(resp_status, 0)
        `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])

        addr_offset = 16'h48;//rx advertise frames
        i = 2;
        u_I2C_controller_driver.mm_request_read(BASE_ADDR + addr_offset, 4'hF, req_tag[i]);
        u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
        $display("TEST: resp_addr: %h , resp_data: %h" , resp_address , resp_data);

        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
        `FAIL_UNLESS_EQUAL(resp_address, BASE_ADDR + addr_offset)
        `FAIL_UNLESS_EQUAL(resp_data, ltpi_top_target.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_high)
        `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
        `FAIL_UNLESS_EQUAL(resp_status, 0)
        `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])

        addr_offset = 16'h50;//tx advertise frames
        i = 3;
        u_I2C_controller_driver.mm_request_read(BASE_ADDR + addr_offset, 4'hF, req_tag[i]);
        u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
        $display("TEST: resp_addr: %h , resp_data: %h" , resp_address , resp_data);

        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
        `FAIL_UNLESS_EQUAL(resp_address, BASE_ADDR + addr_offset)
        `FAIL_UNLESS_EQUAL(resp_data, ltpi_top_target.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_high)
        `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
        `FAIL_UNLESS_EQUAL(resp_status, 0)
        `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])

        addr_offset = 16'h58;//tx operational frames
        i = 3;
        u_I2C_controller_driver.mm_request_read(BASE_ADDR + addr_offset, 4'hF, req_tag[i]);
        u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

        $display("TEST: resp_addr: %h , resp_data: %h" , resp_address , resp_data);
        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
        `FAIL_UNLESS_EQUAL(resp_address, BASE_ADDR + addr_offset)
        `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
        `FAIL_UNLESS_EQUAL(resp_status, 0)
        `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
    `SVTEST_END

    `SVTEST(BMC_HMP_write_advertise_reg)
        logic [15:0] addr_offset = 16'h14;

        logic [ 4:0] supported_channel;
        logic [ 9:0] NL_GPIO_nb;
        logic [ 5:0] I2C_channel_en;
        logic        I2C_Echo_support;

        logic [5:0]  I2C_channel_cpbl;
        logic [1:0]  UART_channel_en;
        logic        UART_Flow_ctrl;
        logic [3:0]  UART_channel_cpbl;
        logic [15:0] OEM_cpbl;

        logic [31:0] data_write        = '0;
        bit   [31:0] data_read         = '0;
        bit   [ 7:0] req_tag; 

        bit   [ 7: 0]  resp_cmd;
        bit   [ 7: 0]  resp_status;
        bit   [ 7: 0]  resp_tag;
        bit   [31: 0]  resp_address;
        bit   [31: 0]  resp_data;
        bit   [ 7: 0]  resp_ben;

        supported_channel  = $urandom_range(5'h1F,0);
        NL_GPIO_nb         = $urandom_range(10'h3FF,0);
        I2C_channel_en     = $urandom_range(6'h3F,0);
        I2C_Echo_support   = $urandom_range(1'h1,0);
        req_tag            = $urandom_range(8'hFF,0);

        data_write[ 4: 0] = supported_channel;
        data_write[17: 8] = NL_GPIO_nb;
        data_write[29:24] = I2C_channel_en;
        data_write[30:30] = I2C_Echo_support;
        
        u_I2C_controller_driver.i2c_controller_setup();

        wait(ltpi_top_controller.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(ltpi_top_target.mgmt_ltpi_top_inst.LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);

        u_I2C_controller_driver.mm_request_write(BASE_ADDR + addr_offset,data_write, 4'hF, req_tag);
        u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP);
        `FAIL_UNLESS_EQUAL(resp_address, BASE_ADDR + addr_offset);
        `FAIL_UNLESS_EQUAL(resp_data, data_write);
        `FAIL_UNLESS_EQUAL(resp_ben, 4'hF);
        `FAIL_UNLESS_EQUAL(resp_status, 0);
        `FAIL_UNLESS_EQUAL(resp_tag, req_tag);

        `FAIL_UNLESS_EQUAL(supported_channel, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.supported_channel);
        `FAIL_UNLESS_EQUAL(NL_GPIO_nb, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.NL_GPIO_nb);
        `FAIL_UNLESS_EQUAL(I2C_channel_en, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_en);
        `FAIL_UNLESS_EQUAL(I2C_Echo_support, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.I2C_Echo_support);

        addr_offset         = 16'h18;
        I2C_channel_cpbl    = $urandom_range(6'h3F, 0);
        UART_channel_cpbl   = $urandom_range(4'hF, 0);
        UART_Flow_ctrl      = $urandom_range(1'h1, 0);
        UART_channel_en     = $urandom_range(2'h3, 0);
        OEM_cpbl            = $urandom_range(16'hFFFF, 0);
        req_tag             = $urandom_range(8'hFF, 0);

        data_write[ 5: 0] = I2C_channel_cpbl;
        data_write[11: 8] = UART_channel_cpbl;
        data_write[   12] = UART_Flow_ctrl;
        data_write[14:13] = UART_channel_en;
        data_write[31:16] = OEM_cpbl;

        u_I2C_controller_driver.mm_request_write(BASE_ADDR + addr_offset,data_write, 4'hF, req_tag);
        u_I2C_controller_driver.mm_response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP);
        `FAIL_UNLESS_EQUAL(resp_address, BASE_ADDR + addr_offset);
        `FAIL_UNLESS_EQUAL(resp_data, data_write);
        `FAIL_UNLESS_EQUAL(resp_ben, 4'hF);
        `FAIL_UNLESS_EQUAL(resp_status, 0);
        `FAIL_UNLESS_EQUAL(resp_tag, req_tag);

        `FAIL_UNLESS_EQUAL(I2C_channel_cpbl, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_cpbl);
        `FAIL_UNLESS_EQUAL(UART_channel_cpbl, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_cpbl);
        `FAIL_UNLESS_EQUAL(UART_Flow_ctrl, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.UART_Flow_ctrl);
        `FAIL_UNLESS_EQUAL(UART_channel_en, ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_en);
        `FAIL_UNLESS_EQUAL(OEM_cpbl[15:8], ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte1);
        `FAIL_UNLESS_EQUAL(OEM_cpbl[7:0], ltpi_top_target.ltpi_csr_avmm_inst.CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte0);
        
    `SVTEST_END

`SVUNIT_TESTS_END

endmodule