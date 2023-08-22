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
// -- Data channel inerface managment - Target device
// -------------------------------------------------------------------
`include "logic.svh"

module mgmt_data_channel_target
import ltpi_pkg::*;
(
    input wire                      clk,
    input wire                      reset,

    output Data_channel_payload_t   payload_o,
    output logic                    payload_o_valid,

    input logic                     resp_valid,
    output logic                    resp_ack,
    input Data_channel_payload_t    resp,

    //signals from phy managment
    input logic [ 3:0]   tx_frm_offset,
    input logic [31:0]   operational_frm_sent,
    input logic          data_channel_rst

);

typedef enum logic [2:0] {
    REQ_DATA_CHANNEL_FSM_IDLE,
    REQ_DATA_CHANNEL_FSM_DATA_VALID,
    REQ_DATA_CHANNEL_FSM_DATA_VALID_DLY,
    REQ_DATA_CHANNEL_FSM_WAIT
} resp_data_chnnl_fsm_t;

resp_data_chnnl_fsm_t          resp_fsm; 
logic [31:0] operational_frm_sent_latch;

always_ff @ (posedge clk or posedge reset or posedge data_channel_rst) begin
    if (reset || data_channel_rst) begin
        resp_fsm                        <= REQ_DATA_CHANNEL_FSM_IDLE;
        payload_o                       <= '0;
        payload_o_valid                 <= 0;
        resp_ack                        <=  0;
    end
    else begin
        case (resp_fsm)
            REQ_DATA_CHANNEL_FSM_IDLE: begin
                if(resp_valid & tx_frm_offset == frame_length) begin // tu sparwdzenie, czy fifo nie jest empty i wyciągnięcie danych
                    payload_o           <= resp;
                    payload_o_valid     <= 1;
                    resp_ack            <= 1;
                    resp_fsm            <= REQ_DATA_CHANNEL_FSM_DATA_VALID;
                end
            end
            REQ_DATA_CHANNEL_FSM_DATA_VALID: begin
                resp_ack <=  0;
                if(tx_frm_offset != frame_length) begin
                    resp_fsm            <= REQ_DATA_CHANNEL_FSM_DATA_VALID_DLY;
                    operational_frm_sent_latch <= operational_frm_sent;
                end
            end
            REQ_DATA_CHANNEL_FSM_DATA_VALID_DLY: begin
                if(tx_frm_offset == frame_length) begin
                    payload_o_valid     <= 0;
                    resp_fsm            <= REQ_DATA_CHANNEL_FSM_WAIT;
                end
            end
            REQ_DATA_CHANNEL_FSM_WAIT: begin
                payload_o_valid         <= 0;
                if(operational_frm_sent > (operational_frm_sent_latch + 2)) begin
                    resp_fsm            <= REQ_DATA_CHANNEL_FSM_IDLE;
                end
            end
        endcase
    end
end

endmodule