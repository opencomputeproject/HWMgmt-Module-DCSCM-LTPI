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

// -------------------------------------------------------------------
// -- Author        : Katarzyna Krzewska
// -- Date          : 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Data channel target FIFO
// -------------------------------------------------------------------

module ltpi_data_channel_target_fifo #(
    parameter REQ_WIDTH     = 32,
    parameter REQ_DEPTH     = 32,
    parameter RESP_WIDTH    = 32,
    parameter RESP_DEPTH    = 32
)
(
    input                           clk,
    input                           reset,

    input        [REQ_WIDTH-1:0]    req_wr_data,
    input                           req_wr_req,
    output       [REQ_WIDTH-1:0]    req_rd_data,
    input                           req_rd_req,
    output logic                    req_empty,
    output logic                    req_full,

    input        [RESP_WIDTH-1:0]   resp_wr_data,
    input                           resp_wr_req,
    output       [RESP_WIDTH-1:0]   resp_rd_data,
    input                           resp_rd_req,
    output logic                    resp_empty,
    output logic                    resp_full
);

scfifo #(
    .lpm_width(REQ_WIDTH),
    .lpm_numwords(REQ_DEPTH)
)
req_fifo(
    .clock(clk),

    .data       (req_wr_data),
    .q          (req_rd_data),
    .empty      (req_empty),
    .full       (req_full),
    .wrreq      (req_wr_req),
    .rdreq      (req_rd_req)
);

scfifo #(
    .lpm_width(RESP_WIDTH),
    .lpm_numwords(RESP_DEPTH)
)
resp_fifo(
    .clock(clk),

    .data       (resp_wr_data),
    .q          (resp_rd_data),
    .empty      (resp_empty),
    .full       (resp_full),
    .wrreq      (resp_wr_req),
    .rdreq      (resp_rd_req)
);

endmodule