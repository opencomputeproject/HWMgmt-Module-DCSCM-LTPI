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
// -- Date          : July 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Management of LTPI transmitted frame
// -------------------------------------------------------------------

module mgmt_ltpi_frm_tx
import ltpi_pkg::*;
#(
    parameter CONTROLLER = 1,
    parameter CSR_LIGHT_VER         = 1
)(
    input wire                      clk,
    input wire                      reset,

    output LTPI_base_Frm_t          ltpi_frame_tx,
    input rstate_t                  LTPI_link_ST,
    input logic [ 3:0]              tx_frm_offset,

    output reg                      transmited_255_detect_frm,
    output reg                      transmited_7_speed_frm,
    output reg                      link_speed_timeout_detect,

    output reg                      link_accept_timeout_detect,
    output reg                      link_cfg_timeout_detect,
    input LTPI_Capabilites_t        accept_frm_capab,

    output link_speed_t             operational_speed,
    input wire                      change_freq_st,

    output logic                    LVDS_DDR,
    input logic [ 6:0]              NL_GPIO_MAX_FRM_CNT,
    input LTPI_base_Frm_t           operational_frm_tx,
    //CSR package 
    input   LTPI_CSR_In_t           LTPI_CSR_In,
    output  LTPI_CSR_Out_t          LTPI_CSR_Out
);

//Frame sent counters
logic [15:0]        link_detect_frm_snt_cnt;
logic [ 7:0]        link_speed_frm_snt_cnt;
logic [ 7:0]        link_cfg_acpt_frm_snt_cnt;
logic [31:0]        link_advertise_frm_snt_cnt;
logic [31:0]        operational_frm_snt_cnt;

//Error counters
logic [31:0]        link_speed_timeout_err_cnt;
logic [31:0]        link_cfg_acpt_timeout_err_cnt;
logic [31:0]        link_aligment_err_cnt;
logic [31:0]        link_lost_err_cnt;
logic               link_lost_err;

Advertise_Frm_t     advertise_frm;
logic [15:0]        local_speed_capabilities;
logic [15:0]        remote_speed_capabilities;
logic [15:0]        speed_select;
link_speed_t        speed;
logic               local_software_reset;

logic               DDR_mode;
logic               pll_reconfig;

logic               tx_frm_offset_flag; // to make sure we count frames just once on tx_frm_offset == frame_length
link_state_t        local_link_state;

Configure_Frm_t     configure_frm;
Configure_Frm_t     accept_frm;

assign operational_speed                    = speed;
assign LVDS_DDR                             = LTPI_CSR_Out.LTPI_Link_Status.DDR_mode;
assign local_speed_capabilities             = LTPI_CSR_In.LTPI_Detect_Capab_local.Link_Speed_capab;
assign remote_speed_capabilities            = LTPI_CSR_In.LTPI_Detect_Capab_remote.Link_Speed_capab;
assign speed_select                         = local_speed_capabilities & remote_speed_capabilities;

assign advertise_frm.comma_symbol           = K28_6;
assign advertise_frm.frame_subtype          = K28_6_SUB_0;
assign advertise_frm.capabilities_type      = DEFAULT_CAPAB_TYPE;
assign advertise_frm.LTPI_Capabilites       = LTPI_CSR_In.LTPI_Advertise_Capab_local;
assign advertise_frm.platform_type          = LTPI_CSR_In.LTPI_platform_ID_local;

assign configure_frm.comma_symbol           = K28_6;
assign configure_frm.frame_subtype          = K28_6_SUB_1;
assign configure_frm.capabilities_type      = DEFAULT_CAPAB_TYPE;
assign configure_frm.LTPI_Capabilites       = LTPI_CSR_In.LTPI_Config_Capab;

assign accept_frm.comma_symbol              = K28_6;
assign accept_frm.frame_subtype             = K28_6_SUB_2;
assign accept_frm.capabilities_type         = DEFAULT_CAPAB_TYPE;
assign accept_frm.LTPI_Capabilites          = accept_frm_capab;

assign local_software_reset                = LTPI_CSR_In.LTPI_Link_Ctrl.software_reset;

