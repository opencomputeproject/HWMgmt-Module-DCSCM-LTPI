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

module mgmt_phy_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "mgmt_phy_unit_test";
string test_name;
int test_nb =0;
localparam int DATA_SNT_CNT = 100;

svunit_testcase svunit_ut;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);
localparam real CLOCK_60  = (TIME_BASE / 60.00);
localparam real CLOCK_120  = (TIME_BASE / 120.00);

//logic clk_60 = 0;
logic clk_60;
logic clk_120;
logic clk_25 ;
logic clk_25_dut0;
logic clk_25_dut1;

logic ref_clk;

logic reset_target  = 0; 
logic reset_controller = 0;
logic lvds_tx_data_ctrl;
logic lvds_tx_clk_ctrl;
logic lvds_rx_data_ctrl;
logic lvds_rx_clk_ctrl;

logic aligned_ctrl;
logic aligned_trg;

//timer 
logic timer_done ='0;
logic timer_start ='0;
logic[31:0] timer ='0;

LTPI_CSR_In_t TRG_LTPI_CSR_In='0;
LTPI_CSR_In_t CTRL_LTPI_CSR_In='0;
LTPI_CSR_Out_t CTRL_LTPI_CSR_Out;
LTPI_CSR_Out_t TRG_LTPI_CSR_Out;

Operational_IO_Frm_t CTRL_operational_frm_tx;
Operational_IO_Frm_t CTRL_operational_frm_rx;

Operational_IO_Frm_t TRG_operational_frm_tx;
Operational_IO_Frm_t TRG_operational_frm_rx;
logic [7:0] k = 1 ;

assign aligned_ctrl  = CTRL_LTPI_CSR_Out.LTPI_Link_Status.aligned;
assign aligned_trg  = TRG_LTPI_CSR_Out.LTPI_Link_Status.aligned;

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

function void timer_fun (input logic start, output logic timer_done );
    if(start == 1'b1) begin
        if(timer < 3000000) begin //3ms
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

logic ref_clk_controller;
logic ref_clk_target;
logic clk_25_controller;
logic clk_60_controller;
logic clk_25_target;
logic clk_60_target;

assign clk_25 = clk_25_dut0;
assign ref_clk_controller   = clk_25_dut0;
assign ref_clk_target    = clk_25_dut1;

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
    .ref_clk        ( ref_clk_controller       ),
    .clk            ( clk_60_controller        ),
    //.clk            ( clk_120        ),
    .reset          ( reset_controller  ),

    .LTPI_CSR_In    ( CTRL_LTPI_CSR_In   ),
    .LTPI_CSR_Out   ( CTRL_LTPI_CSR_Out  ),

    //LVDS output pins
    .lvds_tx_data   ( lvds_tx_data_ctrl  ),
    .lvds_tx_clk    ( lvds_tx_clk_ctrl   ),

    // //LVDS input pins
    .lvds_rx_data   (lvds_rx_data_ctrl   ),
    .lvds_rx_clk    (lvds_rx_clk_ctrl    ),

    .operational_frm_tx (CTRL_operational_frm_tx),
    .operational_frm_rx (CTRL_operational_frm_rx)

);

mgmt_phy_top #(
    .CONTROLLER (0)
) mgmt_phy_top_target(
    .ref_clk        ( ref_clk_target       ),
    .clk            ( clk_60_target        ), 
    //.clk            ( clk_120        ), 
    .reset          ( reset_target   ),

    .LTPI_CSR_In    ( TRG_LTPI_CSR_In   ),
    .LTPI_CSR_Out   ( TRG_LTPI_CSR_Out  ),

    //LVDS output pins
    .lvds_tx_data   ( lvds_rx_data_ctrl   ),
    .lvds_tx_clk    ( lvds_rx_clk_ctrl    ),

    //LVDS input pins
    .lvds_rx_data   ( lvds_tx_data_ctrl      ),
    .lvds_rx_clk    ( lvds_tx_clk_ctrl       ),

    .operational_frm_tx (TRG_operational_frm_tx),
    .operational_frm_rx (TRG_operational_frm_rx)

);
// ------------------------------------------------
    function void build();
        svunit_ut = new (name);
    endfunction


    task setup();
        svunit_ut.setup();
        timer_start  = 0;
        reset_target  = 1; 
        reset_controller = 1; 

        //detect frm
        //speed capabiliestes host
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h80,8'hFF};
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_local.LTPI_Version           <= LTPI_Version;
        //advertise frm host
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.supported_channel    <= 5'd2;
       // CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h321;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h3FF;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b0;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_en       <= 6'h3F;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h3F;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_en      <= 2'h3;
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

        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.supported_channel    <= 5'd7;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h3FF;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b0;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_en       <= 6'h3F;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'hF;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_en      <= 2'h3;
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


        repeat(10) @(posedge clk_25); 

    endtask

    task teardown();
        svunit_ut.teardown();
        timer_start = 0;
        reset_target  = 1; 
        reset_controller = 1;  
    endtask

