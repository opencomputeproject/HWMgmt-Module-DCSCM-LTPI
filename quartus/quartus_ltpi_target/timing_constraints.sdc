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