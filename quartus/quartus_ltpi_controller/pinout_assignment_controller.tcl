#**************************************************************
# Need to change:
# PIN_XX - to correct pin assignment
# IO_STANDARD_XX - to correct IO standard
#**************************************************************

#**************************************************************
# Pinout Information
#**************************************************************

#CLK 25 MHZ
#set_location_assignment PIN_XX -to CLK_25M_OSC_CPU_FPGA
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to CLK_25M_OSC_CPU_FPGA

#PWR GOOD 1V2
#set_location_assignment PIN_XX -to PWRGD_P1V2_MAX10_AUX_CPU_PLD_R
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to PWRGD_P1V2_MAX10_AUX_CPU_PLD_R

#______________________LVDS______________________
#set_location_assignment PIN_XX -to LVDS_TX_R_DP
#set_instance_assignment -name IO_STANDARD LVDS -to LVDS_TX_R_DP
#set_location_assignment PIN_XX -to LVDS_RX_DP
#set_instance_assignment -name IO_STANDARD LVDS -to LVDS_RX_DP
#set_location_assignment PIN_XX -to LVDS_CLK_RX_DP
#set_instance_assignment -name IO_STANDARD LVDS -to LVDS_CLK_RX_DP
#set_location_assignment PIN_XX -to LVDS_CLK_TX_R_DP
#set_instance_assignment -name IO_STANDARD LVDS -to LVDS_CLK_TX_R_DP

#set_location_assignment PIN_XX -to "LVDS_CLK_RX_DP(n)"
#set_location_assignment PIN_XX -to "LVDS_CLK_TX_R_DP(n)"
#set_location_assignment PIN_XX -to "LVDS_RX_DP(n)"
#set_location_assignment PIN_XX -to "LVDS_TX_R_DP(n)"

#______________________UART______________________
#set_location_assignment PIN_XX -to UART_TX
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to UART_TX
#set_location_assignment PIN_XX -to UART_RX
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to UART_RX

#______________________I2C________________________
#set_location_assignment PIN_XX -to I2C_SCL
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to I2C_SCL
#set_location_assignment PIN_XX -to I2C_SDA
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to I2C_SDA

#______________________I2C BMC________________________
#set_location_assignment PIN_XX -to BMC_SMB_SCL
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to BMC_SMB_SCL
#set_location_assignment PIN_XX -to BMC_SMB_SDA
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to BMC_SMB_SDA

#______________________USER PINS__________________
#J21 - ext board _2
#set_location_assignment PIN_XX -to DUT_ALIGNED
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX" -to DUT_ALIGNED

#______________________GPIO______________________
#set_location_assignment PIN_XX -to LL_GPIO_0 
#set_instance_assignment -name IO_STANDARD "IO_STANDARD_XX -to GPIO_0
