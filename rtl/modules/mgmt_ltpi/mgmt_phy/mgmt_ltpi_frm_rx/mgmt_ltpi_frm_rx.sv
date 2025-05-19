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
// -- Management of LTPI recived frame
// -------------------------------------------------------------------

module mgmt_ltpi_frm_rx 
import ltpi_pkg::*;
#(
    parameter CONTROLLER = 1
)
(
    input wire                  clk,
    input wire                  reset,
    //input signals
    input LTPI_base_Frm_t       ltpi_frame_rx,
    input wire                  frame_crc_err,
    input rstate_t              LTPI_link_ST,
    input wire                  change_freq_st,
    input reg [ 3:0]            rx_frm_offset,
    //outupt signal
    output reg                  link_detect_locked,
    output reg                  link_speed_locked,
    output reg                  advertise_locked,

    output reg                  accept_frm_rcv,
    output reg                  configure_frm_recv,
    output reg                  accept_phase_done,
    output LTPI_Capabilites_t   accept_frm_capab,

    output Operational_IO_Frm_t operational_frm_rx,

    output reg                  crc_consec_loss,
    output reg                  operational_frm_lost_error,
    output reg                  unexpected_frame_error,
    output reg                  remote_software_reset,
    output reg [ 6:0]           NL_GPIO_MAX_FRM_CNT,

    output Data_channel_payload_t data_channel_rx,
    output logic                data_channel_rx_valid,
    output LTPI_CSR_Out_t       LTPI_CSR_Out,
    input LTPI_CSR_In_t         LTPI_CSR_In
);

logic [ 2:0]        crc_consec_loss_cnt;
logic               unknown_comma_error;
logic               unknown_subtype_error;

link_state_t        remote_link_state;
link_state_t        remote_link_state_d;
link_state_t        local_link_state;

logic [ 1:0][ 7:0]  remote_speed_capabilities;
logic [ 7:0]        remote_ltpi_version;
Advertise_Frm_t     remote_advertise_frm;
Configure_Frm_t     remote_conf_or_acpt_frm;

logic [31:0]        crc_error_cnt;
logic [31:0]        unknown_comma_err_cnt;
logic [31:0]        unknown_subtype_err_cnt;


logic [ 7:0]        frame_comma_check   [1:0];
logic [15:0]        link_detect_frm_rcv_cnt;
logic [ 7:0]        link_speed_frm_rcv_cnt;
logic [ 7:0]        link_cfg_acpt_frm_rcv_cnt;
logic [31:0]        link_advertise_frm_rcv_cnt;
logic [31:0]        advertise_frm_rcv_cnt;
logic [31:0]        operational_frm_rcv_cnt;
logic               rx_frm_offset_flag;

Advertise_Frm_t     local_advertise_frm;
Configure_Frm_t     configure_frm;
logic               conf_frm_correct;
logic               local_software_reset;

logic [ 6:0]        NL_gpio_frm_nb ;
logic               offset_flag;
logic [ 3:0]        rx_frm_offset_ff;

assign local_software_reset                 = LTPI_CSR_In.LTPI_Link_Ctrl.software_reset;
assign accept_frm_capab                     = conf_frm_correct ? remote_conf_or_acpt_frm.LTPI_Capabilites : '0;
assign configure_frm.LTPI_Capabilites       = LTPI_CSR_In.LTPI_Config_Capab;

assign LTPI_CSR_Out.LTPI_Detect_Capab_remote.Link_Speed_capab       = remote_speed_capabilities;
assign LTPI_CSR_Out.LTPI_Detect_Capab_remote.LTPI_Version           = remote_ltpi_version;
assign LTPI_CSR_Out.LTPI_Advertise_Capab_remote                     = remote_advertise_frm.LTPI_Capabilites;
assign LTPI_CSR_Out.LTPI_platform_ID_remote                         = remote_advertise_frm.platform_type;
assign LTPI_CSR_Out.LTPI_Config_Capab_remote                        = remote_conf_or_acpt_frm.LTPI_Capabilites;
//assign LTPI_CSR_Out.LTPI_Link_Status.link_cfg_acpt_timeout_error    = link_cfg_timeout_detect;

assign LTPI_CSR_Out.LTPI_Link_Status.unknown_subtype_error          = unknown_subtype_error;
assign LTPI_CSR_Out.LTPI_Link_Status.unknown_comma_error            = unknown_comma_error;
assign LTPI_CSR_Out.LTPI_Link_Status.frm_CRC_error                  = frame_crc_err;
assign LTPI_CSR_Out.LTPI_Link_Status.remote_link_state              = remote_link_state;

