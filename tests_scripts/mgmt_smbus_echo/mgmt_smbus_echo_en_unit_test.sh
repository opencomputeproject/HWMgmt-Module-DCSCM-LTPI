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
    mkdir -p mgmt_smbus_echo_en_unit_test_vcs && cd mgmt_smbus_echo_en_unit_test_vcs

    cp $VCS_HOME/bin/synopsys_sim.setup .
    export SYNOPSYS_SIM_SETUP=`pwd`/synopsys_sim.setup
    echo "SYNOPSYS_SIM_SETUP=$SYNOPSYS_SIM_SETUP"

    echo work : `pwd`/work >> synopsys_sim.setup

    vlogan -full64 -sverilog $SVUNIT_INSTALL/svunit_base/svunit_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vlogan -full64 -sverilog ../../../logic/rtl/logic/interfaces/logic_avalon_mm_if.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vlogan -full64 -sverilog ../../../logic/rtl/logic/packages/logic_avalon_mm_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/CSR/RDL/ltpi_csr_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/package/ltpi_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/smbus_relay/smbus_relay_target/smbus_relay_target.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/smbus_relay/smbus_relay_controller/smbus_relay_controller.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/mgmt_ltpi/mgmt_interface/smbus_echo.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/mgmt_ltpi/mgmt_interface/mgmt_smbus.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/CSR/avmm_target_model/avmm_target_model.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/modules/async_input_filter/async_input_filter.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 

    vlogan -full64 -sverilog ../../../logic/rtl/logic/packages/logic_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_mstfsm.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_rxshifter.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_txshifter.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_spksupp.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_condt_det.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_condt_gen.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_clk_cnt.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_txout.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_fifo.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_csr.v

    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altera_i2cslave_to_avlmm_bridge.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_spksupp.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_condt_det.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_databuffer.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_slvfsm.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_avl_mst_intf_gen.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_txshifter.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_rxshifter.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_txout.v
    vlogan -full64 -sverilog ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_clk_cnt.v

    vlogan -full64 -sverilog ../../../tests/mgmt_smbus_echo/mgmt_smbus_echo_en_unit_test.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include+../../../tests/model_packages/ltpi_data_channel_controller
    vlogan -full64 -sverilog ../mgmt_smbus_echo_en_unit_test_runner.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    
    vlogan -full64 +v2k ../../../rtl/modules/CLOCK_MGMT/pll_cpu/pll_cpu.v -work work -timescale=1ps/1ps
    vlogan -full64 +v2k ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/i2c_target_avmm_bridge.v -work work -timescale=1ps/1ps
    vlogan -full64 +v2k ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/i2c_controller_avmm_bridge.v -work work -timescale=1ps/1ps

    vcs -full64 -R mgmt_smbus_echo_en_unit_test_runner -o simv -debug_access+all -gui
elif [[ "$MODELSIM_SIM_EN" = "ON" ]]; then 

    mkdir -p mgmt_smbus_echo_en_unit_test_vcs && cd mgmt_smbus_echo_en_unit_test_vcs

    vlib work
    vmap work work

    vlog -sv $SVUNIT_INSTALL/svunit_base/svunit_pkg.sv -work work +incdir+$SVUNIT_INSTALL/svunit_base
    vlog -sv ../../../logic/rtl/logic/interfaces/logic_avalon_mm_if.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vlog -sv ../../../logic/rtl/logic/packages/logic_avalon_mm_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/CSR/RDL/ltpi_csr_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/package/ltpi_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/smbus_relay/smbus_relay_target/smbus_relay_target.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/smbus_relay/smbus_relay_controller/smbus_relay_controller.sv -suppress 2892 -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/mgmt_ltpi/mgmt_interface/smbus_echo.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/mgmt_ltpi/mgmt_interface/mgmt_smbus.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vlog -sv ../../../rtl/modules/CSR/avmm_target_model/avmm_target_model.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlog -sv ../../../rtl/modules/async_input_filter/async_input_filter.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    vlogan -full64 -sverilog ../../../logic/rtl/logic/packages/logic_pkg.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include 
    
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_mstfsm.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_rxshifter.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_txshifter.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_spksupp.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_condt_det.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_condt_gen.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_clk_cnt.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_txout.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_fifo.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c.v
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/submodules/altera_avalon_i2c_csr.v

    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altera_i2cslave_to_avlmm_bridge.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_spksupp.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_condt_det.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_databuffer.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_slvfsm.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_avl_mst_intf_gen.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_txshifter.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_rxshifter.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_txout.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/submodules/altr_i2c_clk_cnt.v
    vlog -sv ../../../rtl/qsys/i2c_target_avmm_bridge/i2c_target_avmm_bridge/synthesis/i2c_target_avmm_bridge.v -work work -timescale=1ps/1ps
    vlog -sv ../../../rtl/qsys/i2c_controller_avmm_bridge/i2c_controller_avmm_bridge/synthesis/i2c_controller_avmm_bridge.v -work work -timescale=1ps/1ps

    vlog -sv ../../../rtl/modules/CLOCK_MGMT/pll_cpu/pll_cpu.v -work work -timescale=1ps/1ps
    vlog -sv ../../../tests/mgmt_smbus_echo/mgmt_smbus_echo_en_unit_test.sv -work work -suppress 2744 -suppress 7027 -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include+../../../tests/model_packages/ltpi_data_channel_controller

    vlog -sv ../mgmt_smbus_echo_en_unit_test_runner.sv -work work -timescale=1ps/1ps +incdir+$SVUNIT_INSTALL/svunit_base+../../../logic/rtl/logic/include
    vsim mgmt_smbus_echo_en_unit_test_runner -suppress 2892 -suppress 2744 -suppress 2244 -gui -voptargs=+acc -Ldir . -L work -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L fiftyfivenm_ver 

fi
cd ..