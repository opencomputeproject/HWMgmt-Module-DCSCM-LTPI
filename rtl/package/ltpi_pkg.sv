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
// -- Author        : Katarzyna Krzewska
// -- Date          : 3 december 2021
// -- Project Name  : LTPI
// -- Description   : ltpi_pkg.sv
// --
// -- LTPI Package
// -------------------------------------------------------------------

package ltpi_pkg; 


localparam K28_5                = 8'hBC;
localparam K28_6                = 8'hDC;
localparam K28_7                = 8'hFC;
localparam K28_5_SUB_0          = 8'h00; //detect
localparam K28_5_SUB_1          = 8'h01; //speed
localparam K28_6_SUB_0          = 8'h00; //advertise
localparam K28_6_SUB_1          = 8'h01; //configure
localparam K28_6_SUB_2          = 8'h02; //accept
localparam K28_7_SUB_0          = 8'h00; //defoult IO
localparam K28_7_SUB_1          = 8'h01; //defoult Data

localparam DEFAULT_CAPAB_TYPE   = 8'h00;

localparam CONSECUTIVE_K28_5_LINK_DETECT_LOCK   = 7; //Define how many K28.5 frames, with link detect subtype, should be consecutive detected
localparam CONSECUTIVE_K28_5_LINK_SPEED_LOCK    = 3; //Define how many K28.5 frames, with link speed subtype, should be consecutive detected
localparam CONSECUTIVE_K28_6_ADVERTISE_LOCK     = 3; //Define how many K28.6 frames, with advertise subtype, should be consecutive detected
localparam CONSECUTIVE_K28_1_Loss               = 3; //Define how many K28.1 comma are consecutive detected loss
localparam CONSECUTIVE_CRC_Loss                 = 3; //Define how many CRC check are consecutive detected wrong
localparam MAX_OPERATIONAL_LOST_FRM             = 7; //Define max operational frames which can be lost

localparam TX_K28_5_SUB_0_CNT                   = 8'hFF;
localparam TX_K28_5_SUB_1_CNT                   = 3'h7;
localparam LINK_SPEED_TIMEOUT                   = 8'hFF;
localparam LINK_CFG_TIMEOUT                     = 5'h1F; 
localparam LINK_ACCEPT_TIMEOUT                  = 5'h0F;

localparam LTPI_Version                         = 8'h01;
localparam frame_length                         = 4'd15;

localparam PHASE_SHIFTS_90_DEG_FREQ_x1          = 7'd96;
localparam PHASE_SHIFTS_90_DEG_FREQ_x2          = 7'd48;
localparam PHASE_SHIFTS_90_DEG_FREQ_x3          = 7'd32;
localparam PHASE_SHIFTS_90_DEG_FREQ_x4          = 7'd24;
localparam PHASE_SHIFTS_90_DEG_FREQ_x6          = 7'd16;
localparam PHASE_SHIFTS_90_DEG_FREQ_x8          = 7'd12;
localparam PHASE_SHIFTS_90_DEG_FREQ_x10         = 7'd8;
localparam PHASE_SHIFTS_90_DEG_FREQ_x12         = 7'd8;
localparam PHASE_SHIFTS_90_DEG_FREQ_x16         = 7'd6;
// localparam PHASE_SHIFTS_90_DEG_FREQ_x24               = 7'd0;//not used in MAX10
// localparam PHASE_SHIFTS_90_DEG_FREQ_x32               = 7'd0;//not used in MAX10
// localparam PHASE_SHIFTS_90_DEG_FREQ_x40               = 7'd0;//not used in MAX10

