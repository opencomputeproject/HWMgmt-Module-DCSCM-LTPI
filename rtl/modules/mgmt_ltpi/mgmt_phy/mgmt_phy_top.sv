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
// -- LTPI PHY Management top
// -------------------------------------------------------------------

module mgmt_phy_top 
import ltpi_pkg::*;
#(
    parameter EXTERNAL_LINK_CLK = 0,
    parameter CONTROLLER = 1
)(
    input wire                  ref_clk, //25MHZ
    input wire                  clk,     //60MHZ
    input wire                  reset,
    output reg                  reset_interfaces,

    //LVDS output pins
    output wire                 lvds_tx_data,
    output wire                 lvds_tx_clk,

    //LVDS input pins
    input wire                  lvds_rx_data,
    input wire                  lvds_rx_clk,

    output logic [ 3:0]         tx_frm_offset,
    output logic [ 3:0]         rx_frm_offset,
    
    output logic [ 6:0]         NL_GPIO_MAX_FRM_CNT,
    input LTPI_base_Frm_t       operational_frm_tx,
    output Operational_IO_Frm_t operational_frm_rx,

    output Data_channel_payload_t data_channel_rx,
    output logic                data_channel_rx_valid,
    
    input LTPI_CSR_In_t         LTPI_CSR_In,
    output LTPI_CSR_Out_t       LTPI_CSR_Out

);

wire                clk_phy;
wire                clk_phy_90;
wire                tx_pll_locked;
rstate_t            LTPI_link_ST;

logic               change_freq_st;

logic               aligned;
logic               frame_crc_err;

logic [ 2:0]        pll_configuration;
logic               pll_reconfig;
logic               pll_configuration_done;

LTPI_base_Frm_t     ltpi_frame_tx;
LTPI_base_Frm_t     ltpi_frame_rx;

logic               crc_consec_loss;
logic               operational_frm_lost_error;
logic               unexpected_frame_error;
logic               remote_software_reset;
link_state_t        remote_link_state;

logic               transmited_255_detect_frm;
logic               link_detect_locked;

logic               transmited_7_speed_frm;
logic               link_speed_timeout_detect;
logic               link_speed_locked;

logic               advertise_locked;

logic               configure_frm_recv;
logic               accept_frm_rcv;
logic               link_cfg_timeout_detect;
logic               link_accept_timeout_detect;
logic               accept_phase_done;

link_speed_t        operational_speed;
logic               LVDS_DDR;

LTPI_CSR_Out_t      LTPI_CSR_Out_frm_rx;
LTPI_CSR_Out_t      LTPI_CSR_Out_frm_tx;

logic               mgmt_clk_reconfig;
logic               mgmt_clk_configuration_done;

LTPI_Capabilites_t  accept_frm_capab;
logic               link_lost;

assign reset_interfaces                                             = ~tx_pll_locked;
assign LTPI_CSR_Out.LTPI_Link_Status.aligned                        = aligned;
assign LTPI_CSR_Out.LTPI_Link_Status.local_link_state               = LTPI_CSR_Out_frm_tx.LTPI_Link_Status.local_link_state;
assign LTPI_CSR_Out.LTPI_Link_Status.remote_link_state              = LTPI_CSR_Out_frm_rx.LTPI_Link_Status.remote_link_state;
assign LTPI_CSR_Out.LTPI_Link_Status.unknown_subtype_error          = LTPI_CSR_Out_frm_rx.LTPI_Link_Status.unknown_subtype_error;
assign LTPI_CSR_Out.LTPI_Link_Status.unknown_comma_error            = LTPI_CSR_Out_frm_rx.LTPI_Link_Status.unknown_comma_error;
assign LTPI_CSR_Out.LTPI_Link_Status.frm_CRC_error                  = LTPI_CSR_Out_frm_rx.LTPI_Link_Status.frm_CRC_error;
assign LTPI_CSR_Out.LTPI_Link_Status.link_lost_error                = LTPI_CSR_Out_frm_tx.LTPI_Link_Status.link_lost_error;
assign LTPI_CSR_Out.LTPI_Link_Status.DDR_mode                       = LTPI_CSR_Out_frm_tx.LTPI_Link_Status.DDR_mode;
assign LTPI_CSR_Out.LTPI_Link_Status.link_cfg_acpt_timeout_error    = LTPI_CSR_Out_frm_tx.LTPI_Link_Status.link_cfg_acpt_timeout_error;
assign LTPI_CSR_Out.LTPI_Link_Status.link_speed                     = LTPI_CSR_Out_frm_tx.LTPI_Link_Status.link_speed;
assign LTPI_CSR_Out.LTPI_Link_Status.link_speed_timeout_error       = LTPI_CSR_Out_frm_tx.LTPI_Link_Status.link_speed_timeout_error;

