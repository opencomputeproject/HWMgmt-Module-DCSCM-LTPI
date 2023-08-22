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

module ltpi_phy_tx_rx_unit_test;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "ltpi_phy_tx_rx_unit_test";
string test_name;
int test_nb =0;
localparam int DATA_SNT_CNT = 100;

svunit_testcase svunit_ut;

parameter NO_END          = 0;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);
localparam real CLOCK_60  = (TIME_BASE / 60.00);
localparam real CLOCK_100  = (TIME_BASE / 100.00);
localparam real CLOCK_120  = (TIME_BASE / 120.00);
localparam real CLOCK_150  = (TIME_BASE / 150.00);

logic clk_100 = 0;
logic clk_150 = 0;
logic clk_150_90;
logic clk_120 = 0;
logic clk_60 = 0;
logic clk_100_90;
logic clk_25_90;
logic clk_25 = 0;

logic clk_phy; 
logic clk_phy_90;
logic FAST =0;

initial forever #(CLOCK_150/2)  clk_150  = ~clk_150; 
initial forever #(CLOCK_120/2)  clk_120  = ~clk_120; 
initial forever #(CLOCK_100/2)  clk_100  = ~clk_100; 
initial forever #(CLOCK_60/2)  clk_60  = ~clk_60; 
initial forever #(CLOCK_25/2)  clk_25  = ~clk_25;

initial begin
    clk_150_90 = 0;
    #(1.6666666666666667) 
    forever begin
        #(3.3333333333333333333333) clk_150_90 = ~clk_150_90;
    end
end

initial begin
    clk_100_90 = 0;
    #(2.5) 
    forever begin
        #(5) clk_100_90 = ~clk_100_90;
    end
end

initial begin
    clk_25_90 = 0;
    #(10) 
    forever begin
        #(20) clk_25_90 = ~clk_25_90;
    end
end

logic reset_phy_tx = 0;
logic reset_phy_rx = 0;
logic lvds_tx_data;
logic lvds_tx_clk;
logic LVDS_DDR ='1;
logic aligned;

logic [9:0] data_rx_10b;
logic [9:0] data_tx_10b ='0;
int data_tx[100];

logic phy_tx_dv ='0;
logic data_rx_10b_dv;


//timer 
logic timer_done ='0;
logic timer_start ='0;
logic[31:0] timer ='0;


ltpi_csr__out_t hwif_in;
ltpi_csr__in_t hwif_out;

LTPI_base_Frm_t ltpi_frame_tx = '0;
LTPI_base_Frm_t ltpi_frame_rx;

logic [15:0] local_speed_capabilities;

assign hwif_in.LTPI_Detect_Capabilities_Local.link_Speed_capab.value = {8'h0F,8'h80};
assign local_speed_capabilities = hwif_in.LTPI_Detect_Capabilities_Local.link_Speed_capab.value;

link_speed_t link_speed;
rstate_t LTPI_link_ST = ST_COMMA_HUNTING;

