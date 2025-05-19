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

module LTPI_top_gpio_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "LTPI_top_gpio_unit_test";
string test_name;
int test_nb =0;
svunit_testcase svunit_ut;

localparam I2C_TARGET_ADDR = 7'h55;
localparam BASE_ADDR = 16'h200;
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

LTPI_CSR_In_t TRG_LTPI_CSR_In='0;
LTPI_CSR_Out_t TRG_LTPI_CSR_Out;

assign clk_25 = clk_25_controller;

initial begin
    clk_25_controller = 0;
    #5
    forever begin
        #(19) clk_25_controller = ~clk_25_controller;
    end
end
logic ref_clk_target;
initial begin
    //clk_25_target = 0;
    ref_clk_target =0 ;
    #15
    forever begin
        //#(21) clk_25_target = ~clk_25_target;
        #(21) ref_clk_target = ~ref_clk_target;
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
logic [ 3:0]      i2c_csr_address   ='0;
logic             i2c_csr_read      ='0;
logic             i2c_csr_write     ='0;
logic [31:0]      i2c_csr_writedata = '0;
logic [31:0]      i2c_csr_readdata;

assign i2c_serial_scl_in = BMC_smb_scl;
assign BMC_smb_scl = i2c_serial_scl_oe ? 1'b0 : 1'bz;

assign i2c_serial_sda_in = BMC_smb_sda;
assign BMC_smb_sda = i2c_serial_sda_oe ? 1'b0 : 1'bz;
logic clk_60_target;

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

