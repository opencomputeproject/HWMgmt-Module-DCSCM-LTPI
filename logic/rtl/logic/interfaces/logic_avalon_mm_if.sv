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

`include "logic.svh"

/* Interface: logic_avalon_mm_if
 *
 * Avalon-MM interface.
 *
 * Parameters:
 *  DATA_BYTES      - Number of bytes for writedata and readdata signals.
 *  ADDRESS_WIDTH   - Number of bits for address signal.
 *
 * Ports:
 *  clk         - Clock. Used only for internal checkers and assertions
 *  reset_n     - Asynchronous active-low reset. Used only for internal checkers
 *                and assertions
 */
interface logic_avalon_mm_if #(
    int DATA_BYTES      = 8,
    int ADDRESS_WIDTH   = 32,
    int BURST_WIDTH     = 11
) (
    input                           aclk,
    input                           areset_n
);

    initial begin: design_rule_checks
        `LOGIC_DRC_RANGE(ADDRESS_WIDTH, 1, 64)
        `LOGIC_DRC_RANGE(DATA_BYTES, 1, 128)
        `LOGIC_DRC_POWER_OF_2(DATA_BYTES)
    end

    // Standard signals
    logic [ADDRESS_WIDTH-1:0]      address;
    logic [   DATA_BYTES-1:0]      byteenable;
    logic                          write;
    logic [   DATA_BYTES-1:0][7:0] writedata;
    logic                          writeresponsevalid;
    logic [              1:0]      response;
    logic                          read;
    logic [   DATA_BYTES-1:0][7:0] readdata;
    logic                          waitrequest;
    logic                          readdatavalid;

    // Burst signals
    logic [ BURST_WIDTH-1:0]       burstcount;
    logic                          beginbursttransfer;

    // Other signals
    logic                          chipselect;
    logic                          debugaccess;
    logic                          lock;
 
`ifndef LOGIC_MODPORT_DISABLED
    modport slave (
        input  read,
        input  write,
        input  address,
        input  writedata,
        input  byteenable,
        output response,
        output readdata,
        output waitrequest,
        output readdatavalid,
        output writeresponsevalid,
        input  burstcount,
        input  beginbursttransfer,
        input  chipselect,
        input  debugaccess,
        input  lock
    );

    modport master (
        output read,
        output write,
        output address,
        output writedata,
        output byteenable,
        input  response,
        input  readdata,
        input  waitrequest,
        input  readdatavalid,
        input  writeresponsevalid,
        output burstcount,
        output beginbursttransfer,
        output chipselect,
        output debugaccess,
        output lock
    );

    modport monitor (
        input read,
        input write,
        input address,
        input writedata,
        input byteenable,
        input response,
        input readdata,
        input waitrequest,
        input readdatavalid,
        input writeresponsevalid,
        input burstcount,
        input beginbursttransfer,
        input chipselect,
        input debugaccess,
        input lock
    );
`endif

`ifndef SYNTHESIS
    clocking cb_slave @(posedge aclk);
        output read;
        output write;
        output address;
        output writedata;
        output byteenable;
        input  response;
        input  readdata;
        input  waitrequest;
        input  readdatavalid;
        input  writeresponsevalid;
        output burstcount;
        output beginbursttransfer;
        output chipselect;
        output debugaccess;
        output lock;
    endclocking

    modport cb_slave_modport (
        input       areset_n,
        clocking    cb_slave
    );

    clocking cb_master @(posedge aclk);
        input  read;
        input  write;
        input  address;
        input  writedata;
        input  byteenable;
        output response;
        output readdata;
        output waitrequest;
        output readdatavalid;
        output writeresponsevalid;
        input  burstcount;
        input  beginbursttransfer;
        input  chipselect;
        input  debugaccess;
        input  lock;
    endclocking

    modport cb_master_modport (
        input       areset_n,
        clocking    cb_master
    );

    clocking cb_monitor @(posedge aclk);
        input read;
        input write;
        input address;
        input writedata;
        input byteenable;
        input response;
        input readdata;
        input waitrequest;
        input readdatavalid;
        input writeresponsevalid;
        input burstcount;
        input beginbursttransfer;
        input chipselect;
        input debugaccess;
        input lock;
    endclocking

    modport cb_monitor_modport (
        input       areset_n,
        clocking    cb_monitor
    );
`endif

`ifdef VERILATOR
    logic _unused_ports = &{1'b0, aclk, areset_n, 1'b0};
`endif

endinterface