set_global_assignment -entity "i2c_target_avmm_bridge" -library "lib_i2c_target_avmm_bridge" -name IP_TOOL_NAME "Qsys"
set_global_assignment -entity "i2c_target_avmm_bridge" -library "lib_i2c_target_avmm_bridge" -name IP_TOOL_VERSION "21.1"
set_global_assignment -entity "i2c_target_avmm_bridge" -library "lib_i2c_target_avmm_bridge" -name IP_TOOL_ENV "Qsys"
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name SPD_FILE [file join $::quartus(sip_path) "../i2c_target_avmm_bridge.spd"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "../../../i2c_target_avmm_bridge.qsys"]

set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "i2c_target_avmm_bridge.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altera_i2cslave_to_avlmm_bridge.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_avl_mst_intf_gen.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_clk_cnt.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_condt_det.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_databuffer.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_rxshifter.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_slvfsm.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_spksupp.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_txout.v"]
set_global_assignment -library "lib_i2c_target_avmm_bridge" -name MISC_FILE [file join $::quartus(sip_path) "submodules/altr_i2c_txshifter.v"]
