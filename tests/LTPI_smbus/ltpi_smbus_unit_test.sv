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

module ltpi_smbus_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "ltpi_smbus_unit_test";
string test_name;
int test_nb =0;
svunit_testcase svunit_ut;

localparam I2C_TARGET_ADDR = 7'h55;
localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);

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
int temp_cnt =0;

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
logic [1:0] CTRL_uart_rx =0;
logic [1:0] TRG_uart_tx;
logic [1:0] TRG_uart_rx=0;

//I2C
tri1 [ 5:0] CTRL_smb_scl;
tri1 [ 5:0] CTRL_smb_sda;

tri1 [ 5:0] TRG_smb_scl;
tri1 [ 5:0] TRG_smb_sda;

//I2C test CONTROLLER
logic [ 5:0]            i2c_serial_scl_in;
logic [ 5:0]            i2c_serial_sda_in;
logic [ 5:0]            i2c_serial_scl_oe;
logic [ 5:0]            i2c_serial_sda_oe;


//I2C test TARGET
logic [ 5:0][31:0]      i2c_target_address;
logic [ 5:0]            i2c_target_read;
logic [ 5:0][31:0]      i2c_target_readdata;
logic [ 5:0]            i2c_target_readdatavalid;
logic [ 5:0]            i2c_target_waitrequest;
logic [ 5:0]            i2c_target_write;
logic [ 5:0][ 3:0]      i2c_target_byteenable;
logic [ 5:0][31:0]      i2c_target_writedata;
logic [ 5:0]            i2c_target_data_in;
logic [ 5:0]            i2c_target_clk_in;
logic [ 5:0]            i2c_target_data_oe;
logic [ 5:0]            i2c_target_clk_oe;

typedef logic [7:0] i2c_data_t;
i2c_data_t [3:0] i2c_data_write;
logic [31:0] i2c_address_rw = 0;

logic reset_n = 0;
logic [5:0] reset_n_i2C = '0;


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

