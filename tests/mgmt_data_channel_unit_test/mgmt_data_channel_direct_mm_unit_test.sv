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

module mgmt_data_channel_direct_mm_unit_test;
import ltpi_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 
// import ltpi_data_channel_controller_csr_rdl_pkg::*;
// import ltpi_data_channel_controller_model_pkg::*;

string name = "mgmt_data_channel_direct_mm_unit_test";
string test_name;

svunit_testcase svunit_ut;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);

logic clk_25 ;
logic clk_25_dut0;
logic clk_25_dut1;
localparam BASE_ADDR = 32'h0000_0000;

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

logic ref_clk_controller;
logic ref_clk_target;

logic clk_25_controller;
logic clk_60_controller;
logic clk_25_target;
logic clk_60_target;

assign ref_clk_controller   = clk_25_dut0;
//assign ref_clk_target    = clk_25_dut1;
assign ref_clk_target    = clk_25_dut0;
logic reset_n = 0;

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
) u_avmm_m (
    .aclk           (clk_60_controller),
    .areset_n       (reset_controller)
);

logic [ 3:0]      CTRL_tx_frm_offset;
logic [ 3:0]      TRG_tx_frm_offset;
logic [ 1:0]      CTRL_cnt;
logic [ 1:0]      TRG_cnt;
logic [31:0] operational_frm_snt_cnt;