//CLK 60 MHZ
localparam TX_OFFSET_CNT_FREQ_1_SDR             = 6'd24; //frame size 6.4us*60MHz/16
localparam TX_OFFSET_CNT_FREQ_1_DDR             = 6'd12; 
localparam TX_OFFSET_CNT_FREQ_2_SDR             = 6'd12; //frame size 3.2us*60MHz/16
localparam TX_OFFSET_CNT_FREQ_2_DDR             = 6'd6; 
localparam TX_OFFSET_CNT_FREQ_3_SDR             = 6'd8; //frame size 2.133 us*60MHz/16
localparam TX_OFFSET_CNT_FREQ_3_DDR             = 6'd4; 
localparam TX_OFFSET_CNT_FREQ_4_SDR             = 6'd6; //frame size 1.6us*60MHz/16
localparam TX_OFFSET_CNT_FREQ_4_DDR             = 6'd3; 
localparam TX_OFFSET_CNT_FREQ_6_SDR             = 6'd4; //frame size 1.0667 us*60MHz/16
localparam TX_OFFSET_CNT_FREQ_6_DDR             = 6'd2; 
localparam TX_OFFSET_CNT_FREQ_8_SDR             = 6'h3F; //NA
localparam TX_OFFSET_CNT_FREQ_8_DDR             = 6'h3F; //NA

//Clock tick which is needed to send whole frame
localparam FRM_TC_CNT_FREQ_1_SDR                = TX_OFFSET_CNT_FREQ_1_SDR * 16; //ex. frame size 6.4us*60MHz
localparam FRM_TC_CNT_FREQ_1_DDR                = TX_OFFSET_CNT_FREQ_1_DDR * 16; 
localparam FRM_TC_CNT_FREQ_2_SDR                = TX_OFFSET_CNT_FREQ_2_SDR * 16; //ex. frame size 3.2us*60MHz
localparam FRM_TC_CNT_FREQ_2_DDR                = TX_OFFSET_CNT_FREQ_2_DDR * 16;
localparam FRM_TC_CNT_FREQ_3_SDR                = TX_OFFSET_CNT_FREQ_3_SDR * 16; //ex. frame size 2.133 us*60MHz
localparam FRM_TC_CNT_FREQ_3_DDR                = TX_OFFSET_CNT_FREQ_3_DDR * 16;
localparam FRM_TC_CNT_FREQ_4_SDR                = TX_OFFSET_CNT_FREQ_4_SDR * 16;//ex. frame size 1.6us*60MHz
localparam FRM_TC_CNT_FREQ_4_DDR                = TX_OFFSET_CNT_FREQ_4_DDR * 16;
localparam FRM_TC_CNT_FREQ_6_SDR                = TX_OFFSET_CNT_FREQ_6_SDR * 16;//ex. frame size 1.0667 us*60MHz
localparam FRM_TC_CNT_FREQ_6_DDR                = TX_OFFSET_CNT_FREQ_6_DDR * 16;
localparam FRM_TC_CNT_FREQ_8_SDR                = TX_OFFSET_CNT_FREQ_8_SDR * 16;//NA
localparam FRM_TC_CNT_FREQ_8_DDR                = TX_OFFSET_CNT_FREQ_8_DDR * 16;//NA


//CLK 80 MHZ
// localparam TX_OFFSET_CNT_FREQ_1_SDR = 8'd32; //frame size 6.4us*80MHz/16
// localparam TX_OFFSET_CNT_FREQ_1_DDR = 8'd16; 
// localparam TX_OFFSET_CNT_FREQ_2_SDR = 8'd16; //frame size 3.2us*80MHz/16
// localparam TX_OFFSET_CNT_FREQ_2_DDR = 8'd8; 
// localparam TX_OFFSET_CNT_FREQ_3_SDR = 8'dFF; //NA
// localparam TX_OFFSET_CNT_FREQ_3_DDR = 8'dFF; //NA
// localparam TX_OFFSET_CNT_FREQ_4_SDR = 8'd8; //frame size 1.6us*80MHz/16
// localparam TX_OFFSET_CNT_FREQ_4_DDR = 8'd4; 
// localparam TX_OFFSET_CNT_FREQ_6_SDR = 8'dFF; //NA
// localparam TX_OFFSET_CNT_FREQ_6_DDR = 8'dFF; //NA
// localparam TX_OFFSET_CNT_FREQ_8_SDR = 8'h4; //frame size 0.8 us*80MHz/16
// localparam TX_OFFSET_CNT_FREQ_8_DDR = 8'h2; 

