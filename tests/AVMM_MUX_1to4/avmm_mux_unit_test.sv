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

module avmm_mux_unit_test;
    import svunit_pkg::svunit_testcase;

    string name = "avmm_mux_unit_test";
    svunit_testcase svunit_ut;

    localparam real TIME_BASE = 1000.0;
    localparam real CLOCK_20  = (TIME_BASE / 20.00);
    localparam real CLOCK_100 = (TIME_BASE / 100.00);

    localparam int MST0_ADDR_LOW  = 32'h0000_0000;
    localparam int MST0_ADDR_HIGH = 32'h0000_01FF;
    localparam int MST1_ADDR_LOW  = 32'h0000_0200;
    localparam int MST1_ADDR_HIGH = 32'h0000_02FF;
    localparam int MST2_ADDR_LOW  = 32'h0000_0300;
    localparam int MST2_ADDR_HIGH = 32'h0000_03FF;
    localparam int MST3_ADDR_LOW  = 32'h0000_0400;
    localparam int MST3_ADDR_HIGH = 32'hFFFF_FFFF;

    localparam int MST_ADDR_LOW     [3:0] = { MST3_ADDR_LOW, MST2_ADDR_LOW, MST1_ADDR_LOW, MST0_ADDR_LOW};
    localparam int MST_ADDR_HIGH    [3:0] = { MST3_ADDR_HIGH, MST2_ADDR_HIGH, MST1_ADDR_HIGH, MST0_ADDR_HIGH};

    logic clk     = 0;
    logic rstn    = 0;
    int clk_init_dly = 20;

    initial begin
        #clk_init_dly;
        while (1) #(CLOCK_20/2)   clk = ~clk;
    end

    logic_avalon_mm_if #(
        .DATA_BYTES     (4),
        .ADDRESS_WIDTH  (32),
        .BURST_WIDTH    (0)
    ) u_avmm_s (
        .aclk       (clk),
        .areset_n   (rstn)
    );

    logic_avalon_mm_if #(
        .DATA_BYTES     (4),
        .ADDRESS_WIDTH  (32),
        .BURST_WIDTH    (0)
    ) u_avmm_m_0 (
        .aclk       (clk),
        .areset_n   (rstn)
    );

    logic_avalon_mm_if #(
        .DATA_BYTES     (4),
        .ADDRESS_WIDTH  (32),
        .BURST_WIDTH    (0)
    ) u_avmm_m_1 (
        .aclk       (clk),
        .areset_n   (rstn)
    );

    logic_avalon_mm_if #(
        .DATA_BYTES     (4),
        .ADDRESS_WIDTH  (32),
        .BURST_WIDTH    (0)
    ) u_avmm_m_2 (
        .aclk       (clk),
        .areset_n   (rstn)
    );

    logic_avalon_mm_if #(
        .DATA_BYTES     (4),
        .ADDRESS_WIDTH  (32),
        .BURST_WIDTH    (0)
    ) u_avmm_m_3 (
        .aclk       (clk),
        .areset_n   (rstn)
    );


    avmm_mux #(
        .ADDR_WIDTH     (32),
        .DATA_WIDTH     (32)
    ) dut (
        .clk            (clk),
        .rstn           (rstn),
        .avmm_s         (u_avmm_s),
        .avmm_m_0       (u_avmm_m_0),
        .avmm_m_1       (u_avmm_m_1),
        .avmm_m_2       (u_avmm_m_2),
        .avmm_m_3       (u_avmm_m_3)
    );

    function void build(); 
        svunit_ut = new (name);
    endfunction
    
    task setup();
        svunit_ut.setup();

        rstn = 0;
        #100;
        @(posedge clk); 
        rstn = 1;


    endtask

    task teardown();
        svunit_ut.teardown();
        rstn = 0;
    endtask

    task automatic avmm_s_write(bit [31:0] address, bit [31:0] data, ref bit [1:0] resp);
        wait (u_avmm_s.waitrequest == 0);
        
        @ (posedge clk);
        u_avmm_s.burstcount         <= 0;
        u_avmm_s.beginbursttransfer <= 0;
        u_avmm_s.chipselect         <= 1;
        u_avmm_s.debugaccess        <= 0;
        u_avmm_s.lock               <= 0;
        u_avmm_s.read               <= 0;
        u_avmm_s.write              <= 1;
        u_avmm_s.address            <= address;

        for (int b = 0; b < 4; b++) begin
            u_avmm_s.writedata[b]   <=  data[b*8 +: 8];
        end
        u_avmm_s.byteenable         <= '1;
        @ (posedge clk);
        wait (u_avmm_s.writeresponsevalid);
        resp = u_avmm_s.response;

        u_avmm_s.burstcount         <= 0;
        u_avmm_s.beginbursttransfer <= 0;
        u_avmm_s.chipselect         <= 0;
        u_avmm_s.debugaccess        <= 0;
        u_avmm_s.lock               <= 0;
        u_avmm_s.read               <= 0;
        u_avmm_s.write              <= 0;
        u_avmm_s.address            <= 0; 
        for (int b = 0; b < 4; b++) begin
            u_avmm_s.writedata[b]   <= 0;
        end
        u_avmm_s.byteenable         <= 0;       

        @ (posedge clk);
    endtask

    task automatic avmm_s_read(bit [31:0] address, ref bit [31:0] data);
        wait (u_avmm_s.waitrequest == 0);
        @ (posedge clk);
        u_avmm_s.burstcount         <= 0;
        u_avmm_s.beginbursttransfer <= 0;
        u_avmm_s.chipselect         <= 1;
        u_avmm_s.debugaccess        <= 0;
        u_avmm_s.lock               <= 0;
        u_avmm_s.read               <= 1;
        u_avmm_s.write              <= 0;
        u_avmm_s.address            <= address;
        for (int b = 0; b < 4; b++) begin
            u_avmm_s.writedata[b]   <= 0;
        end
        u_avmm_s.byteenable         <= 0;
        @ (posedge clk);
        wait (u_avmm_s.readdatavalid);
        for (int b = 0; b < 4; b++) begin
            data[b*8 +: 8] = u_avmm_s.readdata[b];
        end

        u_avmm_s.burstcount         <= 0;
        u_avmm_s.beginbursttransfer <= 0;
        u_avmm_s.chipselect         <= 0;
        u_avmm_s.debugaccess        <= 0;
        u_avmm_s.lock               <= 0;
        u_avmm_s.read               <= 0;
        u_avmm_s.write              <= 0;
        u_avmm_s.address            <= 0; 
        for (int b = 0; b < 4; b++) begin
            u_avmm_s.writedata[b]   <= 0;
        end
        u_avmm_s.byteenable         <= 0;       

        @ (posedge clk);
    endtask

    task automatic avmm_m_write(ref bit [31:0] address, ref bit [31:0] data, input bit [1:0] response, input bit[2:0] MST_NB);
        case(MST_NB)
            0:begin
                @ (posedge clk);
                
                u_avmm_m_0.waitrequest <= 0;
                wait (u_avmm_m_0.chipselect && u_avmm_m_0.write);
                address = u_avmm_m_0.address;
                for (int b = 0; b < 4; b++) begin
                    data[b*8 +: 8] = u_avmm_m_0.writedata[b];
                end
                @ (posedge clk);
                u_avmm_m_0.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_0.writeresponsevalid <= 1;
                u_avmm_m_0.response           <= response;

                @ (posedge clk);

                u_avmm_m_0.waitrequest        <= 0;
                u_avmm_m_0.writeresponsevalid <= 0;
                u_avmm_m_0.response           <= 0;

                @ (posedge clk);
            end
            1:begin
                @ (posedge clk);
                
                u_avmm_m_1.waitrequest <= 0;
                wait (u_avmm_m_1.chipselect && u_avmm_m_1.write);
                address = u_avmm_m_1.address;
                for (int b = 0; b < 4; b++) begin
                    data[b*8 +: 8] = u_avmm_m_1.writedata[b];
                end
                @ (posedge clk);
                u_avmm_m_1.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_1.writeresponsevalid <= 1;
                u_avmm_m_1.response           <= response;

                @ (posedge clk);

                u_avmm_m_1.waitrequest        <= 0;
                u_avmm_m_1.writeresponsevalid <= 0;
                u_avmm_m_1.response           <= 0;

                @ (posedge clk);
            end
            2:begin
                @ (posedge clk);
                
                u_avmm_m_2.waitrequest <= 0;
                wait (u_avmm_m_2.chipselect && u_avmm_m_2.write);
                address = u_avmm_m_2.address;
                for (int b = 0; b < 4; b++) begin
                    data[b*8 +: 8] = u_avmm_m_2.writedata[b];
                end
                @ (posedge clk);
                u_avmm_m_2.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_2.writeresponsevalid <= 1;
                u_avmm_m_2.response           <= response;

                @ (posedge clk);

                u_avmm_m_2.waitrequest        <= 0;
                u_avmm_m_2.writeresponsevalid <= 0;
                u_avmm_m_2.response           <= 0;

                @ (posedge clk);
            end
            3:begin
                @ (posedge clk);
                
                u_avmm_m_3.waitrequest <= 0;
                wait (u_avmm_m_3.chipselect && u_avmm_m_3.write);
                address = u_avmm_m_3.address;
                for (int b = 0; b < 4; b++) begin
                    data[b*8 +: 8] = u_avmm_m_3.writedata[b];
                end
                @ (posedge clk);
                u_avmm_m_3.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_3.writeresponsevalid <= 1;
                u_avmm_m_3.response           <= response;

                @ (posedge clk);

                u_avmm_m_3.waitrequest        <= 0;
                u_avmm_m_3.writeresponsevalid <= 0;
                u_avmm_m_3.response           <= 0;

                @ (posedge clk);
            end
        endcase
    endtask

    task automatic avmm_m_read(ref bit [31:0] address, input bit [31:0] data, input bit[2:0] MST_NB);
        case(MST_NB)
            0:begin
                @ (posedge clk);

                u_avmm_m_0.waitrequest <= 0;
                wait (u_avmm_m_0.chipselect && u_avmm_m_0.read);
                address = u_avmm_m_0.address;
                @ (posedge clk);
                u_avmm_m_0.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_0.readdatavalid <= 1;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_0.readdata[b] <= data[b*8 +: 8];
                end

                @ (posedge clk);
                u_avmm_m_0.readdatavalid      <= 0;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_0.readdata[b] <= 0;
                end
                u_avmm_m_0.waitrequest        <= 0;
                u_avmm_m_0.writeresponsevalid <= 0;
                u_avmm_m_0.response           <= 0;

                @ (posedge clk);
            end
            1:begin
                @ (posedge clk);

                u_avmm_m_1.waitrequest <= 0;
                wait (u_avmm_m_1.chipselect && u_avmm_m_1.read);
                address = u_avmm_m_1.address;
                @ (posedge clk);
                u_avmm_m_1.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_1.readdatavalid <= 1;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_1.readdata[b] <= data[b*8 +: 8];
                end

                @ (posedge clk);
                u_avmm_m_1.readdatavalid      <= 0;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_1.readdata[b] <= 0;
                end
                u_avmm_m_1.waitrequest        <= 0;
                u_avmm_m_1.writeresponsevalid <= 0;
                u_avmm_m_1.response           <= 0;

                @ (posedge clk);
            end
           2:begin
                @ (posedge clk);

                u_avmm_m_2.waitrequest <= 0;
                wait (u_avmm_m_2.chipselect && u_avmm_m_2.read);
                address = u_avmm_m_2.address;
                @ (posedge clk);
                u_avmm_m_2.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_2.readdatavalid <= 1;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_2.readdata[b] <= data[b*8 +: 8];
                end

                @ (posedge clk);
                u_avmm_m_2.readdatavalid      <= 0;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_2.readdata[b] <= 0;
                end
                u_avmm_m_2.waitrequest        <= 0;
                u_avmm_m_2.writeresponsevalid <= 0;
                u_avmm_m_2.response           <= 0;

                @ (posedge clk);
            end
            3:begin
                @ (posedge clk);

                u_avmm_m_3.waitrequest <= 0;
                wait (u_avmm_m_3.chipselect && u_avmm_m_3.read);
                address = u_avmm_m_3.address;
                @ (posedge clk);
                u_avmm_m_3.waitrequest <= 1;

                repeat ($urandom_range(10, 1)) @ (posedge clk);

                u_avmm_m_3.readdatavalid <= 1;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_3.readdata[b] <= data[b*8 +: 8];
                end

                @ (posedge clk);
                u_avmm_m_3.readdatavalid      <= 0;
                for (int b = 0; b < 4; b++) begin
                    u_avmm_m_3.readdata[b] <= 0;
                end
                u_avmm_m_3.waitrequest        <= 0;
                u_avmm_m_3.writeresponsevalid <= 0;
                u_avmm_m_3.response           <= 0;

                @ (posedge clk);
            end
        endcase
    endtask