assign LTPI_CSR_Out.LTPI_counter.link_lost_err_cnt                  = LTPI_CSR_Out_frm_tx.LTPI_counter.link_lost_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_aligment_err_cnt              = LTPI_CSR_Out_frm_tx.LTPI_counter.link_aligment_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_cfg_acpt_timeout_err_cnt      = LTPI_CSR_Out_frm_tx.LTPI_counter.link_cfg_acpt_timeout_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_speed_timeout_err_cnt         = LTPI_CSR_Out_frm_tx.LTPI_counter.link_speed_timeout_err_cnt;

assign LTPI_CSR_Out.LTPI_Detect_Capab_remote.Link_Speed_capab       = LTPI_CSR_Out_frm_rx.LTPI_Detect_Capab_remote.Link_Speed_capab;
assign LTPI_CSR_Out.LTPI_Detect_Capab_remote.LTPI_Version           = LTPI_CSR_Out_frm_rx.LTPI_Detect_Capab_remote.LTPI_Version;
assign LTPI_CSR_Out.LTPI_Advertise_Capab_remote                     = LTPI_CSR_Out_frm_rx.LTPI_Advertise_Capab_remote;
assign LTPI_CSR_Out.LTPI_Config_or_Accept_Capab                     = LTPI_CSR_Out_frm_rx.LTPI_Config_or_Accept_Capab;
assign LTPI_CSR_Out.LTPI_Config_Capab_remote                        = LTPI_CSR_Out_frm_rx.LTPI_Config_Capab_remote;

assign LTPI_CSR_Out.LTPI_platform_ID_remote                         = LTPI_CSR_Out_frm_rx.LTPI_platform_ID_remote;

assign LTPI_CSR_Out.LTPI_counter.unknown_comma_err_cnt              = LTPI_CSR_Out_frm_rx.LTPI_counter.unknown_comma_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.unknown_subtype_err_cnt            = LTPI_CSR_Out_frm_rx.LTPI_counter.unknown_subtype_err_cnt;
assign LTPI_CSR_Out.LTPI_counter.link_crc_err_cnt                   = LTPI_CSR_Out_frm_rx.LTPI_counter.link_crc_err_cnt;

assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt        = LTPI_CSR_Out_frm_rx.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_detect_frm_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt         = LTPI_CSR_Out_frm_rx.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_speed_frm_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt    = LTPI_CSR_Out_frm_rx.LTPI_counter.linkig_training_frm_rcv_cnt_high.link_advertise_frm_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt      = LTPI_CSR_Out_frm_rx.LTPI_counter.linkig_training_frm_rcv_cnt_low.link_cfg_acpt_frm_cnt;
assign LTPI_CSR_Out.LTPI_counter.operational_frm_rcv_cnt                                    = LTPI_CSR_Out_frm_rx.LTPI_counter.operational_frm_rcv_cnt;

assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt        = LTPI_CSR_Out_frm_tx.LTPI_counter.linkig_training_frm_snt_cnt_low.link_detect_frm_cnt    ;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt         = LTPI_CSR_Out_frm_tx.LTPI_counter.linkig_training_frm_snt_cnt_low.link_speed_frm_cnt     ;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt    = LTPI_CSR_Out_frm_tx.LTPI_counter.linkig_training_frm_snt_cnt_high.link_advertise_frm_cnt;
assign LTPI_CSR_Out.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt      = LTPI_CSR_Out_frm_tx.LTPI_counter.linkig_training_frm_snt_cnt_low.link_cfg_acpt_frm_cnt  ;
assign LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt                                    = LTPI_CSR_Out_frm_tx.LTPI_counter.operational_frm_snt_cnt;


assign remote_link_state = LTPI_CSR_Out_frm_rx.LTPI_Link_Status.remote_link_state;
assign link_lost = (LTPI_link_ST == ST_LINK_LOST_ERR  || LTPI_link_ST == ST_INIT); 
//assign link_lost = 1'b0;
// LVDS PHY TX
logic reset_phy_tx;
assign reset_phy_tx = ~tx_pll_locked;

ltpi_phy_tx ltpi_phy_tx_inst (
    .clk                (clk                                        ),
    .clk_link           (clk_phy                                    ),
    .clk_link_90        (clk_phy_90                                 ),

    .reset              (reset_phy_tx                               ),
    .LVDS_DDR           (LVDS_DDR                                   ),
    //LVDS inpout pins
    .lvds_tx_data       (lvds_tx_data                               ),
    .lvds_tx_clk        (lvds_tx_clk                                ),

    .ltpi_frame_tx      (ltpi_frame_tx                              ),
    .tx_frm_offset      (tx_frm_offset                              ),
    .link_speed         (LTPI_CSR_Out.LTPI_Link_Status.link_speed   )
);

