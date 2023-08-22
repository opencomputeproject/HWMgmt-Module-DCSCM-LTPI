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

`ifndef LOGIC_AXI4_STREAM_SVH
`define LOGIC_AXI4_STREAM_SVH

/* Define: LOGIC_AXI4_STREAM_IF_ASSIGN
 *
 * Assign SystemVerilog interface to another SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - SystemVerilog interface.
 */
`define LOGIC_AXI4_STREAM_IF_ASSIGN(lhs, rhs) \
    always_comb lhs``.tvalid = rhs``.tvalid; \
    always_comb lhs``.tlast = rhs``.tlast; \
    always_comb lhs``.tdata = rhs``.tdata; \
    always_comb lhs``.tstrb = rhs``.tstrb; \
    always_comb lhs``.tkeep = rhs``.tkeep; \
    always_comb lhs``.tdest = rhs``.tdest; \
    always_comb lhs``.tuser = rhs``.tuser; \
    always_comb lhs``.tid = rhs``.tid; \
    always_comb rhs``.tready = lhs``.tready

/* Define: LOGIC_AXI4_STREAM_IF_RX_ASSIGN
 *
 * Assign standalone signals to signals in SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - Standalone SystemVerilog signals.
 */
`define LOGIC_AXI4_STREAM_IF_RX_ASSIGN(lhs, rhs) \
    always_comb lhs``.tvalid = rhs``_tvalid; \
    always_comb lhs``.tlast = rhs``_tlast; \
    always_comb lhs``.tdata = rhs``_tdata; \
    always_comb lhs``.tstrb = rhs``_tstrb; \
    always_comb lhs``.tkeep = rhs``_tkeep; \
    always_comb lhs``.tdest = rhs``_tdest; \
    always_comb lhs``.tuser = rhs``_tuser; \
    always_comb lhs``.tid = rhs``_tid; \
    always_comb rhs``_tready = lhs``.tready

/* Define: LOGIC_AXI4_STREAM_IF_TX_ASSIGN
 *
 * Assign signals in SystemVerilog interface to standalone signals.
 *
 * Parameters:
 *  lhs       - Standalone SystemVerilog signals.
 *  rhs       - SystemVerilog interface.
 */
`define LOGIC_AXI4_STREAM_IF_TX_ASSIGN(lhs, rhs) \
    always_comb lhs``_tvalid = rhs``.tvalid; \
    always_comb lhs``_tlast = rhs``.tlast; \
    always_comb lhs``_tdata = rhs``.tdata; \
    always_comb lhs``_tstrb = rhs``.tstrb; \
    always_comb lhs``_tkeep = rhs``.tkeep; \
    always_comb lhs``_tdest = rhs``.tdest; \
    always_comb lhs``_tuser = rhs``.tuser; \
    always_comb lhs``_tid = rhs``.tid; \
    always_comb rhs``.tready = lhs``_tready

`endif /* LOGIC_AXI4_STREAM_SVH */
