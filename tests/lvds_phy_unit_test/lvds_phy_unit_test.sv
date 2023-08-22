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

module lvds_phy_unit_test;
//import ltpi_pkg::*;
import svunit_pkg::svunit_testcase;
import logic_avalon_mm_pkg::*; 

string name = "lvds_phy_unit_test";
string test_name;
int test_nb =0;
localparam int DATA_SNT_CNT = 300;

svunit_testcase svunit_ut;

int seed;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_25 = (TIME_BASE / 25.00);
localparam real CLOCK_50 = (TIME_BASE / 50.00);
localparam real CLOCK_100  = (TIME_BASE / 100.00);

logic clk_100 = 0;
logic clk_100_90;
logic clk_25 = 0;
logic clk_50 = 0;
logic clk_logic;

initial forever #(CLOCK_100/2)  clk_100  = ~clk_100;
initial forever #(CLOCK_50/2)  clk_50  = ~clk_50; 
initial forever #(CLOCK_25/2)  clk_25  = ~clk_25;

initial begin
    clk_100_90 = 0;
    #(2.5) 
    forever begin
        #(5) clk_100_90 = ~clk_100_90;
    end
end

logic reset_phy_tx = 0;
logic reset_phy_rx = 0;
logic lvds_tx_data;
logic lvds_tx_clk;
logic LVDS_DDR ='0;

logic [31:0] nodelink_status;
logic sm_symbol_locked ='0;
logic frame_correct ='1;

logic [9:0] data_rx_10b;
logic [9:0] data_tx_10b ='0;
int data_tx[DATA_SNT_CNT];

logic phy_tx_dv ='0;
logic data_rx_10b_dv;

logic rx_symbol_locked;

//timer 
logic timer_done ='0;
logic timer_start ='0;
logic[31:0] timer ='0;

logic [3:0] clk200_counter;
logic clk200_counter_tc;
logic wr_req;
logic any_k28_5_found;

function int get_time();
    int file_pointer;
    void'($system("date +%N > sys_time"));
    file_pointer = $fopen("sys_time","r");
    void'($fscanf(file_pointer,"%s",get_time));

    $fclose(file_pointer);
    void'($system("rm sys_time"));
endfunction

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
        //clk_logic = clk_50;
        clk_logic = clk_100;
    end
end

lvds_phy_tx #(
    .CYCLONE_V (0)
)
lvds_phy_tx(
    .clk                (clk_logic),
    .clk_link           (clk_100),
    .clk_link_90        (clk_100_90),
    .reset              (reset_phy_tx),
    .LVDS_DDR           (LVDS_DDR),
    // encoder input
    .phy_tx_in          (data_tx_10b),
    .phy_tx_dv          (wr_req),

    // LVDS interface signals
    .lvds_tx_data       (lvds_tx_data),
    .lvds_tx_clk        (lvds_tx_clk),

    // optional signals
    .txfifo_full        ()
);

lvds_phy_rx #(
    .CYCLONE_V (0)
)
lvds_phy_rx (

    .clk                (clk_logic),
    .reset_phy          (reset_phy_rx),
    .LVDS_DDR           (LVDS_DDR),

    // Parallel encoded data out
    .phy_rx_dv          (data_rx_10b_dv),
    .phy_rx_out         (data_rx_10b),

    // nodelink interface signals
    .lvds_rx_data       (lvds_tx_data),
    .lvds_rx_clk        (lvds_tx_clk),
    .sm_symbol_locked   (sm_symbol_locked),
    .rx_symbol_locked   (rx_symbol_locked),
    .frame_correct      ( frame_correct)
);


// ------------------------------------------------
function void build();
    svunit_ut = new (name);
endfunction


task setup();
    svunit_ut.setup();
    reset_phy_tx = 1; 
    reset_phy_rx = 1;
    data_tx_10b <='0;
    timer_start <= 0;
    sm_symbol_locked ='0;

    seed = get_time();
    $display("Seed: %d", seed);
    repeat(10) @(posedge clk_25); 

endtask

task teardown();
    svunit_ut.teardown();
    reset_phy_tx = 1; 
    reset_phy_rx = 1;
    timer_start <= 0;
    sm_symbol_locked <= 0;
endtask

//Put data to FIFO with PHY clk = 100 MHZ
always @ (posedge clk_100)
    if(reset_phy_tx) begin
        clk200_counter<='0;
    end 
    else begin
    if (clk200_counter_tc)
        clk200_counter <= 4'h0;
    else
        clk200_counter <= clk200_counter + 1'b1;
    end

