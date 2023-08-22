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

module link_state_machine_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "link_state_machine_unit_test";
string test_name;
int test_nb =0;
svunit_testcase svunit_ut;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);
localparam real CLOCK_10  = (TIME_BASE / 10.00);

logic clk_25 ;
logic clk_25_dut0;
logic clk_25_dut1;
//PLL
wire clk_20_dut0;
wire pll_locked_dut0;
wire pll_locked_dut1;

//LVDS test
logic lvds_tx_clk_ctrl;
logic lvds_tx_data_ctrl;
logic lvds_rx_data_ctrl;
logic lvds_rx_clk_ctrl;

logic aligned_ctrl;
logic aligned_trg;

assign clk_25 = clk_25_dut0;

initial begin
    clk_25_dut0 = 0;
    #5
    forever begin
        #(19) clk_25_dut0 = ~clk_25_dut0;
    end
end

initial begin
    clk_25_dut1 = 0;
    #15
    forever begin
        #(21) clk_25_dut1 = ~clk_25_dut1;
    end
end

//timer 
logic timer_done ='0;
logic timer_start ='0;
logic[31:0] timer ='0;

function void timer_fun (input logic start, output logic timer_done );
    if(start == 1'b1) begin
        if(timer < 5500000) begin //5.5ms
            timer <= timer + 1;
            timer_done <= 0;
        end
        else begin
            timer_done <='1;
        end
    end
    else begin
        timer <='0;
        timer_done <= '0;
    end
endfunction

initial begin
    #1
    forever begin
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote = CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote = TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        #1 timer_fun(timer_start,timer_done);
    end
end

logic reset_controller = 0;
logic reset_target = 0;

LTPI_CSR_In_t CTRL_LTPI_CSR_In ='0;
LTPI_CSR_Out_t CTRL_LTPI_CSR_Out;
    
LTPI_CSR_In_t TRG_LTPI_CSR_In='0;
LTPI_CSR_Out_t TRG_LTPI_CSR_Out;

Operational_IO_Frm_t CTRL_operational_frm_tx;
Operational_IO_Frm_t CTRL_operational_frm_rx;

Operational_IO_Frm_t TRG_operational_frm_tx;
Operational_IO_Frm_t TRG_operational_frm_rx;

logic ref_clk_controller;
logic ref_clk_target;
logic clk_25_controller;
logic clk_60_controller;
logic clk_25_target;
logic clk_60_target;


assign aligned_ctrl  = CTRL_LTPI_CSR_Out.LTPI_Link_Status.aligned;
assign aligned_trg  = TRG_LTPI_CSR_Out.LTPI_Link_Status.aligned;

assign ref_clk_controller   = clk_25_dut0;
assign ref_clk_target    = clk_25_dut1;

assign CTRL_operational_frm_tx.comma_symbol  = K28_7;
assign CTRL_operational_frm_tx.frame_subtype = K28_7_SUB_0;
assign CTRL_operational_frm_tx.frame_counter = '0;
assign CTRL_operational_frm_tx.ll_GPIO       = '0;
assign CTRL_operational_frm_tx.nl_GPIO       = '0;
assign CTRL_operational_frm_tx.uart_data     = '0;
assign CTRL_operational_frm_tx.i2c_data      = '0;
assign CTRL_operational_frm_tx.OEM_data      = '0;

assign TRG_operational_frm_tx.comma_symbol  = K28_7;
assign TRG_operational_frm_tx.frame_subtype = K28_7_SUB_0;
assign TRG_operational_frm_tx.frame_counter = '0;
assign TRG_operational_frm_tx.ll_GPIO       = '0;
assign TRG_operational_frm_tx.nl_GPIO       = '0;
assign TRG_operational_frm_tx.uart_data     = '0;
assign TRG_operational_frm_tx.i2c_data      = '0;
assign TRG_operational_frm_tx.OEM_data      = '0;

logic CTRL_add_crc_err = 1;
logic TRG_add_crc_err = 1;
logic [7:0] error_cnt ='0;

// ADD fake data to test CRC error implementation
always @ (posedge clk_25 ) begin
    if (CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON) begin 

        if(mgmt_phy_top_controller.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 3 || mgmt_phy_top_controller.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 4) begin
            CTRL_add_crc_err <= 0;
        end
    end
    else begin
        CTRL_add_crc_err <= 1'b1;
    end

    if (TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON) begin 
        if(mgmt_phy_top_target.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 3 || mgmt_phy_top_target.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 4) begin
            TRG_add_crc_err <= 0;
        end
    end
    else begin
        TRG_add_crc_err <= 1'b1;
    end
end

pll_cpu pll_system_controller (
    .areset                   ( 1'b0    ),
    .inclk0                   ( ref_clk_controller   ),
    .c0                       ( clk_25_controller    ),
    .c1                       ( clk_60_controller    ),
    .c2                       (),
    .locked                   ( )
    );

pll_cpu pll_system_target (
    .areset                   (1'b0),
    .inclk0                   ( ref_clk_target   ),
    .c0                       ( clk_25_target    ),
    .c1                       ( clk_60_target    ),
    .c2                       (),
    .locked                   ()
    );

mgmt_phy_top #(
    .CONTROLLER (1)
) mgmt_phy_top_controller(
    .ref_clk        ( clk_25_controller             ),
    .clk            ( clk_60_controller             ),
    .reset          ( ~reset_controller             ),

    .LTPI_CSR_In    ( CTRL_LTPI_CSR_In           ),
    .LTPI_CSR_Out   ( CTRL_LTPI_CSR_Out          ),
    //LVDS output pins
    .lvds_tx_data   ( lvds_tx_data_ctrl          ),
    .lvds_tx_clk    ( lvds_tx_clk_ctrl           ),

    // //LVDS input pins
    .lvds_rx_data   (lvds_rx_data_ctrl && CTRL_add_crc_err),
    .lvds_rx_clk    (lvds_rx_clk_ctrl            ),

    .operational_frm_tx (CTRL_operational_frm_tx ),
    .operational_frm_rx (CTRL_operational_frm_rx )

);

mgmt_phy_top #(
    .CONTROLLER (0)
) mgmt_phy_top_target(
    .ref_clk        ( clk_25_target              ),
    .clk            ( clk_60_target              ), 
    .reset          ( ~reset_target              ),

    .LTPI_CSR_In    ( TRG_LTPI_CSR_In           ),
    .LTPI_CSR_Out   ( TRG_LTPI_CSR_Out          ),

     //LVDS output pins
    .lvds_tx_data   ( lvds_rx_data_ctrl          ),
    .lvds_tx_clk    ( lvds_rx_clk_ctrl           ),

    // //LVDS input pins
    .lvds_rx_data   ( lvds_tx_data_ctrl && TRG_add_crc_err ),
    .lvds_rx_clk    ( lvds_tx_clk_ctrl           ),

    .operational_frm_tx (TRG_operational_frm_tx ),
    .operational_frm_rx (TRG_operational_frm_rx )


);

// ------------------------------------------------
    function void build();
        svunit_ut = new (name);
    endfunction


    task setup();
        svunit_ut.setup();

        reset_controller = 0; 
        reset_target = 0;
        timer_start = 0;
        
        //detect frm
        //speed capabiliestes host
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h80,8'h1F};
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_local.LTPI_Version           <= LTPI_Version;
        //advertise frm host
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.supported_channel    <= 5'd2;
       // CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h321;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h3FF;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h3F;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_Flow_ctrl       <= '0;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_cpbl    <= 5'd8;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.OEM_cpbl             <= '0;

        CTRL_LTPI_CSR_In.LTPI_platform_ID_local                         <={8'hAA,8'hBB};

        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config                <='0; 
        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st               <='1;
        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='0;
        //configure frm
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.supported_channel            <= 5'd2;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.NL_GPIO_nb                   <= 10'h3FF;
       //CTRL_LTPI_CSR_In.LTPI_Config_Capab.NL_GPIO_nb                   <= 10'h70;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_channel_cpbl             <= 6'h3;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.UART_Flow_ctrl               <= '0;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.UART_channel_cpbl            <= 5'd1;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.OEM_cpbl                     <='0;
        
        //detect frm
        //speed capabiliestes agent
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h00,8'h01};
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.LTPI_Version           <= LTPI_Version;
        //advertise frm agent
        //TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h251;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h3FF;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.supported_channel    <= 5'd7;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'hF;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_Flow_ctrl       <= '0;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_cpbl    <= 5'd4;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.OEM_cpbl             <= '0;

        TRG_LTPI_CSR_In.LTPI_platform_ID_local                         <={8'h12,8'h34};

        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config                <='0; 
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st               <='1;
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='0;

        //CRC error test 
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;

        //CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote.Link_Speed_capab = {8'h00,8'h01}; 
        //TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote.Link_Speed_capab = {8'h80,8'h0F}; 
        reset_controller = 0; 
        reset_target = 0;
        repeat(10) @(posedge clk_25); 

    endtask

    task teardown();
        svunit_ut.teardown();
        reset_controller = 0; 
        reset_target = 0;
    endtask

`SVUNIT_TESTS_BEGIN

    `SVTEST(HPM_delay_reset_test)
        test_nb = 1;
        timer_start = 1;
        test_name = "HPM delay reset test";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        repeat(6000) @(posedge clk_25); //240us
        reset_target = 1;

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(SCM_delay_reset_test)
        test_nb = 2;
        timer_start = 1;
        test_name = "SCM delay reset test";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_target = 1; 
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1;

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

//SCM is in reset ->that couse HPM reset, becouse there is no CLK on LVDS_TX_CLK , 
//which is an input of PLL -> HPM reset is PLL locked signal
    `SVTEST(Reset_SCM_SCM_HPM_in_link_detect)
        test_nb = 3;
        timer_start = 1;
        test_name = "SCM reset while HPM & SCM are in Link Detect state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        $display("aligned_ctrl = %0h, aligned_trg = %0h, timer_done = %0h", aligned_ctrl, aligned_trg ,timer_done);
        //FAIL_UNLESS_EQUAL

        //Link detect state least min 816 us (frame_cnt * frame_time =255 x 3.2us )
        repeat(600) @(posedge clk_25); //24us //SCM & HPM in Link detect state
        reset_controller = 0; 
        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        $display("aligned_ctrl = %0h, aligned_trg = %0h, timer_done = %0h", aligned_ctrl, aligned_trg ,timer_done);
        repeat(600) @(posedge clk_25);
    `SVTEST_END
        

    `SVTEST(Reset_HPM_SCM_HPM_in_link_detect)
        test_nb = 4;
        timer_start = 1;

        test_name = "HPM reset while HPM & SCM are in Link Detect state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25); //24us //SCM & HPM in Link detect state
        
        reset_target = 0; 
        repeat(600) @(posedge clk_25); //24us
        reset_target = 1; 
        
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
         repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(Reset_SCM_SCM_HPM_in_link_speed)
        test_nb = 5;
        timer_start = 1;

        test_name = "SCM reset while HPM & SCM are in Link Speed state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        //repeat(300) @(posedge clk_25); //12us
        reset_controller = 0; 
        repeat(300) @(posedge clk_25); //12us
        reset_controller = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(Reset_HPM_SCM_HPM_in_link_speed)
        test_nb = 6;
        timer_start = 1;
        test_name = "HPM reset while HPM & SCM are in Link Speed state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        //repeat(300) @(posedge clk_25); //12us
        reset_target = 0; 
        repeat(300) @(posedge clk_25); //12us
        reset_target = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(Reset_SCM_SCM_HPM_in_advertise)
        test_nb = 7;
        timer_start = 1;

        test_name = "SCM reset while HPM & SCM are in advertise state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);

        repeat(600) @(posedge clk_25); //24us
        reset_controller = 0; 
        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(Reset_HPM_SCM_HPM_in_advertise)
        test_nb = 8;
        timer_start = 1;
        test_name = "HPM reset while HPM & SCM are in advertise state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);

        repeat(600) @(posedge clk_25); //24us
        reset_target = 0; 
        repeat(600) @(posedge clk_25); //24us
        reset_target = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(Reset_SCM_SCM_HPM_in_configuartion_accept)
        test_nb = 9;
        timer_start = 1;

        test_name = "SCM reset while HPM is na configuration state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;


        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);

        repeat(60) @(posedge clk_25); //24us
        reset_controller = 0; 
        repeat(60) @(posedge clk_25); //24us
        reset_controller = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(Reset_HPM_SCM_HPM_in_configuartion_accept)
        test_nb = 10;
        timer_start = 1;
        test_name = "HPM reset while HPM is in accept state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);

        repeat(600) @(posedge clk_25); //24us
        reset_target = 0; 
        repeat(600) @(posedge clk_25); //24us
        reset_target = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END


    `SVTEST(Reset_SCM_SCM_HPM_in_opertional)
        test_nb = 11;
        timer_start = 1;

        test_name = "SCM reset while HPM is na configuration state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);

        repeat(600) @(posedge clk_25); //24us
        reset_controller = 0; 
        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(Reset_HPM_SCM_HPM_in_operational)
        test_nb = 12;
        timer_start = 1;
        test_name = "HPM reset while HPM is in accept state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;
        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);

        repeat(600) @(posedge clk_25); //24us
        reset_target = 0; 
        repeat(600) @(posedge clk_25); //24us
        reset_target = 1; 

        @(posedge clk_25);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(CRC_error_test_SCM_link_detect_state)
        test_nb = 13;
        timer_start = 1;
        test_name = "CRC error test - SCM recive crc in Link detect state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25); //24us
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;
        repeat(800) @(posedge clk_25); //32us
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25);
        
    `SVTEST_END

    `SVTEST(CRC_error_test_HPM_link_detect_state)
        test_nb = 14;
        timer_start = 1;
        test_name = "CRC error test - HPM recive crc in Link detect state ";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;

        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25); //240us
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;
        repeat(800) @(posedge clk_25); //32us
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;

        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25);


     `SVTEST_END

    `SVTEST(CRC_error_test_SCM_link_speed_state)
        test_nb = 15;
        timer_start = 1;
        test_name = "CRC error test - SCM recive crc in Link speed state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_speed_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_speed_st;

        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        //repeat(10) @(posedge clk_25);

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_speed_st;

        repeat(600) @(posedge clk_25); //24us

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 & CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_detect_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_detect_st));

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25);

   
    `SVTEST_END
    // It is not possile to catch CRC error becouse link state device last to short TRG 
    // `SVTEST(CRC_error_test_HPM_link_speed_state)
    //     test_nb = 16;
    //     timer_start = 1;
    //     test_name = "CRC error test - HPM recive crc in Link speed state";
    //     $display("%s", test_name);
    //     reset_controller = 0; 
    //     reset_target = 0;

    //     CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
    //     CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_speed_st;

    //     TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
    //     TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_speed_st;

    //     repeat(6000) @(posedge clk_25); //240us
    //     reset_controller = 1; 
    //     reset_target = 1;
    //     @(posedge clk_25); 

    //     wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

    //     `FAIL_UNLESS(timer_done =='0);
    //     `FAIL_UNLESS(aligned_ctrl == '1);
    //     `FAIL_UNLESS(aligned_trg == '1);

    //     wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
    //     wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

    //     //repeat(10) @(posedge clk_25); 

    //     TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
    //     TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_speed_st;

    //     repeat(600) @(posedge clk_25); //24us

    //     TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;

    //     wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
    //     `FAIL_UNLESS(timer_done =='0);
    //     wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 &  CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_detect_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_detect_st));

    //     `FAIL_UNLESS(timer_done =='0);
    //     `FAIL_UNLESS(aligned_ctrl == '1);
    //     `FAIL_UNLESS(aligned_trg == '1);

    //     repeat(600) @(posedge clk_25);

    // `SVTEST_END

    `SVTEST(CRC_error_test_SCM_link_advertise_state)
        test_nb = 17;
        timer_start = 1;
        test_name = "CRC error test - SCM recive crc in Link advertise state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= advertise_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= advertise_st;

        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);

        repeat(250) @(posedge clk_25); //15us

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= advertise_st;

        repeat(600) @(posedge clk_25); //24us

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(CRC_error_test_HPM_link_advertise_state)
        test_nb = 18;
        timer_start = 1;
        test_name = "CRC error test - HPM recive crc in Link advertise state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= advertise_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= advertise_st;

        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);

        repeat(250) @(posedge clk_25); //15us

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= advertise_st;

        repeat(600) @(posedge clk_25); //24us

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        repeat(600) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(CRC_error_test_SCM_link_configure_state)
        test_nb = 19;
        timer_start = 1;
        test_name = "CRC error test - SCM recive crc in Link Configuration state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= configuration_accept_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= configuration_accept_st;

        repeat(600) @(posedge clk_25); //24us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);

        //repeat(125) @(posedge clk_25); //5us

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= configuration_accept_st;

        repeat(600) @(posedge clk_25); //24us

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(CRC_error_test_HPM_link_accept_state)
        test_nb = 20;
        timer_start = 1;
        test_name = "CRC error test - HPM recive crc in Link Accept state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= configuration_accept_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= configuration_accept_st;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == configuration_accept_st);

        //repeat(125) @(posedge clk_25); //5us

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= configuration_accept_st;

        repeat(600) @(posedge clk_25); //240us

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(CRC_error_test_SCM_link_operational_state)
        test_nb = 21;
        timer_start = 1;
        test_name = "CRC error test - SCM recive crc in Link Opertional state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= operational_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= operational_st;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25);

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);

        repeat(600) @(posedge clk_25); //24us

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= operational_st;

        repeat(600) @(posedge clk_25); //24us

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;

        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(CRC_error_test_HPM_link_operational_state)
        test_nb = 22;
        timer_start = 1;
        test_name = "CRC error test - HPM recive crc in Link Operational state";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        CTRL_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= operational_st;

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= operational_st;

        repeat(6000) @(posedge clk_25); //240us
        reset_controller = 1; 
        reset_target = 1;
        @(posedge clk_25); 

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

        `FAIL_UNLESS(timer_done =='0);

        repeat(400) @(posedge clk_25);

        //write back detect capabilites remote after speed change
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);

        repeat(600) @(posedge clk_25); //24us

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b1;
        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= operational_st;

        repeat(600) @(posedge clk_25); //24us

        TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
        
        wait(timer_done == 1 || (aligned_ctrl == 0 & aligned_trg == 0 ));
        `FAIL_UNLESS(timer_done =='0);
        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);
        repeat(600) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(CSR_counter_test)
        test_nb = 23;
        timer_start = 1;
        test_name = "CSR counter test";
        $display("%s", test_name);
        reset_controller = 0; 
        reset_target = 0;

        repeat(100) @(posedge clk_25);
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st)
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st)
        `FAIL_UNLESS(timer_done == '0);
        repeat(1000) @(posedge clk_25);

        //check sent and recive link detect frames counters 
        $display("CONTROLLER LTPI_counter - sent: link_detect_frm_cnt = %0h | TARGET LTPI_counter - recive: link_detect_frm_cnt = %0h", 
        CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt, TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt);
        $display("TARGET LTPI_counter - sent: link_detect_frm_cnt = %0h | CONTROLLER LTPI_counter - recive: link_detect_frm_cnt = %0h", 
        TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt, CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt);
        // `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt, 
        // TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt)
        //check sent and recive link speed frames counters 
        $display("CONTROLLER LTPI_counter - sent: link_speed_frm_cnt = %0h | TARGET LTPI_counter - recive: link_speed_frm_cnt = %0h", 
         CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt, TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt);
        $display("TARGET LTPI_counter - sent: link_speed_frm_cnt = %0h | CONTROLLER LTPI_counter - recive: link_speed_frm_cnt = %0h", 
         TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt, CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt);

        // `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt, 
        // TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt)
        // `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt, 
        // CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt)

        //check sent and recive advertise frames counters 
        $display("CONTROLLER LTPI_counter - sent: link_advertise_frm_cnt = %0h | TARGET LTPI_counter - recive: link_advertise_frm_cnt = %0h", 
        CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt, TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt);
        `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt, 
        TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt)
        //check sent and recive configuration/accept frames counters 
         $display("CONTROLLER LTPI_counter - sent: link_cfg_acpt_frm_cnt = %0h | TARGET LTPI_counter - recive: link_cfg_acpt_frm_cnt = %0h", 
         CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt, TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt);
        `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt, 
        TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt)
        //check sent and recive link detect frames counters 
        $display("TARGET LTPI_counter - sent: link_detect_frm_cnt = %0h | CONTROLLER LTPI_counter - recive: link_detect_frm_cnt = %0h", 
         TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt, CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt);
        // `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt, 
        // TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt)
        //check sent and recive link speed frames counters 
        $display("TARGET LTPI_counter - sent: link_speed_frm_cnt = %0h | CONTROLLER LTPI_counter - recive: link_speed_frm_cnt = %0h", 
         TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt, CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt);
        // `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt, 
        // CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt)
        //check sent and recive advertise frames counters 
        $display("TARGET LTPI_counter - sent: link_advertise_frm_cnt = %0h | CONTROLLER LTPI_counter - recive: link_advertise_frm_cnt = %0h", 
        TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt, CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt);
        `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt, 
        CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt)
        //check sent and recive configuration/accept frames counters 
        $display("TARGET LTPI_counter - sent: link_cfg_acpt_frm_cnt = %0h | CONTROLLER LTPI_counter - recive: link_cfg_acpt_frm_cnt = %0h", 
         TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt, CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt);
        `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt, 
        CTRL_LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt)
        //check sent and recive operational frames counters 
        $display("CONTROLLER LTPI_counter - sent: operational_frm_rcv_cnt = %0h | TARGET LTPI_counter - recive: operational_frm_rcv_cnt = %0h", 
         CTRL_LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt, TRG_LTPI_CSR_Out.LTPI_counter.operational_frm_rcv_cnt);
        //`FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt, 
        //TRG_LTPI_CSR_Out.LTPI_counter.operational_frm_rcv_cnt)
        //check sent and recive operational frames counters 
        $display("TARGET LTPI_counter - sent: operational_frm_rcv_cnt = %0h | CONTROLLER LTPI_counter - recive: operational_frm_rcv_cnt = %0h", 
         TRG_LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt, CTRL_LTPI_CSR_Out.LTPI_counter.operational_frm_rcv_cnt);
        //`FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt, 
        //CTRL_LTPI_CSR_Out.LTPI_counter.operational_frm_rcv_cnt)
        
    `SVTEST_END

    `SVTEST(SCM_soft_reset_test)
        test_nb = 24;
        timer_start = 1;
        test_name = "SCM soft reset test";
        $display("%s", test_name);

        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config                <='0; 
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st               <='1;
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='0;

        reset_controller = 0; 
        reset_target = 0;

        repeat(100) @(posedge clk_25);
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        //wait for SCM and HPM in operational state
        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st)
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st)
        //put SCM software reset
        repeat(1000) @(posedge clk_25);
        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='1;
        repeat(300) @(posedge clk_25);
        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='0;

        wait(timer_done == 1 || (CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st);
        `FAIL_UNLESS(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st);
        repeat(600) @(posedge clk_25);

        wait(timer_done == 1 || (CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st));
        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st);
        `FAIL_UNLESS(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st);
        repeat(3000) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(HPM_soft_reset_test)
        test_nb = 25;
        timer_start = 1;
        test_name = "HPM soft reset test";
        $display("%s", test_name);

        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config                <='0; 
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st               <='1;
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='0;

        reset_controller = 0; 
        reset_target = 0;

        repeat(100) @(posedge clk_25);
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(aligned_ctrl == '1);
        `FAIL_UNLESS(aligned_trg == '1);

        //wait for SCM and HPM in operational state
        wait(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st)
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st)

        repeat(1000) @(posedge clk_25);

        //put HPM software reset
        repeat(1000) @(posedge clk_25);
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='1;
        repeat(300) @(posedge clk_25);
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='0;
        repeat(10000) @(posedge clk_25);//400us

        wait(timer_done == 1 || (CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st));
        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st);
        `FAIL_UNLESS(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st);

        wait(timer_done == 1 || (CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st));
        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st);
        `FAIL_UNLESS(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st);

        repeat(3000) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(advertise_test_with_auto_move_config)
        test_nb = 26;
        timer_start = 1;
        test_name = "Advertise test with auto_move_config and trigger_config";
        $display("%s", test_name);

        CTRL_LTPI_CSR_In.LTPI_platform_ID_local                         <={8'h77,8'h99};

        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config    <='0; 
        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st   <='0;
        

        TRG_LTPI_CSR_In.LTPI_platform_ID_local                         <={8'hFF,8'hDD};

        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config <='0; 
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st<='0;

        reset_controller = 0; 
        reset_target = 0;

        repeat(100) @(posedge clk_25);
        reset_controller = 1; 
        reset_target = 1;

        wait(timer_done == 1 || (CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st));
        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st);
        `FAIL_UNLESS(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st);
        
        //restart trigger
        timer_start = 0;
        repeat(100) @(posedge clk_25);
        timer_start = 1;
        repeat(50000) @(posedge clk_25); //2ms

        CTRL_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st <='1;
        repeat(100) @(posedge clk_25);
        TRG_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st <='1;

        wait(timer_done == 1 || (CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st));
        `FAIL_UNLESS(timer_done == '0);
        `FAIL_UNLESS(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st);
        `FAIL_UNLESS(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == operational_st);

        repeat(600) @(posedge clk_25);

        $display("CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local = %0h | TRG_LTPI_CSR_Out.LTPI_Advertise_Capab_remote = %0h", CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local, TRG_LTPI_CSR_Out.LTPI_Advertise_Capab_remote);
        $display("CTRL_LTPI_CSR_In.LTPI_platform_ID_local = %0h | TRG_LTPI_CSR_Out.LTPI_platform_ID_remote = %0h", CTRL_LTPI_CSR_In.LTPI_platform_ID_local, TRG_LTPI_CSR_Out.LTPI_platform_ID_remote);
        `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local, TRG_LTPI_CSR_Out.LTPI_Advertise_Capab_remote)
        `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_In.LTPI_platform_ID_local, TRG_LTPI_CSR_Out.LTPI_platform_ID_remote)

        $display("TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local = %0h | CTRL_LTPI_CSR_Out.LTPI_Advertise_Capab_remote = %0h", TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local, CTRL_LTPI_CSR_Out.LTPI_Advertise_Capab_remote);
        $display("TRG_LTPI_CSR_In.LTPI_platform_ID_local = %0h | CTRL_LTPI_CSR_Out.LTPI_platform_ID_remote = %0h", TRG_LTPI_CSR_In.LTPI_platform_ID_local, CTRL_LTPI_CSR_Out.LTPI_platform_ID_remote);
        `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local, CTRL_LTPI_CSR_Out.LTPI_Advertise_Capab_remote)
        `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_In.LTPI_platform_ID_local, CTRL_LTPI_CSR_Out.LTPI_platform_ID_remote)
    `SVTEST_END

    `SVTEST(advertise_random_data_test)
        test_nb = 27;
        timer_start = 1;
        test_name = "Advertise frame test with random data";
        $display("%s", test_name);

        for(int i = 0 ; i<2; i++) begin
            reset_controller = 0;
            reset_target = 0;

            CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= $urandom_range(0, 10'h3FF);
            CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.supported_channel    <= $urandom_range(0, 5'h1F);
            CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= $urandom_range(0, 6'h3F);
            CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_cpbl    <= $urandom_range(0, 5'h1F);
            CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.OEM_cpbl             <= {$urandom_range(0, 8'hFF), $urandom_range(0, 8'hFF), $urandom_range(0, 8'hFF)};
            CTRL_LTPI_CSR_In.LTPI_platform_ID_local                          <= {$urandom_range(0, 8'hFF), $urandom_range(0, 8'hFF)};

            TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= $urandom_range(0, 10'h3FF);
            TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.supported_channel    <= $urandom_range(0, 5'h1F);
            TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= $urandom_range(0, 6'h3F);
            TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_cpbl    <= $urandom_range(0, 5'h1F);
            TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.OEM_cpbl             <= {$urandom_range(0, 8'hFF), $urandom_range(0, 8'hFF), $urandom_range(0, 8'hFF)};
            TRG_LTPI_CSR_In.LTPI_platform_ID_local                          <= {$urandom_range(0, 8'hFF), $urandom_range(0, 8'hFF)};

            repeat(100) @(posedge clk_25); 
            reset_controller = 1;
            reset_target = 1;
            //wait for SCM and HPM in operational state
            wait(timer_done == 1 || (CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st & TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st));
            `FAIL_UNLESS(timer_done == '0);
            `FAIL_UNLESS(CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st);
            `FAIL_UNLESS(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state  == advertise_st); 

            repeat(1000) @(posedge clk_25); 

            $display("Test nb : %0d ", i); 
            $display("CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local = %0h | TRG_LTPI_CSR_Out.LTPI_Advertise_Capab_remote = %0h", CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local, TRG_LTPI_CSR_Out.LTPI_Advertise_Capab_remote);
            $display("CTRL_LTPI_CSR_In.LTPI_platform_ID_local = %0h | TRG_LTPI_CSR_Out.LTPI_platform_ID_remote = %0h", CTRL_LTPI_CSR_In.LTPI_platform_ID_local, TRG_LTPI_CSR_Out.LTPI_platform_ID_remote);
            `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local, TRG_LTPI_CSR_Out.LTPI_Advertise_Capab_remote)
            `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_In.LTPI_platform_ID_local, TRG_LTPI_CSR_Out.LTPI_platform_ID_remote)

            $display("TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local = %0h | CTRL_LTPI_CSR_Out.LTPI_Advertise_Capab_remote = %0h", TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local, CTRL_LTPI_CSR_Out.LTPI_Advertise_Capab_remote);
            $display("TRG_LTPI_CSR_In.LTPI_platform_ID_local = %0h | CTRL_LTPI_CSR_Out.LTPI_platform_ID_remote = %0h", TRG_LTPI_CSR_In.LTPI_platform_ID_local, CTRL_LTPI_CSR_Out.LTPI_platform_ID_remote);
            `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local, CTRL_LTPI_CSR_Out.LTPI_Advertise_Capab_remote)
            `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_In.LTPI_platform_ID_local, CTRL_LTPI_CSR_Out.LTPI_platform_ID_remote)
            
        end
        `SVTEST_END

`SVUNIT_TESTS_END

endmodule