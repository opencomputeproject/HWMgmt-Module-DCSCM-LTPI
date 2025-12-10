/////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025 Intel Corporation
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
// -- Date          : October 2025
// -- Project Name  : LTPI
// -- Description   :
// -- PHY Management - Controller device  
// -------------------------------------------------------------------

module mgmt_phy_controller
import ltpi_pkg::*; 
(
    input wire          clk,
    input wire          reset,

    input link_speed_t  operational_speed,

    input reg [ 3:0]    tx_frm_offset,

    input wire          aligned,
    input wire          frame_crc_err,

    input wire          link_detect_locked,
    input wire          crc_consec_loss,
    input wire          operational_frm_lost_error,
    input wire          unexpected_frame_error,
    input wire          remote_software_reset,
    input link_state_t  remote_link_state,
    input wire          transmited_255_detect_frm,
    input wire          transmited_7_speed_frm,

    input wire          advertise_locked,

    input wire          link_cfg_timeout_detect,
    input wire          accept_frm_rcv,

    output logic        pll_reconfig,
    input logic         pll_configuration_done,
    input logic         change_freq_st,

    input LTPI_CSR_In_t LTPI_CSR_In,
    output rstate_t     LTPI_link_ST

);

rstate_t     rstate;
rstate_t     rstate_ff;

reg          timer_1ms_start;
logic        timer_1ms_done;

logic       local_software_reset;
logic       retraining_request;

reg         timer_100ms_start;
logic       timer_100ms_done;
logic       link_lost_error;

assign local_software_reset = LTPI_CSR_In.LTPI_Link_Ctrl.software_reset;
assign retraining_request   = LTPI_CSR_In.LTPI_Link_Ctrl.retraining_request;
assign LTPI_link_ST         = rstate_ff;
assign link_lost_error      = crc_consec_loss || (unexpected_frame_error & !frame_crc_err);