function void timer_fun (input logic start, output logic timer_done );
    if(start == 1'b1) begin
        if(timer < 500000) begin //0.5ms
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

initial begin 
    #1
    forever begin
        #1  
        if(FAST) begin
            link_speed = base_freq_x4; 
            clk_phy  = clk_100;
            clk_phy_90 = clk_100_90;
            //link_speed = base_freq_x6; 
            //clk_phy  = clk_150;
            //clk_phy_90 = clk_150_90;
        end
        else begin
            link_speed = base_freq_x1;
            clk_phy  = clk_25;
            clk_phy_90 = clk_25_90;
        end
    end
end

ltpi_phy_tx ltpi_phy_tx (
    .clk                ( clk_60        ),
    //.clk                ( clk_120        ),
    .clk_link           ( clk_phy       ),
    .clk_link_90        ( clk_phy_90    ),

    .reset              ( reset_phy_tx  ),
    .LVDS_DDR           ( LVDS_DDR      ),

    .lvds_tx_data       ( lvds_tx_data  ),
    .lvds_tx_clk        ( lvds_tx_clk   ),

    .ltpi_frame_tx      ( ltpi_frame_tx ),
    .tx_frm_offset      (  ),
    .link_speed         ( link_speed )
);

ltpi_phy_rx ltpi_phy_rx (
    .clk                ( clk_60             ),
    .reset              ( reset_phy_rx       ),
    .LVDS_DDR           ( LVDS_DDR           ),
    // Decode data output
    .rx_frm_offset      (),
    //LVDS output pins
    .lvds_rx_data       ( lvds_tx_data      ),
    .lvds_rx_clk        ( lvds_tx_clk       ),

    .ltpi_frame_rx      ( ltpi_frame_rx     ),
    .aligned            ( aligned           ),
    .frame_crc_err      (                   )

);

// ------------------------------------------------
function void build();
    svunit_ut = new (name);
endfunction


task setup();
    svunit_ut.setup();
    timer_start = 0;
    reset_phy_tx = 1; 
    reset_phy_rx = 1;
    
    ltpi_frame_tx.comma_symbol = K28_5;
    ltpi_frame_tx.frame_subtype = K28_5_SUB_0;
    ltpi_frame_tx.data[0] = LTPI_Version;
    ltpi_frame_tx.data[1] = local_speed_capabilities[15:0];
    ltpi_frame_tx.data[2] = local_speed_capabilities[7:0];

    repeat(10) @(posedge clk_25); 

endtask

task teardown();
    svunit_ut.teardown();
    timer_start = 0;
    reset_phy_tx = 1; 
    reset_phy_rx = 1; 
endtask

`SVUNIT_TESTS_BEGIN

    `SVTEST(transmit_SDR_25MHZ_K28_5)
        FAST ='0;
        timer_start = 1;
        LVDS_DDR=0;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;
        wait(timer_done == 1 || aligned)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned =='1);
        `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
        repeat (10) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(transmit_DDR_25MHZ_K28_5)
        FAST ='0;
        timer_start = 1;
        LVDS_DDR = 1;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;
        wait(timer_done == 1 || aligned)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned =='1);
        `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
            repeat (10) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(transmit_SDR_100MHZ_K28_5)
        FAST ='1;
        timer_start = 1;
        LVDS_DDR = 0;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;
        wait(timer_done == 1 || aligned)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned =='1);
        `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
        repeat (10) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(transmit_DDR_100MHZ_K28_5)
        for(int i=0 ; i< 1000; i=i+10) begin
            FAST ='1;
           
            LVDS_DDR = 1;
            reset_phy_rx = 0; 

            repeat (10) @(posedge clk_25);
            reset_phy_tx = 0;

            ltpi_frame_tx.comma_symbol = 255;
            repeat (i) @(posedge clk_25);
            ltpi_frame_tx.comma_symbol = K28_5;
            timer_start = 1;
            wait(timer_done == 1 || aligned)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(aligned =='1);
            `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
            repeat (10) @(posedge clk_25);
            reset_phy_rx = 1;
            reset_phy_tx = 1;
            timer_start = 0;
            repeat (10) @(posedge clk_25);

        end
    `SVTEST_END

    `SVTEST(transmit_SDR_25MHZ_K28_6)
        ltpi_frame_tx.comma_symbol = K28_6;
        ltpi_frame_tx.frame_subtype = K28_6_SUB_0;
        FAST ='0;
        timer_start = 1;
        LVDS_DDR=0;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;
        wait(timer_done == 1 || aligned)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned =='1);
        `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
        repeat (10) @(posedge clk_25);
    `SVTEST_END

    `SVTEST(transmit_DDR_25MHZ_K28_6)
        ltpi_frame_tx.comma_symbol = K28_6;
        ltpi_frame_tx.frame_subtype = K28_6_SUB_0;
        FAST ='0;
        timer_start = 1;
        LVDS_DDR = 1;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;
        wait(timer_done == 1 || aligned)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned =='1);
        `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
            repeat (10) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(transmit_SDR_100MHZ_K28_6)
        ltpi_frame_tx.comma_symbol = K28_6;
        ltpi_frame_tx.frame_subtype = K28_6_SUB_0;
        FAST ='1;
        timer_start = 1;
        LVDS_DDR = 0;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;
        wait(timer_done == 1 || aligned)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned =='1);
        `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
        repeat (10) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(transmit_DDR_100MHZ_K28_6)
        ltpi_frame_tx.comma_symbol = K28_6;
        ltpi_frame_tx.frame_subtype = K28_6_SUB_0;
        FAST ='1;
        timer_start = 1;
        LVDS_DDR = 1;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;
        wait(timer_done == 1 || aligned)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(aligned =='1);
        `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
        repeat (10) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(transmit_multiple_frm_DDR_100_MHZ_K28_6)
            ltpi_frame_tx.comma_symbol = K28_6;
            ltpi_frame_tx.frame_subtype = K28_6_SUB_0;
            ltpi_frame_tx.data[0] = K28_5;
            ltpi_frame_tx.data[1] = K28_6;
            ltpi_frame_tx.data[3] = K28_5;
            ltpi_frame_tx.data[4] = K28_6;
            ltpi_frame_tx.data[5] = K28_5;
            ltpi_frame_tx.data[6] = K28_6;
            ltpi_frame_tx.data[7] = '0;
            ltpi_frame_tx.data[11] = K28_6;
            ltpi_frame_tx.data[12] = K28_6;

        for (int i = 0 ; i <1000 ; i++) begin
            $display("TEST NB %0h", i);
            reset_phy_tx = 1; 

            reset_phy_rx = 1;

            FAST = 1;
            LVDS_DDR = 1;
            repeat (10) @(posedge clk_25);
            reset_phy_tx = 0; 
            repeat ((i+1)*1) @(posedge clk_25);
            reset_phy_rx = 0;
            timer_start = 1;
            wait(timer_done == 1 || aligned)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(aligned =='1);
            `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
            repeat (10) @(posedge clk_25);
            timer_start = 0;
            repeat (10) @(posedge clk_25);
        end

        for (int i = 0 ; i <1000 ; i++) begin
            $display("TEST NB %0h", i);
            reset_phy_tx = 1; 
            reset_phy_rx = 1;
            FAST = 0;

            LVDS_DDR = 1;
            repeat (10) @(posedge clk_25);
            reset_phy_rx = 0; 
            repeat ((i+1)*1) @(posedge clk_25);
            reset_phy_tx = 0;
            timer_start = 1;
            wait(timer_done == 1 || aligned)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(aligned =='1);
            `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
            repeat (10) @(posedge clk_25);
            timer_start = 0;
        end

    `SVTEST_END

    `SVTEST(transmit_multiple_frm_SDR_25_MHZ_K28_5)
            ltpi_frame_tx.comma_symbol = K28_5;
            ltpi_frame_tx.frame_subtype = K28_6_SUB_0;
            ltpi_frame_tx.data[0] = K28_5;
            ltpi_frame_tx.data[1] = K28_6;
            ltpi_frame_tx.data[3] = K28_5;
            ltpi_frame_tx.data[4] = K28_6;
            ltpi_frame_tx.data[5] = K28_5;
            ltpi_frame_tx.data[6] = K28_6;
            ltpi_frame_tx.data[7] = '0;
            ltpi_frame_tx.data[11] = K28_6;
            ltpi_frame_tx.data[12] = K28_6;
            FAST = 0;
            LVDS_DDR = 0;

        for (int i = 0 ; i <1000 ; i++) begin
            $display("TEST NB %0h", i);
            reset_phy_tx = 1; 
            reset_phy_rx = 1;
            timer_start = 1;
            repeat (10) @(posedge clk_25);
            reset_phy_tx = 0; 
            repeat ((i+1)*1) @(posedge clk_25);
            reset_phy_rx = 0;
            wait(timer_done == 1 || aligned)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(aligned =='1);
            `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
            repeat (10) @(posedge clk_25);
            timer_start = 0;
            repeat (10) @(posedge clk_25);
        end

        for (int i = 0 ; i <1000 ; i++) begin
            $display("TEST NB %0h", i);
            reset_phy_tx = 1; 
            reset_phy_rx = 1;
            FAST = 1;
            timer_start = 1;
            LVDS_DDR = 0;
            repeat (10) @(posedge clk_25);
            reset_phy_rx = 0; 
            repeat ((i+1)*1) @(posedge clk_25);
            reset_phy_tx = 0;
            wait(timer_done == 1 || aligned)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(aligned =='1);
            `FAIL_UNLESS_EQUAL(ltpi_frame_tx,ltpi_frame_rx);
            repeat (10) @(posedge clk_25);
            timer_start = 0;
            repeat (10) @(posedge clk_25);
        end
    `SVTEST_END

 `SVUNIT_TESTS_END

endmodule