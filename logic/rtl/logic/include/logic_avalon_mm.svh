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

`ifndef LOGIC_AVALON_MM_SVH
`define LOGIC_AVALON_MM_SVH

/* Define: LOGIC_AVALON_MM_IF_ASSIGN
 *
 * Assign SystemVerilog interface to another SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - SystemVerilog interface.
 */
`define LOGIC_AVALON_MM_IF_ASSIGN(lhs, rhs) \
    always_comb lhs``.read = rhs``.read; \
    always_comb lhs``.write = rhs``.write; \
    always_comb lhs``.address = rhs``.address; \
    always_comb lhs``.writedata = rhs``.writedata; \
    always_comb lhs``.byteenable = rhs``.byteenable; \
    always_comb rhs``.response = lhs``.response; \
    always_comb rhs``.readdata = lhs``.readdata; \
    always_comb rhs``.waitrequest = lhs``.waitrequest; \
    always_comb rhs``.readdatavalid = lhs``.readdatavalid; \
    always_comb rhs``.writeresponsevalid = lhs``.writeresponsevalid

/* Define: LOGIC_AVALON_MM_IF_SLAVE_ASSIGN
 *
 * Assign standalone signals to signals in SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - Standalone SystemVerilog signals.
 */
`define LOGIC_AVALON_MM_IF_SLAVE_ASSIGN(lhs, rhs) \
    always_comb lhs``.read = rhs``_read; \
    always_comb lhs``.write = rhs``_write; \
    always_comb lhs``.address = rhs``_address; \
    always_comb lhs``.writedata = rhs``_writedata; \
    always_comb lhs``.byteenable = rhs``_byteenable; \
    always_comb rhs``_response = lhs``.response; \
    always_comb rhs``_readdata = lhs``.readdata; \
    always_comb rhs``_waitrequest = lhs``.waitrequest; \
    always_comb rhs``_readdatavalid = lhs``.readdatavalid; \
    always_comb rhs``_writeresponsevalid = lhs``.writeresponsevalid

/* Define: LOGIC_AVALON_MM_IF_MASTER_ASSIGN
 *
 * Assign signals in SystemVerilog interface to standalone signals.
 *
 * Parameters:
 *  lhs       - Standalone SystemVerilog signals.
 *  rhs       - SystemVerilog interface.
 */
`define LOGIC_AVALON_MM_IF_MASTER_ASSIGN(lhs, rhs) \
    always_comb lhs``_read = rhs``.read; \
    always_comb lhs``_write = rhs``.write; \
    always_comb lhs``_address = rhs``.address; \
    always_comb lhs``_writedata = rhs``.writedata; \
    always_comb lhs``_byteenable = rhs``.byteenable; \
    always_comb rhs``.response = lhs``_response; \
    always_comb rhs``.readdata = lhs``_readdata; \
    always_comb rhs``.waitrequest = lhs``_waitrequest; \
    always_comb rhs``.readdatavalid = lhs``_readdatavalid; \
    always_comb rhs``.writeresponsevalid = lhs``_writeresponsevalid

`endif /* LOGIC_AVALON_MM_SVH */
