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
// -- Date          : 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Data channel inerface managment - Controller device
// -------------------------------------------------------------------

`include "logic.svh"

module mgmt_data_channel_controller
import ltpi_pkg::*;
(
    input wire                      clk,
    input wire                      reset,

    //signal to packet layer
    input logic                     req_valid,
    output logic                    req_ack,
    input  Data_channel_payload_t   req_data_channel,

    output  logic                   res_valid,
    output  Data_channel_payload_t  res_data_channel,

    //signals to phy
    output Data_channel_payload_t   req_payload_o,
    output logic                    payload_o_valid,

    input  Data_channel_payload_t   payload_i,
    input  logic                    payload_i_valid,

    //signals from ltpi phy managment
    input logic [31:0]              operational_frm_sent,
    input logic [ 3:0]              tx_frm_offset,
    input link_state_t              local_link_state,
    input logic                     frm_crc_error,
    input logic                     data_channel_rst
);

logic payload_i_valid_ff;
logic payload_i_valid_r_edge;

always_ff @ (posedge clk) payload_i_valid_ff <= payload_i_valid;
assign payload_i_valid_r_edge = ~payload_i_valid_ff & payload_i_valid;

logic frm_crc_error_ff;
always_ff @ (posedge clk) frm_crc_error_ff <= frm_crc_error;

always_ff @ (posedge clk or posedge reset or posedge data_channel_rst) begin
    if (reset || data_channel_rst) begin
        res_valid                               <= 0;
        res_data_channel                        <= 0;
    end
    else begin 
        if(payload_i_valid_r_edge && !frm_crc_error_ff) begin
            res_valid                           <= 1;
            res_data_channel                    <= payload_i;
        end
        else if(payload_i_valid_r_edge) begin
            res_valid                           <= 1;
            res_data_channel.tag                <= payload_i.tag;
            res_data_channel.command            <= CRC_ERROR;
            res_data_channel.address            <= payload_i.address;
            res_data_channel.operation_status   <= 1;
            res_data_channel.byte_en            <= payload_i.byte_en;
            res_data_channel.data               <= payload_i.data;
        end
        else begin
            res_data_channel                    <= 0; 
            res_valid                           <= 0;
        end
    end
end

typedef enum logic [2:0] {
    REQ_DATA_CHANNEL_FSM_IDLE,
    REQ_DATA_CHANNEL_FSM_DATA_VALID,
    REQ_DATA_CHANNEL_FSM_DATA_VALID_DLY,
    REQ_DATA_CHANNEL_FSM_WAIT
} req_data_chnnl_fsm_t;

req_data_chnnl_fsm_t          req_fsm;
logic [31:0] operational_frm_sent_latch;

always_ff @ (posedge clk or posedge reset or posedge data_channel_rst) begin
    if (reset || data_channel_rst) begin
        req_fsm                         <= REQ_DATA_CHANNEL_FSM_IDLE;
        req_payload_o                   <= '0;
        payload_o_valid                 <= 0;
        req_ack                         <=  0;
    end
    else begin
        if(local_link_state == operational_st) begin
            case (req_fsm)
                REQ_DATA_CHANNEL_FSM_IDLE: begin
                    if(req_valid & tx_frm_offset == frame_length) begin
                        req_payload_o   <= req_data_channel;
                        payload_o_valid <= 1;
                        req_ack         <= 1;
                        req_fsm         <= REQ_DATA_CHANNEL_FSM_DATA_VALID;
                    end
                end
                REQ_DATA_CHANNEL_FSM_DATA_VALID: begin
                    req_ack <=  0;
                    if(tx_frm_offset != frame_length) begin
                        req_fsm         <= REQ_DATA_CHANNEL_FSM_DATA_VALID_DLY;
                        operational_frm_sent_latch <= operational_frm_sent;
                    end
                end
                REQ_DATA_CHANNEL_FSM_DATA_VALID_DLY: begin
                    if(tx_frm_offset == frame_length) begin
                        payload_o_valid <= 0;
                        req_fsm         <= REQ_DATA_CHANNEL_FSM_WAIT;
                    end
                end
                REQ_DATA_CHANNEL_FSM_WAIT: begin
                    payload_o_valid     <= 0;
                    if(operational_frm_sent > (operational_frm_sent_latch + 2)) begin
                        req_fsm         <= REQ_DATA_CHANNEL_FSM_IDLE;
                    end
                end
            endcase
        end
    end
end
endmodule