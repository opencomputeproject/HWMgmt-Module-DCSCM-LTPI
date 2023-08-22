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

module ltpi_link_aligned_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "ltpi_link_aligned_unit_test";
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
        #1 timer_fun(timer_start,timer_done);
    end
end

logic reset_controller = 0;
logic reset_target = 0;

LTPI_CSR_In_t CTRL_LTPI_CSR_In ='0;
LTPI_CSR_Out_t CTRL_LTPI_CSR_Out;
    
LTPI_CSR_In_t TRG_LTPI_CSR_In='0;
LTPI_CSR_Out_t TRG_LTPI_CSR_Out;

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



logic [1023:0] CTRL_nl_gpio_in = '0;
//logic [1023:0] CTRL_nl_gpio_in ;
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
logic [1:0] CTRL_uart_rx;
logic [1:0] TRG_uart_tx;
logic [1:0] TRG_uart_rx;


wire CTRL_normal_gpio_stable;
//I2C
wire [ 5:0] CTRL_smb_scl;
wire [ 5:0] CTRL_smb_sda;

wire [ 5:0] TRG_smb_scl;
wire [ 5:0] TRG_smb_sda;

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) CTRL_u_avmm_s (
    .aclk           (clk_60_controller),
    .areset_n       (reset_controller)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) CTRL_u_avmm_m (
    .aclk           (clk_60_controller),
    .areset_n       (reset_controller)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) TRG_u_avmm_s (
    .aclk           (clk_60_target),
    .areset_n       (reset_target)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) TRG_u_avmm_m (
    .aclk           (clk_60_target),
    .areset_n       (reset_target)
);

assign CTRL_u_avmm_m.readdata         = '0;
assign CTRL_u_avmm_m.waitrequest      = '0;
assign CTRL_u_avmm_m.readdatavalid    = '0;

assign TRG_u_avmm_s.address     = '0; 
assign TRG_u_avmm_s.read        = '0;
assign TRG_u_avmm_s.write       = '0;
assign TRG_u_avmm_s.writedata   = '0;
assign TRG_u_avmm_s.byteenable  = '0;

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


mgmt_ltpi_top #(
    .CONTROLLER (1)
) mgmt_ltpi_top_controller(
    .ref_clk        ( clk_25_controller             ),
    .clk            ( clk_60_controller             ),
    .reset          ( ~reset_controller             ),

    .LTPI_CSR_In    ( CTRL_LTPI_CSR_In           ),
    .LTPI_CSR_Out   ( CTRL_LTPI_CSR_Out          ),
    //LVDS output pins
    .lvds_tx_data   ( lvds_tx_data_ctrl          ),
    .lvds_tx_clk    ( lvds_tx_clk_ctrl           ),

    // //LVDS input pins
    .lvds_rx_data   (lvds_rx_data_ctrl           ),
    .lvds_rx_clk    (lvds_rx_clk_ctrl            ),

    .smb_scl        (CTRL_smb_scl                ),//I2C interfaces tunneling through LVDS 
    .smb_sda        (CTRL_smb_sda                ),

    .ll_gpio_in     (CTRL_ll_gpio_in             ),//GPIO input tunneling through LVDS
    .ll_gpio_out    (CTRL_ll_gpio_out            ),//GPIO output tunneling through LVDS
    
    .nl_gpio_in     (CTRL_nl_gpio_in             ),//GPIO input tunneling through LVDS
    .nl_gpio_out    (CTRL_nl_gpio_out            ),//GPIO output tunneling through LVDS

    .uart_rxd       (CTRL_uart_rx                ),//UART interfaces tunneling through LVDS
    .uart_cts       ('0                         ),//Clear To Send
    .uart_txd       (CTRL_uart_tx                ),
    .uart_rts       (                           ),//Request To Send
    .avalon_mm_m    (CTRL_u_avmm_m               ),
    .avalon_mm_s    (CTRL_u_avmm_s               )

);

mgmt_ltpi_top #(
    .CONTROLLER (0)
) mgmt_ltpi_top_target(
    .ref_clk        ( clk_25_target              ),
    .clk            ( clk_60_target              ), 
    .reset          ( ~reset_target              ),

    .LTPI_CSR_In    ( TRG_LTPI_CSR_In           ),
    .LTPI_CSR_Out   ( TRG_LTPI_CSR_Out          ),

     //LVDS output pins
    .lvds_tx_data   ( lvds_rx_data_ctrl          ),
    .lvds_tx_clk    ( lvds_rx_clk_ctrl           ),

    // //LVDS input pins
    .lvds_rx_data   ( lvds_tx_data_ctrl          ),
    .lvds_rx_clk    ( lvds_tx_clk_ctrl           ),

    //interfaces
    .smb_scl        ( TRG_smb_scl               ),//(CTRL_smb_scl),        //I2C interfaces tunneling through LVDS 
    .smb_sda        ( TRG_smb_sda               ),//(CTRL_smb_sda),

    .ll_gpio_in     ( TRG_ll_gpio_in            ),//GPIO input tunneling through LVDS
    .ll_gpio_out    ( TRG_ll_gpio_out           ),

    .nl_gpio_in     ( TRG_nl_gpio_in            ),//GPIO input tunneling through LVDS
    .nl_gpio_out    ( TRG_nl_gpio_out           ),//GPIO output tunneling through LVDS

    .uart_rxd       ( TRG_uart_rx               ),//UART interfaces tunneling through LVDS
    .uart_cts       ( '0                        ),//Clear To Send
    .uart_txd       ( TRG_uart_tx               ),//TRG_uart_rx
    .uart_rts       (                           ),//Request To Send
    .avalon_mm_m    (TRG_u_avmm_m               ),
    .avalon_mm_s    (TRG_u_avmm_s               )
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
        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h80,8'hFF};
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
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h80,8'h10};
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

        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote.Link_Speed_capab = {8'h80,8'h10}; 
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_remote.Link_Speed_capab = {8'h80,8'hFF}; 

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
    `SVTEST(align_test)
        timer_start = 1'b1;
        wait(timer_done == 1'b1 || (aligned_ctrl == 1'b1 && aligned_trg == 1'b1 ));

        `FAIL_UNLESS(timer_done == 1'b0);
        `FAIL_UNLESS(aligned_ctrl == 1'b1);
        `FAIL_UNLESS(aligned_trg == 1'b1);
        repeat(100) @(posedge clk_25); 
    `SVTEST_END

`SVUNIT_TESTS_END

endmodule