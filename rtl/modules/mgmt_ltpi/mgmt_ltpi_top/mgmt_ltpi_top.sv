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
// -- Date          : August 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Management LTPI  - management phy and  intrefaces
// -------------------------------------------------------------------
`include "logic.svh"

module mgmt_ltpi_top 
import ltpi_pkg::*;
#(
    parameter CONTROLLER                = 1,  //Set Controller side with value 1
    parameter GPIO_EN                   = 1,
    parameter NUM_OF_NL_GPIO            = 1024,
    parameter LL_GPIO_RST_VALUE         = 16'hFF_FF, 
    parameter NL_GPIO_RST_VALUE         = { 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                            112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                            112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                            112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF},
    parameter UART_EN                   = 1,
    parameter NUM_OF_UART_DEV           = 2, // from 1 to 2 
    parameter SMBUS_EN                  = 1,
    parameter NUM_OF_SMBUS_DEV          = 6,// from 1 to 6
    parameter DATA_CHANNEL_EN           = 1,
    parameter DATA_CHANNEL_MAILBOX_EN   = 1

)
(
    input wire                                      clk,            //60 MHZ  clk for logic
    input wire                                      ref_clk,        //25 MHZ Source Clock to drive dynamic PLL
    input wire                                      reset,

    //LVDS output pins
    output wire                                     lvds_tx_data,
    output wire                                     lvds_tx_clk,

    //LVDS input pins
    input wire                                      lvds_rx_data,
    input wire                                      lvds_rx_clk,

    output wire                                     tx_pll_locked,
    output wire                                     aligned,            //Mark that LVDS link has locked
    output reg                                      NL_gpio_stable,     //All GPIO_OUT value has been updated with remote MCSI payload

    output  LTPI_CSR_Out_t                          LTPI_CSR_Out,
    input   LTPI_CSR_In_t                           LTPI_CSR_In,

    inout        [(NUM_OF_SMBUS_DEV - 1) :0]       smb_scl,            //I2C interfaces tunneling through LVDS 
    inout        [(NUM_OF_SMBUS_DEV - 1) :0]       smb_sda,

    input  logic [                    15 :0]       ll_gpio_in,
    output logic [                    15 :0]       ll_gpio_out,

    input  logic [  (NUM_OF_NL_GPIO - 1) :0]       nl_gpio_in,        //GPIO input tunneling through LVDS
    output logic [  (NUM_OF_NL_GPIO - 1) :0]       nl_gpio_out,       //GPIO output tunneling through LVDS
    
    input        [ (NUM_OF_UART_DEV - 1) :0]       uart_rxd,           //UART interfaces tunneling through LVDS
    input        [ (NUM_OF_UART_DEV - 1) :0]       uart_cts,           //Clear To Send
    output reg   [ (NUM_OF_UART_DEV - 1) :0]       uart_txd,
    output reg   [ (NUM_OF_UART_DEV - 1) :0]       uart_rts,           //Request To Send
    
    `LOGIC_MODPORT(logic_avalon_mm_if,  master)    avalon_mm_m, //AVMM Master interface tunneling through LVDS, Only exist on target side
    `LOGIC_MODPORT(logic_avalon_mm_if,  slave)     avalon_mm_s, //AVMM Slave interface tunneling through LVDS, //Only exist on controller side
    
    input logic  [                     7 :0]       tag_in,
    output logic [                     7 :0]       tag_out
);

wire                    reset_interfaces;

wire    [ 5:0][3:0]     i2c_event_i;
wire    [ 5:0][3:0]     i2c_event_o;

reg     [ 1:0][3:0]     uart_i;
wire    [ 1:0][3:0]     uart_o;

wire    [ 7:0]          frame_count;
wire    [ 3:0]          tx_frm_offset;
wire    [ 3:0]          rx_frm_offset;
wire    [ 7:0]          frame_count_check;  
wire                    frame_crc_err;

logic    [ 1:0][ 7:0]   LL_GPIO_i;
logic    [ 1:0][ 7:0]   NL_GPIO_i;
logic    [ 7:0]         NL_GPIO_index_i;
logic    [ 3:0][ 7:0]   OEM_i;

logic    [ 1:0][ 7:0]   LL_GPIO_o;
logic    [ 1:0][ 7:0]   NL_GPIO_o;
logic    [ 7:0]         NL_GPIO_index_o;
logic    [ 3:0][ 7:0]   OEM_o;
logic    [ 7:0]         NL_GPIO_MAX_index_o;

Operational_IO_Frm_t    operational_frm_rx;
LTPI_base_Frm_t         operational_frm_tx;

link_state_t            local_link_state;
link_state_t            remote_link_state;
logic    [ 6:0]         NL_GPIO_MAX_FRM_CNT;
LTPI_Capabilites_t      config_capabilites;
logic                   DDR_MODE;
link_speed_t            link_speed;

logic    [ 7:0]         avmm_event_o;
logic    [ 7:0]         avmm_event_i;
logic    [ 5:0]         soft_i2c_channel_rst;
logic                   CSR_data_channel_reset;

assign OEM_i = '0;
logic                   DATA_CHNNL_REQ;
Data_channel_payload_t  req_payload_o;
Data_channel_payload_t  data_channel_rx;
logic                   data_channel_rx_valid;

//Opertional frame code
assign operational_frm_tx.comma_symbol       = K28_7;
assign operational_frm_tx.frame_subtype      = DATA_CHNNL_REQ ? K28_7_SUB_1                  : K28_7_SUB_0;
assign operational_frm_tx.data[ 0]           = DATA_CHNNL_REQ ? LL_GPIO_i[0]                 : NL_GPIO_index_i;
assign operational_frm_tx.data[ 1]           = DATA_CHNNL_REQ ? LL_GPIO_i[1]                 : LL_GPIO_i[0];
assign operational_frm_tx.data[ 2]           = DATA_CHNNL_REQ ? req_payload_o.tag            : LL_GPIO_i[1];
assign operational_frm_tx.data[ 3]           = DATA_CHNNL_REQ ? req_payload_o.command        : NL_GPIO_i[0];
assign operational_frm_tx.data[ 4]           = DATA_CHNNL_REQ ? req_payload_o.address[3]     : NL_GPIO_i[1];
assign operational_frm_tx.data[ 5]           = DATA_CHNNL_REQ ? req_payload_o.address[2]     : {uart_i[1], uart_i[0]};
assign operational_frm_tx.data[ 6]           = DATA_CHNNL_REQ ? req_payload_o.address[1]     : {i2c_event_o[1], i2c_event_o[0]};
assign operational_frm_tx.data[ 7]           = DATA_CHNNL_REQ ? req_payload_o.address[0]     : {i2c_event_o[3], i2c_event_o[2]};
assign operational_frm_tx.data[ 8]           = DATA_CHNNL_REQ ? {req_payload_o.operation_status, req_payload_o.byte_en }     : {i2c_event_o[5], i2c_event_o[4]};
assign operational_frm_tx.data[ 9]           = DATA_CHNNL_REQ ? req_payload_o.data[3]        : OEM_i[0];
assign operational_frm_tx.data[10]           = DATA_CHNNL_REQ ? req_payload_o.data[2]        : OEM_i[1];
assign operational_frm_tx.data[11]           = DATA_CHNNL_REQ ? req_payload_o.data[1]        : OEM_i[2];
assign operational_frm_tx.data[12]           = DATA_CHNNL_REQ ? req_payload_o.data[0]        : OEM_i[3];

//Opertional frame decode
assign NL_GPIO_index_o                      = {1'b0, operational_frm_rx.frame_counter[6:0]};
assign LL_GPIO_o[0]                         = operational_frm_rx.ll_GPIO[0];
assign LL_GPIO_o[1]                         = operational_frm_rx.ll_GPIO[1];
assign NL_GPIO_o[0]                         = operational_frm_rx.nl_GPIO[0];
assign NL_GPIO_o[1]                         = operational_frm_rx.nl_GPIO[1];
assign {uart_o[1]      , uart_o[0]      }   = operational_frm_rx.uart_data;
assign {i2c_event_i[1] , i2c_event_i[0] }   = operational_frm_rx.i2c_data[0];
assign {i2c_event_i[3] , i2c_event_i[2] }   = operational_frm_rx.i2c_data[1];
assign {i2c_event_i[5] , i2c_event_i[4] }   = operational_frm_rx.i2c_data[2];
assign OEM_o[0]                             = operational_frm_rx.OEM_data[0];
assign OEM_o[1]                             = operational_frm_rx.OEM_data[1];
assign OEM_o[2]                             = operational_frm_rx.OEM_data[2];
assign OEM_o[3]                             = operational_frm_rx.OEM_data[3];

assign local_link_state                     = LTPI_CSR_Out.LTPI_Link_Status.local_link_state;
assign remote_link_state                    = LTPI_CSR_Out.LTPI_Link_Status.remote_link_state;
assign aligned                              = LTPI_CSR_Out.LTPI_Link_Status.aligned;
assign DDR_MODE                             = LTPI_CSR_Out.LTPI_Link_Status.DDR_mode;
assign link_speed                           = LTPI_CSR_Out.LTPI_Link_Status.link_speed;
assign frame_crc_err                        = LTPI_CSR_Out.LTPI_Link_Status.frm_CRC_error;
assign config_capabilites                   = LTPI_CSR_Out.LTPI_Config_or_Accept_Capab;

assign soft_i2c_channel_rst                 = LTPI_CSR_In.LTPI_Link_Ctrl.I2C_channel_reset;
assign CSR_data_channel_reset               = LTPI_CSR_In.LTPI_Link_Ctrl.data_channel_reset;

mgmt_phy_top #(
    .CONTROLLER (CONTROLLER)
) mgmt_phy_top_inst(
    .ref_clk                (ref_clk                ),
    .clk                    (clk                    ), 
    .reset                  (reset                  ),
    .reset_interfaces       (reset_interfaces       ),
    //LVDS output pins
    .lvds_tx_data           (lvds_tx_data           ),
    .lvds_tx_clk            (lvds_tx_clk            ),

    //LVDS input pins
    .lvds_rx_data           (lvds_rx_data           ),
    .lvds_rx_clk            (lvds_rx_clk            ),

    .tx_frm_offset          (tx_frm_offset          ),
    .rx_frm_offset          (rx_frm_offset          ),
    .NL_GPIO_MAX_FRM_CNT    (NL_GPIO_MAX_FRM_CNT    ),

    .operational_frm_tx     (operational_frm_tx     ),
    .operational_frm_rx     (operational_frm_rx     ),
    .data_channel_rx        (data_channel_rx        ),
    .data_channel_rx_valid  (data_channel_rx_valid  ),

    .LTPI_CSR_In            (LTPI_CSR_In            ),
    .LTPI_CSR_Out           (LTPI_CSR_Out           )
);

generate begin:GPIO
    if (GPIO_EN) begin
        mgmt_gpio #(
            .NUM_OF_NL_GPIO         (NUM_OF_NL_GPIO         ),
            .LL_GPIO_RST_VALUE      (LL_GPIO_RST_VALUE      ),
            .NL_GPIO_RST_VALUE      (NL_GPIO_RST_VALUE      )
        )
        mgmt_gpio_inst(
            .clk                    (clk                    ),
            .reset                  (reset_interfaces       ),
            //signals from/to pins
            .ll_gpio_in             (ll_gpio_in             ), //LOW LATANCY GPIO input tunneling through LVDS
            .ll_gpio_out            (ll_gpio_out            ), //LOW LATANCY GPIO input tunneling through LVDS
            .nl_gpio_in             (nl_gpio_in             ), //NORMAL LATANCY GPIO input tunneling through LVDS
            .nl_gpio_out            (nl_gpio_out            ), //NORMAL LATANCYGPIO output tunneling through LVDS
            //signal from/to opertional frame managment
            .LL_GPIO_i              (LL_GPIO_i              ),
            .NL_GPIO_i              (NL_GPIO_i              ),
            .NL_GPIO_index_i        (NL_GPIO_index_i        ),

            .NL_GPIO_MAX_FRM_CNT    (NL_GPIO_MAX_FRM_CNT    ),
            .NL_GPIO_index_o        (NL_GPIO_index_o        ),
            .LL_GPIO_o              (LL_GPIO_o              ),
            .NL_GPIO_o              (NL_GPIO_o              ),
            .NL_gpio_stable         (NL_gpio_stable         ),
            //signals from phy managment
            .rx_frm_offset          (rx_frm_offset          ),
            .tx_frm_offset          (tx_frm_offset          ),
            .aligned                (aligned                ),
            .frame_crc_err          (frame_crc_err          ),
            .data_channel_req       (DATA_CHNNL_REQ         ),

            .local_link_state       (local_link_state       ),
            .remote_link_state      (remote_link_state      )
        );
    end
    else begin
        assign LL_GPIO_i = '1;
        assign NL_GPIO_i = '1;
        assign NL_GPIO_index_i = 0;
    end
end
endgenerate

generate begin: UART
    if (UART_EN) begin
        mgmt_uart #(
            .NUM_OF_UART_DEV        (NUM_OF_UART_DEV        )
        ) mgmt_uart_inst(
            .clk                    (clk                    ),
            .reset                  (reset_interfaces       ),
            //signals from/to pins
            .uart_rxd               (uart_rxd               ), //UART interfaces tunneling through LVDS
            .uart_cts               (uart_cts               ), //Clear To Send
            .uart_txd               (uart_txd               ),
            .uart_rts               (uart_rts               ), //Request To Send
            //signal from/to opertional frame managment
            .uart_i_array           (uart_i                 ),
            .uart_o_array           (uart_o                 ),
            //signals from phy managment
            .rx_frm_offset          (rx_frm_offset          ),
            .tx_frm_offset          (tx_frm_offset          ),

            .config_capabilites     (config_capabilites     ),
            .local_link_state       (local_link_state       ),
            .remote_link_state      (remote_link_state      ),
            .frame_crc_err          (frame_crc_err          )
        );
    end
    else begin
        assign uart_i = {4'h7,4'h7};
    end
end
endgenerate

generate begin: SMBUS
    if (SMBUS_EN) begin
        mgmt_smbus #(
            .NUM_OF_SMBUS_DEV       (NUM_OF_SMBUS_DEV       ),
            .CONTROLLER             (CONTROLLER             )
        )mgmt_smbus_inst(
            .clk                    (clk                    ),
            .reset                  (reset_interfaces       ),
            //signals from/to pins
            .smb_scl                (smb_scl                ),        //I2C interfaces tunneling through LVDS 
            .smb_sda                (smb_sda                ),
            //signal from/to opertional frame managment
            .i2c_event_i            (i2c_event_i            ),
            .i2c_event_o            (i2c_event_o            ),
            .soft_i2c_channel_rst   (soft_i2c_channel_rst   ),
            .DDR_MODE               (DDR_MODE               ),
            .link_speed             (link_speed             ),

            .tx_frm_offset          (tx_frm_offset          ),
            .config_capabilites     (config_capabilites     ),
            .local_link_state       (local_link_state       ),
            .remote_link_state      (remote_link_state      )
        );
    end
    else begin
        assign i2c_event_o = 0;
    end
end
endgenerate

Data_channel_payload_t  payload_o;
logic                   req_valid;
logic                   req_ack;
Data_channel_payload_t  req;

logic                   resp_valid;
Data_channel_payload_t  resp;
logic                   reset_data_channel;

assign reset_data_channel = reset_interfaces || (local_link_state != operational_st);


generate begin: data_channel
    if(DATA_CHANNEL_EN) begin
        if(CONTROLLER) begin
            if(DATA_CHANNEL_MAILBOX_EN) begin
                ltpi_data_channel_controller_csr ltpi_data_channel_controller_csr_inst (
                    .clk                    (clk                    ),
                    .reset                  (reset_data_channel     ),
                    .avalon_mm_s            (avalon_mm_s            ),
                    .req_valid              (req_valid              ),
                    .req_ack                (req_ack                ),
                    .req                    (req                    ),
                    .resp_valid             (resp_valid             ),
                    .resp                   (resp                   )
                );
            end
            else  begin
                assign tag_out = resp.tag;
                ltpi_data_channel_controller_mm ltpi_data_channel_controller_mm_inst(
                    .clk                    (clk                    ),
                    .reset                  (reset_data_channel     ),
                    .data_channel_rst       (CSR_data_channel_reset ),
                    .req_valid              (req_valid              ),
                    .req_ack                (req_ack                ),
                    .req                    (req                    ),

                    .resp_valid             (resp_valid             ),
                    .resp                   (resp                   ),

                    .avalon_mm_s            (avalon_mm_s            ),
                    .tag                    (tag_in                 )
                );
            end

            mgmt_data_channel_controller mgmt_data_channel_controller_inst(
                .clk                    (clk                    ),
                .reset                  (reset_data_channel     ),
                .data_channel_rst       (CSR_data_channel_reset ),

                .req_valid              (req_valid              ),
                .req_ack                (req_ack                ),
                .req_data_channel       (req                    ),

                .res_valid              (resp_valid             ),
                .res_data_channel       (resp                   ),

                .req_payload_o          (req_payload_o          ),
                .payload_o_valid        (DATA_CHNNL_REQ         ),
                .payload_i              (data_channel_rx        ),
                .payload_i_valid        (data_channel_rx_valid  ),
                //signals from phy managment
                .operational_frm_sent   (LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt),
                .local_link_state       (local_link_state       ),
                .frm_crc_error          (frame_crc_err          ),
                .tx_frm_offset          (tx_frm_offset          )
            );
        end
        else begin
            logic resp_ack;

            if(DATA_CHANNEL_MAILBOX_EN) begin
                ltpi_data_channel_target ltpi_data_channel_target_inst(
                    .clk                    (clk                    ),
                    .reset                  (reset_data_channel     ),
                    .data_channel_rst       (CSR_data_channel_reset ),
                    .avalon_mm_m            (avalon_mm_m            ),
                    .payload_i              (data_channel_rx        ),
                    .payload_i_valid        (data_channel_rx_valid  ),

                    .resp_rd_valid          (resp_valid             ),
                    .resp_rd_ack            (resp_ack               ),
                    .resp_fifo_rd           (resp                   ),

                    .local_link_state       (local_link_state       ),
                    .frm_crc_error          (frame_crc_err          )
                );
            end
            else begin
                ltpi_data_channel_target_mm ltpi_data_channel_target_mm_inst(
                    .clk                    (clk                    ),
                    .reset                  (reset_data_channel     ),
                    .data_channel_rst       (CSR_data_channel_reset ),
                    .avalon_mm_m            (avalon_mm_m            ),
                    .payload_i              (data_channel_rx        ),
                    .payload_i_valid        (data_channel_rx_valid  ),

                    .resp_valid             (resp_valid             ),
                    .resp_ack               (resp_ack               ),
                    .resp                   (resp                   ),

                    .local_link_state       (local_link_state       ),
                    .frm_crc_error          (frame_crc_err          )
                );
            end

            mgmt_data_channel_target mgmt_data_channel_target_inst (
                .clk                    (clk                    ),
                .reset                  (reset_data_channel     ),

                .payload_o              (req_payload_o          ),
                .payload_o_valid        (DATA_CHNNL_REQ         ),

                .resp_valid             (resp_valid             ),
                .resp_ack               (resp_ack               ),
                .resp                   (resp                   ),

                .tx_frm_offset          (tx_frm_offset          ),
                .operational_frm_sent   (LTPI_CSR_Out.LTPI_counter.operational_frm_snt_cnt),
                .data_channel_rst       (CSR_data_channel_reset)
            );

        end
    end
end
endgenerate

endmodule