`SVUNIT_TESTS_BEGIN

    `SVTEST(check_aligned)
        timer_start = 1;
        reset_target  = 0;
        repeat(10) @(posedge clk_25);
        reset_controller = 0; 
        wait(timer_done == 1 || (aligned_ctrl & aligned_trg))

        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned_ctrl =='1);
        `FAIL_UNLESS(aligned_trg =='1);

    `SVTEST_END

    `SVTEST(LINK_speed_select_test_SDR)
        logic [7:0] i =0;
        link_speed_t link_speed_enum = base_freq_x1;
        repeat(1000) @(posedge clk_25);
        $display("SPEED SELECT TEST DDR MODE : OFF");
        for ( i=0 ; i<5; i++) begin
            timer_start = 1;
            repeat(1000) @(posedge clk_25);
            reset_controller = 1;
            reset_target = 1;
            k = 1<<i;
            TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h00, k };

            repeat(100) @(posedge clk_25); 
            reset_controller = 0; 
            //repeat(1000) @(posedge clk_25);
            reset_target = 0;

            wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(aligned_ctrl == '1);
            `FAIL_UNLESS(aligned_trg == '1);

            wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
            wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

            `FAIL_UNLESS(timer_done =='0);

            repeat(400) @(posedge clk_25);

            //write back detect capabilites remote after speed change
            TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
            CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

            //$display("DDR MODE : OFF | CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            //$display("DDR MODE : OFF | TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            
            //wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
            //wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
            wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
            wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
            
            `FAIL_UNLESS(timer_done =='0);

            repeat(3000) @(posedge clk_25);

            $display("DDR MODE : OFF | CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            $display("DDR MODE : OFF | TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            $display("DDR MODE : OFF | FREQ %s", link_speed_enum.name());
            repeat(100) @(posedge clk_25);

            `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed, link_speed_enum)
            `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed, link_speed_enum)
            link_speed_enum = link_speed_enum.next();
            timer_start = 0;
            repeat(10) @(posedge clk_25);

        end
    `SVTEST_END

    `SVTEST(LINK_speed_select_test_DDR)
        logic [7:0] i = 0;
        link_speed_t link_speed_enum = base_freq_x4;
        
        repeat(1000) @(posedge clk_25);
        $display("SPEED SELECT TEST DDR MODE : ON");
        for ( i=3 ; i<5; i++) begin
            timer_start = 1;
            repeat(1000) @(posedge clk_25);
            reset_controller = 1;
            reset_target = 1;
            k = 1<<i;
            TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h80, k };

            repeat(100) @(posedge clk_25); 
            reset_controller = 0; 
            //repeat(1000) @(posedge clk_25);
            reset_target = 0;

            wait(timer_done == 1 || (aligned_ctrl == 1 & aligned_trg == 1 ));

            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(aligned_ctrl == '1);
            `FAIL_UNLESS(aligned_trg == '1);

            wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);
            wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == link_speed_st);

            `FAIL_UNLESS(timer_done =='0);

            repeat(400) @(posedge clk_25);

            //write back detect capabilites remote after speed change
            TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote <= CTRL_LTPI_CSR_Out.LTPI_Detect_Capab_remote;
            CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote <= TRG_LTPI_CSR_Out.LTPI_Detect_Capab_remote;

            //$display("DDR MODE : ON | CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            //$display("DDR MODE : ON | TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            
            // wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
             //wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st);
            wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
            wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
            
            `FAIL_UNLESS(timer_done =='0);

            repeat(3000) @(posedge clk_25);

            $display("DDR MODE : ON | CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            $display("DDR MODE : ON | TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed = %s ", TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed.name());
            $display("DDR MODE : ON | FREQ %s", link_speed_enum.name());
            repeat(100) @(posedge clk_25);

            `FAIL_UNLESS_EQUAL(CTRL_LTPI_CSR_Out.LTPI_Link_Status.link_speed, link_speed_enum)
            `FAIL_UNLESS_EQUAL(TRG_LTPI_CSR_Out.LTPI_Link_Status.link_speed, link_speed_enum)
            link_speed_enum = link_speed_enum.next();
            timer_start = 0;
            repeat(10) @(posedge clk_25);

        end

     `SVTEST_END

`SVUNIT_TESTS_END

endmodule