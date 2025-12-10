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


module ltpi_csr_avmm_unit_test;
import svunit_pkg::svunit_testcase;
import ltpi_pkg::*;
import ltpi_csr_pkg::*;

string name = "ltpi_csr_avmm_unit_test";
svunit_testcase svunit_ut;

localparam real TIME_BASE = 1000.0;
localparam real CLOCK_50  = (TIME_BASE / 50.00);

logic clk_50MHz = 0;
logic reset_n = 0;
localparam BASE_ADDR = 16'h200;

initial forever #(CLOCK_50/2) clk_50MHz  = ~clk_50MHz;

logic_avalon_mm_if #(
    .DATA_BYTES     (4),
    .ADDRESS_WIDTH  (32),
    .BURST_WIDTH    (0)
) u_avmm (
    .aclk           (clk_50MHz),
    .areset_n       (reset_n)
);
    
LTPI_CSR_In_t CSR_hw_in;
LTPI_CSR_Out_t CSR_hw_out;

ltpi_csr_avmm dut (
    .clk                        (clk_50MHz),
    .reset_n                    (reset_n),
    .avalon_mm_s                (u_avmm),
    .CSR_hw_out                 (CSR_hw_out),
    .CSR_hw_in                  (CSR_hw_in)
);

function void build(); 
    svunit_ut = new (name);
endfunction

task setup();
    svunit_ut.setup();
    reset_n = 0;
    CSR_hw_out    <= '0;

    #100;
    @(posedge clk_50MHz); 
    reset_n = 1;
    
endtask

task teardown();
    svunit_ut.teardown();
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

////////////////////////////////////////
//////////READ/WRITE TESTS//////////////
////////////////////////////////////////