//CSR
assign LTPI_CSR_Out.LTPI_Link_Status.local_link_state               = local_link_state;
assign LTPI_CSR_Out.LTPI_Link_Status.DDR_mode                       = ((LTPI_link_ST >= ST_WAIT_LINK_ADVERTISE_LOCKED && LTPI_link_ST != ST_LINK_LOST_ERR) || (change_freq_st && LTPI_link_ST == ST_COMMA_HUNTING)) ? DDR_mode : 1'b0;
assign LTPI_CSR_Out.LTPI_Link_Status.link_speed                     = ((LTPI_link_ST >= ST_WAIT_LINK_ADVERTISE_LOCKED && LTPI_link_ST != ST_LINK_LOST_ERR) || (change_freq_st && LTPI_link_ST == ST_COMMA_HUNTING)) ? speed : base_freq_x1;
assign LTPI_CSR_Out.LTPI_Link_Status.link_speed_timeout_error       = link_speed_timeout_detect;
assign LTPI_CSR_Out.LTPI_Link_Status.link_cfg_acpt_timeout_error    = link_cfg_timeout_detect;
assign LTPI_CSR_Out.LTPI_Link_Status.link_lost_error                = link_lost_err;

assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt        = link_detect_frm_snt_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt         = link_speed_frm_snt_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt    = link_advertise_frm_snt_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt      = link_cfg_acpt_frm_snt_cnt;
assign LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt                                    = operational_frm_snt_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_aligment_err_cnt                                      = link_aligment_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_lost_err_cnt                                          = link_lost_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_cfg_acpt_timeout_err_cnt                              = link_cfg_acpt_timeout_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_speed_timeout_err_cnt                                 = link_speed_timeout_err_cnt;