// Management of LTPI transmitted frame
mgmt_ltpi_frm_tx  #(
    .CONTROLLER (CONTROLLER)
) mgmt_ltpi_frm_tx_inst(
    .clk                                (clk                            ),
    .reset                              (reset                          ),

    .ltpi_frame_tx                      (ltpi_frame_tx                  ),
    .LTPI_link_ST                       (LTPI_link_ST                   ),
    .tx_frm_offset                      (tx_frm_offset                  ),
    .transmited_255_detect_frm          (transmited_255_detect_frm      ),

    .transmited_7_speed_frm             (transmited_7_speed_frm         ),
    .link_speed_timeout_detect          (link_speed_timeout_detect      ),

    .link_accept_timeout_detect         (link_accept_timeout_detect     ),
    .link_cfg_timeout_detect            (link_cfg_timeout_detect        ),
    .accept_frm_capab                   (accept_frm_capab               ),

    .operational_frm_tx                 (operational_frm_tx             ),
    .operational_speed                  (operational_speed              ),
    .change_freq_st                     (change_freq_st                 ),
    .NL_GPIO_MAX_FRM_CNT                (NL_GPIO_MAX_FRM_CNT            ),
    .LVDS_DDR                           (LVDS_DDR                       ),
    //CSR package 
    .LTPI_CSR_In                        (LTPI_CSR_In                    ),
    .LTPI_CSR_Out                       (LTPI_CSR_Out_frm_tx            )
);
logic reset_phy_rx;
assign reset_phy_rx = ~tx_pll_locked || link_lost;
// LVDS PHY RX
ltpi_phy_rx ltpi_phy_rx_inst (
    .clk                                (clk                            ),
    .reset                              ( reset_phy_rx),//|| link_lost    ),
    .LVDS_DDR                           (LVDS_DDR                       ),
    // Decode data output
    .rx_frm_offset                      (rx_frm_offset                  ),
    .ltpi_frame_rx                      (ltpi_frame_rx                  ),
    //LVDS output pins
    .lvds_rx_data                       (lvds_rx_data                   ),
    .lvds_rx_clk                        (lvds_rx_clk                    ),

    .aligned                            (aligned                        ),
    .frame_crc_err                      (frame_crc_err                  )
);

// Management of LTPI recived frame
mgmt_ltpi_frm_rx #( 
    .CONTROLLER (CONTROLLER)
) mgmt_ltpi_frm_rx_inst (
    .clk                                (clk                            ),
    .reset                              (reset                          ),
    //input signals
    .ltpi_frame_rx                      (ltpi_frame_rx                  ),
    .frame_crc_err                      (frame_crc_err                  ),
    .LTPI_link_ST                       (LTPI_link_ST                   ),
    .change_freq_st                     (change_freq_st                 ),
    .rx_frm_offset                      (rx_frm_offset                  ),
    //outupt signal
    .link_detect_locked                 (link_detect_locked             ),
    .link_speed_locked                  (link_speed_locked              ),
    .advertise_locked                   (advertise_locked               ),

    .accept_frm_rcv                     (accept_frm_rcv                 ),
    .configure_frm_recv                 (configure_frm_recv             ),
    .accept_phase_done                  (accept_phase_done              ),
    .accept_frm_capab                   (accept_frm_capab               ),

    .operational_frm_rx                 (operational_frm_rx             ),
    .data_channel_rx                    (data_channel_rx                ),
    .data_channel_rx_valid              (data_channel_rx_valid          ),

    .crc_consec_loss                    (crc_consec_loss                ),
    .operational_frm_lost_error         (operational_frm_lost_error     ),
    .unexpected_frame_error             (unexpected_frame_error         ),
    .remote_software_reset              (remote_software_reset          ),
    .NL_GPIO_MAX_FRM_CNT                (NL_GPIO_MAX_FRM_CNT            ),
    .LTPI_CSR_Out                       (LTPI_CSR_Out_frm_rx            ),
    .LTPI_CSR_In                        (LTPI_CSR_In                    )
);

logic clk_phy_ext;
logic clk_phy_90_ext;
logic phy_pll_locked;

//to use EXTERNAL_LINK_CLK drive as input clk_phy_ext and clk_phy_90_ext from external clock source,
//and phy_pll_locked input from PLL locked signal
//change clk_phy_ext and clk_phy_90_ext assigments
assign clk_phy_ext = ref_clk;
assign clk_phy_90_ext = ref_clk;
assign phy_pll_locked = reset;