`SVUNIT_TESTS_BEGIN
`SVTEST(read_status_reg)
    logic [31:0] status;
    logic [15:0] addr_offset = 0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_Link_Status.aligned                       = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.link_lost_error               = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.frm_CRC_error                 = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.unknown_comma_error           = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error      = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error   = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.DDR_mode                      = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.link_speed                    = $urandom_range(4'hF, 0);
        CSR_hw_out.LTPI_Link_Status.remote_link_state             = $urandom_range(4'hF, 0);
        CSR_hw_out.LTPI_Link_Status.local_link_state              = $urandom_range(4'hF, 0);

        avmm_read(BASE_ADDR + addr_offset, status);

        
        `FAIL_UNLESS_EQUAL(status[0], CSR_hw_out.LTPI_Link_Status.aligned);
        `FAIL_UNLESS_EQUAL(status[1], CSR_hw_out.LTPI_Link_Status.link_lost_error);
        `FAIL_UNLESS_EQUAL(status[2], CSR_hw_out.LTPI_Link_Status.frm_CRC_error);
        `FAIL_UNLESS_EQUAL(status[3], CSR_hw_out.LTPI_Link_Status.unknown_comma_error);
        `FAIL_UNLESS_EQUAL(status[4], CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error);
        `FAIL_UNLESS_EQUAL(status[5], CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error);
        `FAIL_UNLESS_EQUAL(status[7], CSR_hw_out.LTPI_Link_Status.DDR_mode);
        `FAIL_UNLESS_EQUAL(status[11: 8], CSR_hw_out.LTPI_Link_Status.link_speed);
        `FAIL_UNLESS_EQUAL(status[15:12], CSR_hw_out.LTPI_Link_Status.remote_link_state);
        `FAIL_UNLESS_EQUAL(status[19:16], CSR_hw_out.LTPI_Link_Status.local_link_state);
    end
`SVTEST_END

`SVTEST(write_status_reg)
    logic [31:0] status;
    logic [15:0] addr_offset = 0;
    logic [31:0] data = '1;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_Link_Status.aligned                       = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.link_lost_error               = 1;
        CSR_hw_out.LTPI_Link_Status.frm_CRC_error                 = 1;
        CSR_hw_out.LTPI_Link_Status.unknown_comma_error           = 1;
        CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error      = 1;
        CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error   = 1;
        CSR_hw_out.LTPI_Link_Status.DDR_mode                      = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Link_Status.link_speed                    = $urandom_range(4'hF, 0);
        CSR_hw_out.LTPI_Link_Status.remote_link_state             = $urandom_range(4'hF, 0);
        CSR_hw_out.LTPI_Link_Status.local_link_state              = $urandom_range(4'hF, 0);

        avmm_read(BASE_ADDR + addr_offset, status);
        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_Link_Status.link_lost_error               <= CSR_hw_in.LTPI_Link_Status.link_lost_error;
                CSR_hw_out.LTPI_Link_Status.frm_CRC_error                 <= CSR_hw_in.LTPI_Link_Status.frm_CRC_error;
                CSR_hw_out.LTPI_Link_Status.unknown_comma_error           <= CSR_hw_in.LTPI_Link_Status.unknown_comma_error;
                CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error      <= CSR_hw_in.LTPI_Link_Status.link_speed_timeout_error;
                CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error   <= CSR_hw_in.LTPI_Link_Status.link_cfg_acpt_timeout_error;
            end
        join
        repeat(10)@(posedge clk_50MHz); 
        //RWC
        `FAIL_UNLESS_EQUAL(CSR_hw_in.LTPI_Link_Status.link_lost_error            , 0);
        `FAIL_UNLESS_EQUAL(CSR_hw_in.LTPI_Link_Status.frm_CRC_error              , 0);
        `FAIL_UNLESS_EQUAL(CSR_hw_in.LTPI_Link_Status.unknown_comma_error        , 0);
        `FAIL_UNLESS_EQUAL(CSR_hw_in.LTPI_Link_Status.link_speed_timeout_error   , 0);
        `FAIL_UNLESS_EQUAL(CSR_hw_in.LTPI_Link_Status.link_cfg_acpt_timeout_error, 0);

        repeat(10)@(posedge clk_50MHz); 
    end
`SVTEST_END

`SVTEST(read_detect_capab_local)
    logic [31:0] detect_capab_local;
    logic [15:0] addr_offset = 16'h04;
    int test_number = 32;

    repeat(test_number) begin
        avmm_read(BASE_ADDR + addr_offset, detect_capab_local);
        `FAIL_UNLESS_EQUAL(detect_capab_local[23:8], dut.rdl_base_hwout.LTPI_Detect_Capabilities_Local.link_Speed_capab.value)
        `FAIL_UNLESS_EQUAL(detect_capab_local[ 7:4], dut.rdl_base_hwout.LTPI_Detect_Capabilities_Local.local_Major_Revision.value);
        `FAIL_UNLESS_EQUAL(detect_capab_local[ 3:0], dut.rdl_base_hwout.LTPI_Detect_Capabilities_Local.local_Minor_Revision.value);
    end
`SVTEST_END

`SVTEST(write_detect_capab_local)
    logic [15:0] addr_offset = 16'h4;
    logic [ 1:0][ 7:0] Link_Speed_capab;
    logic [31:0] data_write = '0;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        Link_Speed_capab = $urandom_range(16'hFFFF, 0);
        data_write[23:8] = Link_Speed_capab;
        avmm_write(BASE_ADDR + addr_offset, data_write);
        repeat(10) @clk_50MHz;
        avmm_read(BASE_ADDR + addr_offset, data_read);
        `FAIL_UNLESS_EQUAL(data_write[23:8], data_read[23:8]);
        `FAIL_UNLESS_EQUAL(Link_Speed_capab, CSR_hw_in.LTPI_Detect_Capab_local.Link_Speed_capab);
    end
`SVTEST_END

`SVTEST(read_detect_capab_remote)
    logic [31:0] detect_capab_remote;
    logic [15:0] addr_offset = 16'h8;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_Detect_Capab_remote.LTPI_Version                  = $urandom_range(8'hFF, 0);
        CSR_hw_out.LTPI_Detect_Capab_remote.Link_Speed_capab              = $urandom_range(16'hFFFF, 0);
        
        avmm_read(BASE_ADDR + addr_offset, detect_capab_remote);

        `FAIL_UNLESS_EQUAL(detect_capab_remote[23:8], CSR_hw_out.LTPI_Detect_Capab_remote.Link_Speed_capab)
        `FAIL_UNLESS_EQUAL(detect_capab_remote[7:0], CSR_hw_out.LTPI_Detect_Capab_remote.LTPI_Version);
    end
`SVTEST_END

`SVTEST(read_platform_ID_local)
    logic [31:0] read_platform_ID_local;
    logic [15:0] addr_offset = 16'h0C;
    int test_number = 32;

    repeat(test_number) begin
        avmm_read(BASE_ADDR + addr_offset, read_platform_ID_local);

        `FAIL_UNLESS_EQUAL(read_platform_ID_local[ 15:0], dut.rdl_base_hwout.LTPI_platform_ID_local.platform_ID_local.value);
    end
`SVTEST_END

`SVTEST(read_platform_ID_remote)
    logic [31:0] platform_ID_remote;
    logic [15:0] addr_offset = 16'h10;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_platform_ID_remote.ID = $urandom_range(16'hFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, platform_ID_remote);
        `FAIL_UNLESS_EQUAL(platform_ID_remote[15:0], CSR_hw_out.LTPI_platform_ID_remote.ID);
    end
`SVTEST_END

`SVTEST(write_read_LTPI_Advertise_Capab_local_LOW)
    logic [15:0] addr_offset = 16'h14;

    logic [ 4:0] supported_channel;
    logic [ 9:0] NL_GPIO_nb;
    logic [ 5:0] I2C_channel_en;
    logic        I2C_Echo_support;

    logic [31:0] data_write = '0;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        avmm_read(BASE_ADDR + addr_offset, data_read);
        supported_channel   = $urandom_range(5'h1F, 0);
        NL_GPIO_nb          = $urandom_range(10'h3FF, 0);
        I2C_channel_en      = $urandom_range(6'h3F, 0);
        I2C_Echo_support    = $urandom_range(1'b1, 0);

        data_write[4:0] = supported_channel;
        data_write[17:8] = NL_GPIO_nb;
        data_write[29:24] = I2C_channel_en;
        data_write[30:30] = I2C_Echo_support;

        avmm_write(BASE_ADDR + addr_offset, data_write);
        repeat(10) @clk_50MHz;
        avmm_read(BASE_ADDR + addr_offset, data_read);

        `FAIL_UNLESS_EQUAL(data_read, data_write);
        `FAIL_UNLESS_EQUAL(supported_channel, CSR_hw_in.LTPI_Advertise_Capab_local.supported_channel);
        `FAIL_UNLESS_EQUAL(NL_GPIO_nb, CSR_hw_in.LTPI_Advertise_Capab_local.NL_GPIO_nb);
        `FAIL_UNLESS_EQUAL(I2C_channel_en, CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_en);
        `FAIL_UNLESS_EQUAL(I2C_Echo_support, CSR_hw_in.LTPI_Advertise_Capab_local.I2C_Echo_support);
    end
`SVTEST_END

`SVTEST(write_read_LTPI_Advertise_Capab_local_HIGH)
    logic [15:0] addr_offset = 16'h18;

    logic [5:0]  I2C_channel_cpbl;
    logic [1:0]  UART_channel_en;
    logic        UART_Flow_ctrl;
    logic [3:0]  UART_channel_cpbl;
    logic [15:0] OEM_cpbl;

    logic [31:0] data_write = '0;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        avmm_read(BASE_ADDR + addr_offset, data_read);

        I2C_channel_cpbl    = $urandom_range(6'h3F, 0);
        UART_channel_cpbl   = $urandom_range(4'hF, 0);
        UART_Flow_ctrl      = $urandom_range(1'h1, 0);
        UART_channel_en     = $urandom_range(2'h3, 0);
        OEM_cpbl            = $urandom_range(16'hFFFF, 0);

        data_write[5:0]     = I2C_channel_cpbl;
        data_write[11:8]    = UART_channel_cpbl;
        data_write[12]      = UART_Flow_ctrl;
        data_write[14:13]   = UART_channel_en;
        data_write[31:16]   = OEM_cpbl;

        avmm_write(BASE_ADDR + addr_offset, data_write);
        repeat(10) @clk_50MHz;
        avmm_read(BASE_ADDR + addr_offset, data_read);

        `FAIL_UNLESS_EQUAL(data_read, data_write); 
        `FAIL_UNLESS_EQUAL(I2C_channel_cpbl, CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_cpbl);
        `FAIL_UNLESS_EQUAL(UART_channel_cpbl, CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_cpbl);
        `FAIL_UNLESS_EQUAL(UART_Flow_ctrl, CSR_hw_in.LTPI_Advertise_Capab_local.UART_Flow_ctrl);
        `FAIL_UNLESS_EQUAL(UART_channel_en, CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_en);
        `FAIL_UNLESS_EQUAL(OEM_cpbl[15:8], CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte1);
        `FAIL_UNLESS_EQUAL(OEM_cpbl[7:0], CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte0);
    end
`SVTEST_END

`SVTEST(read_Advertise_Capab_remote_LOW)
    logic [31:0] Advertise_Capab_remote_LOW;
    logic [15:0] addr_offset = 16'h1C;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_Advertise_Capab_remote.supported_channel        = $urandom_range(5'h1F, 0);
        CSR_hw_out.LTPI_Advertise_Capab_remote.NL_GPIO_nb               = $urandom_range(10'h3FF, 0);
        CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_Echo_support         = $urandom_range(1, 0);
        CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_en           = $urandom_range(6'h3F, 0);

        avmm_read(BASE_ADDR + addr_offset, Advertise_Capab_remote_LOW);

        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_LOW[4:0], CSR_hw_out.LTPI_Advertise_Capab_remote.supported_channel);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_LOW[17:8], CSR_hw_out.LTPI_Advertise_Capab_remote.NL_GPIO_nb);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_LOW[29:24], CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_en);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_LOW[30:30], CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_Echo_support);
    end
`SVTEST_END


`SVTEST(read_Advertise_Capab_remote_HIGH)
    logic [31:0] Advertise_Capab_remote_HIGH;
    logic [15:0] addr_offset = 16'h20;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_cpbl     = $urandom_range(6'h3F, 0);
        CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_en      = $urandom_range(2'h3, 0);
        CSR_hw_out.LTPI_Advertise_Capab_remote.UART_Flow_ctrl       = $urandom_range(1'h1, 0);
        CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_cpbl    = $urandom_range(4'hF, 0);
        CSR_hw_out.LTPI_Advertise_Capab_remote.OEM_cpbl             = $urandom_range(16'hFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, Advertise_Capab_remote_HIGH);

        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_HIGH[5:0], CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_cpbl);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_HIGH[11:8], CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_cpbl);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_HIGH[12], CSR_hw_out.LTPI_Advertise_Capab_remote.UART_Flow_ctrl);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_HIGH[14:13], CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_en);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_HIGH[23:16], CSR_hw_out.LTPI_Advertise_Capab_remote.OEM_cpbl.byte0);
        `FAIL_UNLESS_EQUAL(Advertise_Capab_remote_HIGH[31:24], CSR_hw_out.LTPI_Advertise_Capab_remote.OEM_cpbl.byte1);
    end
`SVTEST_END

`SVTEST(read_Config_Capab_LOW)
    logic [31:0] Config_Capab_LOW;
    logic [15:0] addr_offset = 16'h24;
    int test_number = 32;

    repeat(test_number) begin
        avmm_read(BASE_ADDR + addr_offset, Config_Capab_LOW);

        `FAIL_UNLESS_EQUAL(Config_Capab_LOW[4:0], dut.rdl_base_hwout.LTPI_Config_Capab_LOW.supported_channel.value);
        `FAIL_UNLESS_EQUAL(Config_Capab_LOW[17:8], dut.rdl_base_hwout.LTPI_Config_Capab_LOW.NL_GPIO_nb.value);
        `FAIL_UNLESS_EQUAL(Config_Capab_LOW[29:24], dut.rdl_base_hwout.LTPI_Config_Capab_LOW.I2C_channel_en.value);
        `FAIL_UNLESS_EQUAL(Config_Capab_LOW[30:30], dut.rdl_base_hwout.LTPI_Config_Capab_LOW.I2C_channel_echo_support.value);
    end
`SVTEST_END

`SVTEST(read_Config_Capab_HIGH)
    logic [31:0] read_Config_Capab_HIGH;
    logic [15:0] addr_offset = 16'h28;
    int test_number = 32;

    repeat(test_number) begin
        avmm_read(BASE_ADDR + addr_offset, read_Config_Capab_HIGH);

        `FAIL_UNLESS_EQUAL(read_Config_Capab_HIGH[5:0], dut.rdl_base_hwout.LTPI_Config_Capab_HIGH.I2C_channel_speed.value);
        `FAIL_UNLESS_EQUAL(read_Config_Capab_HIGH[14:8], dut.rdl_base_hwout.LTPI_Config_Capab_HIGH.UART_channel_cpbl.value);
        `FAIL_UNLESS_EQUAL(read_Config_Capab_HIGH[31:16], dut.rdl_base_hwout.LTPI_Config_Capab_HIGH.OEM_capab.value);
    end
`SVTEST_END

`SVTEST(read_link_aligment_err_cnt)
    logic [31:0] link_aligment_err_cnt;
    logic [15:0] addr_offset = 16'h2c;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_aligment_err_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, link_aligment_err_cnt);
        `FAIL_UNLESS_EQUAL(link_aligment_err_cnt, CSR_hw_out.LTPI_counter.link_aligment_err_cnt);
    end
`SVTEST_END

`SVTEST(write_link_aligment_err_cnt)
    logic [15:0] addr_offset = 16'h2c;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_aligment_err_cnt = $urandom_range(32'hFFFFFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);

        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.link_aligment_err_cnt <= CSR_hw_in.LTPI_counter.link_aligment_err_cnt;
            end
        join
        repeat(10) @clk_50MHz;
        $display("CSR_hw_in.LTPI_counter.link_aligment_err_cnt %h", CSR_hw_in.LTPI_counter.link_aligment_err_cnt);
        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.link_aligment_err_cnt);
    end
`SVTEST_END

`SVTEST(read_link_lost_err_cnt)
    logic [31:0] link_lost_err_cnt;
    logic [15:0] addr_offset = 16'h30;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_lost_err_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, link_lost_err_cnt);
        `FAIL_UNLESS_EQUAL(link_lost_err_cnt, CSR_hw_out.LTPI_counter.link_lost_err_cnt);
    end
`SVTEST_END

`SVTEST(write_link_lost_err_cnt)
    logic [15:0] addr_offset = 16'h30;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_lost_err_cnt = $urandom_range(32'hFFFFFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);

        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.link_lost_err_cnt <= CSR_hw_in.LTPI_counter.link_lost_err_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.link_lost_err_cnt);
    end
`SVTEST_END

`SVTEST(read_link_crc_err_cnt)
    logic [31:0] link_crc_err_cnt;
    logic [15:0] addr_offset = 16'h34;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_crc_err_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, link_crc_err_cnt);
        `FAIL_UNLESS_EQUAL(link_crc_err_cnt, CSR_hw_out.LTPI_counter.link_crc_err_cnt);
    end
`SVTEST_END

`SVTEST(write_link_crc_err_cnt)
    logic [15:0] addr_offset = 16'h34;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_crc_err_cnt = $urandom_range(32'hFFFFFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);

        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.link_crc_err_cnt <= CSR_hw_in.LTPI_counter.link_crc_err_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.link_crc_err_cnt);
    end
`SVTEST_END

`SVTEST(read_unknown_comma_err_cnt)
    logic [31:0] unknown_comma_err_cnt;
    logic [15:0] addr_offset = 16'h38;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.unknown_comma_err_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, unknown_comma_err_cnt);
        `FAIL_UNLESS_EQUAL(unknown_comma_err_cnt, CSR_hw_out.LTPI_counter.unknown_comma_err_cnt);
    end
`SVTEST_END

`SVTEST(write_unknown_comma_err_cnt)
    logic [15:0] addr_offset = 16'h38;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.unknown_comma_err_cnt = $urandom_range(32'hFFFFFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);

        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.unknown_comma_err_cnt <= CSR_hw_in.LTPI_counter.unknown_comma_err_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.unknown_comma_err_cnt);
    end