//CLK 90MHZ
// localparam TX_OFFSET_CNT_FREQ_1_SDR = 8'd36; //frame size 6.4us*90MHz/16
// localparam TX_OFFSET_CNT_FREQ_1_DDR = 8'd18; 
// localparam TX_OFFSET_CNT_FREQ_2_SDR = 8'd18; //frame size 3.2us*90MHz/16
// localparam TX_OFFSET_CNT_FREQ_2_DDR = 8'd9; 
// localparam TX_OFFSET_CNT_FREQ_3_SDR = 8'd12; //frame size 2.133us*90MHz/16
// localparam TX_OFFSET_CNT_FREQ_3_DDR = 8'd6; 
// localparam TX_OFFSET_CNT_FREQ_4_SDR = 8'd9; //frame size 1.6us*90MHz/16
// localparam TX_OFFSET_CNT_FREQ_4_DDR = 8'dFF; //NA
// localparam TX_OFFSET_CNT_FREQ_6_SDR = 8'd6; //frame size 1.0667 us*90MHz/16
// localparam TX_OFFSET_CNT_FREQ_6_DDR = 8'd3;
// localparam TX_OFFSET_CNT_FREQ_8_SDR = 8'dFF; //NA
// localparam TX_OFFSET_CNT_FREQ_8_DDR = 8'dFF; //NA

//CLK 120 MHZ
// localparam TX_OFFSET_CNT_FREQ_1_SDR = 8'd48; //frame size 6.4us*120MHz/16
// localparam TX_OFFSET_CNT_FREQ_1_DDR = 8'd24; 
// localparam TX_OFFSET_CNT_FREQ_2_SDR = 8'd24; //frame size 3.2us*120MHz/16
// localparam TX_OFFSET_CNT_FREQ_2_DDR = 8'd12; 
// localparam TX_OFFSET_CNT_FREQ_3_SDR = 8'd16; //frame size 1.6us*120MHz/16
// localparam TX_OFFSET_CNT_FREQ_3_DDR = 8'd8; 
// localparam TX_OFFSET_CNT_FREQ_4_SDR = 8'd12; 
// localparam TX_OFFSET_CNT_FREQ_4_DDR = 8'd6; 
// localparam TX_OFFSET_CNT_FREQ_6_SDR = 8'd8; 
// localparam TX_OFFSET_CNT_FREQ_6_DDR = 8'd4; 
// localparam TX_OFFSET_CNT_FREQ_8_SDR = 8'd4; //NA
// localparam TX_OFFSET_CNT_FREQ_8_DDR = 8'd2; //NA



//Link Training and Initialization states
typedef enum logic [3:0]{
    ST_INIT                                 = 4'd0,
    ST_COMMA_HUNTING                        = 4'd1,
    ST_WAIT_LINK_DETECT_LOCKED              = 4'd2,
    ST_WAIT_LINK_SPEED_LOCKED               = 4'd3,
    ST_LINK_SPEED_CHANGE                    = 4'd4,
    ST_WAIT_LINK_ADVERTISE_LOCKED           = 4'd5,
    ST_WAIT_IN_ADVERTISE                    = 4'd6,
    ST_CONFIGURATION_OR_ACCEPT              = 4'd7,
    ST_OPERATIONAL                          = 4'd8,
    ST_OPERATIONAL_RESET                    = 4'd9,
    ST_LINK_LOST_ERR                        = 4'd10
} rstate_t;

//*********     Timer 1ms       ******//
localparam TIMER_1MS_60MHZ = 60000; //1ms clk 60 MHZ