assign LTPI_CSR_Out.LTPI_counter.unknown_comma_err_cnt              = unknown_comma_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.unknown_subtype_err_cnt            = unknown_subtype_err_cnt;

assign LTPI_CSR_Out.LTPI_counter.link_crc_err_cnt                   = crc_error_cnt;

assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt        = link_detect_frm_rcv_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt         = link_speed_frm_rcv_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt    = link_advertise_frm_rcv_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt      = link_cfg_acpt_frm_rcv_cnt;
assign LTPI_CSR_Out.LTPI_counter.operational_frm_rcv_cnt                                    = operational_frm_rcv_cnt;

assign local_advertise_frm.LTPI_Capabilites     = LTPI_CSR_In.LTPI_Advertise_Capab_local;
assign local_advertise_frm.platform_type        = LTPI_CSR_In.LTPI_platform_ID_local;

assign frame_comma_check[0]                     = ltpi_frame_rx.comma_symbol;
assign frame_comma_check[1]                     = ltpi_frame_rx.frame_subtype;

assign NL_GPIO_MAX_FRM_CNT                      = NL_gpio_frm_nb;

always_ff @ (posedge clk) rx_frm_offset_ff <= rx_frm_offset;

//CRC CONSECUTIVE loss
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        crc_consec_loss_cnt         <= '0;
        crc_consec_loss             <= 1'b0;
        offset_flag                 <= 1'b0;
    end
    else begin
        if(LTPI_link_ST == ST_INIT || LTPI_link_ST == ST_COMMA_HUNTING) begin
            crc_consec_loss_cnt     <='0;
            crc_consec_loss         <= 1'b0;
            offset_flag             <= 1'b0;
        end
        else begin
            if(rx_frm_offset_ff != frame_length) begin 
                offset_flag         <= 1'b0;
            end

            if(rx_frm_offset_ff == frame_length && frame_crc_err) begin
                crc_consec_loss_cnt <= crc_consec_loss_cnt + 1'b1;
                crc_consec_loss     <= 1'b0;
                offset_flag         <= 1'b1;
            end
            else if (rx_frm_offset_ff == frame_length && ~offset_flag ) begin
                crc_consec_loss_cnt <='0;
                crc_consec_loss     <= 1'b0;
            end
            else if(crc_consec_loss_cnt == CONSECUTIVE_CRC_Loss) begin
                crc_consec_loss     <= 1'b1;
                crc_consec_loss_cnt <='0;
            end
        end
    end
end

logic unexpected_frame_error_ff;
logic unexpected_frame_error_r_edge;

always_ff @(posedge clk) unexpected_frame_error_ff <= unexpected_frame_error;
assign unexpected_frame_error_r_edge = ~unexpected_frame_error_ff & unexpected_frame_error;

//Check if there was recived unexpected frame
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        unexpected_frame_error                  <= 1'b0;
        remote_software_reset                   <= 1'b0;
    end
    else begin
        if (LTPI_link_ST == ST_INIT) begin
            unexpected_frame_error              <= 1'b0;
        end
        else begin
            if(LTPI_link_ST > ST_COMMA_HUNTING) begin
                if(unexpected_frame_error_r_edge) begin
                    unexpected_frame_error      <= 1'b1;
                end
                //else if(remote_link_state >= remote_link_state_d) begin
                else if ((remote_link_state - remote_link_state_d) == 1 || (remote_link_state - remote_link_state_d) == 0) begin
                    unexpected_frame_error      <= 1'b0;
                    remote_software_reset       <= 1'b0;
                end
                else begin
                    if(remote_link_state_d == operational_st && remote_link_state == advertise_st ) begin
                        remote_software_reset   <= 1'b1;
                    end
                    else begin
                        unexpected_frame_error  <= 1'b1;
                    end
                end
            end
        end
    end
end

//delay remote_link_state
always @ (posedge clk or posedge reset) begin
    if(reset) begin
       remote_link_state_d          <= link_detect_st;
    end
    else begin
        remote_link_state_d         <= remote_link_state;
    end
end

