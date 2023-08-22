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

if [[ -v VCS_HOME ]]; then
    echo "VCS_HOME=$VCS_HOME"
else
    echo "VCS_HOME variable is not set!"
fi

if [[ "$VCS_SIM_EN" = "ON" ]]; then
    mkdir -p m10_pll_top_unit_test_vcs && cd m10_pll_top_unit_test_vcs

    cp $VCS_HOME/bin/synopsys_sim.setup .
    export SYNOPSYS_SIM_SETUP=`pwd`/synopsys_sim.setup
    echo "SYNOPSYS_SIM_SETUP=$SYNOPSYS_SIM_SETUP"

    echo work : `pwd`/work >> synopsys_sim.setup
    vlogan -full64 -sverilog $SVUNIT_INSTALL/svunit_base/svunit_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vlogan -full64 -sverilog ../../../rtl/package/ltpi_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/CLOCK_MGMT/m10_pll_top/m10_pll_top_tester.sv
    vlogan -full64 -sverilog ../../../rtl/modules/CLOCK_MGMT/m10_pll_top/m10_pll_top.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/CLOCK_MGMT/m10_pll_ip/m10_pll_reconfig_file/m10_pll_reconfig_file.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../tests/m10_pll_top/m10_pll_top_unit_test.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vlogan -full64 -sverilog ../m10_pll_top_unit_test_runner.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include


    vlogan -full64 +v2k ../../../rtl/modules/CLOCK_MGMT/m10_pll_ip/m10_reconfig/m10_pll_reconfig.v -work work -timescale=1ps/1ps
    vlogan -full64 +v2k ../../../rtl/modules/CLOCK_MGMT/pll_lvds/pll_lvds.v -work work -timescale=1ps/1ps

    vcs -full64 -R m10_pll_top_unit_test_runner -o simv -debug_access+all -gui
elif [[ "$MODELSIM_SIM_EN" = "ON" ]]; then 
    mkdir -p m10_pll_top_unit_test_modelsim && cd m10_pll_top_unit_test_modelsim

    vlib work
    vmap work work

    vlog -sv $SVUNIT_INSTALL/svunit_base/svunit_pkg.sv -work work +incdir+$SVUNIT_INSTALL/svunit_base
    vlog -sv ../../../rtl/package/ltpi_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/CLOCK_MGMT/m10_pll_top/m10_pll_top_tester.sv
    vlog -sv ../../../rtl/modules/CLOCK_MGMT/m10_pll_top/m10_pll_top.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/CLOCK_MGMT/m10_pll_ip/m10_pll_reconfig_file/m10_pll_reconfig_file.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 

    vlog -sv ../../../rtl/modules/CLOCK_MGMT/m10_pll_ip/m10_reconfig/m10_pll_reconfig.v -work work -timescale=1ps/1ps
    vlog -sv ../../../rtl/modules/CLOCK_MGMT/pll_lvds/pll_lvds.v -work work -timescale=1ps/1ps
    
    vlog -sv ../../../tests/m10_pll_top/m10_pll_top_unit_test.sv -work work -suppress 2744 -suppress 7027 -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vlog -sv ../m10_pll_top_unit_test_runner.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vsim m10_pll_top_unit_test_runner -suppress 2892 -suppress 2744 -suppress 2244 -gui -voptargs=+acc -Ldir . -L work -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver 

fi

cd ..