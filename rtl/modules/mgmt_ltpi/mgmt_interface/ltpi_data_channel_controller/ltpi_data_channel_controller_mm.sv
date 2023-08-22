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
// -- Date          :  2022
// -- Project Name  : LTPI
// -- Description   :
// -- 
// -------------------------------------------------------------------
`include "logic.svh"

module ltpi_data_channel_controller_mm
import ltpi_pkg::*;
(
    input   wire                    clk,
    input   wire                    reset,

    //fifo req signal
    output logic                    req_valid,
    input logic                     req_ack,
    output Data_channel_payload_t   req,

    //fifo res signal
    input  logic                   resp_valid,
    input  Data_channel_payload_t  resp,

    `LOGIC_MODPORT(logic_avalon_mm_if,  slave)  avalon_mm_s,
    input logic [7:0]                           tag,

    input logic        data_channel_rst

);

typedef enum logic [2:0] {
    AVMM_FSM_IDLE,
    AVMM_FSM_WRITE,
    AVMM_FSM_WRITE_COMPL,
    AVMM_FSM_READ,
    AVMM_FSM_READ_COMPL,
    AVMM_FSM_RESP
} avmm_fsm_t;

avmm_fsm_t          avmm_fsm;
logic               avmm_rnw;
logic [31:0]        avmm_address;
logic [3:0]         avmm_byte_enable;
logic [31:0]        avmm_data;
logic [1:0]         avmm_response;

logic timer_1ms_done;
logic timer_1ms_start;

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- AVMM FSM  --------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //
always_ff @ (posedge clk or posedge reset or posedge data_channel_rst) begin
    if (reset || data_channel_rst) begin
        avalon_mm_s.readdata            <= 0;
        avalon_mm_s.readdatavalid       <= 0;
        avalon_mm_s.response            <= 0;
        avalon_mm_s.writeresponsevalid  <= 0; 
        avalon_mm_s.waitrequest         <= 0;

        avmm_fsm                        <= AVMM_FSM_IDLE;
        avmm_rnw                        <= 0;
        avmm_address                    <= 0;
        avmm_data                       <= 0;
        avmm_byte_enable                <= 0;
        avmm_response                   <= 0;

        req_valid                       <= 0;
        req.tag                         <= 0;
        req.command                     <= READ_REQ;
        req.address                     <= 0;
        req.data                        <= 0;
        req.byte_en                     <= 0;
        req.operation_status            <=0;
        timer_1ms_start                 <= 0;

    end
    else begin
        case (avmm_fsm)
            AVMM_FSM_IDLE: begin
                if (!avalon_mm_s.waitrequest) begin
                    if (avalon_mm_s.chipselect) begin
                        if (avalon_mm_s.write) begin
                            avmm_rnw                <= 0;
                            avmm_address            <= avalon_mm_s.address[31:0];
                            for (int b = 0; b < 4; b++) begin
                                if (avalon_mm_s.byteenable[b]) begin
                                    avmm_data[b*8 +: 8] <= avalon_mm_s.writedata[b];
                                end
                                else begin
                                    avmm_data[b*8 +: 8] <= 0;
                                end
                            end
                            avmm_byte_enable        <= avalon_mm_s.byteenable;
                            avalon_mm_s.waitrequest <= 1;
                            avmm_fsm                <= AVMM_FSM_WRITE;
                        end
                        else if (avalon_mm_s.read) begin
                            avmm_rnw                <= 1;
                            avmm_address            <= avalon_mm_s.address[15:0];
                            avmm_byte_enable        <= avalon_mm_s.byteenable;
                            avalon_mm_s.waitrequest <= 1;
                            avmm_fsm                <= AVMM_FSM_READ;
                        end
                    end
                end
                else begin
                    timer_1ms_start                 <= 0;
                    req_valid                       <= 0;
                    avalon_mm_s.waitrequest         <= 0;
                    avalon_mm_s.response            <= 0;
                    avalon_mm_s.writeresponsevalid  <= 0;
                    avalon_mm_s.readdata            <= { 8'b0, 8'b0, 8'b0, 8'b0 };
                    avalon_mm_s.readdatavalid       <= 0;

                    req.tag            <= 0;
                    req.command        <= READ_REQ;
                    req.address        <= 0;
                    req.data           <= 0;
                    req.byte_en        <= 0;
                end
            end
            AVMM_FSM_WRITE: begin
                req.tag                <= tag;
                req.command            <= WRITE_REQ;
                req.address            <= avmm_address;
                req.data               <= avmm_data;
                req.byte_en            <= avmm_byte_enable;
                req.operation_status   <= 4'hf;
                req_valid                           <= 1;

                if(req_ack) begin
                    avmm_fsm                        <= AVMM_FSM_WRITE_COMPL;
                end
            end
            AVMM_FSM_WRITE_COMPL: begin
                timer_1ms_start                     <= 1;
                req_valid                           <= 0;
                if(resp_valid == 1) begin
                    if(resp.command == WRITE_COMP) begin
                        avmm_fsm                    <= AVMM_FSM_RESP;
                    end
                    else if (resp.command == CRC_ERROR) begin
                        avalon_mm_s.waitrequest     <= 0;
                        avmm_fsm                    <= AVMM_FSM_IDLE;
                    end
                end
                else if(timer_1ms_done) begin
                    avmm_fsm                        <= AVMM_FSM_IDLE;
                end
            end
            AVMM_FSM_READ: begin
                req.tag                <= tag;
                req.command            <= READ_REQ;
                req.address            <= avmm_address;
                req.data               <= '0;
                req.byte_en            <= avmm_byte_enable;
                req.operation_status   <= 4'hf;
                req_valid                           <= 1;
                if(req_ack) begin
                    avmm_fsm                        <= AVMM_FSM_READ_COMPL;
                end
            end
            AVMM_FSM_READ_COMPL: begin
                timer_1ms_start                     <= 1;
                req_valid                           <= 0;
                if(resp_valid == 1) begin
                    if(resp.command == READ_COMP) begin
                        avmm_data                   <= resp.data;
                        avmm_fsm                    <= AVMM_FSM_RESP;
                    end
                    else if (resp.command == CRC_ERROR) begin
                        avalon_mm_s.waitrequest     <= 0;
                        avmm_fsm                    <= AVMM_FSM_IDLE;
                    end
                end
                else if(timer_1ms_done) begin
                    avalon_mm_s.waitrequest     <= 0;
                    avmm_fsm                        <= AVMM_FSM_IDLE;
                end
            end
            AVMM_FSM_RESP: begin
                timer_1ms_start                     <= 0;
                if (avalon_mm_s.chipselect) begin
                    if (avmm_rnw) begin  // R
                        for (int b = 0; b < 4; b++) begin
                            if (avmm_byte_enable[b])    avalon_mm_s.readdata[b] <= avmm_data[b*8 +: 8];
                            else                        avalon_mm_s.readdata[b] <= 0;
                        end
                        avalon_mm_s.readdatavalid       <= 1;
                    end
                    else begin  // W
                        avalon_mm_s.response            <= avmm_response;
                        avalon_mm_s.writeresponsevalid  <= 1;
                    end

                    avmm_rnw                        <= 0;
                    avmm_address                    <= 0;
                    avmm_data                       <= 0;
                    avmm_byte_enable                <= 0;
                    avmm_fsm                        <= AVMM_FSM_IDLE;
                end
            end
        endcase
    end
end

logic [15:0] cnt;


always @(posedge clk or posedge reset or posedge data_channel_rst)begin
    if (reset || data_channel_rst) begin
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

endmodule