//check recive correct comma and subtype
//LTPI Link Status - set remote link state
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        remote_link_state                               <= link_detect_st;
        unknown_comma_error                             <= 1'b0;
        unknown_subtype_error                           <= 1'b0;

        link_detect_frm_rcv_cnt                         <= '0;
        link_speed_frm_rcv_cnt                          <= '0;
        link_advertise_frm_rcv_cnt                      <= '0;
        link_cfg_acpt_frm_rcv_cnt                       <= '0;
        operational_frm_rcv_cnt                         <= '0;
        rx_frm_offset_flag <='0;
    end

    else begin
        if(LTPI_CSR_In.clear_reg) begin
            if(LTPI_CSR_In.LTPI_counter.linkig_training_frm_rcv_cnt_low == '0) begin
                link_detect_frm_rcv_cnt                 <= '0;
                link_speed_frm_rcv_cnt                  <= '0;
                link_cfg_acpt_frm_rcv_cnt               <= '0;
            end

            if(LTPI_CSR_In.LTPI_counter.linkig_training_frm_rcv_cnt_high == '0) begin
                link_advertise_frm_rcv_cnt              <= '0;
            end

            if(LTPI_CSR_In.LTPI_counter.operational_frm_rcv_cnt == '0) begin
                operational_frm_rcv_cnt              <= '0;
            end
        end

        if ((LTPI_link_ST == ST_INIT || LTPI_link_ST == ST_COMMA_HUNTING) && change_freq_st == 1'b0) begin
            link_detect_frm_rcv_cnt                     <= '0;
            link_speed_frm_rcv_cnt                      <= '0;
            link_advertise_frm_rcv_cnt                  <= '0;
            advertise_frm_rcv_cnt                       <= '0;
            link_cfg_acpt_frm_rcv_cnt                   <= '0;
            operational_frm_rcv_cnt                     <= '0;
            unknown_comma_error                         <= 1'b0;
            unknown_subtype_error                       <= 1'b0;
            remote_link_state                           <= link_detect_st;
        end
        else if (LTPI_link_ST == ST_COMMA_HUNTING) begin
            unknown_comma_error                         <= 1'b0;
            unknown_subtype_error                       <= 1'b0;
        end
        else if (LTPI_link_ST == ST_INIT || LTPI_link_ST == ST_LINK_LOST_ERR 
                || remote_software_reset || local_software_reset) begin
            link_advertise_frm_rcv_cnt          <= '0;
            advertise_frm_rcv_cnt               <= '0;
            link_cfg_acpt_frm_rcv_cnt           <= '0;
            operational_frm_rcv_cnt             <= '0;
            unknown_comma_error                 <= 1'b0;
            unknown_subtype_error               <= 1'b0;
            rx_frm_offset_flag                  <= 1'b0;
        end
        else if(rx_frm_offset == frame_length & rx_frm_offset_flag == 1'b0) begin
            //to make sure it will be done once each rx_frm_offset == frame_length
            rx_frm_offset_flag <= 1'b1;

            //LTPI Link Status - set remote link state
            //Link Training RX frames counters
            //Operational RX frames counter
            case(frame_comma_check[0])
                K28_5: begin
                    unknown_comma_error                 <= 1'b0;
                    if(frame_comma_check[1] == K28_5_SUB_0) begin
                        unknown_subtype_error           <= 1'b0;
                        remote_link_state               <= link_detect_st;
                        link_detect_frm_rcv_cnt         <= link_detect_frm_rcv_cnt + 1'b1;
                    end
                    else if(frame_comma_check[1] == K28_5_SUB_1) begin
                        unknown_subtype_error           <= 1'b0;
                        remote_link_state               <= link_speed_st;
                        link_speed_frm_rcv_cnt          <= link_speed_frm_rcv_cnt + 1'b1; 
                    end
                    else begin
                        unknown_subtype_error           <= 1'b1;
                    end
                end
                K28_6: begin
                    unknown_comma_error                 <= 1'b0;
                    if(frame_comma_check[1] == K28_6_SUB_0) begin
                        unknown_subtype_error           <= 1'b0;
                        remote_link_state               <= advertise_st;
                        link_advertise_frm_rcv_cnt      <= link_advertise_frm_rcv_cnt + 32'd1;
                        advertise_frm_rcv_cnt           <= advertise_frm_rcv_cnt + 32'd1;
                    end
                    else if(frame_comma_check[1] == K28_6_SUB_1 || frame_comma_check[1] == K28_6_SUB_2) begin
                        unknown_subtype_error           <= 1'b0;
                        remote_link_state               <= configuration_accept_st;
                        link_cfg_acpt_frm_rcv_cnt       <= link_cfg_acpt_frm_rcv_cnt + 1'b1;
                        if(LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT) begin
                            advertise_frm_rcv_cnt           <='0;
                        end
                    end
                    else begin
                        unknown_subtype_error           <= 1'b1;
                    end
                end
                K28_7: begin
                    unknown_comma_error                 <= 1'b0;
                    if(frame_comma_check[1] == K28_7_SUB_0) begin
                        unknown_subtype_error           <= 1'b0;
                        remote_link_state               <= operational_st;
                        operational_frm_rcv_cnt         <= operational_frm_rcv_cnt + 1;
                    end
                    else if(frame_comma_check[1] == K28_7_SUB_1) begin
                        unknown_subtype_error           <= 1'b0;
                        remote_link_state               <= operational_st;
                        operational_frm_rcv_cnt         <= operational_frm_rcv_cnt + 1;
                    end
                    else begin
                        unknown_subtype_error           <= 1'b1;
                    end
                end
                default: begin
                    unknown_comma_error                 <= 1'b1;

                end
            endcase
        end
        else begin
            if(rx_frm_offset != frame_length) begin
                rx_frm_offset_flag      <= 1'b0;
                unknown_comma_error     <= 1'b0;
                unknown_subtype_error   <= 1'b0;
            end
        end
    end
end

//link detect frame recive equel or more then CONSECUTIVE_K28_5_LINK_DETECT_LOCK
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        link_detect_locked <= 1'b0;
    end
    else begin
        if(link_detect_frm_rcv_cnt < CONSECUTIVE_K28_5_LINK_DETECT_LOCK) begin
            link_detect_locked <= 1'b0;
        end
        else begin
            link_detect_locked <= 1'b1;
        end
    end
end

//link speed frame recive equel or more then CONSECUTIVE_K28_5_LINK_SPEED_LOCK
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        link_speed_locked <= 1'b0;
    end
    else begin
        if(link_speed_frm_rcv_cnt < CONSECUTIVE_K28_5_LINK_SPEED_LOCK) begin
            link_speed_locked <= 1'b0;
        end
        else begin
            link_speed_locked <= 1'b1;
        end
    end
end

//advertise frame recive equel or more then CONSECUTIVE_K28_6_ADVERTISE_LOCK
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        advertise_locked <= 1'b0;
    end
    else begin
        if(LTPI_link_ST == ST_WAIT_LINK_ADVERTISE_LOCKED ) begin
            if(advertise_frm_rcv_cnt < CONSECUTIVE_K28_6_ADVERTISE_LOCK) begin
                advertise_locked <= 1'b0;
            end
            else begin
                advertise_locked <= 1'b1;
            end
        end
        else if(LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT) begin
            advertise_locked        <= 1'b0;
        end
    end
end

//Recive remote device speed capabilities
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        remote_speed_capabilities[0] <='0;
        remote_speed_capabilities[1] <='0;
    end
    else begin
        if(LTPI_link_ST == ST_WAIT_LINK_DETECT_LOCKED ) begin //- LTPI spec 0_95 change

            case (rx_frm_offset_ff)
                4'd2: begin
                    remote_ltpi_version          <= ltpi_frame_rx.data[0];
                end
                4'd3: begin
                    remote_speed_capabilities[0] <= ltpi_frame_rx.data[1];
                end
                4'd4: begin
                    remote_speed_capabilities[1] <= ltpi_frame_rx.data[2];
                end
            endcase
        end
        else if( LTPI_link_ST == ST_COMMA_HUNTING && change_freq_st) begin
            remote_speed_capabilities <= LTPI_CSR_In.LTPI_Detect_Capab_remote.Link_Speed_capab;
        end
    
    end
end

//Recive remote advertise frame
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        remote_advertise_frm                          <= '0;
    end
    else begin
        if(LTPI_link_ST == ST_WAIT_LINK_ADVERTISE_LOCKED && advertise_locked != 1'b1) begin

            case(rx_frm_offset_ff)
                4'd0: begin
                    remote_advertise_frm.comma_symbol                       <= ltpi_frame_rx.comma_symbol;
                end
                4'd1: begin
                    remote_advertise_frm.frame_subtype                      <= ltpi_frame_rx.frame_subtype;
                end
                4'd2: begin
                    remote_advertise_frm.platform_type.ID[1]                <= ltpi_frame_rx.data[0];
                end
                4'd3: begin
                    remote_advertise_frm.platform_type.ID[0]                <= ltpi_frame_rx.data[1];
                end
                4'd4: begin
                    remote_advertise_frm.capabilities_type                  <= ltpi_frame_rx.data[2];
                end
                4'd5: begin
                    remote_advertise_frm.LTPI_Capabilites.supported_channel <= ltpi_frame_rx.data[3][4:0];
                end
                4'd6: begin
                    remote_advertise_frm.LTPI_Capabilites.NL_GPIO_nb[7:0]   <= ltpi_frame_rx.data[4];
                end
                4'd7: begin
                    remote_advertise_frm.LTPI_Capabilites.NL_GPIO_nb[9:8]   <= ltpi_frame_rx.data[5][1:0];
                end
                4'd8: begin
                    remote_advertise_frm.LTPI_Capabilites.I2C_Echo_support  <= ltpi_frame_rx.data[6][6];
                    remote_advertise_frm.LTPI_Capabilites.I2C_channel_en    <= ltpi_frame_rx.data[6][5:0];
                end
                4'd9: begin
                    remote_advertise_frm.LTPI_Capabilites.I2C_channel_cpbl  <= ltpi_frame_rx.data[7][5:0];
                end
                4'd10: begin
                    remote_advertise_frm.LTPI_Capabilites.UART_channel_en   <= ltpi_frame_rx.data[8][6:5];
                    remote_advertise_frm.LTPI_Capabilites.UART_Flow_ctrl    <= ltpi_frame_rx.data[8][4];
                    remote_advertise_frm.LTPI_Capabilites.UART_channel_cpbl <= ltpi_frame_rx.data[8][3:0];
                end
                4'd11: begin
                    remote_advertise_frm.LTPI_Capabilites.OEM_cpbl.byte0    <= ltpi_frame_rx.data[9];
                end
                4'd12: begin
                    remote_advertise_frm.LTPI_Capabilites.OEM_cpbl.byte1    <= ltpi_frame_rx.data[10];
                end

            endcase
        end
        
    end
end

//recive accept or configuration frame 
always @ (posedge clk or posedge reset or posedge remote_software_reset) begin
    if(reset || remote_software_reset) begin
        remote_conf_or_acpt_frm <= '0;
    end
    else begin
        if(LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT) begin

            case(rx_frm_offset_ff)
                4'd0: begin
                    remote_conf_or_acpt_frm.comma_symbol                        <= ltpi_frame_rx.comma_symbol;
                end
                4'd1: begin
                    remote_conf_or_acpt_frm.frame_subtype                       <= ltpi_frame_rx.frame_subtype;
                end
                4'd2: begin
                    remote_conf_or_acpt_frm.capabilities_type                   <= ltpi_frame_rx.data[0];
                end
                4'd3: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.supported_channel  <= {3'd0, ltpi_frame_rx.data[1][4:0]};
                end
                4'd4: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.NL_GPIO_nb[7:0]    <= ltpi_frame_rx.data[2];
                end
                4'd5: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.NL_GPIO_nb[9:8]    <= {6'd0, ltpi_frame_rx.data[3][1:0]};
                end
                4'd6: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.I2C_Echo_support   <= ltpi_frame_rx.data[4][6];
                    remote_conf_or_acpt_frm.LTPI_Capabilites.I2C_channel_en     <= ltpi_frame_rx.data[4][5:0];
                end
                4'd7: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.I2C_channel_cpbl   <= ltpi_frame_rx.data[5][5:0];
                end
                4'd8: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.UART_channel_en    <= ltpi_frame_rx.data[6][6:5];
                    remote_conf_or_acpt_frm.LTPI_Capabilites.UART_Flow_ctrl     <= ltpi_frame_rx.data[6][4];
                    remote_conf_or_acpt_frm.LTPI_Capabilites.UART_channel_cpbl  <= ltpi_frame_rx.data[6][3:0];
                end
                4'd9: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.OEM_cpbl.byte0     <= ltpi_frame_rx.data[7];
                end
                4'd10: begin
                    remote_conf_or_acpt_frm.LTPI_Capabilites.OEM_cpbl.byte0     <= ltpi_frame_rx.data[8];
                end
            endcase
        end
    end
end


//recive from SCM operational frame
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        operational_frm_rx.comma_symbol         <= '0;
        operational_frm_rx.frame_subtype        <= '0;
        operational_frm_rx.frame_counter        <= '0;
        operational_frm_rx.ll_GPIO              <= '0;
        operational_frm_rx.nl_GPIO              <= '0;
        operational_frm_rx.uart_data            <= 8'h77; //reset value should be 1 to as UART idle is pulled high, to avoid glitch.
        operational_frm_rx.i2c_data             <= '0;
        operational_frm_rx.OEM_data             <= '0;
        data_channel_rx                         <= 0;
        data_channel_rx_valid                   <= 0;

    end
    else begin
        if(LTPI_link_ST != ST_OPERATIONAL ) begin
            operational_frm_rx.comma_symbol     <= '0;
            operational_frm_rx.frame_subtype    <= '0;
            operational_frm_rx.frame_counter    <= '0;
            operational_frm_rx.ll_GPIO          <= '0;
            operational_frm_rx.nl_GPIO          <= '0;
            operational_frm_rx.uart_data        <= 8'h77; //reset value should be 1 to as UART idle is pulled high, to avoid glitch.
            operational_frm_rx.i2c_data         <= '0;
            operational_frm_rx.OEM_data         <= '0;
            operational_frm_rx.frame_counter    <= '0;
        end
        else if((LTPI_link_ST == ST_OPERATIONAL || LTPI_link_ST == ST_OPERATIONAL_RESET ) & remote_link_state == operational_st) begin 
            if(ltpi_frame_rx.frame_subtype == K28_7_SUB_0) begin
                data_channel_rx_valid               <= 0;
                data_channel_rx                     <= 0;

                operational_frm_rx.comma_symbol     <= ltpi_frame_rx.comma_symbol;
                operational_frm_rx.frame_subtype    <= ltpi_frame_rx.frame_subtype;
                operational_frm_rx.frame_counter    <= ltpi_frame_rx.data[0];
                if(rx_frm_offset_ff == 3) begin
                    operational_frm_rx.ll_GPIO[0]       <= ltpi_frame_rx.data[1];
                end
                else if (rx_frm_offset_ff == 4) begin
                    operational_frm_rx.ll_GPIO[1]       <= ltpi_frame_rx.data[2];
                end
                else if (rx_frm_offset_ff == 5) begin
                    operational_frm_rx.nl_GPIO[0]       <= ltpi_frame_rx.data[3];
                end
                else if (rx_frm_offset_ff == 6) begin
                    operational_frm_rx.nl_GPIO[1]       <= ltpi_frame_rx.data[4];
                end
                else if (rx_frm_offset_ff == 7) begin
                    operational_frm_rx.uart_data        <= ltpi_frame_rx.data[5];
                end
                else if (rx_frm_offset_ff == 8) begin
                    operational_frm_rx.i2c_data[0]      <= ltpi_frame_rx.data[6];
                end
                else if (rx_frm_offset_ff == 9) begin
                    operational_frm_rx.i2c_data[1]      <= ltpi_frame_rx.data[7];
                end
                else if (rx_frm_offset_ff == 10) begin
                    operational_frm_rx.i2c_data[2]      <= ltpi_frame_rx.data[8];
                end
                else if (rx_frm_offset_ff == 11) begin
                    operational_frm_rx.OEM_data[0]      <= ltpi_frame_rx.data[9];
                end
                else if (rx_frm_offset_ff == 12) begin
                    operational_frm_rx.OEM_data[1]      <= ltpi_frame_rx.data[10];
                end
                else if (rx_frm_offset_ff == 13) begin
                    operational_frm_rx.OEM_data[2]      <= ltpi_frame_rx.data[11];
                end
                else if (rx_frm_offset_ff == 14) begin
                    operational_frm_rx.OEM_data[3]      <= ltpi_frame_rx.data[12];
                end
            end
            else if(ltpi_frame_rx.frame_subtype == K28_7_SUB_1) begin
                operational_frm_rx.comma_symbol     <= ltpi_frame_rx.comma_symbol;
                operational_frm_rx.frame_subtype    <= ltpi_frame_rx.frame_subtype;
                if(rx_frm_offset_ff == 2) begin
                    operational_frm_rx.ll_GPIO[0]   <= ltpi_frame_rx.data[0];
                end
                else if (rx_frm_offset_ff == 3) begin
                    operational_frm_rx.ll_GPIO[1]   <= ltpi_frame_rx.data[1];
                end
            
                data_channel_rx.tag                     <= ltpi_frame_rx.data[2];
                data_channel_rx.command                 <= data_chnl_comand_t'(ltpi_frame_rx.data[3]);
                data_channel_rx.address[3]              <= ltpi_frame_rx.data[4];
                data_channel_rx.address[2]              <= ltpi_frame_rx.data[5];
                data_channel_rx.address[1]              <= ltpi_frame_rx.data[6];
                data_channel_rx.address[0]              <= ltpi_frame_rx.data[7];
                data_channel_rx.operation_status        <= ltpi_frame_rx.data[8][7:4];
                data_channel_rx.byte_en                 <= ltpi_frame_rx.data[8][3:0];
                data_channel_rx.data[3]                 <= ltpi_frame_rx.data[9];
                data_channel_rx.data[2]                 <= ltpi_frame_rx.data[10];
                data_channel_rx.data[1]                 <= ltpi_frame_rx.data[11];
                data_channel_rx.data[0]                 <= ltpi_frame_rx.data[12];
                if(rx_frm_offset_ff == 4'hf) begin
                    data_channel_rx_valid <= 1;
                end
                else begin
                    data_channel_rx_valid <= 0;
                end
            end
        end
    end
end

logic [6:0] frm_counter_prev;
logic [6:0] frm_cnt_subtract;

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        operational_frm_lost_error              <= 0;
        frm_counter_prev                        <= 0;
        frm_cnt_subtract                        <= 0;
    end
    else begin
        if(LTPI_link_ST == ST_OPERATIONAL & operational_frm_rx.frame_subtype == K28_7_SUB_0) begin
            if(rx_frm_offset_ff == 0) begin
                frm_counter_prev                <= operational_frm_rx.frame_counter;
            end
            else if (rx_frm_offset_ff == frame_length - 1 ) begin
                if(frm_counter_prev == NL_GPIO_MAX_FRM_CNT - 1) begin
                    frm_cnt_subtract            <= operational_frm_rx.frame_counter;
                end
                else begin
                    frm_cnt_subtract            <= operational_frm_rx.frame_counter - frm_counter_prev ;
                end
            end
            else if (rx_frm_offset_ff == frame_length) begin

                if(frm_cnt_subtract >= MAX_OPERATIONAL_LOST_FRM) begin
                    operational_frm_lost_error  <= 1;
                end
                else begin
                    operational_frm_lost_error  <= 0;
                end
            end
            
        end
        else if (LTPI_link_ST != ST_OPERATIONAL) begin
            operational_frm_lost_error          <= 0;
            frm_counter_prev                    <= 0;
            frm_cnt_subtract                    <= 0;
        end
    end
end

//COUNTERS
//crc errorr count
//unknown comma error count
//unknown subtype error count
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        crc_error_cnt                           <= '0;
        unknown_comma_err_cnt                   <= '0;
        unknown_subtype_err_cnt                 <= '0;
    end
    else begin

            //if(rx_frm_offset == '0 && frame_crc_err) begin
            if(LTPI_link_ST != ST_LINK_SPEED_CHANGE && frame_crc_err) begin
                crc_error_cnt                   <= crc_error_cnt + 32'd1;
            end

            if(LTPI_link_ST != ST_LINK_SPEED_CHANGE && rx_frm_offset == '0 && unknown_comma_error) begin
                unknown_comma_err_cnt           <= unknown_comma_err_cnt + 32'd1; 
            
            end

            if(rx_frm_offset == '0 && unknown_subtype_error) begin
                unknown_subtype_err_cnt         <= unknown_subtype_err_cnt + 32'd1; 
            end
    end
end

//*********************************ONLY for Target
//Check if we get configuration frame 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        configure_frm_recv          <= 1'b0;
    end
    else begin
        if(rx_frm_offset == frame_length) begin
            if(LTPI_link_ST == ST_WAIT_LINK_ADVERTISE_LOCKED  || LTPI_link_ST == ST_WAIT_IN_ADVERTISE) begin
                if(advertise_locked) begin
                    if(frame_comma_check[0] == K28_6 && frame_comma_check[1] == K28_6_SUB_1) begin
                        configure_frm_recv          <= 1'b1;
                    end
                    else begin
                        configure_frm_recv          <= 1'b0;
                    end
                end
            end
            else if (LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT) begin
                //configure_frm_recv                  <= 1'b0;
            end
            else begin
                configure_frm_recv                  <= 1'b0;
            end
        end
    end
end

//ONLY for Target
//check if we recive correct configuration frame from host
always @ (posedge clk or posedge reset) begin
    if(reset ) begin
        conf_frm_correct             <= 1'b0;
    end
    else begin
        if ( LTPI_link_ST == ST_INIT) begin
            conf_frm_correct            <= 1'b0;
        end 
        else if(LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT && rx_frm_offset == frame_length) begin
            if(remote_conf_or_acpt_frm.comma_symbol == K28_6 & remote_conf_or_acpt_frm.frame_subtype == K28_6_SUB_1) begin
                if(((local_advertise_frm.LTPI_Capabilites.supported_channel ^ remote_conf_or_acpt_frm.LTPI_Capabilites.supported_channel)
                    & (~local_advertise_frm.LTPI_Capabilites.supported_channel)) !='0) begin
                    conf_frm_correct <= 1'b0;
                end
                else if (remote_conf_or_acpt_frm.LTPI_Capabilites.NL_GPIO_nb > local_advertise_frm.LTPI_Capabilites.NL_GPIO_nb) begin
                    conf_frm_correct <= 1'b0;
                end                
                else if (remote_conf_or_acpt_frm.LTPI_Capabilites.I2C_Echo_support > local_advertise_frm.LTPI_Capabilites.I2C_Echo_support) begin
                    conf_frm_correct <= 1'b0;
                end
                else if (((local_advertise_frm.LTPI_Capabilites.I2C_channel_en ^ remote_conf_or_acpt_frm.LTPI_Capabilites.I2C_channel_en)
                    & (~local_advertise_frm.LTPI_Capabilites.I2C_channel_en)) != '0) begin
                    conf_frm_correct <= 1'b0;
                end
                else if (((local_advertise_frm.LTPI_Capabilites.I2C_channel_cpbl ^ remote_conf_or_acpt_frm.LTPI_Capabilites.I2C_channel_cpbl)
                    & (~local_advertise_frm.LTPI_Capabilites.I2C_channel_cpbl)) != '0) begin
                    conf_frm_correct <= 1'b0;
                end
                else if (((local_advertise_frm.LTPI_Capabilites.UART_channel_en ^ remote_conf_or_acpt_frm.LTPI_Capabilites.UART_channel_en)
                    & (~local_advertise_frm.LTPI_Capabilites.UART_channel_en)) != '0) begin
                    conf_frm_correct <= 1'b0;
                end
                else if (remote_conf_or_acpt_frm.LTPI_Capabilites.UART_channel_cpbl > local_advertise_frm.LTPI_Capabilites.UART_channel_cpbl) begin
                    conf_frm_correct <= 1'b0;
                end
                else if (remote_conf_or_acpt_frm.LTPI_Capabilites.UART_Flow_ctrl > local_advertise_frm.LTPI_Capabilites.UART_Flow_ctrl) begin
                    conf_frm_correct <= 1'b0;
                end
                //else if (..)
                    //here add OEM capabilites handel error
                //
                else begin
                    conf_frm_correct <= 1'b1;
                end
            end

        end
        else if(LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT )begin

        end
        else begin
            conf_frm_correct         <= 1'b0;
        end
    end
end

always @ (posedge clk or posedge reset) begin
    if(reset ) begin
        accept_phase_done            <= 1'b0;
    end
    else begin 
        if ( LTPI_link_ST == ST_INIT) begin
            accept_phase_done            <= 1'b0;
        end 
        else if(remote_conf_or_acpt_frm.comma_symbol == K28_7 && remote_conf_or_acpt_frm.frame_subtype == K28_7_SUB_0) begin
            if(conf_frm_correct)begin
                accept_phase_done       <= 1'b1;
            end
        end
        else begin
            accept_phase_done       <= 1'b0;
        end
    end
end

//*********************************

//*******************ONLY CONTROLLER
//check if accept frame is correct

always @ (posedge clk or posedge reset) begin
    if(reset ) begin
        accept_frm_rcv                  <= 1'b0;
    end
    else begin
        if(LTPI_link_ST == ST_CONFIGURATION_OR_ACCEPT && rx_frm_offset == frame_length) begin
            if(remote_conf_or_acpt_frm.comma_symbol == K28_6 && remote_conf_or_acpt_frm.frame_subtype == K28_6_SUB_2 ) begin
                if(remote_conf_or_acpt_frm.LTPI_Capabilites == configure_frm.LTPI_Capabilites) begin
                    accept_frm_rcv      <= 1'b1;
                end
                else begin
                    accept_frm_rcv      <= 1'b0;
                end
            end
        end
        else if (LTPI_link_ST != ST_CONFIGURATION_OR_ACCEPT) begin
            accept_frm_rcv              <= 1'b0;
        end
    end
end


logic conf_frm_correct_ff;
logic conf_frm_correct_r_edge;

always_ff @ (posedge clk) conf_frm_correct_ff <= conf_frm_correct;
assign conf_frm_correct_r_edge = ~conf_frm_correct_ff & conf_frm_correct;

//find number of frames which is needed to send all NL gpio's
//assign accepted configuration frame 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        NL_gpio_frm_nb                              <= '0;
        LTPI_CSR_Out.LTPI_Config_or_Accept_Capab    <= '0;
    end
    else begin
        if((accept_frm_rcv & CONTROLLER) || (conf_frm_correct_r_edge & (~CONTROLLER))) begin
            LTPI_CSR_Out.LTPI_Config_or_Accept_Capab <= remote_conf_or_acpt_frm.LTPI_Capabilites;

            if(remote_conf_or_acpt_frm.LTPI_Capabilites.NL_GPIO_nb[3:0] !='0) begin
                NL_gpio_frm_nb   <= (remote_conf_or_acpt_frm.LTPI_Capabilites.NL_GPIO_nb >> 4) + 7'd1;
            end
            else begin
                NL_gpio_frm_nb <= (remote_conf_or_acpt_frm.LTPI_Capabilites.NL_GPIO_nb >> 4) ;
            end
        end
    end
end

endmodule