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
// -- SMBUS echo option
// -------------------------------------------------------------------

module smbus_echo
import ltpi_pkg::*;
(
    input wire             clk,
    input wire             reset,

    input logic  [ 3:0]    i2c_event_i_array,
    output logic [ 3:0]    i2c_event_o_echo_array,

    input logic  [ 3:0]    i2c_event_o_array,
    output logic [ 3:0]    i2c_event_i_echo_array,

    input logic             echo_en,
    input logic             DDR_MODE,
    input link_speed_t      link_speed

);

logic    [1:0]  FRM_TO_SENT;
smbus_event_t   smbus_event_echo;

logic   [ 3:0]  i2c_event_i_array_ff;
logic           event_change_i;
logic           echo_send_req;

logic   [ 8:0]  FRM_TC_CNT;

logic   [ 3:0]  i2c_event_o_array_ff;
logic           event_change_o;
logic   [ 3:0]  i2c_event_o_next;
logic   [ 3:0]  i2c_event_o_next_2;
logic           event_nex_req;
logic           event_nex_req_2;
logic   [11:0]  frame_tc_cnt;
logic           echo_rcved;
logic           check_echo_rcv;

typedef enum logic {
    ST_INIT         = 1'd0,
    ST_FRAME_EVENT  = 1'd1
} state_t;

state_t state;
always @(posedge clk) i2c_event_i_array_ff <= i2c_event_i_array;

assign event_change_i = (i2c_event_i_array_ff != i2c_event_i_array) ? 1'b1 : 1'b0;

// FRM_TC_CNT - tick od clk which is needed to send whole frame
// it depends on which frequency LTPI is working
always @ (posedge clk) begin
    if (reset)begin
        FRM_TC_CNT              <= '0;
    end
    else begin
        case (link_speed)
            base_freq_x1: begin
                if(DDR_MODE) begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_1_DDR; //frame size 3.2us*60MHz/16
                end
                else begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_1_SDR;
                end
            end
            base_freq_x2: begin
                if(DDR_MODE) begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_2_DDR; //frame size 1.6us*60MHz/16
                end
                else begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_2_SDR;
                end
            end
            base_freq_x3: begin
                if(DDR_MODE) begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_3_DDR; //frame size 1.067us*60MHz/16
                end
                else begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_3_SDR;
                end
            end
            base_freq_x4: begin
                if(DDR_MODE) begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_4_DDR; //frame size 0.8us*60MHz/16
                end
                else begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_4_SDR;
                end
            end
            base_freq_x6: begin
                if(DDR_MODE) begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_6_DDR; //frame size 0.533us*60MHz/16
                end
                else begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_6_SDR;
                end
            end
            base_freq_x8: begin
                if(DDR_MODE) begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_8_DDR; //frame size 0.4us*60MHz/16
                end
                else begin
                    FRM_TC_CNT  <= FRM_TC_CNT_FREQ_8_SDR;
                end
            end
            default: begin
                FRM_TC_CNT      <= FRM_TC_CNT_FREQ_1_SDR;
            end
        endcase
    end
end
logic state_i_event;

always @ (posedge clk) begin
    if(reset) begin
        i2c_event_i_echo_array                      <= idle;
        state_i_event                               <= 0;
    end
    else begin
        case(state_i_event)
            0: begin 
                if(event_change_i) begin
                    if(state == ST_INIT) begin
                        i2c_event_i_echo_array      <= i2c_event_i_array;
                        state_i_event               <= 1'b0;
                    end
                    else begin
                        state_i_event               <= 1'b1;
                        i2c_event_i_echo_array      <= idle;
                    end
                end
                else begin
                    i2c_event_i_echo_array          <= idle;
                end
            end
            1: begin
                if(state == ST_INIT) begin
                    i2c_event_i_echo_array          <= i2c_event_i_array;
                    state_i_event                   <= 1'b0;
                end
            end
        endcase
    end
end


always @ (posedge clk) begin
    if(reset) begin
        smbus_event_echo                    <= idle;
        echo_send_req                       <= 1'b0;
    end
    else begin
        if(event_change_i) begin
            case(i2c_event_i_array)
                start: begin
                    echo_send_req           <= 1'b1;
                    smbus_event_echo        <= start_echo;
                end
                data_0: begin
                    echo_send_req           <= 1'b1;
                    smbus_event_echo        <= data_0_echo;
                end
                data_1: begin
                    echo_send_req           <= 1'b1;
                    smbus_event_echo        <= data_1_echo;
                end
                bit_rcv: begin
                    echo_send_req           <= 1'b1;
                    smbus_event_echo        <= data_rcv_echo;
                end
                stop: begin
                    echo_send_req           <= 1'b1;
                    smbus_event_echo        <= stop_echo;
                end
                start_rcv: begin
                end
                stop_rcv: begin
                    echo_send_req           <= 1'b1;
                    smbus_event_echo        <= idle;
                end
                idle: begin
                    echo_send_req           <= 1'b1;
                    smbus_event_echo        <= idle;
                end
                default: begin
                    echo_send_req           <= 1'b0;
                end
            endcase
        end
        else begin
            echo_send_req                   <= 1'b0;
        end
    end
end

always @(posedge clk) i2c_event_o_array_ff <= i2c_event_o_array;

assign event_change_o = (i2c_event_o_array != idle) && (i2c_event_o_array_ff == idle);

