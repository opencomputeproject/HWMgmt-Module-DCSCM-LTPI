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

`ifndef LOGIC_SVH
`define LOGIC_SVH

`ifdef SYNTHESIS
    `ifdef OVL_ASSERT_ON
        `undef OVL_ASSERT_ON
    `endif
`elsif VERILATOR
    /* Define: SYNTHESIS
     *
     * Enable only synthesizable parts of HDL.
     */
    `define SYNTHESIS
`endif

`include "logic_drc.svh"
`include "logic_modport.svh"
`include "logic_axi4_mm.svh"
`include "logic_axi4_lite.svh"
`include "logic_axi4_stream.svh"
`include "logic_avalon_mm.svh"
`include "logic_avalon_st.svh"

`ifdef OVL_ASSERT_ON
`define OVL_VERILOG
`define OVL_SVA_INTERFACE
`include "std_ovl_defines.h"
`endif

`endif /* LOGIC_SVH */