//*********  Base frame   definition******//
typedef struct packed{
    logic [ 7:0]                comma_symbol;
    logic [ 7:0]                frame_subtype;
    logic [ 12:0][ 7:0]         data;
} LTPI_base_Frm_t;

//*********  Advertise frame   definition******//
typedef struct packed{
    logic [1:0][ 7:0]           ID;
} Platform_Type_t;

typedef struct packed{
    logic [ 7:0]                byte0;
    logic [ 7:0]                byte1;
} OEM_Cpbl_t;

typedef struct packed{
    logic [ 4:0]                supported_channel;
    logic [ 9:0]                NL_GPIO_nb;
    logic                       I2C_Echo_support;
    logic [ 5:0]                I2C_channel_en;
    logic [ 5:0]                I2C_channel_cpbl;
    logic [ 1:0]                UART_channel_en;
    logic                       UART_Flow_ctrl;
    logic [ 3:0]                UART_channel_cpbl;
    OEM_Cpbl_t                  OEM_cpbl;
} LTPI_Capabilites_t;

typedef struct packed{
    logic [ 7:0]                comma_symbol;
    logic [ 7:0]                frame_subtype;
    Platform_Type_t             platform_type;
    logic [ 7:0]                capabilities_type;
    LTPI_Capabilites_t          LTPI_Capabilites;
} Advertise_Frm_t;

//*********  Configure/Accept frame   definition******//
typedef struct packed{
    logic [ 7:0]                comma_symbol;
    logic [ 7:0]                frame_subtype;
    logic [ 7:0]                capabilities_type;
    LTPI_Capabilites_t          LTPI_Capabilites;
} Configure_Frm_t;

//*********  Operational default IO frame definition******//
typedef struct packed{
    logic [ 7:0]                comma_symbol;
    logic [ 7:0]                frame_subtype;
    logic [ 7:0]                frame_counter;
    logic [ 1:0][ 7:0]          ll_GPIO;
    logic [ 1:0][ 7:0]          nl_GPIO;
    logic [ 7:0]                uart_data;
    logic [ 2:0][ 7:0]          i2c_data;
    logic [ 3:0][ 7:0]          OEM_data;
} Operational_IO_Frm_t;

//*********  Operational default data frame definition******//

//Data bus command encoding
typedef enum logic [7:0]{
    READ_REQ            = 8'd0,
    WRITE_REQ           = 8'd1,
    READ_COMP           = 8'd2,
    WRITE_COMP          = 8'd3,
    CRC_ERROR           = 8'd4
} data_chnl_comand_t;

typedef struct packed{
    logic [ 7:0]                tag;
    data_chnl_comand_t          command;
    logic [ 3:0][ 7:0]          address;
    logic [ 3:0]                operation_status;
    logic [ 3:0]                byte_en;
    logic [ 3:0][ 7:0]          data;
} Data_channel_payload_t;


typedef struct packed{
    logic [ 7:0]                comma_symbol;
    logic [ 7:0]                frame_subtype;
    logic [ 1:0][ 7:0]          ll_GPIO;
    logic [ 7:0]                tag;
    Data_channel_payload_t      payload;
} Operational_Data_Frm_t;


//*********  CSR register definition******//
typedef enum logic[3:0]{
    link_detect_st              = 4'd0,
    link_speed_st               = 4'd1,
    advertise_st                = 4'd2,
    configuration_accept_st     = 4'd3,
    operational_st              = 4'd4
}link_state_t;

typedef enum logic[3:0]{
    base_freq_x1                = 4'd0,
    base_freq_x2                = 4'd1,
    base_freq_x3                = 4'd2,
    base_freq_x4                = 4'd3,
    base_freq_x6                = 4'd4,
    base_freq_x8                = 4'd5,
    base_freq_x10               = 4'd6,
    base_freq_x12               = 4'd7,
    base_freq_x16               = 4'd8,
    base_freq_x24               = 4'd9,
    base_freq_x32               = 4'd10,
    base_freq_x40               = 4'd11
}link_speed_t;