always @ (posedge clk) rstate_ff <= rstate;

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        rstate                          <= ST_INIT;
        timer_1ms_start                 <= 1'b0;
        timer_100ms_start               <= 1'b0;
        pll_reconfig                    <= 1'b0;
    end
    else begin
        case(rstate)
            ST_INIT: begin
                timer_1ms_start         <= 1'b0;
                timer_100ms_start       <= 1'b0;

                if(pll_configuration_done == 1'b1) begin
                    pll_reconfig         <= 1'b0;
                    rstate               <= ST_COMMA_HUNTING;
                end
                else begin
                    pll_reconfig         <= 1'b1;
                end
            end

            ST_COMMA_HUNTING: begin
                if(change_freq_st == 1'b1 )begin
                    timer_100ms_start      <= 1'b1;
                    if(timer_100ms_done) begin
                        rstate          <= ST_LINK_LOST_ERR; //We are not able to aligne on operational FREQ
                    end
                end

                if (aligned & change_freq_st == 1'b0) begin
                    rstate              <= ST_WAIT_LINK_DETECT_LOCKED;
                end
                 else if (aligned & change_freq_st) begin
                    rstate              <= ST_WAIT_LINK_ADVERTISE_LOCKED;
                end
            end

            ST_WAIT_LINK_DETECT_LOCKED: begin
                if(link_lost_error) begin
                   rstate               <= ST_LINK_LOST_ERR;
                end
                else if(link_detect_locked && transmited_255_detect_frm || remote_link_state == link_speed_st) begin
                    if(tx_frm_offset == frame_length) begin // make sure hole frame was sent
                        rstate          <= ST_WAIT_LINK_SPEED_LOCKED;
                    end
                end
            end

            ST_WAIT_LINK_SPEED_LOCKED: begin
                if (link_lost_error) begin
                    rstate              <= ST_LINK_LOST_ERR; //LTPI spec 1.2 change
                end
                else if(transmited_7_speed_frm && remote_link_state == link_speed_st) begin //LTPI spec 1.2 change
                    if(tx_frm_offset == frame_length) begin // make sure hole frame was sent
                        rstate          <= ST_LINK_SPEED_CHANGE;
                    end
                end
            end

            ST_LINK_SPEED_CHANGE: begin
                pll_reconfig            <= 1'b1;
            end

            ST_WAIT_LINK_ADVERTISE_LOCKED: begin //Advertise state
                timer_1ms_start         <= 1'b1;
                timer_100ms_start       <= 1'b0;

                if (link_lost_error) begin
                    rstate              <= ST_LINK_LOST_ERR;
                end
                else if(timer_1ms_done && advertise_locked) begin
                    if(!LTPI_CSR_In.LTPI_Link_Ctrl.auto_move_config)begin
                        rstate          <= ST_WAIT_IN_ADVERTISE;
                    end
                    else begin
                        if(tx_frm_offset == frame_length) begin // make sure hole frame was sent
                            rstate      <= ST_CONFIGURATION_OR_ACCEPT;
                        end
                    end
                end
                else if(timer_1ms_done) begin
                    rstate              <= ST_LINK_LOST_ERR;
                end
            end //end ST_WAIT_LINK_ADVERTISE_LOCK

            ST_WAIT_IN_ADVERTISE: begin //Advertise state
                timer_1ms_start <= 1'b0;
                if (link_lost_error) begin
                    rstate              <= ST_LINK_LOST_ERR;
                end
                else if(LTPI_CSR_In.LTPI_Link_Ctrl.trigger_config_st)begin
                    if(tx_frm_offset == frame_length) begin // make sure hole frame was sent
                        rstate          <= ST_CONFIGURATION_OR_ACCEPT;
                    end
                end
            end//end ST_WAIT_IN_ADVERTISE

            ST_CONFIGURATION_OR_ACCEPT: begin //Configuration state
                timer_1ms_start <= 1'b0;
                if (link_lost_error) begin
                    rstate              <= ST_LINK_LOST_ERR;
                end
                else if (link_cfg_timeout_detect) begin
                    if(tx_frm_offset == frame_length) begin // make sure hole frame was sent
                        rstate          <= ST_WAIT_LINK_ADVERTISE_LOCKED;
                    end
                end
                else if(accept_frm_rcv) begin
                    if(tx_frm_offset == frame_length) begin // make sure hole frame was sent
                        rstate          <= ST_OPERATIONAL;
                    end
                end
            end//end ST_CONFIGURATION

             ST_OPERATIONAL: begin // Operational state
                if(link_lost_error) begin
                    rstate              <= ST_LINK_LOST_ERR;
                end
                else if(local_software_reset || remote_software_reset) begin
                    rstate              <= ST_OPERATIONAL_RESET;
                end
                else if(retraining_request) begin
                    rstate              <= ST_INIT;
                end
                else if(operational_frm_lost_error) begin
                    rstate              <= ST_LINK_LOST_ERR;
                end

             end//end ST_OPERATIONAL

            ST_OPERATIONAL_RESET: begin
                if(tx_frm_offset == frame_length) begin // after local/remote reset make sure hole frame was sent
                    rstate              <= ST_WAIT_LINK_ADVERTISE_LOCKED;
                end
            end//end ST_OPERATIONAL_RESET

            ST_LINK_LOST_ERR: begin
                rstate                  <= ST_INIT;
            end

            default: begin
                rstate                  <= ST_INIT;
            end

        endcase
    end
end

logic [15:0] cnt;

always @(posedge clk or posedge reset)begin
    if (reset) begin
        timer_1ms_done      <= 1'b0;
        cnt                 <= 16'd0;
    end
    else begin
        if(!timer_1ms_start) begin 
            timer_1ms_done  <= 1'b0;
            cnt             <= 16'd0;
        end
        else if ( cnt < (TIMER_1MS_60MHZ-1)) begin
            timer_1ms_done  <= 1'b0;
            cnt             <= cnt + 1'b1;
        end
        else begin
            timer_1ms_done  <= 1'b1;
            cnt             <= cnt;
        end
    end
end

logic [31:0] cnt100;

always @(posedge clk or posedge reset)begin
    if (reset) begin
        timer_100ms_done      <= 1'b0;
        cnt100                <= 32'd0;
    end
    else begin
        if(!timer_100ms_start) begin 
            timer_100ms_done  <= 1'b0;
            cnt100            <= 32'd0;
        end
        else if ( cnt100 < (TIMER_1MS_60MHZ*100-1)) begin
            timer_100ms_done  <= 1'b0;
            cnt100            <= cnt100 + 1'b1;
        end
        else begin
            timer_100ms_done  <= 1'b1;
            cnt100            <= cnt100;
        end
    end
end

endmodule