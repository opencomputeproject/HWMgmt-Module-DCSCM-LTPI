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

module mgmt_data_channel_unit_test;
import ltpi_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 
import ltpi_data_channel_controller_csr_rdl_pkg::*;
import ltpi_data_channel_controller_model_pkg::*;

string name = "mgmt_data_channel_unit_test";
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

ltpi_data_channel_controller_csr dut (
    .clk                    (clk_60_controller),
    .reset                  (~reset_controller),
    .avalon_mm_s            (u_avmm),
    .req_valid              (req_valid),
    .req_ack                (req_ack),
    .req                    (req),
    .resp_valid             (resp_valid),
    .resp                   (resp)
);

ltpi_data_channel_controller_driver u_controller_driver = new (u_avmm);
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

ltpi_data_channel_target ltpi_data_channel_target_inst(
    .clk                    (clk_60_controller          ),
    .reset                  (~reset_controller          ),
    .data_channel_rst       (0),
    .avalon_mm_m            (u_avmm_m               ),
    .payload_i              (CTRL_payload_o          ),
    .payload_i_valid        (CTRL_payload_o_valid    ),

    .resp_rd_valid          (TRG_resp_valid),
    .resp_rd_ack            (TRG_resp_ack),
    .resp_fifo_rd           (TRG_resp),

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
    u_controller_driver.reset();
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

        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);
        
        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = i*4;

        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);

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

        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);

        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = i*4;

        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);

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

    `SVTEST(req_crc_err)
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

        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });
        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);

        req_addr = new[size];
        foreach(req_addr[i]) req_addr[i] = i*4;

        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });
        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);


        foreach (req_addr[i]) begin
            if( i == 3 || i == 10) begin  
                trg_frm_crc_error = 1; 
            end
            else begin 
                trg_frm_crc_error = 0;
            end

            u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            if(i != 3 && i != 10) begin
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP);
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i]);
                `FAIL_UNLESS_EQUAL(resp_data, req_data[i]);
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF);
                `FAIL_UNLESS_EQUAL(resp_status, 0);
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i]);
            end
            else begin
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), CRC_ERROR)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_status, 1)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
        end

    `SVTEST_END

    `SVTEST(resp_crc_err)
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

        req_tag = new[size];
        foreach (req_tag[i]) req_tag[i] = $urandom_range(0, 8'hFF);
        // void'(randomize (req_tag) with {
        //     req_tag.size() == size;
        // });

        req_addr = new[size];

        foreach(req_addr[i]) req_addr[i] = i*4;

        req_data = new[size];
        foreach (req_data[i]) req_data[i] = $urandom_range(0, 32'hFFFF_FFFF);

        // void'(randomize (req_data) with {
        //     req_data.size() == size;
        // });


        foreach (req_addr[i]) begin
            if( i == 3 || i == 10) begin  
                ctrl_frm_crc_error = 1; 
            end
            else begin 
                ctrl_frm_crc_error = 0;
            end

            u_controller_driver.request_write(req_addr[i], req_data[i], 4'hF, req_tag[i]);
            u_controller_driver.response(resp_cmd, resp_address, resp_data, resp_ben, resp_status, resp_tag);

            if(i != 3 && i != 10) begin
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), WRITE_COMP);
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i]);
                `FAIL_UNLESS_EQUAL(resp_data, req_data[i]);
                `FAIL_UNLESS_EQUAL(resp_ben, 4'hF);
                `FAIL_UNLESS_EQUAL(resp_status, 0);
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i]);
            end
            else begin
                `FAIL_UNLESS_EQUAL(data_chnl_comand_t'(resp_cmd), CRC_ERROR)
                `FAIL_UNLESS_EQUAL(resp_address, req_addr[i])
                `FAIL_UNLESS_EQUAL(resp_status, 1)
                `FAIL_UNLESS_EQUAL(resp_tag, req_tag[i])
            end
        end

    `SVTEST_END

`SVUNIT_TESTS_END

endmodule