`SVUNIT_TESTS_BEGIN
    `SVTEST(write_avmm_m_0)
        int avmm_mst_nb = 0; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [ 1:0] ref_response     [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];
        bit [ 1:0] recv_response    [$];
       
        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];
        ref_response    = new [size];

        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb], MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
            ref_response[i]  = $urandom_range(2'h3,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [1:0] __response;
                    avmm_s_write(ref_address[i], ref_data[i], __response);
                    recv_response.push_back(__response);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    bit [31:0] __data;
                    avmm_m_write(__address, __data, ref_response[i],avmm_mst_nb);
                    recv_address.push_back(__address);
                    recv_data.push_back(__data);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
            `FAIL_UNLESS_EQUAL(ref_response[i], recv_response[i])
        end

    `SVTEST_END

    `SVTEST(write_avmm_m_1)
        int avmm_mst_nb = 1; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [ 1:0] ref_response     [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];
        bit [ 1:0] recv_response    [$];

        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];
        ref_response    = new [size];

        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb],MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
            ref_response[i]  = $urandom_range(2'h3,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [1:0] __response;
                    avmm_s_write(ref_address[i], ref_data[i], __response);
                    recv_response.push_back(__response);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    bit [31:0] __data;
                    avmm_m_write(__address, __data, ref_response[i],avmm_mst_nb);
                    recv_address.push_back(__address);
                    recv_data.push_back(__data);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
            `FAIL_UNLESS_EQUAL(ref_response[i], recv_response[i])
        end

    `SVTEST_END

    `SVTEST(write_avmm_m_2)
        int avmm_mst_nb = 2; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [ 1:0] ref_response     [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];
        bit [ 1:0] recv_response    [$];

        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];
        ref_response    = new [size];

        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb],MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
            ref_response[i]  = $urandom_range(2'h3,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [1:0] __response;
                    avmm_s_write(ref_address[i], ref_data[i], __response);
                    recv_response.push_back(__response);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    bit [31:0] __data;
                    avmm_m_write(__address, __data, ref_response[i], avmm_mst_nb);
                    recv_address.push_back(__address);
                    recv_data.push_back(__data);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
            `FAIL_UNLESS_EQUAL(ref_response[i], recv_response[i])
        end

    `SVTEST_END

    `SVTEST(write_avmm_m_3)
        int avmm_mst_nb = 3; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [ 1:0] ref_response     [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];
        bit [ 1:0] recv_response    [$];

        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];
        ref_response    = new [size];

        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb],MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
            ref_response[i]  = $urandom_range(2'h3,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [1:0] __response;
                    avmm_s_write(ref_address[i], ref_data[i], __response);
                    recv_response.push_back(__response);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    bit [31:0] __data;
                    avmm_m_write(__address, __data, ref_response[i],avmm_mst_nb);
                    recv_address.push_back(__address);
                    recv_data.push_back(__data);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
            `FAIL_UNLESS_EQUAL(ref_response[i], recv_response[i])
        end

    `SVTEST_END

    `SVTEST(read_avmm_m_0)
        int avmm_mst_nb = 0; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];

        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];

        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb],MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __data;
                    avmm_s_read(ref_address[i], __data);
                    recv_data.push_back(__data);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    avmm_m_read(__address, ref_data[i],avmm_mst_nb);
                    recv_address.push_back(__address);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
        end
    `SVTEST_END

    `SVTEST(read_avmm_m_1)
        int avmm_mst_nb = 1; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];

        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];
        
        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb],MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __data;
                    avmm_s_read(ref_address[i], __data);
                    recv_data.push_back(__data);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    avmm_m_read(__address, ref_data[i],avmm_mst_nb);
                    recv_address.push_back(__address);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
        end
    `SVTEST_END

    `SVTEST(read_avmm_m_2)
        int avmm_mst_nb = 2; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];

        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];

        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb],MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __data;
                    avmm_s_read(ref_address[i], __data);
                    recv_data.push_back(__data);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    avmm_m_read(__address, ref_data[i],avmm_mst_nb);
                    recv_address.push_back(__address);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
        end
    `SVTEST_END

    `SVTEST(read_avmm_m_3)
        int avmm_mst_nb = 3; 

        bit [31:0] ref_address      [];
        bit [31:0] ref_data         [];
        bit [31:0] recv_address     [$];
        bit [31:0] recv_data        [$];

        int size        = $urandom_range(200,0);
        ref_address     = new [size];
        ref_data        = new [size];
        for (int i = 0;  i < size ; i++) begin
            ref_address[i]   = $urandom_range(MST_ADDR_HIGH[avmm_mst_nb],MST_ADDR_LOW[avmm_mst_nb]);
            ref_data[i]      = $urandom_range(32'hFFFF_FFFF,0);
        end

        fork
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __data;
                    avmm_s_read(ref_address[i], __data);
                    recv_data.push_back(__data);
                end
            end
            begin
                for (int i = 0; i < size; i++) begin
                    bit [31:0] __address;
                    avmm_m_read(__address, ref_data[i],avmm_mst_nb);
                    recv_address.push_back(__address);
                end
            end
        join

        for (int i = 0; i < size; i++) begin
            `FAIL_UNLESS_EQUAL(ref_address[i], recv_address[i])
            `FAIL_UNLESS_EQUAL(ref_data[i], recv_data[i])
        end
    `SVTEST_END

`SVUNIT_TESTS_END

endmodule