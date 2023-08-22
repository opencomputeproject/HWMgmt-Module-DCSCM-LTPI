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

`ifndef LOGIC_AXI4_MM_SVH
`define LOGIC_AXI4_MM_SVH

/* Define: LOGIC_AXI4_MM_IF_ASSIGN
 *
 * Assign SystemVerilog interface to another SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - SystemVerilog interface.
 */

`define LOGIC_AXI4_MM_IF_ASSIGN(lhs, rhs)         \
    always_comb lhs``.awid      = rhs``.awid;       \
    always_comb lhs``.awaddr    = rhs``.awaddr;     \
    always_comb lhs``.awlen     = rhs``.awlen;      \
    always_comb lhs``.awsize    = rhs``.awsize;     \
    always_comb lhs``.awburst   = rhs``.awburst;    \
    always_comb lhs``.awlock    = rhs``.awlock;     \
    always_comb lhs``.awcache   = rhs``.awcache;    \
    always_comb lhs``.awprot    = rhs``.awprot;     \
    always_comb lhs``.awqos     = rhs``.awqos;      \
    always_comb lhs``.awregion  = rhs``.awregion;   \
    always_comb lhs``.awuser    = rhs``.awuser;     \
    always_comb lhs``.awvalid   = rhs``.awvalid;    \
    always_comb rhs``.awready   = lhs``.awready;    \
    always_comb lhs``.wid       = rhs``.wid;        \
    always_comb lhs``.wdata     = rhs``.wdata;      \
    always_comb lhs``.wstrb     = rhs``.wstrb;      \
    always_comb lhs``.wlast     = rhs``.wlast;      \
    always_comb lhs``.wuser     = rhs``.wuser;      \
    always_comb lhs``.wvalid    = rhs``.wvalid;     \
    always_comb rhs``.wready    = lhs``.wready;     \
    always_comb rhs``.bid       = lhs``.bid;        \
    always_comb rhs``.bresp     = lhs``.bresp;      \
    always_comb rhs``.buser     = lhs``.buser;      \
    always_comb rhs``.bvalid    = lhs``.bvalid;     \
    always_comb lhs``.bready    = rhs``.bready;     \
    always_comb lhs``.arid      = rhs``.arid;       \
    always_comb lhs``.araddr    = rhs``.araddr;     \
    always_comb lhs``.arlen     = rhs``.arlen;      \
    always_comb lhs``.arsize    = rhs``.arsize;     \
    always_comb lhs``.arburst   = rhs``.arburst;    \
    always_comb lhs``.arlock    = rhs``.arlock;     \
    always_comb lhs``.arcache   = rhs``.arcache;    \
    always_comb lhs``.arprot    = rhs``.arprot;     \
    always_comb lhs``.arqos     = rhs``.arqos;      \
    always_comb lhs``.arregion  = rhs``.arregion;   \
    always_comb lhs``.aruser    = rhs``.aruser;     \
    always_comb lhs``.arvalid   = rhs``.arvalid;    \
    always_comb rhs``.arready   = lhs``.arready;    \
    always_comb rhs``.rid       = lhs``.rid;        \
    always_comb rhs``.rdata     = lhs``.rdata;      \
    always_comb rhs``.rresp     = lhs``.rresp;      \
    always_comb rhs``.rlast     = lhs``.rlast;      \
    always_comb rhs``.ruser     = lhs``.ruser;      \
    always_comb rhs``.rvalid    = lhs``.rvalid;     \
    always_comb lhs``.rready    = rhs``.rready;     


/* Define: LOGIC_AXI4_MM_IF_SLAVE_ASSIGN
 *
 * Assign standalone signals to signals in SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - Standalone SystemVerilog signals.
 */
`define LOGIC_AXI4_MM_IF_SLAVE_ASSIGN(lhs, rhs)   \
    always_comb lhs``.awid      = rhs``.__awid;     \
    always_comb lhs``.awaddr    = rhs``._awaddr;    \
    always_comb lhs``.awlen     = rhs``._awlen;     \
    always_comb lhs``.awsize    = rhs``._awsize;    \
    always_comb lhs``.awburst   = rhs``._awburst;   \
    always_comb lhs``.awlock    = rhs``._awlock;    \
    always_comb lhs``.awcache   = rhs``._awcache;   \
    always_comb lhs``.awprot    = rhs``._awprot;    \
    always_comb lhs``.awqos     = rhs``._awqos;     \
    always_comb lhs``.awregion  = rhs``._awregion;  \
    always_comb lhs``.awuser    = rhs``._awuser;    \
    always_comb lhs``.awvalid   = rhs``._awvalid;   \
    always_comb rhs``._awready  = lhs``.awready;    \
    always_comb lhs``.wid       = rhs``._wid;       \
    always_comb lhs``.wdata     = rhs``._wdata;     \
    always_comb lhs``.wstrb     = rhs``._wstrb;     \
    always_comb lhs``.wlast     = rhs``._wlast;     \
    always_comb lhs``.wuser     = rhs``._wuser;     \
    always_comb lhs``.wvalid    = rhs``._wvalid;    \
    always_comb rhs``._wready   = lhs``.wready;     \
    always_comb rhs``._bid      = lhs``.bid;        \
    always_comb rhs``._bresp    = lhs``.bresp;      \
    always_comb rhs``._buser    = lhs``.buser;      \
    always_comb rhs``._bvalid   = lhs``.bvalid;     \
    always_comb lhs``.bready    = rhs``._bready;    \
    always_comb lhs``.arid      = rhs``._arid;      \
    always_comb lhs``.araddr    = rhs``._araddr;    \
    always_comb lhs``.arlen     = rhs``._arlen;     \
    always_comb lhs``.arsize    = rhs``._arsize;    \
    always_comb lhs``.arburst   = rhs``._arburst;   \
    always_comb lhs``.arlock    = rhs``._arlock;    \
    always_comb lhs``.arcache   = rhs``._arcache;   \
    always_comb lhs``.arprot    = rhs``._arprot;    \
    always_comb lhs``.arqos     = rhs``._arqos;     \
    always_comb lhs``.arregion  = rhs``._arregion;  \
    always_comb lhs``.aruser    = rhs``._aruser;    \
    always_comb lhs``.arvalid   = rhs``._arvalid;   \
    always_comb rhs``._arready  = lhs``.arready;    \
    always_comb rhs``._rid      = lhs``.rid;        \
    always_comb rhs``._rdata    = lhs``.rdata;      \
    always_comb rhs``._rresp    = lhs``.rresp;      \
    always_comb rhs``._rlast    = lhs``.rlast;      \
    always_comb rhs``._ruser    = lhs``.ruser;      \
    always_comb rhs``._rvalid   = lhs``.rvalid;     \
    always_comb lhs``.rready    = rhs``._rready;     