always @(posedge clk_60_controller  or negedge reset_controller) begin
    if(!reset_controller) begin
        CTRL_tx_frm_offset <= '0;
        CTRL_cnt <= '0;
        operational_frm_snt_cnt <= 0;
    end
    else begin
        if(CTRL_cnt < 1) begin
            CTRL_cnt <= CTRL_cnt + 1;
        end
        else begin
            CTRL_tx_frm_offset <= CTRL_tx_frm_offset + 1;
            CTRL_cnt <= '0;

            if(CTRL_tx_frm_offset  == 4'hF) begin
                operational_frm_snt_cnt <= operational_frm_snt_cnt + 1; 
            end
        end
    end
end

always @(posedge clk_60_controller  or negedge reset_controller) begin
    if(!reset_controller) begin
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


Data_channel_payload_t  CTRL_payload_o;
Data_channel_payload_t  CTRL_payload_i;
logic CTRL_payload_o_valid;
logic CTRL_payload_i_valid;

logic req_valid;
logic req_ack;
Data_channel_payload_t req;

logic resp_valid;
Data_channel_payload_t resp;

ltpi_data_channel_controller_mm dut (
    .clk                    (clk_60_controller),
    .reset                  (~reset_controller),
    .avalon_mm_s            (u_avmm),
    .tag                    ('0),
    .req_valid              (req_valid),
    .req_ack                (req_ack),
    .req                    (req),
    .resp_valid             (resp_valid),
    .resp                   (resp)
);

logic TRG_resp_valid;
logic TRG_resp_ack;
Data_channel_payload_t TRG_resp;
logic ctrl_frm_crc_error = 0;
logic trg_frm_crc_error = 0;

mgmt_data_channel_controller mgmt_data_channel_controller_inst(
    .clk                    (clk_60_controller          ),
    .reset                  (~reset_controller          ),
    .data_channel_rst       (0),

    .req_valid              (req_valid              ),
    .req_ack                (req_ack                ),
    .req_data_channel       (req                    ),

    .res_valid              (resp_valid             ),
    .res_data_channel       (resp                   ),

    .req_payload_o          (CTRL_payload_o          ),
    .payload_o_valid        (CTRL_payload_o_valid    ),
    .payload_i              (CTRL_payload_i          ),
    .payload_i_valid        (CTRL_payload_i_valid    ),
    //signals from phy managment
    .operational_frm_sent   (operational_frm_snt_cnt),
    .local_link_state       (operational_st         ),
    .frm_crc_error          (ctrl_frm_crc_error      ),
    .tx_frm_offset          (CTRL_tx_frm_offset      )
);

ltpi_data_channel_target_mm ltpi_data_channel_target_inst(
    .clk                    (clk_60_controller          ),
    .reset                  (~reset_controller          ),
    .data_channel_rst       (0),
    .avalon_mm_m            (u_avmm_m               ),
    .payload_i              (CTRL_payload_o          ),
    .payload_i_valid        (CTRL_payload_o_valid    ),

    .resp_valid             (TRG_resp_valid),
    .resp_ack               (TRG_resp_ack),
    .resp                   (TRG_resp),

    .local_link_state       (operational_st         ),
    .frm_crc_error          (trg_frm_crc_error      )
);

mgmt_data_channel_target mgmt_data_channel_target_inst (
    .clk                    (clk_60_controller          ),
    .reset                  (~reset_controller          ),

    .payload_o              (CTRL_payload_i          ),
    .payload_o_valid        (CTRL_payload_i_valid    ),

    .resp_valid             (TRG_resp_valid),
    .resp_ack               (TRG_resp_ack),
    .resp                   (TRG_resp),

    .tx_frm_offset          (TRG_tx_frm_offset      ),
    .operational_frm_sent   (operational_frm_snt_cnt),
    .data_channel_rst       (0)
);

avmm_target_model avmm_target_model_inst
(
    .clk            (clk_60_controller               ),
    .rst_n          (reset_controller                ),
    //AVMM Intf
    .avmm_addr      (u_avmm_m.address           ),
    .avmm_read      (u_avmm_m.read              ),
    .avmm_write     (u_avmm_m.write             ),
    .avmm_wdata     (u_avmm_m.writedata         ),
    .avmm_byteen    (u_avmm_m.byteenable        ),
    .avmm_rdvalid   (u_avmm_m.readdatavalid     ),
    .avmm_waitrq    (u_avmm_m.waitrequest       ),
    .avmm_wrvalid   (u_avmm_m.writeresponsevalid),
    .avmm_rdata     (u_avmm_m.readdata          )
);
// ------------------------------------------------

function void build();
    svunit_ut = new (name);
endfunction

task setup();
    svunit_ut.setup();
    reset_n = 0;

    reset_controller = 0; 
    reset_target = 0;
    timer_start = 0;
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

task automatic avmm_write(logic [15:0] address, logic [31:0] data);
    wait (u_avmm.cb_slave.waitrequest == 0);
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
    wait (u_avmm.cb_slave.writeresponsevalid);

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
    wait (u_avmm.cb_slave.waitrequest == 0);
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
    wait (u_avmm.cb_slave.readdatavalid);
    for (int b = 0; b < 4; b++) begin
        data[b*8 +: 8] =  u_avmm.cb_slave.readdata[b];
    end

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

`SVUNIT_TESTS_BEGIN
    `SVTEST(read_reg)
        logic [31:0] rd_data;
        logic [15:0] addr_offset = 0;
        int k =0; 

        for(int i = 0 ; i< 4*16 ; i=i+4) begin
            avmm_read(BASE_ADDR + i, rd_data);
            `FAIL_UNLESS_EQUAL(rd_data, k);
            $display("Address: %h data read: %h status: %h ",  BASE_ADDR + i , rd_data, CTRL_payload_i.operation_status);
            k=k+1;
            #1000;
        end
        addr_offset = 4*17;
        avmm_read(BASE_ADDR + addr_offset, rd_data);
        $display("Address: %h data read: %h status: %h ",  BASE_ADDR + addr_offset , rd_data, CTRL_payload_i.operation_status);
        #1000;
    `SVTEST_END

    `SVTEST(write_reg)
        logic [15:0] addr_offset = 0;
        logic [31:0] data_write = '0;
        logic [31:0] rd_data;

        for(int i = 0 ; i< 4*16 ; i=i+4) begin
            data_write = $urandom_range(32'hFFFF_FFFF, 0);

            avmm_write(BASE_ADDR + i, data_write);
            $display("Address: %h data write: %h status: %h ",  BASE_ADDR + i , data_write, CTRL_payload_i.operation_status);
        
            #1000;
            avmm_read(BASE_ADDR + i, rd_data);
            $display("Address: %h  data read: %h status: %h ",  BASE_ADDR + i , rd_data, CTRL_payload_i.operation_status);
            `FAIL_UNLESS_EQUAL(rd_data, data_write);
            #1000;
        end
        data_write = $urandom_range(32'hFFFF_FFFF, 0);
        addr_offset = 4*17;
        avmm_write(BASE_ADDR + addr_offset, data_write);
        $display("Address: %h data write: %h status: %h ",  BASE_ADDR + addr_offset , data_write, CTRL_payload_i.operation_status);
        
        #1000;
        avmm_read(BASE_ADDR + addr_offset, rd_data);
        $display("Address: %h  data read: %h: status %h ",  BASE_ADDR + addr_offset , rd_data, CTRL_payload_i.operation_status);
        #1000;

    `SVTEST_END
`SVUNIT_TESTS_END

endmodule