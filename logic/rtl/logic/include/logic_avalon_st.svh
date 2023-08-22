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

`ifndef LOGIC_AVALON_ST_SVH
`define LOGIC_AVALON_ST_SVH

/* Define: LOGIC_AVALON_ST_IF_ASSIGN
 *
 * Assign SystemVerilog interface to another SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - SystemVerilog interface.
 */
`define LOGIC_AVALON_ST_IF_ASSIGN(lhs, rhs) \
    always_comb lhs``.valid = rhs``.valid; \
    always_comb lhs``.startofpacket = rhs``.startofpacket; \
    always_comb lhs``.endofpacket = rhs``.endofpacket; \
    always_comb lhs``.data = rhs``.data; \
    always_comb lhs``.empty = rhs``.empty; \
    always_comb lhs``.error = rhs``.error; \
    always_comb lhs``.channel = rhs``.channel; \
    always_comb rhs``.ready = lhs``.ready

/* Define: LOGIC_AVALON_ST_IF_RX_ASSIGN
 *
 * Assign standalone signals to signals in SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - Standalone SystemVerilog signals.
 */
`define LOGIC_AVALON_ST_IF_RX_ASSIGN(lhs, rhs) \
    always_comb lhs``.valid = rhs``_valid; \
    always_comb lhs``.startofpacket = rhs``_startofpacket; \
    always_comb lhs``.endofpacket = rhs``_endofpacket; \
    always_comb lhs``.data = rhs``_data; \
    always_comb lhs``.empty = rhs``_empty; \
    always_comb lhs``.error = rhs``_error; \
    always_comb lhs``.channel = rhs``_channel; \
    always_comb rhs``_ready = lhs``.ready

/* Define: LOGIC_AVALON_ST_IF_TX_ASSIGN
 *
 * Assign signals in SystemVerilog interface to standalone signals.
 *
 * Parameters:
 *  lhs       - Standalone SystemVerilog signals.
 *  rhs       - SystemVerilog interface.
 */
`define LOGIC_AVALON_ST_IF_TX_ASSIGN(lhs, rhs) \
    always_comb lhs``_valid = rhs``.valid; \
    always_comb lhs``_startofpacket = rhs``.startofpacket; \
    always_comb lhs``_endofpacket = rhs``.endofpacket; \
    always_comb lhs``_data = rhs``.data; \
    always_comb lhs``_empty = rhs``.empty; \
    always_comb lhs``_error = rhs``.error; \
    always_comb lhs``_channel = rhs``.channel; \
    always_comb rhs``.ready = lhs``_ready

`endif /* LOGIC_AVALON_ST_SVH */