//Just make sure we will not loose event while we are in ST_FRAME_EVENT state
always @ (posedge clk) begin
    if(reset) begin
        i2c_event_o_next    <= '1;
        i2c_event_o_next_2  <= '1;
        event_nex_req       <= 1'b0;
        event_nex_req_2     <= 1'b0;
    end
    else begin
        if (state == ST_FRAME_EVENT && event_change_o) begin
            if(event_nex_req) begin
                i2c_event_o_next_2  <= i2c_event_o_array;
                event_nex_req_2     <= 1'b1;
            end
            else begin
                i2c_event_o_next    <= i2c_event_o_array;
                event_nex_req       <= 1'b1;
            end
        end
        else if(state == ST_FRAME_EVENT && echo_send_req) begin
            i2c_event_o_next    <= smbus_event_echo;
            event_nex_req       <= 1'b1;
        end
        else if(state == ST_INIT) begin
            if(event_nex_req) begin
                i2c_event_o_next    <= '0;
                event_nex_req       <= 1'b0;
            end
            else if(event_nex_req_2) begin
                event_nex_req_2     <= 1'b0;
                i2c_event_o_next_2  <= 1'b0;
            end
            else begin
                i2c_event_o_next    <= '0;
                event_nex_req       <= 1'b0;
                event_nex_req_2     <= 1'b0;
                i2c_event_o_next_2  <= 1'b0;
            end
        end 
    end
end

//Event catch state machine. We have to be sure we will catch and send event.
//ST_FRAME_EVENT last for 1 frame duration 
//ex. operational frame 25MHZ SDR - frame duration 6.4us ( for CLK 60 MHZ it is 384 clock tick)
always @ (posedge clk) begin
    if(reset) begin
        i2c_event_o_echo_array              <= idle;
        frame_tc_cnt                        <= '0;
        state                               <= ST_INIT;
        FRM_TO_SENT                         <= 1;
    end
    else begin
        case (state)
        ST_INIT: begin
            frame_tc_cnt                <= '0;
            if(event_change_o) begin
                state                   <= ST_FRAME_EVENT;
                i2c_event_o_echo_array  <= i2c_event_o_array;
            end
            else if(echo_send_req) begin
                state                   <= ST_FRAME_EVENT;
                i2c_event_o_echo_array  <= smbus_event_echo;
                if(smbus_event_echo == data_rcv_echo || smbus_event_echo == data_0_echo || smbus_event_echo == data_1_echo) begin//2.0 DC-SMC spec LTPI v1.1- Data Echo and Data Received Echo must be sent at least 3 times
                    FRM_TO_SENT         <= 3;
                end
                else begin
                    FRM_TO_SENT         <= 1;
                end
            end
            else if(event_nex_req) begin
                FRM_TO_SENT             <= 1;
                state                   <= ST_FRAME_EVENT;
                i2c_event_o_echo_array  <= i2c_event_o_next;
            end
            else if(event_nex_req_2) begin
                FRM_TO_SENT             <= 1;
                state                   <= ST_FRAME_EVENT;
                i2c_event_o_echo_array  <= i2c_event_o_next_2;
            end
            // else if(i2c_event_o_echo_array == stop_rcv) begin
            //     state                   <= ST_FRAME_EVENT;
            //     i2c_event_o_echo_array  <= idle;
            // end
            else begin
                state                   <= ST_INIT;
                FRM_TO_SENT             <= 1;
            end
        end
        ST_FRAME_EVENT: begin
            frame_tc_cnt                <= frame_tc_cnt + 10'd01;
            if(frame_tc_cnt > (FRM_TO_SENT * FRM_TC_CNT)) begin
                if (check_echo_rcv && echo_rcved) begin//2.0 DC-SMC spec LTPI v1.1 - Data Echo and Data Received, Echo shall be correctly received at least once before moving to the next state of the transaction
                    state                   <= ST_INIT;
                end
                else if (!check_echo_rcv) begin
                    state                   <= ST_INIT;
                end
            end
        end
        default: begin
            state                           <= ST_INIT;
        end

        endcase
     end
end

//2.0 DC-SMC spec LTPI v1.1 - Data Echo and Data Received
//Echo shall be correctly received at least once before moving to the next state of the transaction
always @ (posedge clk) begin
    if(reset) begin
        echo_rcved      <= 1'b0;
        check_echo_rcv  <= 1'b0;
    end
    else begin
        if(state == ST_FRAME_EVENT ) begin
            case (i2c_event_o_echo_array)
                data_0: begin 
                    check_echo_rcv  <= 1'b1;
                    echo_rcved      <= i2c_event_i_array == data_0_echo    ? 1'b1 : 1'b0; 
                end
                data_1:begin 
                    check_echo_rcv  <= 1'b1;
                    echo_rcved      <= i2c_event_i_array == data_1_echo    ? 1'b1 : 1'b0; 
                end
                bit_rcv:begin 
                    check_echo_rcv  <= 1'b1;
                    echo_rcved      <= i2c_event_i_array == data_rcv_echo  ? 1'b1 : 1'b0; 
                end
                default:begin 
                    echo_rcved      <= 1'b0;
                    check_echo_rcv  <= 1'b0;
                end
            endcase
        end
        else begin
            echo_rcved              <= 1'b0;
            check_echo_rcv          <= 1'b0;
        end
    end
end
endmodule