//Generate frame training 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        ltpi_frame_tx                           <= '0;

        link_detect_frm_snt_cnt                 <= '0;
        link_speed_frm_snt_cnt                  <= '0;
        link_advertise_frm_snt_cnt              <= '0;
        link_cfg_acpt_frm_snt_cnt               <= '0;
        operational_frm_snt_cnt                 <= '0;

        tx_frm_offset_flag                      <= 1'b0;

    end
    else begin
        if(LTPI_CSR_In.clear_reg) begin
            if(LTPI_CSR_In.LTPI_counter.linkig_training_frm_snt_cnt_low == '0) begin
                link_detect_frm_snt_cnt         <= '0;
                link_speed_frm_snt_cnt          <= '0;
                link_cfg_acpt_frm_snt_cnt       <= '0;
            end

            if(LTPI_CSR_In.LTPI_counter.linkig_training_frm_snt_cnt_high == '0) begin
                link_advertise_frm_snt_cnt      <= '0;
            end

            if(LTPI_CSR_In.LTPI_counter.operational_frm_snt_cnt == '0) begin
                operational_frm_snt_cnt         <= '0;
            end
        end

        if((LTPI_link_ST == ST_INIT || LTPI_link_ST == ST_LINK_LOST_ERR) && change_freq_st == 1'b0) begin
            ltpi_frame_tx                       <= '0;
            link_detect_frm_snt_cnt             <= '0;
            link_speed_frm_snt_cnt              <= '0;
            link_advertise_frm_snt_cnt          <= '0;
            link_cfg_acpt_frm_snt_cnt           <= '0;
            operational_frm_snt_cnt             <= '0;
            tx_frm_offset_flag                  <= 1'b0;

        end
        else if(LTPI_link_ST == ST_INIT || LTPI_link_ST == ST_LINK_LOST_ERR) begin
            link_advertise_frm_snt_cnt          <= '0;
            link_cfg_acpt_frm_snt_cnt           <= '0;
            operational_frm_snt_cnt             <= '0;
            tx_frm_offset_flag                  <= 1'b0;
        end
        else begin
            if(tx_frm_offset != frame_length) begin 
                    tx_frm_offset_flag <= 1'b0;
            end
            if ((LTPI_link_ST == ST_COMMA_HUNTING || LTPI_link_ST == ST_WAIT_LINK_DETECT_LOCKED) && change_freq_st == 1'b0)begin
                case(tx_frm_offset )
                    4'd0: begin
                        ltpi_frame_tx.comma_symbol  <= K28_5;
                    end
                    4'd1: begin
                        ltpi_frame_tx.frame_subtype <= K28_5_SUB_0;
                    end
                    4'd2: begin
                        ltpi_frame_tx.data[0]       <= LTPI_Version;//LTPI version
                    end
                    4'd3: begin
                        ltpi_frame_tx.data[1]       <= local_speed_capabilities[ 7:0];//Speed capabilites B1
                    end
                    4'd4: begin
                        ltpi_frame_tx.data[2]      <= local_speed_capabilities[15:8];//Speed capabilites B2
                    end
                    4'd15: begin
                        if(LTPI_link_ST !== ST_COMMA_HUNTING & tx_frm_offset_flag == 1'b0 ) begin
                            link_detect_frm_snt_cnt <= link_detect_frm_snt_cnt + 1'b1;
                            tx_frm_offset_flag <= 1'b1;
                        end
                    end
                    default: begin
                    end //end case of default
                endcase
            end
            else if (LTPI_link_ST == ST_WAIT_LINK_SPEED_LOCKED || LTPI_link_ST == ST_LINK_SPEED_CHANGE) begin
                case(tx_frm_offset )
                    4'd0: begin
                        ltpi_frame_tx.comma_symbol  <= K28_5;
                    end
                    4'd1: begin
                        ltpi_frame_tx.frame_subtype <= K28_5_SUB_1;
                    end
                    4'd2: begin
                        ltpi_frame_tx.data[0] <= LTPI_Version;//LTPI version
                    end
                    4'd3: begin
                        ltpi_frame_tx.data[1] <= speed_select[ 7:0];//Speed select capabilites B1
                    end
                    4'd4: begin
                        ltpi_frame_tx.data[2] <= speed_select[15:8];//Speed select capabilites B2
                    end
                    4'd15: begin
                        if(!tx_frm_offset_flag) begin
                            link_speed_frm_snt_cnt  <= link_speed_frm_snt_cnt + 1'b1;
                            tx_frm_offset_flag <= 1'b1;
                        end
                    end
                    default: begin

                    end //end case of default
                endcase
            end
            else if((LTPI_link_ST == ST_WAIT_LINK_ADVERTISE_LOCKED || LTPI_link_ST == ST_WAIT_IN_ADVERTISE) 
                 || (LTPI_link_ST == ST_COMMA_HUNTING  && change_freq_st)) begin
                case(tx_frm_offset )
                    4'd0: begin
                        ltpi_frame_tx.comma_symbol <= advertise_frm.comma_symbol;
                    end
                    4'd1: begin
                        ltpi_frame_tx.frame_subtype <= advertise_frm.frame_subtype;
                    end
                    4'd2: begin
                        ltpi_frame_tx.data[0] <= advertise_frm.platform_type.ID[1];
                    end
                    4'd3: begin
                        ltpi_frame_tx.data[1] <= advertise_frm.platform_type.ID[0];
                    end
                    4'd4: begin
                        ltpi_frame_tx.data[2] <= advertise_frm.capabilities_type;
                    end
                    4'd5: begin
                        ltpi_frame_tx.data[3] <= {3'd0, advertise_frm.LTPI_Capabilites.supported_channel};
                    end
                    4'd6: begin
                        ltpi_frame_tx.data[4] <= advertise_frm.LTPI_Capabilites.NL_GPIO_nb[7:0];
                    end
                    4'd7: begin
                        ltpi_frame_tx.data[5] <= {6'd0, advertise_frm.LTPI_Capabilites.NL_GPIO_nb[9:8]};
                    end
                    4'd8: begin
                        ltpi_frame_tx.data[6] <= {1'd0, advertise_frm.LTPI_Capabilites.I2C_Echo_support, advertise_frm.LTPI_Capabilites.I2C_channel_en};
                    end
                    4'd9: begin
                        ltpi_frame_tx.data[7] <= {2'd0, advertise_frm.LTPI_Capabilites.I2C_channel_cpbl};
                    end
                    4'd10: begin
                        ltpi_frame_tx.data[8] <= {1'd0, advertise_frm.LTPI_Capabilites.UART_channel_en, advertise_frm.LTPI_Capabilites.UART_Flow_ctrl, advertise_frm.LTPI_Capabilites.UART_channel_cpbl};
                    end
                    4'd11: begin
                        ltpi_frame_tx.data[9] <= advertise_frm.LTPI_Capabilites.OEM_cpbl.byte0;
                    end
                    4'd12: begin
                        ltpi_frame_tx.data[10] <= advertise_frm.LTPI_Capabilites.OEM_cpbl.byte1;
                    end
                    4'd13: begin
                        ltpi_frame_tx.data[11] <= '0;
                    end
                    4'd14: begin
                        ltpi_frame_tx.data[12] <= '0;
                    end
                    4'd15: begin
                        if(!tx_frm_offset_flag) begin
                            link_advertise_frm_snt_cnt  <= link_advertise_frm_snt_cnt + 1;
                            tx_frm_offset_flag <= 1'b1;
                        end
                    end
                    default: begin

                    end //end case of default
                endcase
            end
            else if(LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT) begin
                if(CONTROLLER) begin
                    case(tx_frm_offset )
                        4'd0: begin
                            ltpi_frame_tx.comma_symbol <= configure_frm.comma_symbol;
                        end
                        4'd1: begin
                            ltpi_frame_tx.frame_subtype <= configure_frm.frame_subtype;
                        end
                        4'd2: begin
                            ltpi_frame_tx.data[0] <= configure_frm.capabilities_type;
                        end
                        4'd3: begin
                            ltpi_frame_tx.data[1] <= {3'd0, configure_frm.LTPI_Capabilites.supported_channel};
                        end
                        4'd4: begin
                            ltpi_frame_tx.data[2] <= configure_frm.LTPI_Capabilites.NL_GPIO_nb[7:0];
                        end
                        4'd5: begin
                            ltpi_frame_tx.data[3] <= {6'd0, configure_frm.LTPI_Capabilites.NL_GPIO_nb[9:8]};
                        end
                        4'd6: begin
                            ltpi_frame_tx.data[4] <= {1'd0, configure_frm.LTPI_Capabilites.I2C_Echo_support, configure_frm.LTPI_Capabilites.I2C_channel_en};
                        end
                        4'd7: begin
                            ltpi_frame_tx.data[5] <= {2'd0, configure_frm.LTPI_Capabilites.I2C_channel_cpbl};
                        end
                        4'd8: begin
                            ltpi_frame_tx.data[6] <= {1'd0, configure_frm.LTPI_Capabilites.UART_channel_en, configure_frm.LTPI_Capabilites.UART_Flow_ctrl, configure_frm.LTPI_Capabilites.UART_channel_cpbl};
                        end
                        4'd9: begin
                            ltpi_frame_tx.data[7] <= configure_frm.LTPI_Capabilites.OEM_cpbl.byte0;
                        end
                        4'd10: begin
                            ltpi_frame_tx.data[8] <= configure_frm.LTPI_Capabilites.OEM_cpbl.byte1;
                        end
                        4'd11: begin
                            ltpi_frame_tx.data[9] <= '0;
                        end
                        4'd12: begin
                            ltpi_frame_tx.data[10] <= '0;
                        end
                        4'd13: begin
                            ltpi_frame_tx.data[11] <= '0;
                        end
                        4'd14: begin
                            ltpi_frame_tx.data[12] <= '0;
                        end
                        4'd15: begin
                            if(!tx_frm_offset_flag) begin
                                link_cfg_acpt_frm_snt_cnt <= link_cfg_acpt_frm_snt_cnt + 1;
                                tx_frm_offset_flag <= 1'b1;
                            end
                        end
                        default: begin

                        end //end case of default
                    endcase
                end
                else begin
                    case(tx_frm_offset )
                        4'd0: begin
                            ltpi_frame_tx.comma_symbol <= accept_frm.comma_symbol;
                        end
                        4'd1: begin
                            ltpi_frame_tx.frame_subtype <= accept_frm.frame_subtype;
                        end
                        4'd2: begin
                            ltpi_frame_tx.data[0] <= accept_frm.capabilities_type;
                        end
                        4'd3: begin
                            ltpi_frame_tx.data[1] <= {3'd0, accept_frm.LTPI_Capabilites.supported_channel};
                        end
                        4'd4: begin
                            ltpi_frame_tx.data[2] <= accept_frm.LTPI_Capabilites.NL_GPIO_nb[7:0];
                        end
                        4'd5: begin
                            ltpi_frame_tx.data[3] <= {6'd0, accept_frm.LTPI_Capabilites.NL_GPIO_nb[9:8]};
                        end
                        4'd6: begin
                            ltpi_frame_tx.data[4] <= {1'd0, accept_frm.LTPI_Capabilites.I2C_Echo_support, accept_frm.LTPI_Capabilites.I2C_channel_en};
                        end
                        4'd7: begin
                            ltpi_frame_tx.data[5] <= {2'd0, accept_frm.LTPI_Capabilites.I2C_channel_cpbl};
                        end
                        4'd8: begin
                            ltpi_frame_tx.data[6] <= {1'd0, accept_frm.LTPI_Capabilites.UART_channel_en, accept_frm.LTPI_Capabilites.UART_Flow_ctrl, accept_frm.LTPI_Capabilites.UART_channel_cpbl};
                        end
                        4'd9: begin
                            ltpi_frame_tx.data[7] <= accept_frm.LTPI_Capabilites.OEM_cpbl.byte0;
                        end
                        4'd10: begin
                            ltpi_frame_tx.data[8] <= accept_frm.LTPI_Capabilites.OEM_cpbl.byte1;
                        end
                        4'd11: begin
                            ltpi_frame_tx.data[9] <= '0;
                        end
                        4'd12: begin
                            ltpi_frame_tx.data[10] <= '0;
                        end
                        4'd13: begin
                            ltpi_frame_tx.data[11] <= '0;
                        end
                        4'd14: begin
                            ltpi_frame_tx.data[12] <= '0;
                        end
                        4'd15: begin
                            if(!tx_frm_offset_flag) begin
                                link_cfg_acpt_frm_snt_cnt <= link_cfg_acpt_frm_snt_cnt + 1'b1;
                                tx_frm_offset_flag <= 1'b1;
                            end
                        end
                        default: begin
                        end
                    endcase
                end
            end
            else if (LTPI_link_ST == ST_OPERATIONAL || LTPI_link_ST == ST_OPERATIONAL_RESET) begin
                case(tx_frm_offset )
                    4'd0: begin
                        ltpi_frame_tx.comma_symbol  <= operational_frm_tx.comma_symbol;
                    end
                    4'd1: begin
                        ltpi_frame_tx.frame_subtype <= operational_frm_tx.frame_subtype;
                    end
                    4'd2: begin
                        ltpi_frame_tx.data[0] <= operational_frm_tx.data[0];
                    end
                    4'd3: begin
                        ltpi_frame_tx.data[1] <= operational_frm_tx.data[1];
                    end
                    4'd4: begin
                        ltpi_frame_tx.data[2] <= operational_frm_tx.data[2];
                    end
                    4'd5: begin
                        ltpi_frame_tx.data[3] <= operational_frm_tx.data[3];
                    end
                    4'd6: begin
                        ltpi_frame_tx.data[4] <= operational_frm_tx.data[4];
                    end
                    4'd7: begin
                        ltpi_frame_tx.data[5] <= operational_frm_tx.data[5];
                    end
                    4'd8: begin
                        ltpi_frame_tx.data[6] <= operational_frm_tx.data[6];
                    end
                    4'd9: begin
                        ltpi_frame_tx.data[7] <= operational_frm_tx.data[7];
                    end
                    4'd10: begin
                        ltpi_frame_tx.data[8] <= operational_frm_tx.data[8];
                    end
                    4'd11: begin
                        ltpi_frame_tx.data[9] <= operational_frm_tx.data[9];
                    end
                    4'd12: begin
                        ltpi_frame_tx.data[10] <= operational_frm_tx.data[10];
                    end
                    4'd13: begin
                        ltpi_frame_tx.data[11] <= operational_frm_tx.data[11];
                    end
                    4'd14: begin
                        ltpi_frame_tx.data[12] <= operational_frm_tx.data[12];
                    end
                    4'd15: begin
                        if(!tx_frm_offset_flag) begin
                            operational_frm_snt_cnt <= operational_frm_snt_cnt + 32'd1;
                            tx_frm_offset_flag <= 1'b1;
                        end
                    end
                    default: begin

                    end //end case of default
                endcase
            end
        end
    end
end

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        transmited_255_detect_frm               <= 1'b0; 
    end
    else begin
        if(link_detect_frm_snt_cnt < TX_K28_5_SUB_0_CNT) begin 
            transmited_255_detect_frm           <= 1'b0;
        end
        else begin
            transmited_255_detect_frm           <= 1'b1;
        end
    end
end

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        transmited_7_speed_frm                  <= 1'b0; 
        link_speed_timeout_detect               <= 1'b0;
    end
    else begin
        if(LTPI_link_ST == ST_INIT || LTPI_link_ST == ST_LINK_LOST_ERR) begin
            transmited_7_speed_frm              <= 1'b0;
            link_speed_timeout_detect           <= 1'b0;
        end
        else begin 
            if(link_speed_frm_snt_cnt < TX_K28_5_SUB_1_CNT) begin 
                transmited_7_speed_frm          <= 1'b0;
            end
            else begin
                transmited_7_speed_frm          <= 1'b1;
                if(link_speed_frm_snt_cnt >= LINK_SPEED_TIMEOUT) begin
                    link_speed_timeout_detect   <= 1'b1;
                end
            end
        end
    end
end

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        link_cfg_timeout_detect             <= 1'b0; 
    end
    else begin
        if(link_cfg_acpt_frm_snt_cnt < LINK_CFG_TIMEOUT) begin 
            link_cfg_timeout_detect         <= 1'b0;
        end
        else begin
            link_cfg_timeout_detect         <= 1'b1;
        end
    end
end

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        link_accept_timeout_detect          <= 1'b0; 
    end
    else begin
        if(link_cfg_acpt_frm_snt_cnt < LINK_ACCEPT_TIMEOUT) begin 
            link_accept_timeout_detect      <= 1'b0;
        end
        else begin
            link_accept_timeout_detect      <= 1'b1;
        end
    end
end

//LTPI Link Status - set local link state
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        local_link_state            <= link_detect_st;
    end
    else begin
        case(LTPI_link_ST)
            ST_COMMA_HUNTING: begin
                local_link_state    <= link_detect_st;
            end
            ST_WAIT_LINK_DETECT_LOCKED: begin
                local_link_state    <= link_detect_st;
            end
            ST_WAIT_LINK_SPEED_LOCKED: begin
                local_link_state    <= link_speed_st;
            end
            ST_LINK_SPEED_CHANGE: begin
                local_link_state    <= link_speed_st;
            end
            ST_WAIT_LINK_ADVERTISE_LOCKED: begin
                local_link_state    <= advertise_st;
            end
            ST_WAIT_IN_ADVERTISE: begin
                local_link_state    <= advertise_st;
            end
            ST_CONFIGURATION_OR_ACCEPT: begin
                local_link_state    <= configuration_accept_st;
            end
            ST_OPERATIONAL: begin
                local_link_state    <= operational_st;
            end
        endcase
    end
end

//Read DDR/SDR mode 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        DDR_mode            <= 1'b0;
    end
    else begin
        if(LTPI_link_ST == ST_INIT && pll_reconfig != 1'b1)begin
            DDR_mode        <= 1'b0;
        end
        else if((LTPI_link_ST == ST_WAIT_LINK_DETECT_LOCKED)  //LTPI spec v 0_95 change
            || (LTPI_link_ST == ST_COMMA_HUNTING && change_freq_st)) begin // after change freq we have to read back remote speed
            
            if(speed_select[15]) begin
                DDR_mode    <= 1'b1;
            end
            else begin
                DDR_mode    <= 1'b0;
            end
        end
    end
end

//proceed link speed capabilites 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        speed                       <= base_freq_x1;
    end
    else begin
        if(LTPI_link_ST == ST_INIT & change_freq_st != 1'b1)begin
            speed                   <= base_freq_x1;
        end
        else if((LTPI_link_ST == ST_WAIT_LINK_DETECT_LOCKED)  //LTPI spec v 0_95 change
            || (LTPI_link_ST == ST_COMMA_HUNTING && change_freq_st)) begin // after change freq we have to read back remote speed

            if (speed_select[11])begin
                speed               <= base_freq_x40;
            end
            else if(speed_select[10])begin
                speed               <= base_freq_x32;
            end
            else if(speed_select[9])begin
                speed               <= base_freq_x24;
            end
            else if(speed_select[8])begin
                speed               <= base_freq_x16;
            end
            else if(speed_select[7])begin
                speed               <= base_freq_x12;
            end
            else if(speed_select[6])begin
                speed               <= base_freq_x10;
            end
            else if(speed_select[5])begin
                speed               <= base_freq_x8;
            end
            else if(speed_select[4])begin
                speed               <= base_freq_x6;
            end
            else if(speed_select[3])begin
                speed               <= base_freq_x4;
            end
            else if(speed_select[2])begin
                speed               <= base_freq_x3;
            end
            else if(speed_select[1])begin
                speed               <= base_freq_x2;
            end
            else if(speed_select[0])begin
                speed               <= base_freq_x1;
            end
        end
    end
end

//LTPI Link Status - set lost error 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        link_lost_err       <= 1'b0;
    end
    else begin
        if(LTPI_link_ST == ST_LINK_LOST_ERR) begin
            link_lost_err   <= 1'b1;
        end
        else begin
            link_lost_err   <= 1'b0;
        end
    end
end

//COUNTERS
//link aligment error cnt
//link speed timeout error count 
//link configuration/accept timeout error count

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        link_aligment_err_cnt                   <= '0;
        link_speed_timeout_err_cnt              <= '0;
        link_cfg_acpt_timeout_err_cnt           <= '0;
        link_lost_err_cnt                       <= '0;
    end
    else begin

        if(LTPI_CSR_In.clear_reg) begin
            if(LTPI_CSR_In.LTPI_counter.link_aligment_err_cnt == '0) begin
                link_aligment_err_cnt           <= '0;
            end

            if(LTPI_CSR_In.LTPI_counter.link_speed_timeout_err_cnt == '0) begin
                link_speed_timeout_err_cnt      <= '0;
            end

            if(LTPI_CSR_In.LTPI_counter.link_cfg_acpt_timeout_err_cnt == '0) begin
                link_cfg_acpt_timeout_err_cnt   <='0;
            end

            if(LTPI_CSR_In.LTPI_counter.link_lost_err_cnt == '0) begin
                link_lost_err_cnt               <='0;
            end
        end

        if(LTPI_link_ST == ST_INIT) begin
            link_aligment_err_cnt <='0;
        end
        else if(LTPI_link_ST == ST_COMMA_HUNTING) begin
            if( tx_frm_offset_flag) begin
                link_aligment_err_cnt <= link_aligment_err_cnt + 1;
            end
        end
        else begin

            if(link_speed_timeout_detect) begin
                link_speed_timeout_err_cnt      <= link_speed_timeout_err_cnt + 31'd1;
            end 

            if(link_cfg_timeout_detect) begin
                link_cfg_acpt_timeout_err_cnt   <= link_cfg_acpt_timeout_err_cnt + 31'd1;
            end 

            if(link_lost_err) begin 
                link_lost_err_cnt               <= link_lost_err_cnt + 31'd1;
            end
        end
    end
end

endmodule