typedef struct packed{
    link_state_t                local_link_state;
    link_state_t                remote_link_state;
    link_speed_t                link_speed;
    logic                       DDR_mode;
    logic                       link_cfg_acpt_timeout_error;
    logic                       link_speed_timeout_error;
    logic                       unknown_subtype_error;
    logic                       unknown_comma_error;
    logic                       frm_CRC_error;
    logic                       link_lost_error;
    logic                       aligned;
}LTPI_Link_Status_t;

typedef struct packed{
    logic                       link_cfg_acpt_timeout_error;
    logic                       link_speed_timeout_error;
    logic                       unknown_comma_error;
    logic                       frm_CRC_error;
    logic                       link_lost_error;
}LTPI_Link_Status_RWC_t;

typedef struct packed{
    logic [ 1:0][ 7:0]          Link_Speed_capab;
    logic [ 7:0]                LTPI_Version;
} LTPI_Detect_Capab_CSR_t;

typedef struct packed{
    //when auto_move_config LOW, wait for trigger_config_st HIGH to go to configuration state
    logic                       trigger_config_st;
    //auto_move_config
    //when HIGH LTPI SM does not wait for BMC write data to CSR
    //when LOW LTPI wait for BMC write data to CSR register trigger_config_st HIGH
    logic                       auto_move_config; 
    logic                       data_channel_reset;
    logic [ 5:0]                I2C_channel_reset;
    logic                       retraining_request;
    logic                       software_reset;
} LTPI_Link_Ctrl_t;

typedef struct packed{
    logic [ 7:0]                link_cfg_acpt_frm_cnt;
    logic [ 7:0]                link_speed_frm_cnt;
    logic [15:0]                link_detect_frm_cnt;
}Linkig_Training_Frm_Cnt_low_t;

typedef struct packed{
    logic [31:0]                link_advertise_frm_cnt;
}Linkig_Training_Frm_Cnt_high_t;


typedef struct packed {
    logic [31:0]                    link_aligment_err_cnt;
    logic [31:0]                    link_lost_err_cnt;
    logic [31:0]                    link_crc_err_cnt;
    logic [31:0]                    unknown_comma_err_cnt;
    logic [31:0]                    unknown_subtype_err_cnt;
    logic [31:0]                    link_speed_timeout_err_cnt;
    logic [31:0]                    link_cfg_acpt_timeout_err_cnt;
    Linkig_Training_Frm_Cnt_low_t   linkig_training_frm_rcv_cnt_low;
    Linkig_Training_Frm_Cnt_high_t  linkig_training_frm_rcv_cnt_high;
    Linkig_Training_Frm_Cnt_low_t   linkig_training_frm_snt_cnt_low;
    Linkig_Training_Frm_Cnt_high_t  linkig_training_frm_snt_cnt_high;
    logic [31:0]                    operational_frm_rcv_cnt;
    logic [31:0]                    operational_frm_snt_cnt;
}LTPI_Counter_t;

//CRC error struct for generate CRC error 
typedef struct packed{
    logic CRC_error_test_ON;
    link_state_t CRC_error_link_state;
}CRC_error_test_t;

///////////////////////DEBUG///////////////////////////////////
//TRG
typedef struct packed{
    logic [31:0]               controller_smbstate;
}smb_trg_dbg_cntrl_smbstate_t;

typedef struct packed{
    logic [31:0]               relay_state;
}smb_trg_dbg_cntrl_relay_state_t;

typedef struct packed{
    logic [3:0]                i2c_event_i;
    logic [3:0]                i2c_event_o;
    logic [3:0]                ioc_frame_i;
    logic [3:0]                ioc_frame_o;
    logic [0:0]                SCL_OE;
    logic [0:0]                SDA_OE;
    logic [0:0]                ia_controller_scl;
    logic [0:0]                ia_controller_sda;
}smb_trg_dbg_relay_event_ioc_frame_bus_t;