`SVTEST_END

`SVTEST(read_link_speed_timeout_err_cnt)
    logic [31:0] link_speed_timeout_err_cnt;
    logic [15:0] addr_offset = 16'h3c;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, link_speed_timeout_err_cnt);
        `FAIL_UNLESS_EQUAL(link_speed_timeout_err_cnt, CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt);
    end
`SVTEST_END

`SVTEST(write_link_speed_timeout_err_cnt)
    logic [15:0] addr_offset = 16'h3c;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt = $urandom_range(32'hFFFFFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);
        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt <= CSR_hw_in.LTPI_counter.link_speed_timeout_err_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.link_speed_timeout_err_cnt);
    end
`SVTEST_END

`SVTEST(read_link_cfg_acpt_timeout_err_cnt)
    logic [31:0] link_cfg_acpt_timeout_err_cnt;
    logic [15:0] addr_offset = 16'h40;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, link_cfg_acpt_timeout_err_cnt);
        `FAIL_UNLESS_EQUAL(link_cfg_acpt_timeout_err_cnt, CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt);
    end
`SVTEST_END

`SVTEST(write_link_cfg_acpt_timeout_err_cnt)
    logic [15:0] addr_offset = 16'h40;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt = $urandom_range(32'hFFFFFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);

        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt <= CSR_hw_in.LTPI_counter.link_cfg_acpt_timeout_err_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.link_cfg_acpt_timeout_err_cnt);
    end
