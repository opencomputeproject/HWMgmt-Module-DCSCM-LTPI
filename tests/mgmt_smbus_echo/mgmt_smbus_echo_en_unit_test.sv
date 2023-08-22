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

module mgmt_smbus_echo_en_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "mgmt_smbus_echo_en_unit_test";
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

int temp_cnt =0;
link_speed_t link_speed;
logic DDR_MODE;
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
LTPI_Capabilites_t config_capabilites;
logic ref_clk_controller;
logic ref_clk_target;
logic clk_25_controller;
logic clk_60_controller;
logic clk_25_target;
logic clk_60_target;

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

//logic [ 7:0] i2c_data_read [3:0]; 
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
            .waitrequest    (0                          ),
            .write          (i2c_target_write[i]         ),
            .byteenable     (i2c_target_byteenable[i]    ),
            .writedata      (i2c_target_writedata[i]     ),
            .clk            (ref_clk_target             ),
            .i2c_data_in    (i2c_target_data_in[i]       ),
            .i2c_clk_in     (i2c_target_clk_in[i]        ),
            .i2c_data_oe    (i2c_target_data_oe[i]       ),
            .i2c_clk_oe     (i2c_target_clk_oe[i]        ),
            .rst_n          (reset_n                    )
        );

        avmm_target_model avmm_target_model_inst
        (
            .clk            (ref_clk_target                ),
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

logic [ 5:0][3:0] CTRL_i2c_event_i;
logic [ 5:0][3:0] CTRL_i2c_event_o;
logic [ 3:0]      CTRL_tx_frm_offset;
logic [ 3:0]      TRG_tx_frm_offset;
logic [ 1:0]      CTRL_cnt;
logic [ 1:0]      TRG_cnt;

always @(posedge clk_60_controller  or negedge reset_controller) begin
    if(!reset_controller) begin
        CTRL_tx_frm_offset <= '0;
        CTRL_cnt <= '0;
    end
    else begin
        if(CTRL_cnt < 1) begin
            CTRL_cnt <= CTRL_cnt + 1;
        end
        else begin
            CTRL_tx_frm_offset <= CTRL_tx_frm_offset + 1;
            CTRL_cnt <= '0;
        end
    end
end

always @(posedge clk_60_target  or negedge reset_target) begin
    if(!reset_target) begin
        TRG_tx_frm_offset <= '0;
        TRG_cnt <= '0;
    end
    else begin
        if(TRG_cnt < 1) begin
            TRG_cnt <= TRG_cnt + 1;
        end
        else begin
            TRG_tx_frm_offset <= TRG_tx_frm_offset + 1;
            TRG_cnt <= '0;
        end
    end
end

mgmt_smbus #(
    .CONTROLLER (1)
)mgmt_smbus_controller(
    .clk                    (clk_60_controller          ),
    .reset                  (~reset_controller          ),
    //signals from/to pins
    .smb_scl                (CTRL_smb_scl            ),        //I2C interfaces tunneling through LVDS 
    .smb_sda                (CTRL_smb_sda            ),
    //signal from/to opertional frame managment
    .i2c_event_i            (CTRL_i2c_event_i        ),
    .i2c_event_o            (CTRL_i2c_event_o        ),
    .soft_i2c_channel_rst   (1'b0                   ),
    .DDR_MODE               (DDR_MODE               ),
    .link_speed             (link_speed             ),

    .tx_frm_offset          (CTRL_tx_frm_offset      ),
    .config_capabilites     (config_capabilites     ),
    .local_link_state       (operational_st         ),
    .remote_link_state      (operational_st         )
);

mgmt_smbus #(
    .CONTROLLER (0)
)mgmt_smbus_target(
    .clk                    (clk_60_target           ),
    .reset                  (~reset_target           ),
    //signals from/to pins
    .smb_scl                (TRG_smb_scl            ),        //I2C interfaces tunneling through LVDS 
    .smb_sda                (TRG_smb_sda            ),
    //signal from/to opertional frame managment
    .i2c_event_i            (CTRL_i2c_event_o        ),
    .i2c_event_o            (CTRL_i2c_event_i        ),
    .soft_i2c_channel_rst   (1'b0                   ),
    .DDR_MODE               (DDR_MODE               ),
    .link_speed             (link_speed             ),

    .tx_frm_offset          (TRG_tx_frm_offset      ),
    .config_capabilites     (config_capabilites     ),
    .local_link_state       (operational_st         ),
    .remote_link_state      (operational_st         )
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
    DDR_MODE = 1'b0;
    //configure frm
    config_capabilites.I2C_channel_cpbl             <= 6'h00;
    config_capabilites.I2C_channel_en               <= 6'h3F;
    config_capabilites.I2C_Echo_support             <= 1'b1;

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

task i2c_controller_setup(input int index);

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

    `SVTEST(i2c_test_freq_change_echo_ON_SDR)
        logic [7:0] i =0;
        logic [31: 0] data_read;
        DDR_MODE = 1'b0;
        link_speed = base_freq_x1;

        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_setup(i2c_dev_nb);
        end

        for ( i=0 ; i<5; i++) begin
            repeat(1000) @(posedge clk_25); 
            for(int j = 0 ; j < 1 ; j++) begin
                //$display("Test nb: %0d FREQ: %s" , j , link_speed.name());
                for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin
                    for( int k = 0 ; k<(4*2) ; k=k+4) begin
                        i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                        i2c_address_rw = k;

                        csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                        wait(i2c_target_write);
                        repeat(5000) @(posedge clk_25); 

                        csr_read(i2c_dev_nb, i2c_address_rw,data_read);
                        `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                        repeat(5000) @(posedge clk_25); 
                    end
                end
            end
            `FAIL_UNLESS(timer_done =='0);

            repeat(3000) @(posedge clk_25);
            $display("I2C_Echo_support: ON | FREQ %s", link_speed.name());
            repeat(100) @(posedge clk_25);

            link_speed = link_speed.next();

            reset_controller = 0; 
            reset_target = 0;
            repeat(10) @(posedge clk_25);
            reset_controller = 1; 
            reset_target = 1;

        end
    `SVTEST_END

    `SVTEST(i2c_test_freq_change_echo_OFF_SDR)
        logic [7:0] i = 0;
        logic [31: 0] data_read;
        DDR_MODE = 1'b0;
        link_speed = base_freq_x1;
        config_capabilites.I2C_Echo_support             <= 1'b0;
        
        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_setup(i2c_dev_nb);
        end

        for ( i=0 ; i<5; i++) begin
            repeat(1000) @(posedge clk_25); 
            for(int j = 0 ; j < 1 ; j++) begin
                //$display("Test nb: %0d FREQ: %s" , j , link_speed.name());
                for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin
                    for( int k = 0 ; k<(4*2) ; k=k+4) begin
                        i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                        i2c_address_rw = k;

                        csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                        wait(i2c_target_write);
                        repeat(5000) @(posedge clk_25); 

                        csr_read(i2c_dev_nb, i2c_address_rw,data_read);
                        `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                        repeat(5000) @(posedge clk_25); 
                    end
                end
            end
            `FAIL_UNLESS(timer_done =='0);

            repeat(3000) @(posedge clk_25);
            $display("I2C_Echo_support: OFF | FREQ %s", link_speed.name());
            repeat(100) @(posedge clk_25);

            link_speed = link_speed.next();

            reset_controller = 0; 
            reset_target = 0;
            repeat(10) @(posedge clk_25);
            reset_controller = 1; 
            reset_target = 1;

        end
    `SVTEST_END

    `SVTEST(i2c_test_freq_change_echo_ON_DDR)
        logic [31: 0] data_read;
        logic [7:0] i =0;
        DDR_MODE = 1'b1;
        link_speed = base_freq_x1;

        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_setup(i2c_dev_nb);
        end

        for ( i=0 ; i<5; i++) begin
            repeat(1000) @(posedge clk_25); 
            for(int j = 0 ; j < 1 ; j++) begin
                //$display("Test nb: %0d FREQ: %s" , j , link_speed.name());
                for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin
                    for( int k = 0 ; k<(4*2) ; k=k+4) begin
                        i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                        i2c_address_rw = k;

                        csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                        wait(i2c_target_write);
                        repeat(5000) @(posedge clk_25); 

                        csr_read(i2c_dev_nb, i2c_address_rw,data_read);
                        `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                        repeat(5000) @(posedge clk_25); 
                    end
                end
            end
            `FAIL_UNLESS(timer_done =='0);

            repeat(3000) @(posedge clk_25);
            $display("I2C_Echo_support: ON | FREQ %s", link_speed.name());
            repeat(100) @(posedge clk_25);

            link_speed = link_speed.next();

            reset_controller = 0; 
            reset_target = 0;
            repeat(10) @(posedge clk_25);
            reset_controller = 1; 
            reset_target = 1;

        end
    `SVTEST_END

    `SVTEST(i2c_test_freq_change_echo_OFF_DDR)
        logic [31: 0] data_read;
        logic [7:0] i =0;
        DDR_MODE = 1'b1;
        link_speed = base_freq_x1;
        config_capabilites.I2C_Echo_support             <= 1'b0;
        
        for (int i2c_dev_nb =0 ; i2c_dev_nb<6; i2c_dev_nb++) begin
            i2c_controller_setup(i2c_dev_nb);
        end

        for ( i=0 ; i<5; i++) begin
            repeat(1000) @(posedge clk_25); 
            for(int j = 0 ; j < 1 ; j++) begin
                //$display("Test nb: %0d FREQ: %s" , j , link_speed.name());
                for( int i2c_dev_nb = 0 ; i2c_dev_nb < 6 ; i2c_dev_nb++) begin
                    for( int k = 0 ; k<(4*2) ; k=k+4) begin
                        i2c_data_write = $urandom_range(32'hFFFF_FFFF, 0);
                        i2c_address_rw = k;

                        csr_write(i2c_dev_nb, i2c_address_rw,i2c_data_write);
                        wait(i2c_target_write);
                        repeat(5000) @(posedge clk_25); 

                        csr_read(i2c_dev_nb, i2c_address_rw,data_read);
                        `FAIL_UNLESS_EQUAL(i2c_data_write, data_read)
                        repeat(5000) @(posedge clk_25); 
                    end
                end
            end
            `FAIL_UNLESS(timer_done =='0);

            repeat(3000) @(posedge clk_25);
            $display("I2C_Echo_support: OFF | FREQ %s", link_speed.name());
            repeat(100) @(posedge clk_25);

            link_speed = link_speed.next();

            reset_controller = 0; 
            reset_target = 0;
            repeat(10) @(posedge clk_25);
            reset_controller = 1; 
            reset_target = 1;
        end
    `SVTEST_END
`SVUNIT_TESTS_END

endmodule