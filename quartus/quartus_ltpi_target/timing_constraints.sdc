#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3

#**************************************************************
# Create Clock
#**************************************************************
create_clock -name {CLK_25M_OSC_CPU_FPGA} -period 40.000 -waveform { 0.000 20.000 } [get_ports {CLK_25M_OSC_CPU_FPGA}]
create_clock -name {LVDS_CLK_TX_R_DP} -period 5.000 -waveform { 0.000 2.500 } [get_ports {LVDS_CLK_TX_R_DP}]
create_clock -name {LVDS_CLK_RX_DP} -period 5.000 -waveform { 0.000 2.500 } [get_ports {LVDS_CLK_RX_DP}]
create_generated_clock -name {ltpi_top_target_inst|mgmt_ltpi_top_inst|mgmt_phy_top_inst|dynamic_pll.m10_pll_top_inst|pll_inst|altpll_component|auto_generated|pll1|clk[0]} -source {ltpi_top_target_inst|mgmt_ltpi_top_inst|mgmt_phy_top_inst|dynamic_pll.m10_pll_top_inst|pll_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 1 -multiply_by 8 -duty_cycle 50.00 { ltpi_top_target_inst|mgmt_ltpi_top_inst|mgmt_phy_top_inst|dynamic_pll.m10_pll_top_inst|pll_inst|altpll_component|auto_generated|pll1|clk[0] }
create_generated_clock -name {ltpi_top_target_inst|mgmt_ltpi_top_inst|mgmt_phy_top_inst|dynamic_pll.m10_pll_top_inst|pll_inst|altpll_component|auto_generated|pll1|clk[1]} -source {ltpi_top_target_inst|mgmt_ltpi_top_inst|mgmt_phy_top_inst|dynamic_pll.m10_pll_top_inst|pll_inst|altpll_component|auto_generated|pll1|inclk[0]} -divide_by 1 -multiply_by 8 -duty_cycle 50.00 { ltpi_top_target_inst|mgmt_ltpi_top_inst|mgmt_phy_top_inst|dynamic_pll.m10_pll_top_inst|pll_inst|altpll_component|auto_generated|pll1|clk[1] }

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks -create_base_clocks

#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty 

set_false_path -from {ltpi_top_target:ltpi_top_target_inst|mgmt_ltpi_top:mgmt_ltpi_top_inst|mgmt_phy_top:mgmt_phy_top_inst|ltpi_phy_tx:ltpi_phy_tx_inst|LVDS_DDR_ff} -to {ltpi_top_target:ltpi_top_target_inst|mgmt_ltpi_top:mgmt_ltpi_top_inst|mgmt_phy_top:mgmt_phy_top_inst|ltpi_phy_tx:ltpi_phy_tx_inst|lvds_phy_tx:lvds_phy_tx|*}
set_false_path -from {ltpi_top_target:ltpi_top_target_inst|mgmt_ltpi_top:mgmt_ltpi_top_inst|mgmt_phy_top:mgmt_phy_top_inst|ltpi_phy_tx:ltpi_phy_tx_inst|reset_phy} -to {ltpi_top_target:ltpi_top_target_inst|mgmt_ltpi_top:mgmt_ltpi_top_inst|mgmt_phy_top:mgmt_phy_top_inst|ltpi_phy_tx:ltpi_phy_tx_inst|lvds_phy_tx:lvds_phy_tx|*}


#**************************************************************
# Set input/output delays
#**************************************************************

#transmitter
set ext_skew_max -5.45
set ext_skew_min 0

set_output_delay -clock lvds_tx_clk_ext -max $ext_skew_max [get_ports {LVDS_TX_R_DP}]
set_output_delay -clock lvds_tx_clk_ext -min $ext_skew_min [get_ports {LVDS_TX_R_DP}]
set_output_delay -clock lvds_tx_clk_ext -max $ext_skew_max [get_ports {LVDS_TX_R_DP}] -clock_fall -add_delay
set_output_delay -clock lvds_tx_clk_ext -min $ext_skew_min [get_ports {LVDS_TX_R_DP}] -clock_fall -add_delay

set_output_delay -clock lvds_tx_clk_ext -max $ext_skew_max [get_ports {LVDS_TX_R_DP(n)}]
set_output_delay -clock lvds_tx_clk_ext -min $ext_skew_min [get_ports {LVDS_TX_R_DP(n)}]
set_output_delay -clock lvds_tx_clk_ext -max $ext_skew_max [get_ports {LVDS_TX_R_DP(n)}] -clock_fall -add_delay
set_output_delay -clock lvds_tx_clk_ext -min $ext_skew_min [get_ports {LVDS_TX_R_DP(n)}] -clock_fall -add_delay

#Receiver
set ssync_input_delay_max -1
set ssync_input_delay_min 0

set_input_delay -clock LVDS_CLK_RX_DP -max $ssync_input_delay_max [get_ports {LVDS_RX_DP}]
set_input_delay -clock LVDS_CLK_RX_DP -min $ssync_input_delay_min [get_ports {LVDS_RX_DP}]
set_input_delay -clock LVDS_CLK_RX_DP -max $ssync_input_delay_max [get_ports {LVDS_RX_DP}] -clock_fall -add_delay
set_input_delay -clock LVDS_CLK_RX_DP -min $ssync_input_delay_min [get_ports {LVDS_RX_DP}] -clock_fall -add_delay


create_clock -name {rx_frm_offset_clk} -period 1000.000 [get_nets  {ltpi_top_controller:ltpi_top_controller_inst|mgmt_ltpi_top:mgmt_ltpi_top_inst|mgmt_phy_top:mgmt_phy_top_inst|ltpi_phy_rx:ltpi_phy_rx_inst|rx_frm_offset[0]}]
set_false_path -from {rx_frm_offset_clk} -to {*}