`SVTEST_END

`SVTEST(read_linkig_training_frm_rcv_cnt_low)
    logic [31:0] linkig_training_frm_rcv_cnt_low;
    logic [15:0] addr_offset = 16'h44;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt     = $urandom_range(16'hFFFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt      = $urandom_range(8'hFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt   = $urandom_range(8'hFF, 0);

        avmm_read(BASE_ADDR + addr_offset, linkig_training_frm_rcv_cnt_low);

        `FAIL_UNLESS_EQUAL(linkig_training_frm_rcv_cnt_low[15:0], CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt);
        `FAIL_UNLESS_EQUAL(linkig_training_frm_rcv_cnt_low[23:16], CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt);
        `FAIL_UNLESS_EQUAL(linkig_training_frm_rcv_cnt_low[31:24], CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt);
    end
`SVTEST_END

`SVTEST(write_linkig_training_frm_rcv_cnt_low)
    logic [15:0] addr_offset = 16'h44;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt   = $urandom_range(16'hFFFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt    = $urandom_range(8'hFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt = $urandom_range(8'hFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);

        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt   <= CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt;
                CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt    <= CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt;
                CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt <= CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt);
        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt);
        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt);
    end
`SVTEST_END

`SVTEST(read_linkig_training_frm_rcv_cnt_high)
    logic [31:0] linkig_training_frm_rcv_cnt_high;
    logic [15:0] addr_offset = 16'h48;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt = $urandom_range(32'hFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, linkig_training_frm_rcv_cnt_high);
        `FAIL_UNLESS_EQUAL(linkig_training_frm_rcv_cnt_high, CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt);
    end
