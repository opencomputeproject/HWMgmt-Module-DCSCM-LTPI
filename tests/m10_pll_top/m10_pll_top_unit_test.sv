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

`timescale 1 ns / 1 ps
`include "svunit_defines.svh"

module m10_pll_top_unit_test;
import svunit_pkg::svunit_testcase;
import ltpi_pkg::*;


string name = "m10_pll_top_unit_test";
svunit_testcase svunit_ut;

parameter NO_END = 0;

localparam real TIME_BASE = 1000.0;

//localparam real CLOCK_50  = (TIME_BASE / 50.00);
localparam real CLOCK_60  = (TIME_BASE / 60.00);
localparam real CLOCK_25  = (TIME_BASE / 25.00);

//logic clk_50MHz = 0;
logic clk_60MHz = 0;
logic clk_25MHz = 0;

//initial forever #(CLOCK_50/2)  clk_50MHz  = ~clk_50MHz;
initial forever #(CLOCK_60/2)  clk_60MHz  = ~clk_60MHz; 
initial forever #(CLOCK_25/2)  clk_25MHz  = ~clk_25MHz;

logic reset = 0;

// DUT
logic clk_out;
logic clk_out_90;
logic locked;

m10_pll_top_tester dut (
    .ref_clk            (clk_25MHz),
    .mgmt_clk           (clk_60MHz),
    .reset_n            (!reset),

    .clk_out            (clk_out),
    .clk_out_90         (clk_out_90),

    .locked             (locked),
    .reconfig           ()
);


// --------------------------------------------
function void build(); 
    svunit_ut = new (name);
endfunction

task setup();
    svunit_ut.setup();

    reset = 1;

    #100;

    repeat(10) @(posedge clk_25MHz); 
    reset = 0;
endtask

task teardown();
    svunit_ut.teardown();

    reset = 1;
endtask

`SVUNIT_TESTS_BEGIN
    `SVTEST(corect_freq_test)
    
    realtime time_pos;
    realtime time_neg;

    for(int i=0; i<8 ;i++) begin
        wait(dut.mgmt_clk_reconfig)
        wait(dut.mgmt_clk_configuration_done)
        @(posedge dut.c0);
        time_pos = $realtime;
        @(negedge dut.c0);
        time_neg = $realtime;
        $display("TEST HIGH : Time: conf %h: %t - %t = %t", dut.mgmt_clk_configuration, time_pos, time_neg,(time_neg - time_pos));
        
        case (dut.mgmt_clk_configuration)
            0: `FAIL_UNLESS((time_neg - time_pos) > 19.9ns && (time_neg - time_pos) < 20.1ns)
            1: `FAIL_UNLESS((time_neg - time_pos) > 9.9ns  && (time_neg - time_pos) < 10.1ns)
            2: `FAIL_UNLESS((time_neg - time_pos) > 6660ps && (time_neg - time_pos) < 6670ps)
            4: `FAIL_UNLESS((time_neg - time_pos) > 3330ps && (time_neg - time_pos) < 3340ps)
            5: `FAIL_UNLESS((time_neg - time_pos) > 2.4ns  && (time_neg - time_pos) < 2.6ns )
            6: `FAIL_UNLESS((time_neg - time_pos) > 1.9ns  && (time_neg - time_pos) < 2.1ns )
            7: `FAIL_UNLESS((time_neg - time_pos) > 1660ps && (time_neg - time_pos) < 1670ps)
            default: `FAIL_IF(0)
        endcase

        @(negedge dut.c0);
        time_neg = $realtime;
        @(posedge dut.c0);
        time_pos = $realtime;
        $display("TEST LOW: Time: conf %h: %t - %t = %t", dut.mgmt_clk_configuration, time_neg , time_pos,(time_pos - time_neg));

        case (dut.mgmt_clk_configuration)
            0: `FAIL_UNLESS((time_pos - time_neg) > 19.9ns && (time_pos - time_neg) < 20.1ns)
            1: `FAIL_UNLESS((time_pos - time_neg) > 9.9ns  && (time_pos - time_neg) < 10.1ns)
            2: `FAIL_UNLESS((time_pos - time_neg) > 6660ps && (time_pos - time_neg) < 6670ps)
            4: `FAIL_UNLESS((time_pos - time_neg) > 3330ps && (time_pos - time_neg) < 3340ps)
            5: `FAIL_UNLESS((time_pos - time_neg) > 2.4ns  && (time_pos - time_neg) < 2.6ns )
            6: `FAIL_UNLESS((time_pos - time_neg) > 1.9ns  && (time_pos - time_neg) < 2.1ns )
            7: `FAIL_UNLESS((time_pos - time_neg) > 1660ps && (time_pos - time_neg) < 1670ps)
            default: `FAIL_IF(0)
        endcase
    end

    `SVTEST_END

`SVUNIT_TESTS_END

endmodule
