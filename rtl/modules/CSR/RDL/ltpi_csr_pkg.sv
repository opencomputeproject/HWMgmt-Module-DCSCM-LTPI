// Generated by PeakRDL-regblock - A free and open-source SystemVerilog generator
//  https://github.com/SystemRDL/PeakRDL-regblock

package ltpi_csr_pkg;
    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Link_Status__aligned__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Link_Status__link_lost_error__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Link_Status__frm_CRC_error__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Link_Status__unknown_comma_error__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Link_Status__link_speed_timeout_error__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Link_Status__link_cfg_acpt_timeout_error__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Link_Status__DDR_mode__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__LTPI_Link_Status__link_speed__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__LTPI_Link_Status__remote_link_state__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__LTPI_Link_Status__local_link_state__in_t;

    typedef struct {
        ltpi_csr__LTPI_Link_Status__aligned__in_t aligned;
        ltpi_csr__LTPI_Link_Status__link_lost_error__in_t link_lost_error;
        ltpi_csr__LTPI_Link_Status__frm_CRC_error__in_t frm_CRC_error;
        ltpi_csr__LTPI_Link_Status__unknown_comma_error__in_t unknown_comma_error;
        ltpi_csr__LTPI_Link_Status__link_speed_timeout_error__in_t link_speed_timeout_error;
        ltpi_csr__LTPI_Link_Status__link_cfg_acpt_timeout_error__in_t link_cfg_acpt_timeout_error;
        ltpi_csr__LTPI_Link_Status__DDR_mode__in_t DDR_mode;
        ltpi_csr__LTPI_Link_Status__link_speed__in_t link_speed;
        ltpi_csr__LTPI_Link_Status__remote_link_state__in_t remote_link_state;
        ltpi_csr__LTPI_Link_Status__local_link_state__in_t local_link_state;
    } ltpi_csr__LTPI_Link_Status__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Minor_Version__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Major_Version__in_t;

    typedef struct {
        logic [15:0] next;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__link_Speed_capab__in_t;

    typedef struct {
        ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Minor_Version__in_t remote_Minor_Version;
        ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Major_Version__in_t remote_Major_Version;
        ltpi_csr__LTPI_Detect_Capabilities_Remote__link_Speed_capab__in_t link_Speed_capab;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__in_t;

    typedef struct {
        logic [15:0] next;
    } ltpi_csr__LTPI_platform_ID_remote__platform_ID_remote__in_t;

    typedef struct {
        ltpi_csr__LTPI_platform_ID_remote__platform_ID_remote__in_t platform_ID_remote;
    } ltpi_csr__LTPI_platform_ID_remote__in_t;

    typedef struct {
        logic [4:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__supported_channel__in_t;

    typedef struct {
        logic [9:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__NL_GPIO_nb__in_t;

    typedef struct {
        logic [5:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_en__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_echo_support__in_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__supported_channel__in_t supported_channel;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__NL_GPIO_nb__in_t NL_GPIO_nb;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_en__in_t I2C_channel_en;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_echo_support__in_t I2C_channel_echo_support;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__in_t;

    typedef struct {
        logic [5:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__I2C_channel_speed__in_t;

    typedef struct {
        logic [6:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__UART_channel_cpbl__in_t;

    typedef struct {
        logic [15:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__OEM_capab__in_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__I2C_channel_speed__in_t I2C_channel_speed;
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__UART_channel_cpbl__in_t UART_channel_cpbl;
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__OEM_capab__in_t OEM_capab;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__in_t;

    typedef struct {
        logic [4:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__supported_channel__in_t;

    typedef struct {
        logic [9:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__NL_GPIO_nb__in_t;

    typedef struct {
        logic [5:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_en__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_echo_support__in_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__supported_channel__in_t supported_channel;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__NL_GPIO_nb__in_t NL_GPIO_nb;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_en__in_t I2C_channel_en;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_echo_support__in_t I2C_channel_echo_support;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__in_t;

    typedef struct {
        logic [5:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__I2C_channel_speed__in_t;

    typedef struct {
        logic [6:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__UART_channel_cpbl__in_t;

    typedef struct {
        logic [15:0] next;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__OEM_capab__in_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__I2C_channel_speed__in_t I2C_channel_speed;
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__UART_channel_cpbl__in_t UART_channel_cpbl;
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__OEM_capab__in_t OEM_capab;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__link_aligment_err_cnt__err_cnt__in_t;

    typedef struct {
        ltpi_csr__link_aligment_err_cnt__err_cnt__in_t err_cnt;
    } ltpi_csr__link_aligment_err_cnt__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__link_lost_err_cnt__err_cnt__in_t;

    typedef struct {
        ltpi_csr__link_lost_err_cnt__err_cnt__in_t err_cnt;
    } ltpi_csr__link_lost_err_cnt__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__link_crc_err_cnt__err_cnt__in_t;

    typedef struct {
        ltpi_csr__link_crc_err_cnt__err_cnt__in_t err_cnt;
    } ltpi_csr__link_crc_err_cnt__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__unknown_comma_err_cnt__err_cnt__in_t;

    typedef struct {
        ltpi_csr__unknown_comma_err_cnt__err_cnt__in_t err_cnt;
    } ltpi_csr__unknown_comma_err_cnt__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__link_speed_timeout_err_cnt__err_cnt__in_t;

    typedef struct {
        ltpi_csr__link_speed_timeout_err_cnt__err_cnt__in_t err_cnt;
    } ltpi_csr__link_speed_timeout_err_cnt__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__link_cfg_acpt_timeout_err_cnt__err_cnt__in_t;

    typedef struct {
        ltpi_csr__link_cfg_acpt_timeout_err_cnt__err_cnt__in_t err_cnt;
    } ltpi_csr__link_cfg_acpt_timeout_err_cnt__in_t;

    typedef struct {
        logic [15:0] next;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__link_detect_frm_cnt__in_t;

    typedef struct {
        logic [7:0] next;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__link_speed_frm_cnt__in_t;

    typedef struct {
        logic [7:0] next;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__link_cfg_acpt_frm_cnt__in_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_rcv_cnt_low__link_detect_frm_cnt__in_t link_detect_frm_cnt;
        ltpi_csr__linkig_training_frm_rcv_cnt_low__link_speed_frm_cnt__in_t link_speed_frm_cnt;
        ltpi_csr__linkig_training_frm_rcv_cnt_low__link_cfg_acpt_frm_cnt__in_t link_cfg_acpt_frm_cnt;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__linkig_training_frm_rcv_cnt_high__link_advertise_frm_cnt__in_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_rcv_cnt_high__link_advertise_frm_cnt__in_t link_advertise_frm_cnt;
    } ltpi_csr__linkig_training_frm_rcv_cnt_high__in_t;

    typedef struct {
        logic [15:0] next;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__link_detect_frm_cnt__in_t;

    typedef struct {
        logic [7:0] next;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__link_speed_frm_cnt__in_t;

    typedef struct {
        logic [7:0] next;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__link_cfg_acpt_frm_cnt__in_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_snt_cnt_low__link_detect_frm_cnt__in_t link_detect_frm_cnt;
        ltpi_csr__linkig_training_frm_snt_cnt_low__link_speed_frm_cnt__in_t link_speed_frm_cnt;
        ltpi_csr__linkig_training_frm_snt_cnt_low__link_cfg_acpt_frm_cnt__in_t link_cfg_acpt_frm_cnt;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__linkig_training_frm_snt_cnt_high__link_advertise_frm_cnt__in_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_snt_cnt_high__link_advertise_frm_cnt__in_t link_advertise_frm_cnt;
    } ltpi_csr__linkig_training_frm_snt_cnt_high__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__operational_frm_rcv_cnt__frm_cnt__in_t;

    typedef struct {
        ltpi_csr__operational_frm_rcv_cnt__frm_cnt__in_t frm_cnt;
    } ltpi_csr__operational_frm_rcv_cnt__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__operational_frm_snt_cnt__frm_cnt__in_t;

    typedef struct {
        ltpi_csr__operational_frm_snt_cnt__frm_cnt__in_t frm_cnt;
    } ltpi_csr__operational_frm_snt_cnt__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__smb_trg_dbg_cntrl_smbstate__controller_smbstate__in_t;

    typedef struct {
        ltpi_csr__smb_trg_dbg_cntrl_smbstate__controller_smbstate__in_t controller_smbstate;
    } ltpi_csr__smb_trg_dbg_cntrl_smbstate__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__smb_trg_dbg_cntrl_relay_state__relay_state__in_t;

    typedef struct {
        ltpi_csr__smb_trg_dbg_cntrl_relay_state__relay_state__in_t relay_state;
    } ltpi_csr__smb_trg_dbg_cntrl_relay_state__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_o__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_i__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_o__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_i__in_t;

    typedef struct {
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda__in_t ia_controller_sda;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl__in_t ia_controller_scl;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__in_t ia_controller_sda_oe;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__in_t ia_controller_scl_oe;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_o__in_t ioc_frame_o;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_i__in_t ioc_frame_i;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_o__in_t i2c_event_o;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_i__in_t i2c_event_i;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__controller_smbstate__in_t;

    typedef struct {
        ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__controller_smbstate__in_t controller_smbstate;
    } ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__relay_state__in_t;

    typedef struct {
        ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__relay_state__in_t relay_state;
    } ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__in_t;

    typedef struct {
        logic next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_o__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_i__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_o__in_t;

    typedef struct {
        logic [3:0] next;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_i__in_t;

    typedef struct {
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda__in_t ia_controller_sda;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl__in_t ia_controller_scl;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__in_t ia_controller_sda_oe;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__in_t ia_controller_scl_oe;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_o__in_t ioc_frame_o;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_i__in_t ioc_frame_i;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_o__in_t i2c_event_o;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_i__in_t i2c_event_i;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__in_t;

    typedef struct {
        logic [31:0] next;
    } ltpi_csr__pmbus2_relay_recovery_cntr__recovery_cnt__in_t;

    typedef struct {
        ltpi_csr__pmbus2_relay_recovery_cntr__recovery_cnt__in_t recovery_cnt;
    } ltpi_csr__pmbus2_relay_recovery_cntr__in_t;

    typedef struct {
        ltpi_csr__LTPI_Link_Status__in_t LTPI_Link_Status;
        ltpi_csr__LTPI_Detect_Capabilities_Remote__in_t LTPI_Detect_Capabilities_Remote;
        ltpi_csr__LTPI_platform_ID_remote__in_t LTPI_platform_ID_remote;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__in_t LTPI_Advertise_Capab_local_LOW;
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__in_t LTPI_Advertise_Capab_local_HIGH;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__in_t LTPI_Advertise_Capab_remote_LOW;
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__in_t LTPI_Advertise_Capab_remote_HIGH;
        ltpi_csr__link_aligment_err_cnt__in_t link_aligment_err_cnt;
        ltpi_csr__link_lost_err_cnt__in_t link_lost_err_cnt;
        ltpi_csr__link_crc_err_cnt__in_t link_crc_err_cnt;
        ltpi_csr__unknown_comma_err_cnt__in_t unknown_comma_err_cnt;
        ltpi_csr__link_speed_timeout_err_cnt__in_t link_speed_timeout_err_cnt;
        ltpi_csr__link_cfg_acpt_timeout_err_cnt__in_t link_cfg_acpt_timeout_err_cnt;
        ltpi_csr__linkig_training_frm_rcv_cnt_low__in_t linkig_training_frm_rcv_cnt_low;
        ltpi_csr__linkig_training_frm_rcv_cnt_high__in_t linkig_training_frm_rcv_cnt_high;
        ltpi_csr__linkig_training_frm_snt_cnt_low__in_t linkig_training_frm_snt_cnt_low;
        ltpi_csr__linkig_training_frm_snt_cnt_high__in_t linkig_training_frm_snt_cnt_high;
        ltpi_csr__operational_frm_rcv_cnt__in_t operational_frm_rcv_cnt;
        ltpi_csr__operational_frm_snt_cnt__in_t operational_frm_snt_cnt;
        ltpi_csr__smb_trg_dbg_cntrl_smbstate__in_t smb_trg_dbg_cntrl_smbstate;
        ltpi_csr__smb_trg_dbg_cntrl_relay_state__in_t smb_trg_dbg_cntrl_relay_state;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__in_t smb_trg_dbg_relay_event_ioc_frame_bus;
        ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__in_t smb_cntrl_dbg_cntrl_smbstate;
        ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__in_t smb_cntrl_dbg_cntrl_relay_state;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__in_t smb_cntrl_dbg_relay_event_ioc_frame_bus;
        ltpi_csr__pmbus2_relay_recovery_cntr__in_t pmbus2_relay_recovery_cntr;
    } ltpi_csr__in_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Status__aligned__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Status__link_lost_error__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Status__frm_CRC_error__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Status__unknown_comma_error__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Status__link_speed_timeout_error__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Status__link_cfg_acpt_timeout_error__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Status__DDR_mode__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__LTPI_Link_Status__link_speed__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__LTPI_Link_Status__remote_link_state__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__LTPI_Link_Status__local_link_state__out_t;

    typedef struct {
        ltpi_csr__LTPI_Link_Status__aligned__out_t aligned;
        ltpi_csr__LTPI_Link_Status__link_lost_error__out_t link_lost_error;
        ltpi_csr__LTPI_Link_Status__frm_CRC_error__out_t frm_CRC_error;
        ltpi_csr__LTPI_Link_Status__unknown_comma_error__out_t unknown_comma_error;
        ltpi_csr__LTPI_Link_Status__link_speed_timeout_error__out_t link_speed_timeout_error;
        ltpi_csr__LTPI_Link_Status__link_cfg_acpt_timeout_error__out_t link_cfg_acpt_timeout_error;
        ltpi_csr__LTPI_Link_Status__DDR_mode__out_t DDR_mode;
        ltpi_csr__LTPI_Link_Status__link_speed__out_t link_speed;
        ltpi_csr__LTPI_Link_Status__remote_link_state__out_t remote_link_state;
        ltpi_csr__LTPI_Link_Status__local_link_state__out_t local_link_state;
    } ltpi_csr__LTPI_Link_Status__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__LTPI_Detect_Capabilities_Local__local_Minor_Version__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__LTPI_Detect_Capabilities_Local__local_Major_Version__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__LTPI_Detect_Capabilities_Local__link_Speed_capab__out_t;

    typedef struct {
        ltpi_csr__LTPI_Detect_Capabilities_Local__local_Minor_Version__out_t local_Minor_Version;
        ltpi_csr__LTPI_Detect_Capabilities_Local__local_Major_Version__out_t local_Major_Version;
        ltpi_csr__LTPI_Detect_Capabilities_Local__link_Speed_capab__out_t link_Speed_capab;
    } ltpi_csr__LTPI_Detect_Capabilities_Local__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Minor_Version__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Major_Version__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__link_Speed_capab__out_t;

    typedef struct {
        ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Minor_Version__out_t remote_Minor_Version;
        ltpi_csr__LTPI_Detect_Capabilities_Remote__remote_Major_Version__out_t remote_Major_Version;
        ltpi_csr__LTPI_Detect_Capabilities_Remote__link_Speed_capab__out_t link_Speed_capab;
    } ltpi_csr__LTPI_Detect_Capabilities_Remote__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__LTPI_platform_ID_local__platform_ID_local__out_t;

    typedef struct {
        ltpi_csr__LTPI_platform_ID_local__platform_ID_local__out_t platform_ID_local;
    } ltpi_csr__LTPI_platform_ID_local__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__LTPI_platform_ID_remote__platform_ID_remote__out_t;

    typedef struct {
        ltpi_csr__LTPI_platform_ID_remote__platform_ID_remote__out_t platform_ID_remote;
    } ltpi_csr__LTPI_platform_ID_remote__out_t;

    typedef struct {
        logic [4:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__supported_channel__out_t;

    typedef struct {
        logic [9:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__NL_GPIO_nb__out_t;

    typedef struct {
        logic [5:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_en__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_echo_support__out_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__supported_channel__out_t supported_channel;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__NL_GPIO_nb__out_t NL_GPIO_nb;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_en__out_t I2C_channel_en;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__I2C_channel_echo_support__out_t I2C_channel_echo_support;
    } ltpi_csr__LTPI_Advertise_Capab_local_LOW__out_t;

    typedef struct {
        logic [5:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__I2C_channel_speed__out_t;

    typedef struct {
        logic [6:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__UART_channel_cpbl__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__OEM_capab__out_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__I2C_channel_speed__out_t I2C_channel_speed;
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__UART_channel_cpbl__out_t UART_channel_cpbl;
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__OEM_capab__out_t OEM_capab;
    } ltpi_csr__LTPI_Advertise_Capab_local_HIGH__out_t;

    typedef struct {
        logic [4:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__supported_channel__out_t;

    typedef struct {
        logic [9:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__NL_GPIO_nb__out_t;

    typedef struct {
        logic [5:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_en__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_echo_support__out_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__supported_channel__out_t supported_channel;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__NL_GPIO_nb__out_t NL_GPIO_nb;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_en__out_t I2C_channel_en;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__I2C_channel_echo_support__out_t I2C_channel_echo_support;
    } ltpi_csr__LTPI_Advertise_Capab_remote_LOW__out_t;

    typedef struct {
        logic [5:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__I2C_channel_speed__out_t;

    typedef struct {
        logic [6:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__UART_channel_cpbl__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__OEM_capab__out_t;

    typedef struct {
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__I2C_channel_speed__out_t I2C_channel_speed;
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__UART_channel_cpbl__out_t UART_channel_cpbl;
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__OEM_capab__out_t OEM_capab;
    } ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__out_t;

    typedef struct {
        logic [4:0] value;
    } ltpi_csr__LTPI_Config_Capab_LOW__supported_channel__out_t;

    typedef struct {
        logic [9:0] value;
    } ltpi_csr__LTPI_Config_Capab_LOW__NL_GPIO_nb__out_t;

    typedef struct {
        logic [5:0] value;
    } ltpi_csr__LTPI_Config_Capab_LOW__I2C_channel_en__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Config_Capab_LOW__I2C_channel_echo_support__out_t;

    typedef struct {
        ltpi_csr__LTPI_Config_Capab_LOW__supported_channel__out_t supported_channel;
        ltpi_csr__LTPI_Config_Capab_LOW__NL_GPIO_nb__out_t NL_GPIO_nb;
        ltpi_csr__LTPI_Config_Capab_LOW__I2C_channel_en__out_t I2C_channel_en;
        ltpi_csr__LTPI_Config_Capab_LOW__I2C_channel_echo_support__out_t I2C_channel_echo_support;
    } ltpi_csr__LTPI_Config_Capab_LOW__out_t;

    typedef struct {
        logic [5:0] value;
    } ltpi_csr__LTPI_Config_Capab_HIGH__I2C_channel_speed__out_t;

    typedef struct {
        logic [6:0] value;
    } ltpi_csr__LTPI_Config_Capab_HIGH__UART_channel_cpbl__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__LTPI_Config_Capab_HIGH__OEM_capab__out_t;

    typedef struct {
        ltpi_csr__LTPI_Config_Capab_HIGH__I2C_channel_speed__out_t I2C_channel_speed;
        ltpi_csr__LTPI_Config_Capab_HIGH__UART_channel_cpbl__out_t UART_channel_cpbl;
        ltpi_csr__LTPI_Config_Capab_HIGH__OEM_capab__out_t OEM_capab;
    } ltpi_csr__LTPI_Config_Capab_HIGH__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__link_aligment_err_cnt__err_cnt__out_t;

    typedef struct {
        ltpi_csr__link_aligment_err_cnt__err_cnt__out_t err_cnt;
    } ltpi_csr__link_aligment_err_cnt__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__link_lost_err_cnt__err_cnt__out_t;

    typedef struct {
        ltpi_csr__link_lost_err_cnt__err_cnt__out_t err_cnt;
    } ltpi_csr__link_lost_err_cnt__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__link_crc_err_cnt__err_cnt__out_t;

    typedef struct {
        ltpi_csr__link_crc_err_cnt__err_cnt__out_t err_cnt;
    } ltpi_csr__link_crc_err_cnt__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__unknown_comma_err_cnt__err_cnt__out_t;

    typedef struct {
        ltpi_csr__unknown_comma_err_cnt__err_cnt__out_t err_cnt;
    } ltpi_csr__unknown_comma_err_cnt__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__link_speed_timeout_err_cnt__err_cnt__out_t;

    typedef struct {
        ltpi_csr__link_speed_timeout_err_cnt__err_cnt__out_t err_cnt;
    } ltpi_csr__link_speed_timeout_err_cnt__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__link_cfg_acpt_timeout_err_cnt__err_cnt__out_t;

    typedef struct {
        ltpi_csr__link_cfg_acpt_timeout_err_cnt__err_cnt__out_t err_cnt;
    } ltpi_csr__link_cfg_acpt_timeout_err_cnt__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__link_detect_frm_cnt__out_t;

    typedef struct {
        logic [7:0] value;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__link_speed_frm_cnt__out_t;

    typedef struct {
        logic [7:0] value;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__link_cfg_acpt_frm_cnt__out_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_rcv_cnt_low__link_detect_frm_cnt__out_t link_detect_frm_cnt;
        ltpi_csr__linkig_training_frm_rcv_cnt_low__link_speed_frm_cnt__out_t link_speed_frm_cnt;
        ltpi_csr__linkig_training_frm_rcv_cnt_low__link_cfg_acpt_frm_cnt__out_t link_cfg_acpt_frm_cnt;
    } ltpi_csr__linkig_training_frm_rcv_cnt_low__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__linkig_training_frm_rcv_cnt_high__link_advertise_frm_cnt__out_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_rcv_cnt_high__link_advertise_frm_cnt__out_t link_advertise_frm_cnt;
    } ltpi_csr__linkig_training_frm_rcv_cnt_high__out_t;

    typedef struct {
        logic [15:0] value;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__link_detect_frm_cnt__out_t;

    typedef struct {
        logic [7:0] value;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__link_speed_frm_cnt__out_t;

    typedef struct {
        logic [7:0] value;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__link_cfg_acpt_frm_cnt__out_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_snt_cnt_low__link_detect_frm_cnt__out_t link_detect_frm_cnt;
        ltpi_csr__linkig_training_frm_snt_cnt_low__link_speed_frm_cnt__out_t link_speed_frm_cnt;
        ltpi_csr__linkig_training_frm_snt_cnt_low__link_cfg_acpt_frm_cnt__out_t link_cfg_acpt_frm_cnt;
    } ltpi_csr__linkig_training_frm_snt_cnt_low__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__linkig_training_frm_snt_cnt_high__link_advertise_frm_cnt__out_t;

    typedef struct {
        ltpi_csr__linkig_training_frm_snt_cnt_high__link_advertise_frm_cnt__out_t link_advertise_frm_cnt;
    } ltpi_csr__linkig_training_frm_snt_cnt_high__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__operational_frm_rcv_cnt__frm_cnt__out_t;

    typedef struct {
        ltpi_csr__operational_frm_rcv_cnt__frm_cnt__out_t frm_cnt;
    } ltpi_csr__operational_frm_rcv_cnt__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__operational_frm_snt_cnt__frm_cnt__out_t;

    typedef struct {
        ltpi_csr__operational_frm_snt_cnt__frm_cnt__out_t frm_cnt;
    } ltpi_csr__operational_frm_snt_cnt__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Ctrl__software_reset__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Ctrl__retraining_req__out_t;

    typedef struct {
        logic [6:0] value;
    } ltpi_csr__LTPI_Link_Ctrl__I2C_channel_reset__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Ctrl__data_channel_reset__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Ctrl__auto_move_config__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__LTPI_Link_Ctrl__trigger_config_st__out_t;

    typedef struct {
        ltpi_csr__LTPI_Link_Ctrl__software_reset__out_t software_reset;
        ltpi_csr__LTPI_Link_Ctrl__retraining_req__out_t retraining_req;
        ltpi_csr__LTPI_Link_Ctrl__I2C_channel_reset__out_t I2C_channel_reset;
        ltpi_csr__LTPI_Link_Ctrl__data_channel_reset__out_t data_channel_reset;
        ltpi_csr__LTPI_Link_Ctrl__auto_move_config__out_t auto_move_config;
        ltpi_csr__LTPI_Link_Ctrl__trigger_config_st__out_t trigger_config_st;
    } ltpi_csr__LTPI_Link_Ctrl__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__smb_trg_dbg_cntrl_smbstate__controller_smbstate__out_t;

    typedef struct {
        ltpi_csr__smb_trg_dbg_cntrl_smbstate__controller_smbstate__out_t controller_smbstate;
    } ltpi_csr__smb_trg_dbg_cntrl_smbstate__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__smb_trg_dbg_cntrl_relay_state__relay_state__out_t;

    typedef struct {
        ltpi_csr__smb_trg_dbg_cntrl_relay_state__relay_state__out_t relay_state;
    } ltpi_csr__smb_trg_dbg_cntrl_relay_state__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_o__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_i__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_o__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_i__out_t;

    typedef struct {
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda__out_t ia_controller_sda;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl__out_t ia_controller_scl;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__out_t ia_controller_sda_oe;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__out_t ia_controller_scl_oe;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_o__out_t ioc_frame_o;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__ioc_frame_i__out_t ioc_frame_i;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_o__out_t i2c_event_o;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__i2c_event_i__out_t i2c_event_i;
    } ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__controller_smbstate__out_t;

    typedef struct {
        ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__controller_smbstate__out_t controller_smbstate;
    } ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__relay_state__out_t;

    typedef struct {
        ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__relay_state__out_t relay_state;
    } ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__out_t;

    typedef struct {
        logic value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_o__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_i__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_o__out_t;

    typedef struct {
        logic [3:0] value;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_i__out_t;

    typedef struct {
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda__out_t ia_controller_sda;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl__out_t ia_controller_scl;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_sda_oe__out_t ia_controller_sda_oe;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ia_controller_scl_oe__out_t ia_controller_scl_oe;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_o__out_t ioc_frame_o;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__ioc_frame_i__out_t ioc_frame_i;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_o__out_t i2c_event_o;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__i2c_event_i__out_t i2c_event_i;
    } ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__out_t;

    typedef struct {
        logic [31:0] value;
    } ltpi_csr__pmbus2_relay_recovery_cntr__recovery_cnt__out_t;

    typedef struct {
        ltpi_csr__pmbus2_relay_recovery_cntr__recovery_cnt__out_t recovery_cnt;
    } ltpi_csr__pmbus2_relay_recovery_cntr__out_t;

    typedef struct {
        ltpi_csr__LTPI_Link_Status__out_t LTPI_Link_Status;
        ltpi_csr__LTPI_Detect_Capabilities_Local__out_t LTPI_Detect_Capabilities_Local;
        ltpi_csr__LTPI_Detect_Capabilities_Remote__out_t LTPI_Detect_Capabilities_Remote;
        ltpi_csr__LTPI_platform_ID_local__out_t LTPI_platform_ID_local;
        ltpi_csr__LTPI_platform_ID_remote__out_t LTPI_platform_ID_remote;
        ltpi_csr__LTPI_Advertise_Capab_local_LOW__out_t LTPI_Advertise_Capab_local_LOW;
        ltpi_csr__LTPI_Advertise_Capab_local_HIGH__out_t LTPI_Advertise_Capab_local_HIGH;
        ltpi_csr__LTPI_Advertise_Capab_remote_LOW__out_t LTPI_Advertise_Capab_remote_LOW;
        ltpi_csr__LTPI_Advertise_Capab_remote_HIGH__out_t LTPI_Advertise_Capab_remote_HIGH;
        ltpi_csr__LTPI_Config_Capab_LOW__out_t LTPI_Config_Capab_LOW;
        ltpi_csr__LTPI_Config_Capab_HIGH__out_t LTPI_Config_Capab_HIGH;
        ltpi_csr__link_aligment_err_cnt__out_t link_aligment_err_cnt;
        ltpi_csr__link_lost_err_cnt__out_t link_lost_err_cnt;
        ltpi_csr__link_crc_err_cnt__out_t link_crc_err_cnt;
        ltpi_csr__unknown_comma_err_cnt__out_t unknown_comma_err_cnt;
        ltpi_csr__link_speed_timeout_err_cnt__out_t link_speed_timeout_err_cnt;
        ltpi_csr__link_cfg_acpt_timeout_err_cnt__out_t link_cfg_acpt_timeout_err_cnt;
        ltpi_csr__linkig_training_frm_rcv_cnt_low__out_t linkig_training_frm_rcv_cnt_low;
        ltpi_csr__linkig_training_frm_rcv_cnt_high__out_t linkig_training_frm_rcv_cnt_high;
        ltpi_csr__linkig_training_frm_snt_cnt_low__out_t linkig_training_frm_snt_cnt_low;
        ltpi_csr__linkig_training_frm_snt_cnt_high__out_t linkig_training_frm_snt_cnt_high;
        ltpi_csr__operational_frm_rcv_cnt__out_t operational_frm_rcv_cnt;
        ltpi_csr__operational_frm_snt_cnt__out_t operational_frm_snt_cnt;
        ltpi_csr__LTPI_Link_Ctrl__out_t LTPI_Link_Ctrl;
        ltpi_csr__smb_trg_dbg_cntrl_smbstate__out_t smb_trg_dbg_cntrl_smbstate;
        ltpi_csr__smb_trg_dbg_cntrl_relay_state__out_t smb_trg_dbg_cntrl_relay_state;
        ltpi_csr__smb_trg_dbg_relay_event_ioc_frame_bus__out_t smb_trg_dbg_relay_event_ioc_frame_bus;
        ltpi_csr__smb_cntrl_dbg_cntrl_smbstate__out_t smb_cntrl_dbg_cntrl_smbstate;
        ltpi_csr__smb_cntrl_dbg_cntrl_relay_state__out_t smb_cntrl_dbg_cntrl_relay_state;
        ltpi_csr__smb_cntrl_dbg_relay_event_ioc_frame_bus__out_t smb_cntrl_dbg_relay_event_ioc_frame_bus;
        ltpi_csr__pmbus2_relay_recovery_cntr__out_t pmbus2_relay_recovery_cntr;
    } ltpi_csr__out_t;
endpackage