`SVTEST_END

`SVTEST(write_linkig_training_frm_rcv_cnt_high)
    logic [15:0] addr_offset = 16'h48;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, data_read);
        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt  <= CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt);
    end
`SVTEST_END

`SVTEST(read_linkig_training_frm_snt_cnt_low)
    logic [31:0] linkig_training_frm_snt_cnt_low;
    logic [15:0] addr_offset = 16'h4c;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt     = $urandom_range(16'hFFFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt      = $urandom_range(8'hFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt   = $urandom_range(8'hFF, 0);

        avmm_read(BASE_ADDR + addr_offset, linkig_training_frm_snt_cnt_low);

        `FAIL_UNLESS_EQUAL(linkig_training_frm_snt_cnt_low[15:0], CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt);
        `FAIL_UNLESS_EQUAL(linkig_training_frm_snt_cnt_low[23:16], CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt);
        `FAIL_UNLESS_EQUAL(linkig_training_frm_snt_cnt_low[31:24], CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt);
    end
`SVTEST_END

`SVTEST(write_linkig_training_frm_snt_cnt_low)
    logic [15:0] addr_offset = 16'h4C;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt   = $urandom_range(16'hFFFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt    = $urandom_range(8'hFF, 0);
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt = $urandom_range(8'hFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);
        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt   <= CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt;
                CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt    <= CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt;
                CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt <= CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt);
        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt);
        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt);
    end
`SVTEST_END

