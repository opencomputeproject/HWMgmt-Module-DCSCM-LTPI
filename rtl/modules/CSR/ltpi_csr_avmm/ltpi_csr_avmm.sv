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

// -------------------------------------------------------------------
// -- Author        : Jakub Wiczynski, Katarzyna Krzewska 
// -- Date          : September 2022
// -- Project Name  : LTPI
// -- Description   :
// -- LTPI CSR Avalone mm 
// -------------------------------------------------------------------

`timescale 100 ps / 1 ps

`include "logic.svh"

import ltpi_pkg::*;
import ltpi_csr_pkg::*;
import ltpi_csr_light_pkg::*;

module ltpi_csr_avmm
#(
    parameter CSR_LIGHT_VER_EN = 0
)
(
    input                                       clk,
    input                                       reset_n,
    `LOGIC_MODPORT(logic_avalon_mm_if,  slave)  avalon_mm_s,

    input LTPI_CSR_Out_t                        CSR_hw_out,
    output LTPI_CSR_In_t                        CSR_hw_in
);

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- Parameters for defining base addresses of register space sections ------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //
localparam logic [15:0] CSR_REGISTERS_BASE_ADDRESS       = 16'h200;
localparam int          CSR_REGISTERS_SIZE               = 64 * 4;
localparam logic [15:0] CSR_REGISTERS_END_ADDRESS        = CSR_REGISTERS_BASE_ADDRESS + CSR_REGISTERS_SIZE - 1;
// ------------------------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //
// ----- FSM signals --------------------------------------------------------------------------------------------------------//
// ------------------------------------------------------------------------------------------------------------------------- //

typedef enum logic [2:0] {
    AVMM_FSM_IDLE,
    AVMM_FSM_WRITE,
    AVMM_FSM_WR_BASE_RDL,
    AVMM_FSM_READ,
    AVMM_FSM_RD_BASE_RDL,
    AVMM_FSM_RESP
} avmm_fsm_t;

avmm_fsm_t          avmm_fsm;
logic               avmm_rnw;
logic [15:0]        avmm_address;
logic [3:0]         avmm_byte_enable;
logic [31:0]        avmm_data;
logic [1:0]         avmm_response;



// ------------------------------------------------------------------------------------------------------------------------- //
// ----- RDL modules instances  -------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //

logic               rdl_base_req;
logic               rdl_base_wr_en;
logic [ 7:0]        rdl_base_addr;
logic [31:0]        rdl_base_wr_data;
logic               rdl_base_wr_ack;
logic [31:0]        rdl_base_rd_data;
logic               rdl_base_rd_ack;

logic               wr_reg;

//////////////////
//RDL_BASE_HWIN///
//////////////////
ltpi_csr__in_t      rdl_base_hwin;
ltpi_csr__out_t     rdl_base_hwout;

ltpi_csr_light__in_t      light_rdl_base_hwin;
ltpi_csr_light__out_t     light_rdl_base_hwout;

generate begin: CSR
    if (!CSR_LIGHT_VER_EN) begin


        ltpi_csr u_rdl_base (
            .clk                    (clk),
            .rst                    (~reset_n),

            .s_cpuif_req            (rdl_base_req),
            .s_cpuif_req_is_wr      (rdl_base_wr_en),
            .s_cpuif_addr           (rdl_base_addr),
            .s_cpuif_wr_data        (rdl_base_wr_data),
            //.s_cpuif_wr_biten       ('1), //unncomment with "old" version of peakRDL
            .s_cpuif_req_stall_wr   (),
            .s_cpuif_req_stall_rd   (),
            .s_cpuif_rd_ack         (rdl_base_rd_ack),
            .s_cpuif_rd_err         (),
            .s_cpuif_rd_data        (rdl_base_rd_data),
            .s_cpuif_wr_ack         (rdl_base_wr_ack),
            .s_cpuif_wr_err         (),
            .hwif_in                (rdl_base_hwin),
            .hwif_out               (rdl_base_hwout)
        );

        assign rdl_base_hwin.LTPI_Link_Status.aligned.next                                  = CSR_hw_out.LTPI_Link_Status.aligned;
        assign rdl_base_hwin.LTPI_Link_Status.link_lost_error.next                          = CSR_hw_out.LTPI_Link_Status.link_lost_error;
        assign rdl_base_hwin.LTPI_Link_Status.frm_CRC_error.next                            = CSR_hw_out.LTPI_Link_Status.frm_CRC_error;
        assign rdl_base_hwin.LTPI_Link_Status.unknown_comma_error.next                      = CSR_hw_out.LTPI_Link_Status.unknown_comma_error;
        assign rdl_base_hwin.LTPI_Link_Status.link_speed_timeout_error.next                 = CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error;
        assign rdl_base_hwin.LTPI_Link_Status.link_cfg_acpt_timeout_error.next              = CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error;
        assign rdl_base_hwin.LTPI_Link_Status.DDR_mode.next                                 = CSR_hw_out.LTPI_Link_Status.DDR_mode;
        assign rdl_base_hwin.LTPI_Link_Status.link_speed.next                               = CSR_hw_out.LTPI_Link_Status.link_speed;
        assign rdl_base_hwin.LTPI_Link_Status.remote_link_state.next                        = CSR_hw_out.LTPI_Link_Status.remote_link_state;
        assign rdl_base_hwin.LTPI_Link_Status.local_link_state.next                         = CSR_hw_out.LTPI_Link_Status.local_link_state;

        assign rdl_base_hwin.LTPI_Detect_Capabilities_Remote.remote_Minor_Version.next      = CSR_hw_out.LTPI_Detect_Capab_remote.LTPI_Version[3:0]; 
        assign rdl_base_hwin.LTPI_Detect_Capabilities_Remote.remote_Major_Version.next      = CSR_hw_out.LTPI_Detect_Capab_remote.LTPI_Version[7:4];
        assign rdl_base_hwin.LTPI_Detect_Capabilities_Remote.link_Speed_capab.next          = CSR_hw_out.LTPI_Detect_Capab_remote.Link_Speed_capab;

        assign rdl_base_hwin.LTPI_platform_ID_remote.platform_ID_remote.next                = CSR_hw_out.LTPI_platform_ID_remote.ID;

        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.supported_channel.next         = CSR_hw_out.LTPI_Advertise_Capab_remote.supported_channel;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.NL_GPIO_nb.next                = CSR_hw_out.LTPI_Advertise_Capab_remote.NL_GPIO_nb;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.I2C_channel_echo_support.next  = CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_Echo_support;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.I2C_channel_en.next            = CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_en;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.I2C_channel_speed.next        = CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_cpbl;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.UART_channel_cpbl.next[6:5]   = CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_en;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.UART_channel_cpbl.next[4]     = CSR_hw_out.LTPI_Advertise_Capab_remote.UART_Flow_ctrl;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.UART_channel_cpbl.next[3:0]   = CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_cpbl;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.OEM_capab.next[15:8]          = CSR_hw_out.LTPI_Advertise_Capab_remote.OEM_cpbl.byte1;
        assign rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.OEM_capab.next[7:0]           = CSR_hw_out.LTPI_Advertise_Capab_remote.OEM_cpbl.byte0;

        assign rdl_base_hwin.link_aligment_err_cnt.err_cnt.next                             = CSR_hw_out.LTPI_counter.link_aligment_err_cnt;
        assign rdl_base_hwin.link_lost_err_cnt.err_cnt.next                                 = CSR_hw_out.LTPI_counter.link_lost_err_cnt;
        assign rdl_base_hwin.link_crc_err_cnt.err_cnt.next                                  = CSR_hw_out.LTPI_counter.link_crc_err_cnt;
        assign rdl_base_hwin.unknown_comma_err_cnt.err_cnt.next                             = CSR_hw_out.LTPI_counter.unknown_comma_err_cnt;
        assign rdl_base_hwin.link_speed_timeout_err_cnt.err_cnt.next                        = CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt;
        assign rdl_base_hwin.link_cfg_acpt_timeout_err_cnt.err_cnt.next                     = CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt;

        assign rdl_base_hwin.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt.next       = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt;
        assign rdl_base_hwin.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt.next        = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt;
        assign rdl_base_hwin.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt.next     = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt;
        assign rdl_base_hwin.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt.next   = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt;

        assign rdl_base_hwin.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt.next       = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt;
        assign rdl_base_hwin.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt.next        = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt;
        assign rdl_base_hwin.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt.next     = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt;
        assign rdl_base_hwin.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt.next   = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt;

        assign rdl_base_hwin.operational_frm_rcv_cnt.frm_cnt.next                           = CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt;
        assign rdl_base_hwin.operational_frm_snt_cnt.frm_cnt.next                           = CSR_hw_out.LTPI_counter.operational_frm_snt_cnt;


        ////////////////////////////////////////////DEBUG////////////////////////////////
        assign  rdl_base_hwin.smb_trg_dbg_cntrl_smbstate.controller_smbstate.next              = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_cntrl_smbstate.controller_smbstate         ;
        assign  rdl_base_hwin.smb_trg_dbg_cntrl_relay_state.relay_state.next                   = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_cntrl_relay_state.relay_state              ;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_i.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_i      ;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_o.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_o      ;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_i.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_i      ;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_o.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_o      ;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_scl_oe.next  = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.SCL_OE           ;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_sda_oe.next  = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.SDA_OE           ;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_scl.next     = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_scl;
        assign  rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_sda.next     = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_sda;
        
        assign  rdl_base_hwin.smb_cntrl_dbg_cntrl_smbstate.controller_smbstate.next             = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_cntrl_smbstate.controller_smbstate         ;
        assign  rdl_base_hwin.smb_cntrl_dbg_cntrl_relay_state.relay_state.next                  = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_cntrl_relay_state.relay_state              ;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_i.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_i      ;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_o.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_o      ;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_i.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_i      ;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_o.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_o      ;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_scl_oe.next = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.SCL_OE           ;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_sda_oe.next = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.SDA_OE           ;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_scl.next    = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_scl;
        assign  rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_sda.next    = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_sda;
        assign  rdl_base_hwin.pmbus2_relay_recovery_cntr.recovery_cnt.next                      = CSR_hw_out.LTPI_pmbus2_recovery_cnt;
        /////////////////////////////////////////////////////////////////////////////////


        assign CSR_hw_in.LTPI_Detect_Capab_local.Link_Speed_capab                           = rdl_base_hwout.LTPI_Detect_Capabilities_Local.link_Speed_capab.value;
        assign CSR_hw_in.LTPI_Detect_Capab_local.LTPI_Version[7:4]                          = rdl_base_hwout.LTPI_Detect_Capabilities_Local.local_Major_Version.value;
        assign CSR_hw_in.LTPI_Detect_Capab_local.LTPI_Version[3:0]                          = rdl_base_hwout.LTPI_Detect_Capabilities_Local.local_Minor_Version.value;

        assign CSR_hw_in.LTPI_platform_ID_local.ID                                          = rdl_base_hwout.LTPI_platform_ID_local.platform_ID_local.value;

        assign CSR_hw_in.LTPI_Advertise_Capab_local.supported_channel                       = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.supported_channel.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.NL_GPIO_nb                              = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_en                          = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.I2C_Echo_support                        = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_cpbl                        = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_en                         = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[6:5];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.UART_Flow_ctrl                          = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[4];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_cpbl                       = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[3:0];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte1                          = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[15:8];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte0                          = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[7:0];

        assign CSR_hw_in.LTPI_Config_Capab.supported_channel                                = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.supported_channel.value;
        assign CSR_hw_in.LTPI_Config_Capab.NL_GPIO_nb                                       = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.value;
        assign CSR_hw_in.LTPI_Config_Capab.I2C_channel_en                                   = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.value;
        assign CSR_hw_in.LTPI_Config_Capab.I2C_Echo_support                                 = rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.value;
        assign CSR_hw_in.LTPI_Config_Capab.I2C_channel_cpbl                                 = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.value;
        assign CSR_hw_in.LTPI_Config_Capab.UART_channel_en                                  = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[6:5];
        assign CSR_hw_in.LTPI_Config_Capab.UART_Flow_ctrl                                   = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[4];
        assign CSR_hw_in.LTPI_Config_Capab.UART_channel_cpbl                                = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[3:0];
        assign CSR_hw_in.LTPI_Config_Capab.OEM_cpbl.byte1                                   = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[15:8];
        assign CSR_hw_in.LTPI_Config_Capab.OEM_cpbl.byte0                                   = rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[7:0];

        assign CSR_hw_in.LTPI_Link_Ctrl.software_reset                                      = rdl_base_hwout.LTPI_Link_Ctrl.software_reset.value;
        assign CSR_hw_in.LTPI_Link_Ctrl.retraining_request                                  = rdl_base_hwout.LTPI_Link_Ctrl.retraining_req.value;
        assign CSR_hw_in.LTPI_Link_Ctrl.I2C_channel_reset                                   = rdl_base_hwout.LTPI_Link_Ctrl.I2C_channel_reset.value;    
        assign CSR_hw_in.LTPI_Link_Ctrl.data_channel_reset                                  = rdl_base_hwout.LTPI_Link_Ctrl.data_channel_reset.value;    
        assign CSR_hw_in.LTPI_Link_Ctrl.auto_move_config                                    = rdl_base_hwout.LTPI_Link_Ctrl.auto_move_config.value;  
        assign CSR_hw_in.LTPI_Link_Ctrl.trigger_config_st                                   = rdl_base_hwout.LTPI_Link_Ctrl.trigger_config_st.value;        

        assign CSR_hw_in.LTPI_Detect_Capab_remote.Link_Speed_capab                          = rdl_base_hwout.LTPI_Detect_Capabilities_Remote.link_Speed_capab.value;
        assign CSR_hw_in.LTPI_Detect_Capab_remote.LTPI_Version[7:4]                         = rdl_base_hwout.LTPI_Detect_Capabilities_Remote.remote_Major_Version.value;
        assign CSR_hw_in.LTPI_Detect_Capab_remote.LTPI_Version[3:0]                         = rdl_base_hwout.LTPI_Detect_Capabilities_Remote.remote_Minor_Version.value;

        always_ff @ (posedge clk or negedge reset_n) begin
            if (!reset_n) begin
                rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.supported_channel.next                 <= rdl_base_hwout.LTPI_Config_Capab_LOW.supported_channel.value;
                rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.next                        <= rdl_base_hwout.LTPI_Config_Capab_LOW.NL_GPIO_nb.value;
                rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.next                    <= rdl_base_hwout.LTPI_Config_Capab_LOW.I2C_channel_en.value;
                rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.next          <= rdl_base_hwout.LTPI_Config_Capab_LOW.I2C_channel_echo_support.value;
                rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.next                <= rdl_base_hwout.LTPI_Config_Capab_HIGH.I2C_channel_speed.value;
                rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[6:5]           <= rdl_base_hwout.LTPI_Config_Capab_HIGH.UART_channel_cpbl.value[6:5];
                rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[4]             <= rdl_base_hwout.LTPI_Config_Capab_HIGH.UART_channel_cpbl.value[4];
                rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[3:0]           <= rdl_base_hwout.LTPI_Config_Capab_HIGH.UART_channel_cpbl.value[3:0];
                rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[15:8]                  <= rdl_base_hwout.LTPI_Config_Capab_HIGH.OEM_capab.value[15:8];
                rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[7:0]                   <= rdl_base_hwout.LTPI_Config_Capab_HIGH.OEM_capab.value[7:0];
            end
            else begin
                CSR_hw_in.clear_reg <= wr_reg;

                if(wr_reg) begin
                    CSR_hw_in.LTPI_Link_Status.link_cfg_acpt_timeout_error                          <=  rdl_base_hwout.LTPI_Link_Status.link_cfg_acpt_timeout_error.value;
                    CSR_hw_in.LTPI_Link_Status.link_speed_timeout_error                             <=  rdl_base_hwout.LTPI_Link_Status.link_speed_timeout_error.value;
                    CSR_hw_in.LTPI_Link_Status.unknown_comma_error                                  <=  rdl_base_hwout.LTPI_Link_Status.unknown_comma_error.value;
                    CSR_hw_in.LTPI_Link_Status.frm_CRC_error                                        <=  rdl_base_hwout.LTPI_Link_Status.frm_CRC_error.value;
                    CSR_hw_in.LTPI_Link_Status.link_lost_error                                      <=  rdl_base_hwout.LTPI_Link_Status.link_lost_error.value;
                    
                    CSR_hw_in.LTPI_counter.link_aligment_err_cnt                                    <= rdl_base_hwout.link_aligment_err_cnt.err_cnt.value;
                    CSR_hw_in.LTPI_counter.link_lost_err_cnt                                        <= rdl_base_hwout.link_lost_err_cnt.err_cnt.value;
                    CSR_hw_in.LTPI_counter.link_crc_err_cnt                                         <= rdl_base_hwout.link_crc_err_cnt.err_cnt.value;
                    CSR_hw_in.LTPI_counter.unknown_comma_err_cnt                                    <= rdl_base_hwout.unknown_comma_err_cnt.err_cnt.value;
                    CSR_hw_in.LTPI_counter.link_speed_timeout_err_cnt                               <= rdl_base_hwout.link_speed_timeout_err_cnt.err_cnt.value;
                    CSR_hw_in.LTPI_counter.link_cfg_acpt_timeout_err_cnt                            <= rdl_base_hwout.link_cfg_acpt_timeout_err_cnt.err_cnt.value;
                    
                    CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt      <= rdl_base_hwout.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt.value;
                    CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt       <= rdl_base_hwout.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt.value;
                    CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt    <= rdl_base_hwout.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt.value;
                    
                    CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt  <= rdl_base_hwout.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt.value;

                    CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt      <= rdl_base_hwout.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt.value;
                    CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt       <= rdl_base_hwout.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt.value;                   
                    CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt    <= rdl_base_hwout.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt.value;
                    CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt  <= rdl_base_hwout.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt.value;

                    CSR_hw_in.LTPI_counter.operational_frm_snt_cnt                                  <= rdl_base_hwout.operational_frm_snt_cnt.frm_cnt.value;
                    CSR_hw_in.LTPI_counter.operational_frm_rcv_cnt                                  <= rdl_base_hwout.operational_frm_rcv_cnt.frm_cnt.value;

                end
                else begin
                    CSR_hw_in.LTPI_Link_Status.link_cfg_acpt_timeout_error                          <= CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error;
                    CSR_hw_in.LTPI_Link_Status.link_speed_timeout_error                             <= CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error;
                    CSR_hw_in.LTPI_Link_Status.unknown_comma_error                                  <= CSR_hw_out.LTPI_Link_Status.unknown_comma_error;
                    CSR_hw_in.LTPI_Link_Status.frm_CRC_error                                        <= CSR_hw_out.LTPI_Link_Status.frm_CRC_error;
                    CSR_hw_in.LTPI_Link_Status.link_lost_error                                      <= CSR_hw_out.LTPI_Link_Status.link_lost_error;

                    CSR_hw_in.LTPI_counter.link_aligment_err_cnt                                    <= CSR_hw_out.LTPI_counter.link_aligment_err_cnt;
                    CSR_hw_in.LTPI_counter.link_lost_err_cnt                                        <= CSR_hw_out.LTPI_counter.link_lost_err_cnt;
                    CSR_hw_in.LTPI_counter.link_crc_err_cnt                                         <= CSR_hw_out.LTPI_counter.link_crc_err_cnt;
                    CSR_hw_in.LTPI_counter.unknown_comma_err_cnt                                    <= CSR_hw_out.LTPI_counter.unknown_comma_err_cnt;
                    CSR_hw_in.LTPI_counter.link_speed_timeout_err_cnt                               <= CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt;
                    CSR_hw_in.LTPI_counter.link_cfg_acpt_timeout_err_cnt                            <= CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt;

                    CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low                          <= CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low;
                    CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_high                         <= CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high;

                    CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low                          <= CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low;
                    CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_high                         <= CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high;

                    CSR_hw_in.LTPI_counter.operational_frm_rcv_cnt                                  <= CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt;
                    CSR_hw_in.LTPI_counter.operational_frm_snt_cnt                                  <= CSR_hw_out.LTPI_counter.operational_frm_snt_cnt;
                end

                if(wr_reg && avmm_address == 16'h214) begin
                    rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.supported_channel.next               <= rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.supported_channel.value;
                    rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.next                      <= rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.value;
                    rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.next                  <= rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.value;
                    rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.next        <= rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.value;
                end
                if(wr_reg && avmm_address == 16'h218) begin
                    rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.next              <= rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.value;
                    rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[6:5]         <= rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[6:5];
                    rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[4]           <= rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[4];
                    rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[3:0]         <= rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[3:0];
                    rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[15:8]                <= rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[15:8];
                    rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[7:0]                 <= rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[7:0];
                end

            end
        end
    
    end 
    else begin
        
        ltpi_csr_light u_rdl_base_light (
            .clk                    (clk),
            .rst                    (~reset_n),

            .s_cpuif_req            (rdl_base_req),
            .s_cpuif_req_is_wr      (rdl_base_wr_en),
            .s_cpuif_addr           (rdl_base_addr),
            .s_cpuif_wr_data        (rdl_base_wr_data),
            //.s_cpuif_wr_biten       ('1), //unncomment with "old" version of peakRDL
            .s_cpuif_req_stall_wr   (),
            .s_cpuif_req_stall_rd   (),
            .s_cpuif_rd_ack         (rdl_base_rd_ack),
            .s_cpuif_rd_err         (),
            .s_cpuif_rd_data        (rdl_base_rd_data),
            .s_cpuif_wr_ack         (rdl_base_wr_ack),
            .s_cpuif_wr_err         (),
            .hwif_in                (light_rdl_base_hwin),
            .hwif_out               (light_rdl_base_hwout)
        );

        assign light_rdl_base_hwin.LTPI_Link_Status.aligned.next                                  = CSR_hw_out.LTPI_Link_Status.aligned;
        assign light_rdl_base_hwin.LTPI_Link_Status.link_lost_error.next                          = CSR_hw_out.LTPI_Link_Status.link_lost_error;
        assign light_rdl_base_hwin.LTPI_Link_Status.frm_CRC_error.next                            = CSR_hw_out.LTPI_Link_Status.frm_CRC_error;
        assign light_rdl_base_hwin.LTPI_Link_Status.unknown_comma_error.next                      = CSR_hw_out.LTPI_Link_Status.unknown_comma_error;
        assign light_rdl_base_hwin.LTPI_Link_Status.link_speed_timeout_error.next                 = CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error;
        assign light_rdl_base_hwin.LTPI_Link_Status.link_cfg_acpt_timeout_error.next              = CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error;
        assign light_rdl_base_hwin.LTPI_Link_Status.DDR_mode.next                                 = CSR_hw_out.LTPI_Link_Status.DDR_mode;
        assign light_rdl_base_hwin.LTPI_Link_Status.link_speed.next                               = CSR_hw_out.LTPI_Link_Status.link_speed;
        assign light_rdl_base_hwin.LTPI_Link_Status.remote_link_state.next                        = CSR_hw_out.LTPI_Link_Status.remote_link_state;
        assign light_rdl_base_hwin.LTPI_Link_Status.local_link_state.next                         = CSR_hw_out.LTPI_Link_Status.local_link_state;

        assign light_rdl_base_hwin.LTPI_Detect_Capabilities_Remote.remote_Minor_Version.next      = CSR_hw_out.LTPI_Detect_Capab_remote.LTPI_Version[3:0]; 
        assign light_rdl_base_hwin.LTPI_Detect_Capabilities_Remote.remote_Major_Version.next      = CSR_hw_out.LTPI_Detect_Capab_remote.LTPI_Version[7:4];
        assign light_rdl_base_hwin.LTPI_Detect_Capabilities_Remote.link_Speed_capab.next          = CSR_hw_out.LTPI_Detect_Capab_remote.Link_Speed_capab;

        // assign rdl_base_hwin.LTPI_platform_ID_remote.platform_ID_remote.next                = CSR_hw_out.LTPI_platform_ID_remote.ID;

        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.supported_channel.next         = CSR_hw_out.LTPI_Advertise_Capab_remote.supported_channel;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.NL_GPIO_nb.next                = CSR_hw_out.LTPI_Advertise_Capab_remote.NL_GPIO_nb;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.I2C_channel_echo_support.next  = CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_Echo_support;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_LOW.I2C_channel_en.next            = CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_en;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.I2C_channel_speed.next        = CSR_hw_out.LTPI_Advertise_Capab_remote.I2C_channel_cpbl;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.UART_channel_cpbl.next[6:5]   = CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_en;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.UART_channel_cpbl.next[4]     = CSR_hw_out.LTPI_Advertise_Capab_remote.UART_Flow_ctrl;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.UART_channel_cpbl.next[3:0]   = CSR_hw_out.LTPI_Advertise_Capab_remote.UART_channel_cpbl;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.OEM_capab.next[15:8]          = CSR_hw_out.LTPI_Advertise_Capab_remote.OEM_cpbl.byte1;
        assign light_rdl_base_hwin.LTPI_Advertise_Capab_remote_HIGH.OEM_capab.next[7:0]           = CSR_hw_out.LTPI_Advertise_Capab_remote.OEM_cpbl.byte0;

        // assign rdl_base_hwin.link_aligment_err_cnt.err_cnt.next                             = CSR_hw_out.LTPI_counter.link_aligment_err_cnt;
        // assign rdl_base_hwin.link_lost_err_cnt.err_cnt.next                                 = CSR_hw_out.LTPI_counter.link_lost_err_cnt;
        // assign rdl_base_hwin.link_crc_err_cnt.err_cnt.next                                  = CSR_hw_out.LTPI_counter.link_crc_err_cnt;
        // assign rdl_base_hwin.unknown_comma_err_cnt.err_cnt.next                             = CSR_hw_out.LTPI_counter.unknown_comma_err_cnt;
        // assign rdl_base_hwin.link_speed_timeout_err_cnt.err_cnt.next                        = CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt;
        // assign rdl_base_hwin.link_cfg_acpt_timeout_err_cnt.err_cnt.next                     = CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt;

        // assign rdl_base_hwin.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt.next       = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt;
        // assign rdl_base_hwin.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt.next        = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt;
        // assign rdl_base_hwin.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt.next     = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt;
        // assign rdl_base_hwin.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt.next   = CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt;

        // assign rdl_base_hwin.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt.next       = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt;
        // assign rdl_base_hwin.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt.next        = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt;
        // assign rdl_base_hwin.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt.next     = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt;
        // assign rdl_base_hwin.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt.next   = CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt;

        // assign rdl_base_hwin.operational_frm_rcv_cnt.frm_cnt.next                           = CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt;
        // assign rdl_base_hwin.operational_frm_snt_cnt.frm_cnt.next                           = CSR_hw_out.LTPI_counter.operational_frm_snt_cnt;

        ////////////////////////////////////////////DEBUG////////////////////////////////
        assign  light_rdl_base_hwin.smb_trg_dbg_cntrl_smbstate.controller_smbstate.next              = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_cntrl_smbstate.controller_smbstate         ;
        assign  light_rdl_base_hwin.smb_trg_dbg_cntrl_relay_state.relay_state.next                   = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_cntrl_relay_state.relay_state              ;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_i.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_i      ;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_o.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.i2c_event_o      ;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_i.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_i      ;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_o.next           = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ioc_frame_o      ;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_scl_oe.next  = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.SCL_OE           ;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_sda_oe.next  = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.SDA_OE           ;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_scl.next     = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_scl;
        assign  light_rdl_base_hwin.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_sda.next     = CSR_hw_out.LTPI_SMB_DBG_TRG.smb_trg_dbg_relay_event_ioc_frame_bus.ia_controller_sda;
        
        assign  light_rdl_base_hwin.smb_cntrl_dbg_cntrl_smbstate.controller_smbstate.next             = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_cntrl_smbstate.controller_smbstate         ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_cntrl_relay_state.relay_state.next                  = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_cntrl_relay_state.relay_state              ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_i.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_i      ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_o.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.i2c_event_o      ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_i.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_i      ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_o.next          = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ioc_frame_o      ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_scl_oe.next = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.SCL_OE           ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_sda_oe.next = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.SDA_OE           ;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_scl.next    = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_scl;
        assign  light_rdl_base_hwin.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_sda.next    = CSR_hw_out.LTPI_SMB_DBG_CNTRL.smb_cntrl_dbg_relay_event_ioc_frame_bus.ia_controller_sda;
        /////////////////////////////////////////////////////////////////////////////////

        assign CSR_hw_in.LTPI_Detect_Capab_local.Link_Speed_capab                           = light_rdl_base_hwout.LTPI_Detect_Capabilities_Local.link_Speed_capab.value;
        assign CSR_hw_in.LTPI_Detect_Capab_local.LTPI_Version[7:4]                          = light_rdl_base_hwout.LTPI_Detect_Capabilities_Local.local_Major_Version.value;
        assign CSR_hw_in.LTPI_Detect_Capab_local.LTPI_Version[3:0]                          = light_rdl_base_hwout.LTPI_Detect_Capabilities_Local.local_Minor_Version.value;

        assign CSR_hw_in.LTPI_platform_ID_local.ID                                          = light_rdl_base_hwout.LTPI_platform_ID_local.platform_ID_local.value;

        assign CSR_hw_in.LTPI_Advertise_Capab_local.supported_channel                       = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.supported_channel.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.NL_GPIO_nb                              = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_en                          = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.I2C_Echo_support                        = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.I2C_channel_cpbl                        = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.value;
        assign CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_en                         = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[6:5];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.UART_Flow_ctrl                          = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[4];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.UART_channel_cpbl                       = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[3:0];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte1                          = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[15:8];
        assign CSR_hw_in.LTPI_Advertise_Capab_local.OEM_cpbl.byte0                          = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[7:0];

        assign CSR_hw_in.LTPI_Config_Capab.supported_channel                                = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.supported_channel.value;
        assign CSR_hw_in.LTPI_Config_Capab.NL_GPIO_nb                                       = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.value;
        assign CSR_hw_in.LTPI_Config_Capab.I2C_channel_en                                   = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.value;
        assign CSR_hw_in.LTPI_Config_Capab.I2C_Echo_support                                 = light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.value;
        assign CSR_hw_in.LTPI_Config_Capab.I2C_channel_cpbl                                 = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.value;
        assign CSR_hw_in.LTPI_Config_Capab.UART_channel_en                                  = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[6:5];
        assign CSR_hw_in.LTPI_Config_Capab.UART_Flow_ctrl                                   = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[4];
        assign CSR_hw_in.LTPI_Config_Capab.UART_channel_cpbl                                = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[3:0];
        assign CSR_hw_in.LTPI_Config_Capab.OEM_cpbl.byte1                                   = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[15:8];
        assign CSR_hw_in.LTPI_Config_Capab.OEM_cpbl.byte0                                   = light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[7:0];

        assign CSR_hw_in.LTPI_Link_Ctrl.software_reset                                      = light_rdl_base_hwout.LTPI_Link_Ctrl.software_reset.value;
        assign CSR_hw_in.LTPI_Link_Ctrl.retraining_request                                  = light_rdl_base_hwout.LTPI_Link_Ctrl.retraining_req.value;
        assign CSR_hw_in.LTPI_Link_Ctrl.I2C_channel_reset                                   = light_rdl_base_hwout.LTPI_Link_Ctrl.I2C_channel_reset.value;    
        assign CSR_hw_in.LTPI_Link_Ctrl.data_channel_reset                                  = light_rdl_base_hwout.LTPI_Link_Ctrl.data_channel_reset.value;    
        assign CSR_hw_in.LTPI_Link_Ctrl.auto_move_config                                    = light_rdl_base_hwout.LTPI_Link_Ctrl.auto_move_config.value;  
        assign CSR_hw_in.LTPI_Link_Ctrl.trigger_config_st                                   = light_rdl_base_hwout.LTPI_Link_Ctrl.trigger_config_st.value;        

        assign CSR_hw_in.LTPI_Detect_Capab_remote.Link_Speed_capab                          = light_rdl_base_hwout.LTPI_Detect_Capabilities_Remote.link_Speed_capab.value;
        assign CSR_hw_in.LTPI_Detect_Capab_remote.LTPI_Version[7:4]                         = light_rdl_base_hwout.LTPI_Detect_Capabilities_Remote.remote_Major_Version.value;
        assign CSR_hw_in.LTPI_Detect_Capab_remote.LTPI_Version[3:0]                         = light_rdl_base_hwout.LTPI_Detect_Capabilities_Remote.remote_Minor_Version.value;
        
        
        always_ff @ (posedge clk or negedge reset_n) begin
            if (!reset_n) begin
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.supported_channel.next                 <= light_rdl_base_hwout.LTPI_Config_Capab_LOW.supported_channel.value;
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.next                        <= light_rdl_base_hwout.LTPI_Config_Capab_LOW.NL_GPIO_nb.value;
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.next                    <= light_rdl_base_hwout.LTPI_Config_Capab_LOW.I2C_channel_en.value;
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.next          <= light_rdl_base_hwout.LTPI_Config_Capab_LOW.I2C_channel_echo_support.value;
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.next                <= light_rdl_base_hwout.LTPI_Config_Capab_HIGH.I2C_channel_speed.value;
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[6:5]           <= light_rdl_base_hwout.LTPI_Config_Capab_HIGH.UART_channel_cpbl.value[6:5];
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[4]             <= light_rdl_base_hwout.LTPI_Config_Capab_HIGH.UART_channel_cpbl.value[4];
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[3:0]           <= light_rdl_base_hwout.LTPI_Config_Capab_HIGH.UART_channel_cpbl.value[3:0];
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[15:8]                  <= light_rdl_base_hwout.LTPI_Config_Capab_HIGH.OEM_capab.value[15:8];
                light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[7:0]                   <= light_rdl_base_hwout.LTPI_Config_Capab_HIGH.OEM_capab.value[7:0];
            end
            else begin
                CSR_hw_in.clear_reg <= wr_reg;

                if(wr_reg) begin
                    CSR_hw_in.LTPI_Link_Status.link_cfg_acpt_timeout_error                          <= light_rdl_base_hwout.LTPI_Link_Status.link_cfg_acpt_timeout_error.value;
                    CSR_hw_in.LTPI_Link_Status.link_speed_timeout_error                             <= light_rdl_base_hwout.LTPI_Link_Status.link_speed_timeout_error.value;
                    CSR_hw_in.LTPI_Link_Status.unknown_comma_error                                  <= light_rdl_base_hwout.LTPI_Link_Status.unknown_comma_error.value;
                    CSR_hw_in.LTPI_Link_Status.frm_CRC_error                                        <= light_rdl_base_hwout.LTPI_Link_Status.frm_CRC_error.value;
                    CSR_hw_in.LTPI_Link_Status.link_lost_error                                      <= light_rdl_base_hwout.LTPI_Link_Status.link_lost_error.value;
                    
                    //CSR_hw_in.LTPI_counter.link_aligment_err_cnt                                    <= light_rdl_base_hwout.link_aligment_err_cnt.err_cnt.value;
                    //CSR_hw_in.LTPI_counter.link_lost_err_cnt                                        <= light_rdl_base_hwout.link_lost_err_cnt.err_cnt.value;
                    //CSR_hw_in.LTPI_counter.link_crc_err_cnt                                         <= light_rdl_base_hwout.link_crc_err_cnt.err_cnt.value;
                    //CSR_hw_in.LTPI_counter.unknown_comma_err_cnt                                    <= light_rdl_base_hwout.unknown_comma_err_cnt.err_cnt.value;
                    //CSR_hw_in.LTPI_counter.link_speed_timeout_err_cnt                               <= rdl_base_hwout.link_speed_timeout_err_cnt.err_cnt.value;
                    //CSR_hw_in.LTPI_counter.link_cfg_acpt_timeout_err_cnt                            <= rdl_base_hwout.link_cfg_acpt_timeout_err_cnt.err_cnt.value;
                    
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt      <= rdl_base_hwout.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt.value;
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt       <= rdl_base_hwout.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt.value;
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt    <= rdl_base_hwout.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt.value;
                    
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt  <= rdl_base_hwout.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt.value;

                    //CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt      <= rdl_base_hwout.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt.value;
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt       <= rdl_base_hwout.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt.value;                   
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt    <= rdl_base_hwout.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt.value;
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt  <= rdl_base_hwout.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt.value;

                    //CSR_hw_in.LTPI_counter.operational_frm_snt_cnt                                  <= rdl_base_hwout.operational_frm_snt_cnt.frm_cnt.value;
                    //CSR_hw_in.LTPI_counter.operational_frm_rcv_cnt                                  <= rdl_base_hwout.operational_frm_rcv_cnt.frm_cnt.value;

                end
                else begin
                    CSR_hw_in.LTPI_Link_Status.link_cfg_acpt_timeout_error                          <= CSR_hw_out.LTPI_Link_Status.link_cfg_acpt_timeout_error;
                    CSR_hw_in.LTPI_Link_Status.link_speed_timeout_error                             <= CSR_hw_out.LTPI_Link_Status.link_speed_timeout_error;
                    CSR_hw_in.LTPI_Link_Status.unknown_comma_error                                  <= CSR_hw_out.LTPI_Link_Status.unknown_comma_error;
                    CSR_hw_in.LTPI_Link_Status.frm_CRC_error                                        <= CSR_hw_out.LTPI_Link_Status.frm_CRC_error;
                    CSR_hw_in.LTPI_Link_Status.link_lost_error                                      <= CSR_hw_out.LTPI_Link_Status.link_lost_error;

                    //CSR_hw_in.LTPI_counter.link_aligment_err_cnt                                    <= CSR_hw_out.LTPI_counter.link_aligment_err_cnt;
                    //CSR_hw_in.LTPI_counter.link_lost_err_cnt                                        <= CSR_hw_out.LTPI_counter.link_lost_err_cnt;
                    //CSR_hw_in.LTPI_counter.link_crc_err_cnt                                         <= CSR_hw_out.LTPI_counter.link_crc_err_cnt;
                    //CSR_hw_in.LTPI_counter.unknown_comma_err_cnt                                    <= CSR_hw_out.LTPI_counter.unknown_comma_err_cnt;
                    //CSR_hw_in.LTPI_counter.link_speed_timeout_err_cnt                               <= CSR_hw_out.LTPI_counter.link_speed_timeout_err_cnt;
                    //CSR_hw_in.LTPI_counter.link_cfg_acpt_timeout_err_cnt                            <= CSR_hw_out.LTPI_counter.link_cfg_acpt_timeout_err_cnt;

                    //CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_low                          <= CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_low;
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_rcv_cnt_high                         <= CSR_hw_out.LTPI_counter.linkig_training_frm_rcv_cnt_high;

                    //CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_low                          <= CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_low;
                    //CSR_hw_in.LTPI_counter.linkig_training_frm_snt_cnt_high                         <= CSR_hw_out.LTPI_counter.linkig_training_frm_snt_cnt_high;

                    //CSR_hw_in.LTPI_counter.operational_frm_rcv_cnt                                  <= CSR_hw_out.LTPI_counter.operational_frm_rcv_cnt;
                    //CSR_hw_in.LTPI_counter.operational_frm_snt_cnt                                  <= CSR_hw_out.LTPI_counter.operational_frm_snt_cnt;
                end

                if(wr_reg && avmm_address == 16'h214) begin
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.supported_channel.next               <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.supported_channel.value;
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.next                      <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.NL_GPIO_nb.value;
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.next                  <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_en.value;
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.next        <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_LOW.I2C_channel_echo_support.value;
                end
                if(wr_reg && avmm_address == 16'h218) begin
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.next              <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.I2C_channel_speed.value;
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[6:5]         <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[6:5];
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[4]           <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[4];
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.next[3:0]         <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.UART_channel_cpbl.value[3:0];
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[15:8]                <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[15:8];
                    light_rdl_base_hwin.LTPI_Advertise_Capab_local_HIGH.OEM_capab.next[7:0]                 <= light_rdl_base_hwout.LTPI_Advertise_Capab_local_HIGH.OEM_capab.value[7:0];
                end
            end
        end
    end
end
endgenerate

// ------------------------------------------------------------------------------------------------------------------------- //

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- AVMM FSM  --------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //
always_ff @ (posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        avalon_mm_s.readdata            <= 0;
        avalon_mm_s.readdatavalid       <= 0;
        avalon_mm_s.response            <= 0;
        avalon_mm_s.writeresponsevalid  <= 0; 
        avalon_mm_s.waitrequest         <= 0;

        rdl_base_req                    <= 0;
        rdl_base_wr_en                  <= 0;
        rdl_base_addr                   <= 0;
        rdl_base_wr_data                <= 0;

        avmm_fsm                        <= AVMM_FSM_IDLE;
        avmm_rnw                        <= 0;
        avmm_address                    <= 0;
        avmm_data                       <= 0;
        avmm_byte_enable                <= 0;
        avmm_response                   <= 0;

        wr_reg   <= 0;
    end
    else begin
        case (avmm_fsm)
            AVMM_FSM_IDLE: begin
                if (!avalon_mm_s.waitrequest) begin
                    if (avalon_mm_s.chipselect) begin
                        if (avalon_mm_s.write) begin
                            avmm_rnw                    <= 0;
                            avmm_address                <= avalon_mm_s.address[15:0];
                            for (int b = 0; b < 4; b++) begin
                                if (avalon_mm_s.byteenable[b]) begin
                                    avmm_data[b*8 +: 8] <= avalon_mm_s.writedata[b];
                                end
                                else begin
                                    avmm_data[b*8 +: 8] <= 0;
                                end
                            end
                            avmm_byte_enable <= avalon_mm_s.byteenable;
                            avalon_mm_s.waitrequest     <= 1;
                            avmm_fsm                    <= AVMM_FSM_WRITE;
                        end
                        else if (avalon_mm_s.read) begin
                            avmm_rnw                    <= 1;
                            avmm_address                <= avalon_mm_s.address[15:0];
                            avmm_byte_enable            <= avalon_mm_s.byteenable;
                            avalon_mm_s.waitrequest     <= 1;
                            avmm_fsm                    <= AVMM_FSM_READ;
                        end
                    end
                end
                else begin
                    avalon_mm_s.waitrequest             <= 0;
                    avalon_mm_s.response                <= 0;
                    avalon_mm_s.writeresponsevalid      <= 0;
                    avalon_mm_s.readdata                <= { 8'b0, 8'b0, 8'b0, 8'b0 };
                    avalon_mm_s.readdatavalid           <= 0;
                end
            end
            AVMM_FSM_WRITE: begin
                if (avmm_address >= CSR_REGISTERS_BASE_ADDRESS && avmm_address <= CSR_REGISTERS_END_ADDRESS) begin    // base regs
                    rdl_base_req                        <= 1;
                    rdl_base_wr_en                      <= 1;
                    rdl_base_addr                       <= avmm_address;
                    rdl_base_wr_data                    <= avmm_data;
                    avmm_fsm                            <= AVMM_FSM_WR_BASE_RDL;
                end
                else begin
                    avmm_fsm                            <= AVMM_FSM_RESP;
                end
            end
            AVMM_FSM_WR_BASE_RDL: begin
                rdl_base_req                            <= 0;
                rdl_base_wr_en                          <= 0;
                rdl_base_addr                           <= 0;
                rdl_base_wr_data                        <= 0;

                if (rdl_base_wr_ack) begin
                    wr_reg                              <= 1;
                    avmm_fsm                            <= AVMM_FSM_RESP;
                end
            end
            AVMM_FSM_READ: begin
                if (avmm_address >= CSR_REGISTERS_BASE_ADDRESS && avmm_address <= CSR_REGISTERS_END_ADDRESS) begin
                    rdl_base_req                        <= 1;
                    rdl_base_wr_en                      <= 0;
                    rdl_base_addr                       <= avmm_address;
                    avmm_fsm                            <= AVMM_FSM_RD_BASE_RDL;
                end
                else begin
                    avmm_fsm                            <= AVMM_FSM_IDLE;
                end
            end
            AVMM_FSM_RD_BASE_RDL: begin
                rdl_base_req                            <= 0;
                rdl_base_wr_en                          <= 0;
                rdl_base_addr                           <= 0;
                rdl_base_wr_data                        <= 0;

                if (rdl_base_rd_ack) begin
                    avmm_data                           <= rdl_base_rd_data;
                    avmm_fsm                            <= AVMM_FSM_RESP;
                end
            end
            AVMM_FSM_RESP: begin
                wr_reg   <= 0;
                if (avalon_mm_s.chipselect) begin
                    if (avmm_rnw) begin  // R
                        for (int b = 0; b < 4; b++) begin
                            if (avmm_byte_enable[b])    avalon_mm_s.readdata[b] <= avmm_data[b*8 +: 8];
                            else                        avalon_mm_s.readdata[b] <= 0;
                        end
                        avalon_mm_s.readdatavalid       <= 1;
                    end
                    else begin  // W
                        avalon_mm_s.response            <= avmm_response;
                        avalon_mm_s.writeresponsevalid  <= 1;
                    end

                    avmm_rnw                            <= 0;
                    avmm_address                        <= 0;
                    avmm_data                           <= 0;
                    avmm_byte_enable                    <= 0;
                    avmm_fsm                            <= AVMM_FSM_IDLE;
                end

            end
        endcase
    end
end

endmodule