/* Define: LOGIC_AXI4_MM_IF_MASTER_ASSIGN
 *
 * Assign signals in SystemVerilog interface to standalone signals.
 *
 * Parameters:
 *  lhs       - Standalone SystemVerilog signals.
 *  rhs       - SystemVerilog interface.
 */
`define LOGIC_AXI4_MM_IF_MASTER_ASSIGN(lhs, rhs)  \
    always_comb lhs``._awid     = rhs``.awid;       \
    always_comb lhs``._awaddr   = rhs``.awaddr;     \
    always_comb lhs``._awlen    = rhs``.awlen;      \
    always_comb lhs``._awsize   = rhs``.awsize;     \
    always_comb lhs``._awburst  = rhs``.awburst;    \
    always_comb lhs``._awlock   = rhs``.awlock;     \
    always_comb lhs``._awcache  = rhs``.awcache;    \
    always_comb lhs``._awprot   = rhs``.awprot;     \
    always_comb lhs``._awqos    = rhs``.awqos;      \
    always_comb lhs``._awregion = rhs``.awregion;   \
    always_comb lhs``._awuser   = rhs``.awuser;     \
    always_comb lhs``._awvalid  = rhs``.awvalid;    \
    always_comb rhs``.awready   = lhs``._awready;   \
    always_comb lhs``._wid      = rhs``.wid;        \
    always_comb lhs``._wdata    = rhs``.wdata;      \
    always_comb lhs``._wstrb    = rhs``.wstrb;      \
    always_comb lhs``._wlast    = rhs``.wlast;      \
    always_comb lhs``._wuser    = rhs``.wuser;      \
    always_comb lhs``._wvalid   = rhs``.wvalid;     \
    always_comb rhs``.wready    = lhs``._wready;    \
    always_comb rhs``.bid       = lhs``._bid;       \
    always_comb rhs``.bresp     = lhs``._bresp;     \
    always_comb rhs``.buser     = lhs``._buser;     \
    always_comb rhs``.bvalid    = lhs``._bvalid;    \
    always_comb lhs``._bready   = rhs``.bready;     \
    always_comb lhs``._arid     = rhs``.arid;       \
    always_comb lhs``._araddr   = rhs``.araddr;     \
    always_comb lhs``._arlen    = rhs``.arlen;      \
    always_comb lhs``._arsize   = rhs``.arsize;     \
    always_comb lhs``._arburst  = rhs``.arburst;    \
    always_comb lhs``._arlock   = rhs``.arlock;     \
    always_comb lhs``._arcache  = rhs``.arcache;    \
    always_comb lhs``._arprot   = rhs``.arprot;     \
    always_comb lhs``._arqos    = rhs``.arqos;      \
    always_comb lhs``._arregion = rhs``.arregion;   \
    always_comb lhs``._aruser   = rhs``.aruser;     \
    always_comb lhs``._arvalid  = rhs``.arvalid;    \
    always_comb rhs``.arready   = lhs``._arready;   \
    always_comb rhs``.rid       = lhs``._rid;       \
    always_comb rhs``.rdata     = lhs``._rdata;     \
    always_comb rhs``.rresp     = lhs``._rresp;     \
    always_comb rhs``.rlast     = lhs``._rlast;     \
    always_comb rhs``.ruser     = lhs``._ruser;     \
    always_comb rhs``.rvalid    = lhs``._rvalid;    \
    always_comb lhs``._rready   = rhs``.rready;     

/* Define: LOGIC_AXI4_MM_IF_SLAVE_ASSIGN_ARRAY
 *
 * Assign standalone signals to signals in SystemVerilog interface.
 *
 * Parameters:
 *  lhs       - SystemVerilog interface.
 *  rhs       - Standalone SystemVerilog signals.
 *  index     - Array index for rhs.
 */
`define LOGIC_AXI4_MM_IF_SLAVE_ASSIGN_ARRAY(lhs, rhs, index)      \
    always_comb lhs``.awid              = rhs``.__awid[index];      \
    always_comb lhs``.awaddr            = rhs``._awaddr[index];     \
    always_comb lhs``.awlen             = rhs``._awlen[index];      \
    always_comb lhs``.awsize            = rhs``._awsize[index];     \
    always_comb lhs``.awburst           = rhs``._awburst[index];    \
    always_comb lhs``.awlock            = rhs``._awlock[index];     \
    always_comb lhs``.awcache           = rhs``._awcache[index];    \
    always_comb lhs``.awprot            = rhs``._awprot[index];     \
    always_comb lhs``.awqos             = rhs``._awqos[index];      \
    always_comb lhs``.awregion          = rhs``._awregion[index];   \
    always_comb lhs``.awuser            = rhs``._awuser[index];     \
    always_comb lhs``.awvalid           = rhs``._awvalid[index];    \
    always_comb rhs``._awready[index]   = lhs``.awready;            \
    always_comb lhs``.wid               = rhs``._wid[index];        \
    always_comb lhs``.wdata             = rhs``._wdata[index];      \
    always_comb lhs``.wstrb             = rhs``._wstrb[index];      \
    always_comb lhs``.wlast             = rhs``._wlast[index];      \
    always_comb lhs``.wuser             = rhs``._wuser[index];      \
    always_comb lhs``.wvalid            = rhs``._wvalid[index];     \
    always_comb rhs``._wready[index]    = lhs``.wready;             \
    always_comb rhs``._bid[index]       = lhs``.bid;                \
    always_comb rhs``._bresp[index]     = lhs``.bresp;              \
    always_comb rhs``._buser[index]     = lhs``.buser;              \
    always_comb rhs``._bvalid[index]    = lhs``.bvalid;             \
    always_comb lhs``.bready            = rhs``._bready[index];     \
    always_comb lhs``.arid              = rhs``._arid[index];       \
    always_comb lhs``.araddr            = rhs``._araddr[index];     \
    always_comb lhs``.arlen             = rhs``._arlen[index];      \
    always_comb lhs``.arsize            = rhs``._arsize[index];     \
    always_comb lhs``.arburst           = rhs``._arburst[index];    \
    always_comb lhs``.arlock            = rhs``._arlock[index];     \
    always_comb lhs``.arcache           = rhs``._arcache[index];    \
    always_comb lhs``.arprot            = rhs``._arprot[index];     \
    always_comb lhs``.arqos             = rhs``._arqos[index];      \
    always_comb lhs``.arregion          = rhs``._arregion[index];   \
    always_comb lhs``.aruser            = rhs``._aruser[index];     \
    always_comb lhs``.arvalid           = rhs``._arvalid[index];    \
    always_comb rhs``._arready[index]   = lhs``.arready;            \
    always_comb rhs``._rid[index]       = lhs``.rid;                \
    always_comb rhs``._rdata[index]     = lhs``.rdata;              \
    always_comb rhs``._rresp[index]     = lhs``.rresp;              \
    always_comb rhs``._rlast[index]     = lhs``.rlast;              \
    always_comb rhs``._ruser[index]     = lhs``.ruser;              \
    always_comb rhs``._rvalid[index]    = lhs``.rvalid;             \
    always_comb lhs``.rready            = rhs``._rready[index];     \


