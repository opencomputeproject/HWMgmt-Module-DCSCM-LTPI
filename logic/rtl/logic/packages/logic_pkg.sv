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

/* Package: logic_pkg
 *
 * Logic package.
 */
package logic_pkg;
    /* Enum: system_t
     *
     * System select.
     *
     * SYSTEM_GENERIC           - Generic system
     * SYSTEM_SIMULATION        - Default system targeted for simulation.
     * SYSTEM_INTEL_HPS         - Intel Hard Processor System (ARM).
     * SYSTEM_INTEL_NIOS_II     - Intel soft-processor Nios-II.
     * SYSTEM_XILINX_ZYNQ       - Xilinx hard-processor Zynq.
     * SYSTEM_XILINX_MICROBLAZE - Xilinx soft-processor MicroBlaze.
     */
    typedef enum {
        SYSTEM_GENERIC,
        SYSTEM_SIMULATION,
        SYSTEM_INTEL_HPS,
        SYSTEM_INTEL_NIOS_II,
        SYSTEM_XILINX_ZYNQ,
        SYSTEM_XILINX_MICROBLAZE
    } system_t;

    /* Enum: target_t
     *
     * Optimize project using dedicated target.
     *
     * TARGET_GENERIC            - Generic target not related to any vendor or
     *                             device.
     * TARGET_SIMULATION         - Optimized for simulation.
     * TARGET_INTEL              - Optimized for non-specific Intel FPGAs.
     * TARGET_INTEL_ARRIA_10     - Optimized for Intel Arria 10 without HPS.
     * TARGET_INTEL_ARRIA_10_SOC - Optimized for Intel Arria 10 with HPS.
     */
    typedef enum {
        TARGET_GENERIC,
        TARGET_SIMULATION,
        TARGET_INTEL,
        TARGET_INTEL_ARRIA_10,
        TARGET_INTEL_ARRIA_10_SOC
    } target_t;
endpackage