assign clk200_counter_tc = LVDS_DDR ? clk200_counter == 4'h4 : clk200_counter == 4'h9;

logic wr_req_flag =0;

initial begin
    #1
    forever begin
        @(posedge clk_100) //phy_clk
        #1
        if(LVDS_DDR) begin
            if(clk200_counter == 4'h3 & wr_req_flag == 0) begin
                wr_req_flag = 1;
                wr_req = 1;
                @(posedge clk_logic)
                wr_req = 1;
                @(posedge clk_logic)
                wr_req = 0;
            //wr_req <= clk200_counter == 4'h3;
            end
            else if(clk200_counter != 4'h3) begin
                wr_req_flag = 0;
            end
            else begin
                @(posedge clk_logic)
                wr_req = 0;
            end
        end
        else begin
            if(clk200_counter == 4'h8 & wr_req_flag == 0) begin
                wr_req_flag = 1;
                wr_req = 1;
                @(posedge clk_logic)
                wr_req = 1;
                @(posedge clk_logic)
                wr_req = 0;
            end
            else if(clk200_counter != 4'h8) begin
                wr_req_flag = 0;
            end
            else begin
                wr_req <= 0;
            end
            //wr_req <= clk200_counter == 4'h8;
        end
    end
end

always @ (posedge clk_100) begin
    if(reset_phy_tx) begin
        wr_req<='0;
    end
    else begin
        if(LVDS_DDR) begin
            wr_req <= clk200_counter == 4'h3;

        end
        else begin
            wr_req <= clk200_counter == 4'h8;
        end
    end
end

        int j = 0;
        int l = 1;
        int i = 0;
`SVUNIT_TESTS_BEGIN

    `SVTEST(transmit_K28_5_DDR)
        LVDS_DDR ='1;
        test_nb = 0;
        test_name = "transmit_K28_5_DDR";
        $display("%s", test_name);
        timer_start = '1;
        repeat(60) @(posedge clk_25); 
        reset_phy_tx = '0; 
        reset_phy_rx = '0;

        data_tx_10b <= 10'b10_1000_0011;

        wait(timer_done == 1 || rx_symbol_locked)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(rx_symbol_locked);
        timer_start = '0;
        repeat(10) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(transmit_K28_5_SDR)
        LVDS_DDR ='0;
        test_nb = 1;
        test_name = "transmit_K28_5_SDR";
        $display("%s", test_name);
        timer_start = '1;
        reset_phy_tx = '0; 
        reset_phy_rx = '0;

        data_tx_10b <= 10'b10_1000_0011;

        wait(timer_done == 1 || rx_symbol_locked)
        data_tx_10b <= '0;
        wait(timer_done == 1 || rx_symbol_locked)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS(rx_symbol_locked);
        timer_start = '0;
        repeat(10) @(posedge clk_25);

    `SVTEST_END


    `SVTEST(transmit_K28_5_frm_SDR)


        LVDS_DDR ='0;
        test_nb = 2;
        test_name = "transmit_K28_5_frm_SDR";
        $display("%s", test_name);

        for (int m=0; m<DATA_SNT_CNT; m++) begin
            //data_tx[m] = $urandom(seed); //$urandom_range(0,255);
            data_tx[m] = $urandom_range(0,255);
        end

        timer_start = '1;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;   

        data_tx_10b <= 10'h00;
        repeat(100) @(posedge clk_100); 

        //send random data
        while(i<DATA_SNT_CNT) begin
            @(posedge clk_100); 
            if(clk200_counter =='0 ) begin
                data_tx_10b <= data_tx[i];
                    //data_tx_10b <= j;
                    i = i+1;
            end

            if(rx_symbol_locked) begin
                frame_correct<=0;
            end
            else begin
                frame_correct<=1;
            end
        end

        data_tx_10b <= 10'h00;
        repeat(100) @(posedge clk_100);

        wait(timer_done == 1 || data_rx_10b=='0)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS_EQUAL('0, data_rx_10b )

        if(rx_symbol_locked) begin
            frame_correct<=0;
        end
        repeat(10)@(posedge clk_100); 
        frame_correct <='1;
        
        //send corect frame with K28_5 symbol
        fork
        begin
            i=0;
            while(i<DATA_SNT_CNT) begin
                @(posedge clk_100); 
                if(clk200_counter =='0 ) begin
                    if( j % 16) begin 
                        data_tx_10b <= data_tx[j];
                        //data_tx_10b <= j;
                        i = i+1;
                    end
                    else begin
                        data_tx_10b <= 10'b10_1000_0011; // put COMMA sign every 16 data's
                        j=0;
                    end
                    j = j+1;
                end

                if(rx_symbol_locked) begin
                    sm_symbol_locked <= '1;
                end
            end
        end

        begin
            wait(timer_done == 1 || rx_symbol_locked)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(rx_symbol_locked);
            wait(timer_done == 1 || data_rx_10b==10'b10_1000_0011)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS_EQUAL(10'b10_1000_0011, data_rx_10b )

            while(i<DATA_SNT_CNT) begin
                `FAIL_UNLESS(timer_done =='0);
                wait(data_rx_10b_dv == 1);
                if(data_rx_10b != 10'b10_1000_0011 ) begin
                    $display("data_tx_10b = %0h | data_rx_10b = %0h", data_tx[l], data_rx_10b);
                    `FAIL_UNLESS_EQUAL(data_tx[l], data_rx_10b )
                    l = l+1;
                end
                else begin
                l=1;
                end
                wait(data_rx_10b_dv == 0);
                //end
            end
         end
        join
        timer_start = '0;
        repeat(10) @(posedge clk_25);

    `SVTEST_END

    `SVTEST(transmit_K28_5_frm_DDR)
        int j = 0;
        int l = 1;
        int i = 0;

        LVDS_DDR ='1;
        test_nb = 3;
        test_name = "transmit_K28_5_frm_DDR";
        $display("%s", test_name);

        for (int m=0; m<DATA_SNT_CNT; m++) begin
            //data_tx[m] = $urandom(seed);
            data_tx[m] = $urandom_range(0,255);
        end

        timer_start = '1;
        reset_phy_tx = 0; 
        reset_phy_rx = 0;   

        data_tx_10b <= 10'h00;
        repeat(100) @(posedge clk_100); 
        frame_correct <='1;
        //send random data
        while(i<DATA_SNT_CNT) begin
            @(posedge clk_100); 
            if(clk200_counter =='0 ) begin
                data_tx_10b <= data_tx[i];
                    //data_tx_10b <= j;
                    i = i+1;
            end

            if(rx_symbol_locked) begin
                frame_correct<=0;
            end
            else begin
                frame_correct<=1;
            end
        end

        data_tx_10b <= 10'h00;
        repeat(100) @(posedge clk_100);

        wait(timer_done == 1 || data_rx_10b=='0)
        `FAIL_UNLESS(timer_done =='0);
        `FAIL_UNLESS_EQUAL('0, data_rx_10b )
        if(rx_symbol_locked) begin
            frame_correct<=0;
        end
        repeat(10)@(posedge clk_100); 
        frame_correct <='1;
        
        //send corect frame with K28_5 symbol
        fork
        begin
            i=0;
            while(i<DATA_SNT_CNT) begin
                @(posedge clk_100); 
                if(clk200_counter =='0 ) begin
                    if( j % 16) begin 
                        data_tx_10b <= j;//data_tx[j];
                        //data_tx_10b <= 0;
                        //data_tx[j]=0;
                        data_tx[j]=j;
                        i = i+1;
                    end
                    else begin
                        data_tx_10b <= 10'b10_1000_0011; // put COMMA sign every 16 data's
                        j=0;
                    end
                    j = j+1;
                end
                if(rx_symbol_locked ) begin//&& data_rx_10b==10'b10_1000_0011) begin
                    sm_symbol_locked <= '1;
                    
                end
                // else if(rx_symbol_locked) begin
                //     frame_correct <='0;
                // end
                else begin
                    sm_symbol_locked <= '0;
                    frame_correct <='1;
                end
            end
        end

        begin
            wait(timer_done == 1 || rx_symbol_locked)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS(rx_symbol_locked);
            wait(timer_done == 1|| data_rx_10b==10'b10_1000_0011)
            `FAIL_UNLESS(timer_done =='0);
            `FAIL_UNLESS_EQUAL(10'b10_1000_0011, data_rx_10b )

            while(i<DATA_SNT_CNT) begin
                `FAIL_UNLESS(timer_done =='0);

                wait(data_rx_10b_dv == 1);
                if(data_rx_10b != 10'b10_1000_0011 ) begin
                    $display("data_tx_10b = %0h | data_rx_10b = %0h", data_tx[l], data_rx_10b);
                    `FAIL_UNLESS_EQUAL(data_tx[l], data_rx_10b )
                    l = l+1;
                end
                else begin
                    l=1;
                end
                wait(data_rx_10b_dv == 0);
            end
         end
        join

        timer_start = '0;
        repeat(10) @(posedge clk_25);

    `SVTEST_END

`SVUNIT_TESTS_END

endmodule