ltpi_top_controller ltpi_top_controller(
    .CLK_25M_OSC_CPU_FPGA        ( clk_25_controller             ),
    .reset_in          ( ~reset_controller             ),

    //LVDS output pins
    .lvds_tx_data   ( lvds_tx_data_ctrl          ),
    .lvds_tx_clk    ( lvds_tx_clk_ctrl           ),

    // //LVDS input pins
    .lvds_rx_data   (lvds_rx_data_ctrl           ),
    .lvds_rx_clk    (lvds_rx_clk_ctrl            ),

    .BMC_smb_scl    (BMC_smb_scl                ),//I2C interfaces to BMC
    .BMC_smb_sda    (BMC_smb_sda                ),
    .aligned        (aligned_ctrl                ),

    .smb_scl        (CTRL_smb_scl                ),//I2C interfaces tunneling through LVDS 
    .smb_sda        (CTRL_smb_sda                ),

    .ll_gpio_in     (CTRL_ll_gpio_in             ),//GPIO input tunneling through LVDS
    .ll_gpio_out    (CTRL_ll_gpio_out            ),//GPIO output tunneling through LVDS
    
    .nl_gpio_in     (CTRL_nl_gpio_in             ),//GPIO input tunneling through LVDS
    .nl_gpio_out    (CTRL_nl_gpio_out            ),//GPIO output tunneling through LVDS

    .uart_rxd       (CTRL_uart_rx                ),//UART interfaces tunneling through LVDS
    .uart_cts       ('0                         ),//Clear To Send
    .uart_txd       (CTRL_uart_tx                ),
    .uart_rts       ()       //Request To Send

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
    .lvds_rx_data   ( lvds_tx_data_ctrl  ),
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
    .uart_rts       (                           ), //Request To Send
    .avalon_mm_m    (TRG_u_avmm_m               ),
    .avalon_mm_s    (TRG_u_avmm_s               )

);

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm (
    .aclk           (clk_25_controller),
    .areset_n       (!reset_controller)
);

i2c_controller_avmm_bridge i2c_controller_avmm_bridge_BMC (
    .i2c_clock_clk      (clk_25_controller          ), 
    .i2c_csr_address    (u_avmm.address        ),
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
    //detect frm
    //speed capabiliestes agent
    TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab       <={8'h80,8'h08};
    TRG_LTPI_CSR_In.LTPI_Detect_Capab_local.LTPI_Version           <= LTPI_Version;
    //advertise frm agent
    //TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h251;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.NL_GPIO_nb           <= 10'h3FF;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.supported_channel    <= 5'd7;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_Echo_support     <= 1;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_en       <= 6'h3F;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.I2C_channel_cpbl     <= 6'h3F;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_en      <=0;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_Flow_ctrl       <= '0;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.UART_channel_cpbl    <= 5'd8;
    TRG_LTPI_CSR_In.LTPI_Advertise_Capab_local.OEM_cpbl             <= '0;

    TRG_LTPI_CSR_In.LTPI_platform_ID_local                         <={8'h12,8'h34};

    TRG_LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config                <='0; 
    TRG_LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st               <='1;
    TRG_LTPI_CSR_In.LTPI_Link_Ctrl.software_reset                  <='0;


    TRG_LTPI_CSR_In.CRC_error_test.CRC_error_test_ON <= 1'b0;
    TRG_LTPI_CSR_In.CRC_error_test.CRC_error_link_state <= link_detect_st;


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

task automatic avmm_write(logic [15:0] address, logic [31:0] data);
    @ (u_avmm.cb_slave);
    u_avmm.burstcount             <= 0;
    u_avmm.beginbursttransfer     <= 0;
    u_avmm.chipselect             <= 1;
    u_avmm.debugaccess            <= 0;
    u_avmm.lock                   <= 0;
    u_avmm.cb_slave.read          <= 0;
    u_avmm.cb_slave.write         <= 1;
    u_avmm.cb_slave.address       <= address;
    for (int b = 0; b < 4; b++) begin
        u_avmm.cb_slave.writedata[b] <=  data[b*8 +: 8];
    end
    u_avmm.cb_slave.byteenable    <= '1;
    @ (u_avmm.cb_slave);

    u_avmm.burstcount             <= 0;
    u_avmm.beginbursttransfer     <= 0;
    u_avmm.chipselect             <= 0;
    u_avmm.debugaccess            <= 0;
    u_avmm.lock                   <= 0;
    u_avmm.cb_slave.read          <= 0;
    u_avmm.cb_slave.write         <= 0;
    u_avmm.cb_slave.address       <= 0;        
    @ (u_avmm.cb_slave);
endtask

task automatic avmm_read(logic [15:0] address, ref logic [31:0] data);
    @ (u_avmm.cb_slave);
    u_avmm.burstcount             <= 0;
    u_avmm.beginbursttransfer     <= 0;
    u_avmm.chipselect             <= 1;
    u_avmm.debugaccess            <= 0;
    u_avmm.lock                   <= 0;
    u_avmm.cb_slave.read          <= 1;
    u_avmm.cb_slave.write         <= 0;
    u_avmm.cb_slave.address       <= address;
    u_avmm.cb_slave.byteenable    <= '1;
    @ (u_avmm.cb_slave);

    u_avmm.burstcount             <= 0;
    u_avmm.beginbursttransfer     <= 0;
    u_avmm.chipselect             <= 0;
    u_avmm.debugaccess            <= 0;
    u_avmm.lock                   <= 0;
    u_avmm.cb_slave.read          <= 0;
    u_avmm.cb_slave.write         <= 0;
    u_avmm.cb_slave.address       <= 0;    

    @ (u_avmm.cb_slave);
    @ (u_avmm.cb_slave);
    for (int b = 0; b < 4; b++) begin
        data[b*8 +: 8] =  u_avmm.cb_slave.readdata[b];
    end
    @ (u_avmm.cb_slave);
endtask

task i2c_controller_setup();
    logic[31:0] data_rd;
    
    avmm_write(4'h2,0); //Diseble Avalone i2C 
    avmm_write(4'h3,32'h0000_0003);//Configure ISER
    avmm_write(4'h8,32'h0000_007D);//Configure SCL_LOW 0x08 -100k
    avmm_write(4'h9,32'h0000_007D);//Configure SCL_HIGH 0x09 - 100k
    avmm_write(4'hA,32'h0000_000F);//Configure SDA_HOLD 0x0A
    avmm_write(4'h2,32'h0000_000F);//Enable Avalone i2C 

    for (int i = 0 ; i<11 ;i++) begin
        avmm_read(i,data_rd);
        $display("REGISTER adr: %h data %h", i,data_rd);
    end

    data_rd = 0; 
    while(!(data_rd & 32'h0000_0001)) begin
        avmm_read(4'h4, data_rd);
    end
endtask
    
task automatic csr_write(logic [15:0] address, logic[31:0] data);
    logic[31:0] data_rd = 0;

    avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b0}); //TRANSMIT TARGET ADR BYTE
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(4'h4, data_rd);
        //$display("data_rd: %h", data_rd);
    end
    
    avmm_write(4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone write adres byte 0
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(4'h4, data_rd);
    end

    avmm_write(4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone write adres byte 1
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(4'h4, data_rd);
    end
    for(int b = 0 ; b < 4 ; b++) begin
        if( b == 3 ) begin
            avmm_write(4'h0, {24'h0000_01,data[b*8 +: 8]});
        end
        else begin
            avmm_write(4'h0,{4'h0,24'h0000_00,data[b*8 +: 8]});
        end
        data_rd = 0;
        while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
            avmm_read(4'h4, data_rd);
        end
    end
    $display("WRITE ADR: %h | DATA : %h", address, data); 
endtask

task automatic csr_read (logic [15:0] address, ref logic[31:0] data);
    logic[31:0] data_rd = 0;
    avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR , 1'b0}); //TRANSMIT TARGET ADR BYTE
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(4'h4, data_rd);
        //$display("data_rd: %h", data_rd);
    end
    
    avmm_write(4'h0,{24'h0000_00,address[15:8]});//TRANSMIT avalone read adres byte 0
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(4'h4, data_rd);
    end

    avmm_write(4'h0,{24'h0000_00,address[7:0]});//TRANSMIT avalone read adres byte 1
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(4'h4, data_rd);
    end

    avmm_write(4'h0,{24'h0000_02, I2C_TARGET_ADDR ,1'b1});//TRANSMIT TARGET ADR COMMAND RD
    data_rd = 0;
    while(!(data_rd & 32'h0000_0001)) begin //wait for TX_READY ==1
        avmm_read(4'h4, data_rd);
    end

    repeat(10000) @(posedge clk_25); 

    for(int b = 0; b < 4; b++) begin
        if(b < 3) begin
            avmm_write(4'h0, 0); //Read 1/2/3 B
        end
        else begin
            avmm_write(4'h0, 32'h0000_0100); //Read 4 B then stop
        end

        data_rd = 0;
        while((data_rd & 32'h0000_0002) != 32'h0000_0002) begin //wait for RX_READY ==1
            avmm_read(4'h4, data_rd);
        end

        avmm_read(4'h1, data_rd);
        data [b*8 +: 8] = data_rd[7:0]; 
    end
    $display("READ ADR: %h | DATA : %h", address , data); 
endtask

`SVUNIT_TESTS_BEGIN

    `SVTEST(gpio)
        TRG_ll_gpio_in <= 16'h1234;
        CTRL_ll_gpio_in <= 16'hABCD;


        wait(ltpi_top_controller.ltpi_csr_avmm_inst.CSR_hw_out.LTPI_Link_Status.local_link_state == operational_st)
        wait(TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st)
        //wait(timer_done == 1 || CTRL_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
        //wait(timer_done == 1 || TRG_LTPI_CSR_Out.LTPI_Link_Status.local_link_state == operational_st);
       //`FAIL_UNLESS(timer_done =='0);
       //timer_start = 0;
        repeat(2000) @(posedge clk_25); 
        `FAIL_UNLESS_EQUAL(CTRL_ll_gpio_in, TRG_ll_gpio_out)
        `FAIL_UNLESS_EQUAL(TRG_ll_gpio_in, CTRL_ll_gpio_out)

        repeat(5000) @(posedge clk_25);
        TRG_ll_gpio_in <= '0;
        CTRL_ll_gpio_in <= '1;
        repeat(5000) @(posedge clk_25);
    `SVTEST_END
    
`SVUNIT_TESTS_END

endmodule