`SVTEST(read_linkig_training_frm_snt_cnt_high)
    logic [31:0] linkig_training_frm_snt_cnt_high;
    logic [15:0] addr_offset = 16'h50;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, linkig_training_frm_snt_cnt_high);
        `FAIL_UNLESS_EQUAL(linkig_training_frm_snt_cnt_high, CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt);
    end
`SVTEST_END

`SVTEST(write_linkig_training_frm_snt_cnt_high)
    logic [15:0] addr_offset = 16'h50;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, data_read);

        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt  <= CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt);
    end
`SVTEST_END

`SVTEST(read_operational_frm_rcv_cnt)
    logic [31:0] operational_frm_rcv_cnt;
    logic [15:0] addr_offset = 16'h54;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, operational_frm_rcv_cnt);
        `FAIL_UNLESS_EQUAL(operational_frm_rcv_cnt, CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt);
    end
`SVTEST_END

`SVTEST(write_operational_frm_rcv_cnt)
    logic [15:0] addr_offset = 16'h54;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, data_read);
        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt  <= CSR_hw_in.LTPI_counter.operational_frm_rcv_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.operational_frm_rcv_cnt);
    end
`SVTEST_END

`SVTEST(read_operational_frm_snt_cnt)
    logic [31:0] operational_frm_snt_cnt;
    logic [15:0] addr_offset = 16'h58;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.operational_frm_snt_cnt = $urandom_range(32'hFFFFFFFF, 0);
        avmm_read(BASE_ADDR + addr_offset, operational_frm_snt_cnt);
        `FAIL_UNLESS_EQUAL(operational_frm_snt_cnt, CSR_hw_out.LTPI_counter.operational_frm_snt_cnt);
    end