typedef struct packed {
    smb_trg_dbg_cntrl_smbstate_t            smb_trg_dbg_cntrl_smbstate;
    smb_trg_dbg_cntrl_relay_state_t         smb_trg_dbg_cntrl_relay_state;
    smb_trg_dbg_relay_event_ioc_frame_bus_t smb_trg_dbg_relay_event_ioc_frame_bus;
} LTPI_SMB_DBG_TRG_t;


//CNTRL

typedef struct packed{
    logic [31:0]               controller_smbstate;
}smb_cntrl_dbg_cntrl_smbstate_t;

typedef struct packed{
    logic [31:0]               relay_state;
}smb_cntrl_dbg_cntrl_relay_state_t;

typedef struct packed{
    logic [3:0]                i2c_event_i;
    logic [3:0]                i2c_event_o;
    logic [3:0]                ioc_frame_i;
    logic [3:0]                ioc_frame_o;
    logic [0:0]                SCL_OE;
    logic [0:0]                SDA_OE;
    logic [0:0]                ia_controller_scl;
    logic [0:0]                ia_controller_sda;
}smb_cntrl_dbg_relay_event_ioc_frame_bus_t;


typedef struct packed {
    smb_cntrl_dbg_cntrl_smbstate_t            smb_cntrl_dbg_cntrl_smbstate;
    smb_cntrl_dbg_cntrl_relay_state_t         smb_cntrl_dbg_cntrl_relay_state;
    smb_cntrl_dbg_relay_event_ioc_frame_bus_t smb_cntrl_dbg_relay_event_ioc_frame_bus;
} LTPI_SMB_DBG_CNTRL_t;
///////////////////////////////////////////////////////////////


//output data from ltpi_top
typedef struct packed{
    LTPI_Link_Status_t          LTPI_Link_Status;
    LTPI_Detect_Capab_CSR_t     LTPI_Detect_Capab_remote;
    Platform_Type_t             LTPI_platform_ID_remote;
    LTPI_Capabilites_t          LTPI_Advertise_Capab_remote;
    LTPI_Capabilites_t          LTPI_Config_Capab_remote;
    LTPI_Capabilites_t          LTPI_Config_or_Accept_Capab;
    LTPI_Counter_t              LTPI_counter;
    //debug
    LTPI_SMB_DBG_TRG_t          LTPI_SMB_DBG_TRG;
    LTPI_SMB_DBG_CNTRL_t        LTPI_SMB_DBG_CNTRL;
    logic [31:0]                LTPI_pmbus2_recovery_cnt;
} LTPI_CSR_Out_t;//RO

//input data to ltpi_top
typedef struct packed{
    LTPI_Link_Status_RWC_t      LTPI_Link_Status;
    LTPI_Detect_Capab_CSR_t     LTPI_Detect_Capab_local;
    Platform_Type_t             LTPI_platform_ID_local;
    LTPI_Capabilites_t          LTPI_Advertise_Capab_local;
    LTPI_Capabilites_t          LTPI_Config_Capab;
    LTPI_Counter_t              LTPI_counter;
    LTPI_Link_Ctrl_t            LTPI_Link_Ctrl;
    CRC_error_test_t            CRC_error_test; // simulate in witch state there will CRC_error generate 
    //CSR register to read back after speed change
    LTPI_Detect_Capab_CSR_t     LTPI_Detect_Capab_remote;
    logic                       clear_reg;
} LTPI_CSR_In_t;//RW



typedef enum logic [3:0] {
    idle,//0
    start,//1
    start_rcv,//2
    stop,//3
    stop_rcv,//4
    bit_rcv,//5
    data_0,//6
    data_1,//7
    start_echo,//8
    stop_echo,//9
    data_0_echo,//10 - A
    data_1_echo,//11 - B
    data_rcv_echo//12 - C
} smbus_event_t;

endpackage