generate begin: dynamic_pll
    if(!EXTERNAL_LINK_CLK) begin
        // Dynamic PLL reconfiguration for LTPI phy Tx clocks
        m10_pll_top m10_pll_top_inst (
            .ref_clk                            (ref_clk                        ),
            .reset                              (reset                          ),
            .mgmt_clk                           (clk                            ),
            .mgmt_reset                         (reset                          ),

            .mgmt_clk_configuration             (operational_speed[2:0]         ),
            .mgmt_clk_reconfig                  (mgmt_clk_reconfig              ),
            .mgmt_clk_configuration_done        (mgmt_clk_configuration_done    ),

            .c0                                 (clk_phy                        ),
            .c1                                 (clk_phy_90                     ),

            .locked                             (tx_pll_locked                  )
        );
    end
    else begin
        assign clk_phy       = clk_phy_ext;
        assign clk_phy_90    = clk_phy_90_ext;
        assign tx_pll_locked = phy_pll_locked;
        assign mgmt_clk_configuration_done = phy_pll_locked;
    end
end
endgenerate

// LTPI PHY Management - here is main FSM - diffrent for Controller and Target device
generate begin: mgmt_phy
    if(CONTROLLER) begin: controller
        mgmt_phy_controller mgmt_phy_controller_inst (
            .clk                        (clk                            ),
            .reset                      (~tx_pll_locked                 ),

            .operational_speed          (operational_speed              ),
            .tx_frm_offset              (tx_frm_offset                  ),
            .aligned                    (aligned                        ),
            .frame_crc_err              (frame_crc_err                  ),

            .link_detect_locked         (link_detect_locked             ),
            .crc_consec_loss            (crc_consec_loss                ),
            .operational_frm_lost_error (operational_frm_lost_error     ),
            .unexpected_frame_error     (unexpected_frame_error         ),
            .remote_software_reset      (remote_software_reset          ),
            .remote_link_state          (remote_link_state              ),
            
            .transmited_255_detect_frm  (transmited_255_detect_frm      ),
            .transmited_7_speed_frm     (transmited_7_speed_frm         ),
            .link_speed_timeout_detect  (link_speed_timeout_detect      ),

            .advertise_locked           (advertise_locked               ),

            .link_cfg_timeout_detect    (link_cfg_timeout_detect        ),
            .accept_frm_rcv             (accept_frm_rcv                 ),

            .pll_reconfig               (mgmt_clk_reconfig              ),
            .pll_configuration_done     (mgmt_clk_configuration_done    ),
            .change_freq_st             (change_freq_st                 ),

            .LTPI_CSR_In                (LTPI_CSR_In                    ),
            .LTPI_link_ST               (LTPI_link_ST                   )
        );
    end
    else begin: target
        mgmt_phy_target mgmt_phy_target_inst (
            .clk                        (clk                            ),
            .reset                      (~tx_pll_locked                 ),

            .operational_speed          (operational_speed              ),
            .tx_frm_offset              (tx_frm_offset                  ),
            .aligned                    (aligned                        ),
            .frame_crc_err              (frame_crc_err                  ),
            
            .link_detect_locked         (link_detect_locked             ),
            .crc_consec_loss            (crc_consec_loss                ),
            .operational_frm_lost_error (operational_frm_lost_error     ),
            .unexpected_frame_error     (unexpected_frame_error         ),
            .remote_software_reset      (remote_software_reset          ),
            .remote_link_state          (remote_link_state              ),

            .transmited_255_detect_frm  (transmited_255_detect_frm      ),
            .link_speed_timeout_detect  (link_speed_timeout_detect      ),
            .link_speed_locked          (link_speed_locked              ),

            .advertise_locked           (advertise_locked               ),

            .link_accept_timeout_detect (link_accept_timeout_detect     ),
            .configure_frm_recv         (configure_frm_recv             ),
            .accept_phase_done          (accept_phase_done              ),

            .pll_reconfig               (mgmt_clk_reconfig              ),
            .pll_configuration_done     (mgmt_clk_configuration_done    ),
            .change_freq_st             (change_freq_st                 ),

            .LTPI_CSR_In                (LTPI_CSR_In                    ),
            .LTPI_link_ST               (LTPI_link_ST                   )
        ); 
    end
end
endgenerate

//determine if LTPI is in link speed state
always @ (posedge clk or posedge reset) begin
   if(reset) begin
       change_freq_st               <= 1'b0;
    end
    else begin
        if(mgmt_clk_reconfig == 1'b1) begin
            if(LTPI_link_ST == ST_LINK_SPEED_CHANGE) begin // 4 - ST_WAIT_LINK_SPEED_LOCKED
                change_freq_st      <= 1'b1;
            end
        end
        else if(change_freq_st && (LTPI_CSR_Out.LTPI_Link_Status.local_link_state == advertise_st)) begin
            change_freq_st          <= 1'b0;
        end
    end
end

endmodule