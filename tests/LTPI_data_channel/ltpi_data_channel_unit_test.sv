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

module ltpi_data_channel_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 
import ltpi_data_channel_controller_csr_rdl_pkg::*;
import ltpi_data_channel_controller_model_pkg::*;

string name = "ltpi_data_channel_unit_test";
string test_name;
int test_nb =0;
svunit_testcase svunit_ut;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);
localparam real CLOCK_10  = (TIME_BASE / 10.00);
localparam BASE_ADDR = 32'h0000_0000;

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
logic [1:0] CTRL_uart_rx ='0;
logic [1:0] TRG_uart_tx;
logic [1:0] TRG_uart_rx ='0;
wire tx_coreclock;
wire CTRL_normal_gpio_stable;
//I2C
wire [ 5:0] CTRL_smb_scl;
wire [ 5:0] CTRL_smb_sda;

wire [ 5:0] TRG_smb_scl;
wire [ 5:0] TRG_smb_sda;

logic CTRL_add_crc_err = 1;
logic TRG_add_crc_err = 1;


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

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm (
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
    .lvds_rx_data   (lvds_rx_data_ctrl && CTRL_add_crc_err),
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
    .uart_rts       (),                           //Request To Send
    .avalon_mm_m    (CTRL_u_avmm_m               ),
    .avalon_mm_s    (u_avmm               )
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
    .lvds_rx_data   ( lvds_tx_data_ctrl && TRG_add_crc_err ),
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

avmm_target_model avmm_target_model_inst
(
    .clk            (clk_60_target                  ),
    .rst_n          (reset_target                   ),
    //AVMM Intf
    .avmm_addr      (TRG_u_avmm_m.address           ),
    .avmm_read      (TRG_u_avmm_m.read              ),
    .avmm_write     (TRG_u_avmm_m.write             ),
    .avmm_wdata     (TRG_u_avmm_m.writedata         ),
    .avmm_byteen    (TRG_u_avmm_m.byteenable        ),
    .avmm_rdvalid   (TRG_u_avmm_m.readdatavalid     ),
    .avmm_waitrq    (TRG_u_avmm_m.waitrequest       ),
    .avmm_wrvalid   (TRG_u_avmm_m.writeresponsevalid),
    .avmm_rdata     (TRG_u_avmm_m.readdata          )
);

ltpi_data_channel_controller_driver u_controller_driver = new (u_avmm);
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
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h80,8'h08};
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

        CTRL_LTPI_CSR_In.LTPI_Detect_Capab_remote.Link_Speed_capab = {8'h80,8'h08}; 
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
    `SVTEST(basic)
        int size;

        bit [31:0] req_addr [];
        bit [31:0] req_data [];
        bit [ 7:0] req_tag  [];

        bit [ 7:0] resp_cmd;
        bit [ 7:0] resp_status;
        bit [ 7:0] resp_tag;
        bit [31:0] resp_address;
        bit [31:0] resp_data;
        bit [ 7:0] resp_ben;

        size = 15;

        //VCS
        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });

        //VCS & Modelsim
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);

        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = i*4;

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);

        TRG_ll_gpio_in <= 16'h1234;
        CTRL_ll_gpio_in <= 16'hABCD;

        //CTRL_nl_gpio_in <= 1024'h9876543210;
        for(int j = 0 ; j<128; j++) begin
            CTRL_nl_gpio_in[j*8+:8] <= $urandom_range(0, 8'hFF);
        end
        timer_start = 1;
        
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        `FAIL_UNLESS(timer_done =='0);
        timer_start = 0;

        repeat(1500) @(posedge clk_25); 

        foreach (req_addr[i]) begin
            u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, i)
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
        end

        foreach (req_addr[i]) begin
            u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
         end

        foreach (req_addr[i]) begin
            u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
        end
    `SVTEST_END

    `SVTEST(fifo_test)
        int size;

        bit [31:0] req_addr [];
        bit [31:0] req_data [];
        bit [ 7:0] req_tag  [];

        bit [ 7:0] resp_cmd;
        bit [ 7:0] resp_status;
        bit [ 7:0] resp_tag;
        bit [31:0] resp_address;
        bit [31:0] resp_data;
        bit [ 7:0] resp_ben;

        size = 15;

        //VCS
        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });

        //VCS & Modelsim
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);

        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = i*4;

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);
        
        TRG_ll_gpio_in <= 16'h1234;
        CTRL_ll_gpio_in <= 16'hABCD;

        for(int j = 0 ; j<128; j++) begin
            CTRL_nl_gpio_in[j*8+:8] <= $urandom_range(0, 8'hFF);
        end
        timer_start = 1;
        
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        `FAIL_UNLESS(timer_done =='0);
        timer_start = 0;

        repeat(1500) @(posedge clk_25); 

        foreach (req_addr[i]) begin
            u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
        end

        foreach (req_addr[i]) begin
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
            //$display("TEST %h: resp_addr: %h , req_addr: %h" ,  i, resp_address ,req_addr[i]);
            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)

            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, i)
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
        end

        foreach (req_addr[i]) begin
            u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
        end

        foreach (req_addr[i]) begin
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
        end

        foreach (req_addr[i]) begin
            u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
        end

        foreach (req_addr[i]) begin
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
            `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
            `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
            `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
            `FAIL_UNLESS_EQUAL(resp_status, 0)
            `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
        end
    `SVTEST_END

    `SVTEST(req_crc_error)
        int size;

        bit [31:0] req_addr [];
        bit [31:0] req_data [];
        bit [ 7:0] req_tag  [];

        bit [ 7:0] resp_cmd;
        bit [ 7:0] resp_status;
        bit [ 7:0] resp_tag;
        bit [31:0] resp_address;
        bit [31:0] resp_data;
        bit [ 7:0] resp_ben;

        size = 15;

        //VCS
        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });

        //VCS & Modelsim
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);

        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = i*4;

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);
        
        TRG_ll_gpio_in <= 16'h1234;
        CTRL_ll_gpio_in <= 16'hABCD;

        //CTRL_nl_gpio_in <= 1024'h9876543210;
        for(int j = 0 ; j<128; j++) begin
            CTRL_nl_gpio_in[j*8+:8] <= $urandom_range(0, 8'hFF);
        end
        timer_start = 1;
        
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        `FAIL_UNLESS(timer_done =='0);
        timer_start = 0;

        repeat(1500) @(posedge clk_25); 

        foreach (req_addr[i]) begin
            if (i==3 || i == 10) begin
                fork 
                    begin
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.ltpi_frame_tx.frame_subtype == 1) ;
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        TRG_add_crc_err <= 0;
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        TRG_add_crc_err <= 1;
                    end
                    begin
                        u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
                    end
                join
                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), CRC_ERROR)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_status, 1)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
            else begin
                u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
            
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_data, i)
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
                `FAIL_UNLESS_EQUAL(resp_status, 0)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
        end

        foreach (req_addr[i]) begin
            if (i==3 || i == 10) begin
                fork 
                    begin
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.ltpi_frame_tx.frame_subtype == 1) ;
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        TRG_add_crc_err <= 0;
                        wait(mgmt_ltpi_top_controller.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        TRG_add_crc_err <= 1;
                    end
                    begin
                        u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
                    end
                join

                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), CRC_ERROR)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_status, 1)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
            else begin
                u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
                `FAIL_UNLESS_EQUAL(resp_status, 0)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
        end

    `SVTEST_END

    `SVTEST(resp_crc_error)
        int size;

        bit [31:0] req_addr [];
        bit [31:0] req_data [];
        bit [ 7:0] req_tag  [];

        bit [ 7:0] resp_cmd;
        bit [ 7:0] resp_status;
        bit [ 7:0] resp_tag;
        bit [31:0] resp_address;
        bit [31:0] resp_data;
        bit [ 7:0] resp_ben;

        size = 15;

        //VCS
        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });

        //VCS & Modelsim
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);

        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = i*4;

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);
        
        TRG_ll_gpio_in <= 16'h1234;
        CTRL_ll_gpio_in <= 16'hABCD;

        //CTRL_nl_gpio_in <= 1024'h9876543210;
        for(int j = 0 ; j<128; j++) begin
            CTRL_nl_gpio_in[j*8+:8] <= $urandom_range(0, 8'hFF);
        end
        timer_start = 1;
        
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        `FAIL_UNLESS(timer_done =='0);
        timer_start = 0;

        repeat(1500) @(posedge clk_25); 

        foreach (req_addr[i]) begin
            if (i==3 || i == 10) begin
                u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
                fork 
                    begin
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.ltpi_frame_tx.frame_subtype == 1) ;
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        
                        CTRL_add_crc_err <= 0;
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        CTRL_add_crc_err <= 1;
                    end
                    begin
                        u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
                        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), CRC_ERROR)
                        `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                        `FAIL_UNLESS_EQUAL(resp_status, 1)
                        `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
                    end
                join

            end
            else begin
                u_controller_driver.request_read(req_addr[i], 4'hF, req_tag[i]);
                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
            
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), READ_COMP)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_data, i)
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
                `FAIL_UNLESS_EQUAL(resp_status, 0)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
        end

        foreach (req_addr[i]) begin
            if (i==3 || i == 10) begin
                u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
                fork 
                    begin
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.ltpi_frame_tx.frame_subtype == 1) ;
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == frame_length);
                        CTRL_add_crc_err <= 0;
                        wait(mgmt_ltpi_top_target.mgmt_phy_top_inst.mgmt_ltpi_frm_tx_inst.tx_frm_offset == 0);
                        CTRL_add_crc_err <= 1;
                    end
                    begin
                        u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
                        `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), CRC_ERROR)
                        `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                        `FAIL_UNLESS_EQUAL(resp_status, 1)
                        `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
                    end
                join

            end
            else begin
                u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
                u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_data, req_data[i])
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF)
                `FAIL_UNLESS_EQUAL(resp_status, 0)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
        end

    `SVTEST_END

`SVUNIT_TESTS_END

endmodule