#/////////////////////////////////////////////////////////////////////////////////
#// Copyright (c) 2022 Intel Corporation
#//
#// Permission is hereby granted, free of charge, to any person obtaining a
#// copy of this software and associated documentation files (the "Software"),
#// to deal in the Software without restriction, including without limitation
#// the rights to use, copy, modify, merge, publish, distribute, sublicense,
#// and/or sell copies of the Software, and to permit persons to whom the
#// Software is furnished to do so, subject to the following conditions:
#//
#// The above copyright notice and this permission notice shall be included in
#// all copies or substantial portions of the Software.
#//
#// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#// DEALINGS IN THE SOFTWARE.
#/////////////////////////////////////////////////////////////////////////////////

#!/bin/bash
VCS_SIM_EN="ON"
MODELSIM_SIM_EN="OFF"

if [[ -v SVUNIT_INSTALL ]]; then
    echo "SVUNIT_INSTALL=$SVUNIT_INSTALL"
else
    echo "SVUNIT_INSTALL variable is not set!"
fi
if [[ "$VCS_SIM_EN" = "ON" ]]; then
    mkdir -p ltpi_csr_avmm_unit_test_vcs && cd ltpi_csr_avmm_unit_test_vcs

    vcs -full64 -R -timescale=1ps/1ps -sverilog $SVUNIT_INSTALL/svunit_base/svunit_pkg.sv \
    ../../../logic/rtl/logic/interfaces/logic_avalon_mm_if.sv \
    ../../../logic/rtl/logic/packages/logic_avalon_mm_pkg.sv \
    ../../../rtl/modules/CSR/RDL/ltpi_csr_pkg.sv \
    ../../../rtl/modules/CSR/RDL/ltpi_csr.sv \
    ../../../rtl/modules/CSR/RDL/ltpi_csr_light_pkg.sv \
    ../../../rtl/modules/CSR/RDL/ltpi_csr_light.sv \
    ../../../rtl/package/ltpi_pkg.sv \
    ../../../rtl/modules/CSR/ltpi_csr_avmm/ltpi_csr_avmm.sv \
    ../../../tests/LTPI_CSR_AVMM_UNIT_TEST/ltpi_csr_avmm_unit_test.sv \
    ../ltpi_csr_avmm_unit_test_runner.sv \
    +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include -debug_access+all -gui
elif [[ "$MODELSIM_SIM_EN" = "ON" ]]; then 
    mkdir -p ltpi_csr_avmm_unit_test_modelsim && cd ltpi_csr_avmm_unit_test_modelsim
    vlib work
    vmap work work

    vlog -sv $SVUNIT_INSTALL/svunit_base/svunit_pkg.sv -work work +incdir+$SVUNIT_INSTALL/svunit_base
    vlog -sv ../../../logic/rtl/logic/interfaces/logic_avalon_mm_if.sv -work work +incdir+../../../logic/rtl/logic/include
    vlog -sv ../../../logic/rtl/logic/packages/logic_avalon_mm_pkg.sv -work work 
    vlog -sv ../../../rtl/modules/CSR/RDL/ltpi_csr_pkg.sv -work work 
    vlog -sv ../../../rtl/modules/CSR/RDL/ltpi_csr.sv -work work 
    vlog -sv ../../../rtl/modules/CSR/RDL/ltpi_csr_light_pkg.sv -work work 
    vlog -sv ../../../rtl/modules/CSR/RDL/ltpi_csr_light.sv -work work 
    vlog -sv ../../../rtl/package/ltpi_pkg.sv -work work 
    vlog -sv ../../../rtl/modules/CSR/ltpi_csr_avmm/ltpi_csr_avmm.sv -work work +incdir+$SVUNIT_INSTALL/svunit_base +incdir+../../../logic/rtl/logic/include
    vlog -sv ../../../tests/LTPI_CSR_AVMM_UNIT_TEST/ltpi_csr_avmm_unit_test.sv -work work +incdir+$SVUNIT_INSTALL/svunit_base
    vlog -sv ../ltpi_csr_avmm_unit_test_runner.sv -work work +incdir+$SVUNIT_INSTALL/svunit_base

    vsim ltpi_csr_avmm_unit_test_runner -suppress 8386 -gui -voptargs=+acc -Ldir . -L work
else 
    echo "Simulation tool not set!"
fi

cd ..