/* Define: LOGIC_AXI4_MM_IF_MASTER_ASSIGN_ARRAY
 *
 * Assign signals in SystemVerilog interface to standalone signals.
 *
 * Parameters:
 *  lhs       - Standalone SystemVerilog signals.
 *  rhs       - SystemVerilog interface.
 *  index     - Array index for lhs.
 */
`define LOGIC_AXI4_MM_IF_MASTER_ASSIGN_ARRAY(lhs, index, rhs)     \
    always_comb lhs``._awid[index]      = rhs``.awid;               \
    always_comb lhs``._awaddr[index]    = rhs``.awaddr;             \
    always_comb lhs``._awlen[index]     = rhs``.awlen;              \
    always_comb lhs``._awsize[index]    = rhs``.awsize;             \
    always_comb lhs``._awburst[index]   = rhs``.awburst;            \
    always_comb lhs``._awlock[index]    = rhs``.awlock;             \
    always_comb lhs``._awcache[index]   = rhs``.awcache;            \
    always_comb lhs``._awprot[index]    = rhs``.awprot;             \
    always_comb lhs``._awqos[index]     = rhs``.awqos;              \
    always_comb lhs``._awregion[index]  = rhs``.awregion;           \
    always_comb lhs``._awuser[index]    = rhs``.awuser;             \
    always_comb lhs``._awvalid[index]   = rhs``.awvalid;            \
    always_comb rhs``.awready           = lhs``._awready[index];    \
    always_comb lhs``._wid[index]       = rhs``.wid;                \
    always_comb lhs``._wdata[index]     = rhs``.wdata;              \
    always_comb lhs``._wstrb[index]     = rhs``.wstrb;              \
    always_comb lhs``._wlast[index]     = rhs``.wlast;              \
    always_comb lhs``._wuser[index]     = rhs``.wuser;              \
    always_comb lhs``._wvalid[index]    = rhs``.wvalid;             \
    always_comb rhs``.wready            = lhs``._wready[index];     \
    always_comb rhs``.bid               = lhs``._bid[index];        \
    always_comb rhs``.bresp             = lhs``._bresp[index];      \
    always_comb rhs``.buser             = lhs``._buser[index];      \
    always_comb rhs``.bvalid            = lhs``._bvalid[index];     \
    always_comb lhs``._bready[index]    = rhs``.bready;             \
    always_comb lhs``._arid[index]      = rhs``.arid;               \
    always_comb lhs``._araddr[index]    = rhs``.araddr;             \
    always_comb lhs``._arlen[index]     = rhs``.arlen;              \
    always_comb lhs``._arsize[index]    = rhs``.arsize;             \
    always_comb lhs``._arburst[index]   = rhs``.arburst;            \
    always_comb lhs``._arlock[index]    = rhs``.arlock;             \
    always_comb lhs``._arcachev         = rhs``.arcache;            \
    always_comb lhs``._arprot[index]    = rhs``.arprot;             \
    always_comb lhs``._arqos[index]     = rhs``.arqos;              \
    always_comb lhs``._arregion[index]  = rhs``.arregion;           \
    always_comb lhs``._aruser[index]    = rhs``.aruser;             \
    always_comb lhs``._arvalid[index]   = rhs``.arvalid;            \
    always_comb rhs``.arready           = lhs``._arready[index];    \
    always_comb rhs``.rid               = lhs``._rid[index];        \
    always_comb rhs``.rdata             = lhs``._rdata[index];      \
    always_comb rhs``.rresp             = lhs``._rresp[index];      \
    always_comb rhs``.rlast             = lhs``._rlast[index];      \
    always_comb rhs``.ruser             = lhs``._ruser[index];      \
    always_comb rhs``.rvalid            = lhs``._rvalid[index];     \
    always_comb lhs``._rready[index]    = rhs``.rready;

`endif /* LOGIC_AXI4_MM_SVH */