//AVMM  0 to 5
logic [ 5:0][31:0]  u_avmm_addr;
logic [ 5:0]        u_avmm_read;
logic [ 5:0]        u_avmm_write;
logic [ 5:0][31:0]  u_avmm_wdata;
logic [ 5:0][ 3:0]  u_avmm_byteen;
logic [ 5:0][31:0]  u_avmm_rdata;
logic [ 5:0]        u_avmm_rdvalid;
logic [ 5:0]        u_avmm_waitrq;
logic [ 5:0]        u_avmm_chipselect;
logic [ 5:0]        u_avmm_wrvalid;
logic [ 5:0][ 1:0]  u_avmm_response;

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_0 (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_1 (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);
logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_2 (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);
logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_3 (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);
logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_4 (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);
logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm_5 (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);

`define AVMM_ASSIGN(index) \
assign u_avmm_addr[index]            = u_avmm_``index``.address        ;\
assign u_avmm_read[index]            = u_avmm_``index``.read           ;\
assign u_avmm_write[index]           = u_avmm_``index``.write          ;\
assign u_avmm_wdata[index][ 7: 0]    = u_avmm_``index``.writedata[0]   ;\
assign u_avmm_wdata[index][15: 8]    = u_avmm_``index``.writedata[1]   ;\
assign u_avmm_wdata[index][23:16]    = u_avmm_``index``.writedata[2]   ;\
assign u_avmm_wdata[index][31:24]    = u_avmm_``index``.writedata[3]   ;\
assign u_avmm_byteen[index]          = u_avmm_``index``.byteenable     ;\
assign u_avmm_``index``.readdata[0]       = u_avmm_rdata[index][ 7: 0] ;\
assign u_avmm_``index``.readdata[1]       = u_avmm_rdata[index][15: 8] ;\
assign u_avmm_``index``.readdata[2]       = u_avmm_rdata[index][23:16] ;\
assign u_avmm_``index``.readdata[3]       = u_avmm_rdata[index][31:24] ;\
assign u_avmm_``index``.readdatavalid     = u_avmm_rdvalid[index]      ;\
assign u_avmm_``index``.waitrequest       = u_avmm_waitrq [index]      ;\
assign u_avmm_``index``.response          = u_avmm_response[index]     ;\
assign u_avmm_``index``.writeresponsevalid= u_avmm_wrvalid[index]      ;\
assign u_avmm_chipselect[index]= u_avmm_``index``.chipselect           ;\

`AVMM_ASSIGN(0)
`AVMM_ASSIGN(1)
`AVMM_ASSIGN(2)
`AVMM_ASSIGN(3)
`AVMM_ASSIGN(4)
`AVMM_ASSIGN(5)


genvar i;
generate 

    for(i = 0; i < 6; i = i+1) begin 

        assign i2c_serial_scl_in[i] = CTRL_smb_scl[i];
        assign CTRL_smb_scl[i] = i2c_serial_scl_oe[i] ? 1'b0 : 1'bz;

        assign i2c_serial_sda_in[i] = CTRL_smb_sda[i];
        assign CTRL_smb_sda[i] = i2c_serial_sda_oe[i] ? 1'b0 : 1'bz;

        assign i2c_target_clk_in[i] = TRG_smb_scl[i];
        assign TRG_smb_scl[i] = i2c_target_clk_oe[i] ? 1'b0 : 1'bz;

        assign i2c_target_data_in[i] = TRG_smb_sda[i];
        assign TRG_smb_sda[i] = i2c_target_data_oe[i] ? 1'b0 : 1'bz;

        i2c_controller_avmm_bridge i2c_controller_avmm_bridge_inst (
            .i2c_clock_clk      (clk_25),
            .i2c_csr_address    (u_avmm_addr [i][3:0]),
            .i2c_csr_read       (u_avmm_read [i]     ),
            .i2c_csr_write      (u_avmm_write[i]     ),
            .i2c_csr_writedata  (u_avmm_wdata[i]     ),
            .i2c_csr_readdata   (u_avmm_rdata[i]     ),

            .i2c_irq_irq        (),
            .i2c_reset_reset_n  (reset_n_i2C[i]      ), 
            .i2c_serial_sda_in  (i2c_serial_sda_in[i]), 
            .i2c_serial_scl_in  (i2c_serial_scl_in[i]),
            .i2c_serial_sda_oe  (i2c_serial_sda_oe[i]),
            .i2c_serial_scl_oe  (i2c_serial_scl_oe[i])
        );

        i2c_target_avmm_bridge i2c_target_avmm_bridge_inst (
            .address        (i2c_target_address[i]       ),
            .read           (i2c_target_read[i]          ),
            .readdata       (i2c_target_readdata[i]      ),
            .readdatavalid  (i2c_target_readdatavalid[i] ),
            //.waitrequest    (i2c_target_waitrequest[i]   ),
            .waitrequest    (0                          ),
            .write          (i2c_target_write[i]         ),
            .byteenable     (i2c_target_byteenable[i]    ),
            .writedata      (i2c_target_writedata[i]     ),
            .clk            (ref_clk_target              ),
            .i2c_data_in    (i2c_target_data_in[i]       ),
            .i2c_clk_in     (i2c_target_clk_in[i]        ),
            .i2c_data_oe    (i2c_target_data_oe[i]       ),
            .i2c_clk_oe     (i2c_target_clk_oe[i]        ),
            .rst_n          (reset_n                    )
        );

        avmm_target_model avmm_target_model_inst
        (
            .clk            (ref_clk_target                 ),
            .rst_n          (reset_n                       ),
    //AVMM Intf
            .avmm_addr      (i2c_target_address[i]          ),
            .avmm_read      (i2c_target_read[i]             ),
            .avmm_write     (i2c_target_write[i]            ),
            .avmm_wdata     (i2c_target_writedata[i]        ),
            .avmm_byteen    (i2c_target_byteenable[i]       ),
            .avmm_rdvalid   (i2c_target_readdatavalid[i]    ),
            .avmm_waitrq    (i2c_target_waitrequest[i]      ),
            .avmm_rdata     (i2c_target_readdata[i]         )

);
end
endgenerate


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
    reset_n = 0;
    reset_n_i2C = '0; 

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
    CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h00;
    CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_en       <= 6'h3F;
    CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b1;
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
    CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_channel_cpbl             <= 6'h00;
    CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_channel_en               <= 6'h3F;
    CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_Echo_support             <= 1'b1;
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
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h00;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_en       <= 6'h3F;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b1;
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

    u_avmm_0.address    = 0;
    u_avmm_0.read       = 0;
    u_avmm_0.write      = 0;
    u_avmm_0.writedata  = 0;

    u_avmm_1.address    = 0;
    u_avmm_1.read       = 0;
    u_avmm_1.write      = 0;
    u_avmm_1.writedata  = 0;

    u_avmm_2.address    = 0;
    u_avmm_2.read       = 0;
    u_avmm_2.write      = 0;
    u_avmm_2.writedata  = 0;

    u_avmm_3.address    = 0;
    u_avmm_3.read       = 0;
    u_avmm_3.write      = 0;
    u_avmm_3.writedata  = 0;

    u_avmm_4.address    = 0;
    u_avmm_4.read       = 0;
    u_avmm_4.write      = 0;
    u_avmm_4.writedata  = 0;

    u_avmm_5.address    = 0;
    u_avmm_5.read       = 0;
    u_avmm_5.write      = 0;
    u_avmm_5.writedata  = 0;

    repeat(10) @(posedge clk_25); 
    reset_n = 1;
    reset_controller = 1; 
    reset_target = 1;

endtask

task teardown();
    svunit_ut.teardown();
    reset_controller = 0; 
    reset_target = 0;
    reset_n = 0;
endtask

task automatic avmm_write(input int index, logic [15:0] address, logic [31:0] data);
    case (index)
        0: begin
            @ (u_avmm_0.cb_slave);
            u_avmm_0.burstcount             <= 0;
            u_avmm_0.beginbursttransfer     <= 0;
            u_avmm_0.chipselect             <= 1;
            u_avmm_0.debugaccess            <= 0;
            u_avmm_0.lock                   <= 0;
            u_avmm_0.cb_slave.read          <= 0;
            u_avmm_0.cb_slave.write         <= 1;
            u_avmm_0.cb_slave.address       <= address;
            for (int b = 0; b < 4; b++) begin
                u_avmm_0.cb_slave.writedata[b] <=  data[b*8 +: 8];
            end
            u_avmm_0.cb_slave.byteenable    <= '1;
            @ (u_avmm_0.cb_slave);

            u_avmm_0.burstcount             <= 0;
            u_avmm_0.beginbursttransfer     <= 0;
            u_avmm_0.chipselect             <= 0;
            u_avmm_0.debugaccess            <= 0;
            u_avmm_0.lock                   <= 0;
            u_avmm_0.cb_slave.read          <= 0;
            u_avmm_0.cb_slave.write         <= 0;
            u_avmm_0.cb_slave.address       <= 0;        
            @ (u_avmm_0.cb_slave);
        end
        1: begin
            @ (u_avmm_1.cb_slave);
            u_avmm_1.burstcount             <= 0;
            u_avmm_1.beginbursttransfer     <= 0;
            u_avmm_1.chipselect             <= 1;
            u_avmm_1.debugaccess            <= 0;
            u_avmm_1.lock                   <= 0;
            u_avmm_1.cb_slave.read          <= 0;
            u_avmm_1.cb_slave.write         <= 1;
            u_avmm_1.cb_slave.address       <= address;
            for (int b = 0; b < 4; b++) begin
                u_avmm_1.cb_slave.writedata[b] <=  data[b*8 +: 8];
            end
            u_avmm_1.cb_slave.byteenable    <= '1;
            @ (u_avmm_1.cb_slave);

            u_avmm_1.burstcount             <= 0;
            u_avmm_1.beginbursttransfer     <= 0;
            u_avmm_1.chipselect             <= 0;
            u_avmm_1.debugaccess            <= 0;
            u_avmm_1.lock                   <= 0;
            u_avmm_1.cb_slave.read          <= 0;
            u_avmm_1.cb_slave.write         <= 0;
            u_avmm_1.cb_slave.address       <= 0;        
            @ (u_avmm_1.cb_slave);
        end
        2: begin
            @ (u_avmm_2.cb_slave);
            u_avmm_2.burstcount             <= 0;
            u_avmm_2.beginbursttransfer     <= 0;
            u_avmm_2.chipselect             <= 1;
            u_avmm_2.debugaccess            <= 0;
            u_avmm_2.lock                   <= 0;
            u_avmm_2.cb_slave.read          <= 0;
            u_avmm_2.cb_slave.write         <= 1;
            u_avmm_2.cb_slave.address       <= address;
            for (int b = 0; b < 4; b++) begin
                u_avmm_2.cb_slave.writedata[b] <=  data[b*8 +: 8];
            end
            u_avmm_2.cb_slave.byteenable    <= '1;
            @ (u_avmm_2.cb_slave);

            u_avmm_2.burstcount             <= 0;
            u_avmm_2.beginbursttransfer     <= 0;
            u_avmm_2.chipselect             <= 0;
            u_avmm_2.debugaccess            <= 0;
            u_avmm_2.lock                   <= 0;
            u_avmm_2.cb_slave.read          <= 0;
            u_avmm_2.cb_slave.write         <= 0;
            u_avmm_2.cb_slave.address       <= 0;        
            @ (u_avmm_2.cb_slave);
        end
        3: begin
            @ (u_avmm_3.cb_slave);
            u_avmm_3.burstcount             <= 0;
            u_avmm_3.beginbursttransfer     <= 0;
            u_avmm_3.chipselect             <= 1;
            u_avmm_3.debugaccess            <= 0;
            u_avmm_3.lock                   <= 0;
            u_avmm_3.cb_slave.read          <= 0;
            u_avmm_3.cb_slave.write         <= 1;
            u_avmm_3.cb_slave.address       <= address;
            for (int b = 0; b < 4; b++) begin
                u_avmm_3.cb_slave.writedata[b] <=  data[b*8 +: 8];
            end
            u_avmm_3.cb_slave.byteenable    <= '1;
            @ (u_avmm_3.cb_slave);

            u_avmm_3.burstcount             <= 0;
            u_avmm_3.beginbursttransfer     <= 0;
            u_avmm_3.chipselect             <= 0;
            u_avmm_3.debugaccess            <= 0;
            u_avmm_3.lock                   <= 0;
            u_avmm_3.cb_slave.read          <= 0;
            u_avmm_3.cb_slave.write         <= 0;
            u_avmm_3.cb_slave.address       <= 0;        
            @ (u_avmm_3.cb_slave);
        end
        4: begin
            @ (u_avmm_4.cb_slave);
            u_avmm_4.burstcount             <= 0;
            u_avmm_4.beginbursttransfer     <= 0;
            u_avmm_4.chipselect             <= 1;
            u_avmm_4.debugaccess            <= 0;
            u_avmm_4.lock                   <= 0;
            u_avmm_4.cb_slave.read          <= 0;
            u_avmm_4.cb_slave.write         <= 1;
            u_avmm_4.cb_slave.address       <= address;
            for (int b = 0; b < 4; b++) begin
                u_avmm_4.cb_slave.writedata[b] <=  data[b*8 +: 8];
            end
            u_avmm_4.cb_slave.byteenable    <= '1;
            @ (u_avmm_4.cb_slave);

            u_avmm_4.burstcount             <= 0;
            u_avmm_4.beginbursttransfer     <= 0;
            u_avmm_4.chipselect             <= 0;
            u_avmm_4.debugaccess            <= 0;
            u_avmm_4.lock                   <= 0;
            u_avmm_4.cb_slave.read          <= 0;
            u_avmm_4.cb_slave.write         <= 0;
            u_avmm_4.cb_slave.address       <= 0;        
            @ (u_avmm_4.cb_slave);
        end
        5: begin
            @ (u_avmm_5.cb_slave);
            u_avmm_5.burstcount             <= 0;
            u_avmm_5.beginbursttransfer     <= 0;
            u_avmm_5.chipselect             <= 1;
            u_avmm_5.debugaccess            <= 0;
            u_avmm_5.lock                   <= 0;
            u_avmm_5.cb_slave.read          <= 0;
            u_avmm_5.cb_slave.write         <= 1;
            u_avmm_5.cb_slave.address       <= address;
            for (int b = 0; b < 4; b++) begin
                u_avmm_5.cb_slave.writedata[b] <=  data[b*8 +: 8];
            end
            u_avmm_5.cb_slave.byteenable    <= '1;
            @ (u_avmm_5.cb_slave);

            u_avmm_5.burstcount             <= 0;
            u_avmm_5.beginbursttransfer     <= 0;
            u_avmm_5.chipselect             <= 0;
            u_avmm_5.debugaccess            <= 0;
            u_avmm_5.lock                   <= 0;
            u_avmm_5.cb_slave.read          <= 0;
            u_avmm_5.cb_slave.write         <= 0;
            u_avmm_5.cb_slave.address       <= 0;        
            @ (u_avmm_5.cb_slave);
        end
    endcase 
endtask

task automatic avmm_read(input int index,logic [15:0] address, ref logic [31:0] data);
    case(index)
        0: begin
            @ (u_avmm_0.cb_slave);
            u_avmm_0.burstcount             <= 0;
            u_avmm_0.beginbursttransfer     <= 0;
            u_avmm_0.chipselect             <= 1;
            u_avmm_0.debugaccess            <= 0;
            u_avmm_0.lock                   <= 0;
            u_avmm_0.cb_slave.read          <= 1;
            u_avmm_0.cb_slave.write         <= 0;
            u_avmm_0.cb_slave.address       <= address;
            u_avmm_0.cb_slave.byteenable    <= '1;
            @ (u_avmm_0.cb_slave);

            u_avmm_0.burstcount             <= 0;
            u_avmm_0.beginbursttransfer     <= 0;
            u_avmm_0.chipselect             <= 0;
            u_avmm_0.debugaccess            <= 0;
            u_avmm_0.lock                   <= 0;
            u_avmm_0.cb_slave.read          <= 0;
            u_avmm_0.cb_slave.write         <= 0;
            u_avmm_0.cb_slave.address       <= 0;    

            @ (u_avmm_0.cb_slave);
            @ (u_avmm_0.cb_slave);
            for (int b = 0; b < 4; b++) begin
                data[b*8 +: 8] =  u_avmm_0.cb_slave.readdata[b];
            end
            @ (u_avmm_0.cb_slave);
        end
        1: begin
            @ (u_avmm_1.cb_slave);
            u_avmm_1.burstcount             <= 0;
            u_avmm_1.beginbursttransfer     <= 0;
            u_avmm_1.chipselect             <= 1;
            u_avmm_1.debugaccess            <= 0;
            u_avmm_1.lock                   <= 0;
            u_avmm_1.cb_slave.read          <= 1;
            u_avmm_1.cb_slave.write         <= 0;
            u_avmm_1.cb_slave.address       <= address;
            u_avmm_1.cb_slave.byteenable    <= '1;
            @ (u_avmm_1.cb_slave);

            u_avmm_1.burstcount             <= 0;
            u_avmm_1.beginbursttransfer     <= 0;
            u_avmm_1.chipselect             <= 0;
            u_avmm_1.debugaccess            <= 0;
            u_avmm_1.lock                   <= 0;
            u_avmm_1.cb_slave.read          <= 0;
            u_avmm_1.cb_slave.write         <= 0;
            u_avmm_1.cb_slave.address       <= 0;    

            @ (u_avmm_1.cb_slave);
            @ (u_avmm_1.cb_slave);
            for (int b = 0; b < 4; b++) begin
                data[b*8 +: 8] =  u_avmm_1.cb_slave.readdata[b];
            end
            @ (u_avmm_1.cb_slave);
        end
        2: begin
            @ (u_avmm_2.cb_slave);
            u_avmm_2.burstcount             <= 0;
            u_avmm_2.beginbursttransfer     <= 0;
            u_avmm_2.chipselect             <= 1;
            u_avmm_2.debugaccess            <= 0;
            u_avmm_2.lock                   <= 0;
            u_avmm_2.cb_slave.read          <= 1;
            u_avmm_2.cb_slave.write         <= 0;
            u_avmm_2.cb_slave.address       <= address;
            u_avmm_2.cb_slave.byteenable    <= '1;
            @ (u_avmm_2.cb_slave);

            u_avmm_2.burstcount             <= 0;
            u_avmm_2.beginbursttransfer     <= 0;
            u_avmm_2.chipselect             <= 0;
            u_avmm_2.debugaccess            <= 0;
            u_avmm_2.lock                   <= 0;
            u_avmm_2.cb_slave.read          <= 0;
            u_avmm_2.cb_slave.write         <= 0;
            u_avmm_2.cb_slave.address       <= 0;    

            @ (u_avmm_2.cb_slave);
            @ (u_avmm_2.cb_slave);
            for (int b = 0; b < 4; b++) begin
                data[b*8 +: 8] =  u_avmm_2.cb_slave.readdata[b];
            end
            @ (u_avmm_2.cb_slave);
        end
        3: begin
            @ (u_avmm_3.cb_slave);
            u_avmm_3.burstcount             <= 0;
            u_avmm_3.beginbursttransfer     <= 0;
            u_avmm_3.chipselect             <= 1;
            u_avmm_3.debugaccess            <= 0;
            u_avmm_3.lock                   <= 0;
            u_avmm_3.cb_slave.read          <= 1;
            u_avmm_3.cb_slave.write         <= 0;
            u_avmm_3.cb_slave.address       <= address;
            u_avmm_3.cb_slave.byteenable    <= '1;
            @ (u_avmm_3.cb_slave);

            u_avmm_3.burstcount             <= 0;
            u_avmm_3.beginbursttransfer     <= 0;
            u_avmm_3.chipselect             <= 0;
            u_avmm_3.debugaccess            <= 0;
            u_avmm_3.lock                   <= 0;
            u_avmm_3.cb_slave.read          <= 0;
            u_avmm_3.cb_slave.write         <= 0;
            u_avmm_3.cb_slave.address       <= 0;    

            @ (u_avmm_3.cb_slave);
            @ (u_avmm_3.cb_slave);
            for (int b = 0; b < 4; b++) begin
                data[b*8 +: 8] =  u_avmm_3.cb_slave.readdata[b];
            end
            @ (u_avmm_3.cb_slave);
        end
       4: begin
            @ (u_avmm_4.cb_slave);
            u_avmm_4.burstcount             <= 0;
            u_avmm_4.beginbursttransfer     <= 0;
            u_avmm_4.chipselect             <= 1;
            u_avmm_4.debugaccess            <= 0;
            u_avmm_4.lock                   <= 0;
            u_avmm_4.cb_slave.read          <= 1;
            u_avmm_4.cb_slave.write         <= 0;
            u_avmm_4.cb_slave.address       <= address;
            u_avmm_4.cb_slave.byteenable    <= '1;
            @ (u_avmm_4.cb_slave);

            u_avmm_4.burstcount             <= 0;
            u_avmm_4.beginbursttransfer     <= 0;
            u_avmm_4.chipselect             <= 0;
            u_avmm_4.debugaccess            <= 0;
            u_avmm_4.lock                   <= 0;
            u_avmm_4.cb_slave.read          <= 0;
            u_avmm_4.cb_slave.write         <= 0;
            u_avmm_4.cb_slave.address       <= 0;    

            @ (u_avmm_4.cb_slave);
            @ (u_avmm_4.cb_slave);
            for (int b = 0; b < 4; b++) begin
                data[b*8 +: 8] =  u_avmm_4.cb_slave.readdata[b];
            end
            @ (u_avmm_4.cb_slave);
        end
        5: begin
            @ (u_avmm_5.cb_slave);
            u_avmm_5.burstcount             <= 0;
            u_avmm_5.beginbursttransfer     <= 0;
            u_avmm_5.chipselect             <= 1;
            u_avmm_5.debugaccess            <= 0;
            u_avmm_5.lock                   <= 0;
            u_avmm_5.cb_slave.read          <= 1;
            u_avmm_5.cb_slave.write         <= 0;
            u_avmm_5.cb_slave.address       <= address;
            u_avmm_5.cb_slave.byteenable    <= '1;
            @ (u_avmm_5.cb_slave);

            u_avmm_5.burstcount             <= 0;
            u_avmm_5.beginbursttransfer     <= 0;
            u_avmm_5.chipselect             <= 0;
            u_avmm_5.debugaccess            <= 0;
            u_avmm_5.lock                   <= 0;
            u_avmm_5.cb_slave.read          <= 0;
            u_avmm_5.cb_slave.write         <= 0;
            u_avmm_5.cb_slave.address       <= 0;    

            @ (u_avmm_5.cb_slave);
            @ (u_avmm_5.cb_slave);
            for (int b = 0; b < 4; b++) begin
                data[b*8 +: 8] =  u_avmm_5.cb_slave.readdata[b];
            end
            @ (u_avmm_5.cb_slave);
        end
    endcase
endtask

task i2c_controller_avmm_bridge_setup(input int index);

    logic[31:0] data_rd;
    repeat(10) @(posedge clk_25); 
    reset_n_i2C[index] = 1; 
    repeat(1000) @(posedge clk_25); 

    avmm_write(index, 4'h2,0); //Diseble Avalone i2C 
    avmm_write(index, 4'h3,32'h0000_0003);//Configure ISER
    avmm_write(index, 4'h8,32'h0000_007D);//Configure SCL_LOW 0x08 -100k
    avmm_write(index, 4'h9,32'h0000_007D);//Configure SCL_HIGH 0x09 - 100k
    avmm_write(index, 4'hA,32'h0000_000F);//Configure SDA_HOLD 0x0A
    avmm_write(index, 4'h2,32'h0000_000F);//Enable Avalone i2C 

    for (int i = 0 ; i<11 ;i++) begin
        avmm_read(index, i,data_rd);
        $display("REGISTER adr: %h data %h", i,data_rd);
    end

    data_rd = 0; 
    while(!(data_rd & 32'h0000_0001)) begin
        avmm_read(index, 4'h4, data_rd);
    end
endtask

task automatic csr_write(input int index, logic [15:0] address, logic[31:0] data);
    logic[31:0] data_rd = 0;

    avmm_write(index, 4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b0}); //TRANSMIT TARGET ADR BYTE
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(index, 4'h4, data_rd);
        //$display("data_rd: %h", data_rd);
    end
    
    avmm_write(index, 4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone write adres byte 0
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(index, 4'h4, data_rd);
    end

    avmm_write(index, 4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone write adres byte 1
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(index, 4'h4, data_rd);
    end
    for(int b = 0 ; b < 4 ; b++) begin
        if( b == 3 ) begin
            avmm_write(index, 4'h0, {24'h0000_01,data[b*8 +: 8]});
        end
        else begin
            avmm_write(index,4'h0,{4'h0,24'h0000_00,data[b*8 +: 8]});
        end
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(index, 4'h4, data_rd);
        end
    end
    $display("WRITE ADR: %h | DATA : %h", address, data); 
endtask

task automatic csr_read (input int index,logic [15:0] address, ref logic[31:0] data);
    logic[31:0] data_rd = 0;
    avmm_write(index, 4'h0,{24'h0000_02, I2C_TARGET_ADDR , 1'b0}); //TRANSMIT TARGET ADR BYTE
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(index, 4'h4, data_rd);
        //$display("data_rd: %h", data_rd);
    end
    
    avmm_write(index, 4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone read adres byte 0
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(index, 4'h4, data_rd);
    end

    avmm_write(index, 4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone read adres byte 1
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(index, 4'h4, data_rd);
    end

    avmm_write(index, 4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b1});//TRANSMIT TARGET ADR COMMAND RD
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(index,4'h4, data_rd);
    end

    repeat(10000) @(posedge clk_25); 

    for(int b = 0; b < 4; b++) begin
        if(b < 3) begin
            avmm_write(index, 4'h0, 0); //Read 1/2/3 B
        end
        else begin
            avmm_write(index, 4'h0, 32'h0000_0100); //Read 4 B then stop
        end

        data_rd = 0;
        while((data_rd & 32'h0000_0002) != 32'h0000_0002) begin //wait for RX_READY ==1
            avmm_read(index, 4'h4, data_rd);
        end

        avmm_read(index, 4'h1, data_rd);
        data [b*8 +: 8] = data_rd[7:0]; 
    end
    $display("READ ADR: %h | DATA : %h", address , data); 
endtask


`SVUNIT_TESTS_BEGIN
    `SVTEST(i2c_test_echo_on_25MHZ_SDR)
        logic [31: 0] data_read;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b1;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_Echo_support              <= 1'b1;
        TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h00,8'h01};
        
        timer_start = 1;
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
       `FAIL_UNLESS(timer_done =='0);
       
        $display("CTRL & TRG in opertional mode");
        repeat(5000) @(posedge clk_25); 

        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_avmm_bridge_setup(i2c_dev_nb);
        end

        for(int j = 0 ; j < 1 ; j++) begin
            $display("Test nb: %0d" , j);
            for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin //6 dev
                //for( int k = 0 ; k<(4*16) ; k=k+4) begin
                for( int k = 0 ; k<(4*2) ; k=k+4) begin
                    i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                    i2c_address_rw = k;

                    csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                    wait(i2c_target_write);
                    repeat(5000) @(posedge clk_25); 

                    csr_read(i2c_dev_nb, i2c_address_rw, data_read);
                    `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                    repeat(5000) @(posedge clk_25); 
                end
            end
        end

    `SVTEST_END

    `SVTEST(i2c_test_echo_off_25MHZ_SDR)
        logic [31: 0] data_read;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b0;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_Echo_support              <= 1'b0;

        TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h00,8'h01};

        timer_start = 1;
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
       `FAIL_UNLESS(timer_done =='0);
        timer_start = 0;
        $display("CTRL & TRG in opertional mode");
        repeat(5000) @(posedge clk_25); 

        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_avmm_bridge_setup(i2c_dev_nb);
        end

        for(int j = 0 ; j < 1 ; j++) begin
            $display("Test nb: %0d" , j);
            for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin //6 dev
                //for( int k = 0 ; k<(4*16) ; k=k+4) begin
                for( int k = 0 ; k<(4*2) ; k=k+4) begin
                    i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                    i2c_address_rw = k;

                    timer_start = 1;
                    csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                    wait(timer_done == 1 || i2c_target_write);
                    `FAIL_UNLESS(timer_done =='0);
                    timer_start = 0;
                    repeat(5000) @(posedge clk_25); 

                    csr_read(i2c_dev_nb, i2c_address_rw,data_read);
                    `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                    repeat(5000) @(posedge clk_25); 
                end
            end
        end

    `SVTEST_END

    `SVTEST(i2c_test_echo_on_100MHZ_DDR)
        logic [31: 0] data_read;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b1;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_Echo_support              <= 1'b1;

        CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_channel_cpbl              <= 6'h3F;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h3F;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h3F;

        timer_start = 1;
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
       `FAIL_UNLESS(timer_done =='0);
        timer_start = 0;

        $display("CTRL & TRG in opertional mode");
        repeat(5000) @(posedge clk_25); 

        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_avmm_bridge_setup(i2c_dev_nb);
        end

        for(int j = 0 ; j < 1 ; j++) begin
            $display("Test nb: %0d" , j);
            for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin //6 dev
                //for( int k = 0 ; k<(4*16) ; k=k+4) begin
                for( int k = 0 ; k<(4*2) ; k=k+4) begin
                    i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                    i2c_address_rw = k;

                    timer_start = 1;
                    csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                    wait(timer_done == 1 || i2c_target_write);
                    `FAIL_UNLESS(timer_done =='0);
                    timer_start = 0;
                    repeat(5000) @(posedge clk_25); 

                    csr_read(i2c_dev_nb, i2c_address_rw,data_read);
                    `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                    repeat(5000) @(posedge clk_25); 
                end
            end
        end

    `SVTEST_END

    `SVTEST(i2c_test_echo_off_100MHZ_DDR)
        logic [31: 0] data_read;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_channel_cpbl              <= 6'h3F;
        CTRL_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h3F;
        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h3F;

        TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1'b0;
        CTRL_LTPI_CSR_In.LTPI_Config_Capab.I2C_Echo_support              <= 1'b0;

        timer_start = 1;
        wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
       `FAIL_UNLESS(timer_done =='0);
        timer_start = 0;
        $display("CTRL & TRG in opertional mode");
        repeat(5000) @(posedge clk_25); 

        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_avmm_bridge_setup(i2c_dev_nb);
        end

        for(int j = 0 ; j < 1 ; j++) begin
            $display("Test nb: %0d" , j);
            for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin //6 dev
                //for( int k = 0 ; k<(4*16) ; k=k+4) begin
                for( int k = 0 ; k<(4*2) ; k=k+4) begin
                    i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                    i2c_address_rw = k;

                    timer_start = 1;
                    csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                    wait(timer_done == 1 || i2c_target_write);
                    `FAIL_UNLESS(timer_done =='0);
                    timer_start = 0;

                    repeat(5000) @(posedge clk_25); 

                    csr_read(i2c_dev_nb, i2c_address_rw,data_read);
                    `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                    repeat(5000) @(posedge clk_25); 
                end
            end
        end

    `SVTEST_END

`SVUNIT_TESTS_END

endmodule