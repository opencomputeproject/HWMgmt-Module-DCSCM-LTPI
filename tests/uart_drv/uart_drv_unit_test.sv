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

module uart_drv_unit_test;

import svunit_pkg::svunit_testcase;
import uart_unit_test_pkg::*;

string name = "uart_drv_unit_test";

svunit_testcase svunit_ut;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);
localparam real CLOCK_1G = (TIME_BASE / 1000.00);

logic clk_1G = 0;
logic clk_25 = 0;

initial forever #(CLOCK_25/2)  clk_25  = ~clk_25;
initial forever #(CLOCK_1G/2)  clk_1G  = ~clk_1G;

logic reset = 0;

uart_if uart_if_m( // TX
    .clk (clk_1G),
    .rstn(reset)
);

uart_driver_target uart_drv_s = new (uart_if_m);

uart_if uart_if_s( //RX
    .clk (clk_1G),
    .rstn(reset)
);
uart_driver_controller uart_drv_m = new (uart_if_s);

assign uart_if_s.data = uart_if_m.data;

function void build();
    svunit_ut = new (name);
endfunction

task setup();
    svunit_ut.setup();
    uart_drv_m.reset();
    uart_drv_s.reset();

    reset = 0; 
    repeat(10) @(posedge clk_25); 
    reset = 1; 

endtask

task teardown();
    svunit_ut.teardown();
    reset = 0; 
endtask
logic [7:0] uart_rd_data;

`SVUNIT_TESTS_BEGIN
    `SVTEST(uart_drv_wr_base)

        logic [ 7: 0] uart_wr_data;
        for(int i = 0; i < 256 ; i++) begin
            uart_wr_data  = $urandom_range(8'hFF,0);
            @(posedge clk_25); 
            fork 
                begin
                    uart_drv_s.write(uart_wr_data);
                end
                begin
                    uart_drv_m.read(uart_rd_data);
                end
            join
            $display("data_wr: %h , data_rd: %h",uart_wr_data , uart_rd_data);
            `FAIL_UNLESS_EQUAL(uart_wr_data, uart_rd_data)
        end

    `SVTEST_END

    `SVTEST(uart_drv_wr_921600)
        logic [ 7: 0] uart_wr_data;

        uart_drv_s.set_baudrate(921600);
        uart_drv_m.set_baudrate(921600);
        
        for(int i = 0; i < 256 ; i++) begin
            uart_wr_data  = $urandom_range(8'hFF,0);
            
            @(posedge clk_25); 
            fork 
                begin
                    uart_drv_s.write(uart_wr_data);
                end
                begin
                    uart_drv_m.read(uart_rd_data);
                end
            join
            $display("data_wr: %h , data_rd: %h",uart_wr_data , uart_rd_data);
            `FAIL_UNLESS_EQUAL(uart_wr_data, uart_rd_data)
        end
    `SVTEST_END


`SVUNIT_TESTS_END

endmodule