`SVTEST_END

`SVTEST(write_operational_frm_snt_cnt)
    logic [15:0] addr_offset = 16'h58;
    logic [31:0] data_read = '0;
    int test_number = 32;

    repeat(test_number) begin
        CSR_hw_out.LTPI_counter.operational_frm_snt_cnt = $urandom_range(32'hFFFFFFFF, 0);

        avmm_read(BASE_ADDR + addr_offset, data_read);
        fork 
            begin
                avmm_write(BASE_ADDR + addr_offset, '1);
            end
            begin
                wait(CSR_hw_in.clear_reg);
                CSR_hw_out.LTPI_counter.operational_frm_snt_cnt  <= CSR_hw_in.LTPI_counter.operational_frm_snt_cnt;
            end
        join
        repeat(10) @clk_50MHz;

        `FAIL_UNLESS_EQUAL(0, CSR_hw_in.LTPI_counter.operational_frm_snt_cnt);
    end

`SVTEST_END

`SVTEST(write_read_LTPI_Link_Ctrl)
    logic [15:0] addr_offset = 16'h80;
    logic software_reset;
    logic retraining_request;
    logic [5:0] I2C_channel_reset;
    logic data_channel_reset;
    logic auto_move_config;
    logic trigger_config_st;
    logic [31:0] data_write = '0;
    logic [31:0] data_read = '0;
    int test_number = 32;
    
    repeat(test_number) begin
        software_reset      = $urandom_range(1, 0);
        retraining_request  = $urandom_range(1, 0);
        I2C_channel_reset   = $urandom_range(6'h3f, 0);
        data_channel_reset  = $urandom_range(1, 0);
        auto_move_config    = $urandom_range(1, 0);
        trigger_config_st   = $urandom_range(1, 0);

        data_write[0] = software_reset;
        data_write[1] = retraining_request;
        data_write[8:2] = I2C_channel_reset;
        data_write[9] = data_channel_reset;
        data_write[10] = auto_move_config;
        data_write[11] = trigger_config_st;

        avmm_write(BASE_ADDR + addr_offset, data_write);

        repeat(10) @clk_50MHz;

        avmm_read(BASE_ADDR + addr_offset, data_read);

        `FAIL_UNLESS_EQUAL(data_read, data_write);
        `FAIL_UNLESS_EQUAL(software_reset, CSR_hw_in.LTPI_Link_Ctrl.software_reset);
        `FAIL_UNLESS_EQUAL(retraining_request, CSR_hw_in.LTPI_Link_Ctrl.retraining_request);
        `FAIL_UNLESS_EQUAL(I2C_channel_reset, CSR_hw_in.LTPI_Link_Ctrl.I2C_channel_reset);
        `FAIL_UNLESS_EQUAL(data_channel_reset, CSR_hw_in.LTPI_Link_Ctrl.data_channel_reset);
        `FAIL_UNLESS_EQUAL(auto_move_config, CSR_hw_in.LTPI_Link_Ctrl.auto_move_config);
        `FAIL_UNLESS_EQUAL(trigger_config_st, CSR_hw_in.LTPI_Link_Ctrl.trigger_config_st);
    end

`SVTEST_END
    
`SVUNIT_TESTS_END

endmodule