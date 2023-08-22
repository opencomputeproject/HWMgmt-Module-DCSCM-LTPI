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
// -- Data channel target 
// -------------------------------------------------------------------

`include "logic.svh"

module ltpi_data_channel_target
import ltpi_pkg::*;
#(
    parameter                       QUEUE_DEPTH = 16
)
(
    input                           clk,
    input                           reset,
    input logic                     data_channel_rst,
    `LOGIC_MODPORT(logic_avalon_mm_if, master)  avalon_mm_m,

    input  Data_channel_payload_t   payload_i,
    input  logic payload_i_valid,
    
    output logic                    resp_rd_valid,
    input logic                     resp_rd_ack,
    output Data_channel_payload_t   resp_fifo_rd,

    input logic                     frm_crc_error,
    input link_state_t              local_link_state

);

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- Parameters for defining base addresses of register space sections ------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //
localparam logic [31:0] DATA_CHNL_REGISTERS_BASE_ADDRESS       = 32'h0000_0000;
//localparam int          DATA_CHNL_REGISTERS_SIZE               = 16 * 4;
//localparam logic [31:0] DATA_CHNL_REGISTERS_END_ADDRESS        = DATA_CHNL_REGISTERS_BASE_ADDRESS + DATA_CHNL_REGISTERS_SIZE - 1;
localparam logic [31:0] DATA_CHNL_REGISTERS_END_ADDRESS        = 32'hFFFF_FFFF;

typedef enum logic [2:0] {
    AVMM_FSM_IDLE,
    AVMM_FSM_WRITE,
    AVMM_FSM_READ,
    AVMM_FSM_CRC_ERROR,
    AVMM_FSM_REQ_ACK
} avmm_fsm_t;

avmm_fsm_t              avmm_fsm;
logic                   timer_1ms_done;
logic                   timer_1ms_start;

logic                   payload_i_valid_ff;
logic                   payload_i_valid_r_edge;


always_ff @ (posedge clk) payload_i_valid_ff <= payload_i_valid;
assign payload_i_valid_r_edge = ~payload_i_valid_ff & payload_i_valid;

Data_channel_payload_t  resp;
logic                   resp_valid;

logic                   req_valid;
Data_channel_payload_t  req;
logic                   req_ack;

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- REQ/RESP FIFO instance -------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //
logic                   fifo_req_wr;
Data_channel_payload_t  fifo_req_wr_data;
logic                   fifo_req_rd;
Data_channel_payload_t  fifo_req_rd_data;
logic                   fifo_req_rd_ack;
logic                   fifo_req_empty;
logic                   fifo_req_full;

logic                   fifo_resp_wr;
Data_channel_payload_t  fifo_resp_wr_data;
logic                   fifo_resp_rd;
Data_channel_payload_t  fifo_resp_rd_data;
logic                   fifo_resp_empty;
logic                   fifo_resp_full;

//assign fifo_req_wr_data     = {payload_i, frm_crc_error};
assign fifo_req_wr          = payload_i_valid_r_edge;
logic fifo_req_rd_frm_crc_error;
logic req_frm_crc_err;
logic frm_crc_error_ff;

always_ff @ (posedge clk) frm_crc_error_ff <= frm_crc_error;

ltpi_data_channel_target_fifo  #(
    .REQ_WIDTH      ($bits(Data_channel_payload_t) + 1),
    .REQ_DEPTH      (QUEUE_DEPTH),
    .RESP_WIDTH     ($bits(Data_channel_payload_t)),
    .RESP_DEPTH     (QUEUE_DEPTH)
)
ltpi_data_channel_target_fifo_inst
(
    .clk            (clk),
    .reset          (reset),

    .req_wr_data    ({payload_i, frm_crc_error_ff}),
    .req_wr_req     (fifo_req_wr),
    .req_rd_data    ({fifo_req_rd_data , fifo_req_rd_frm_crc_error} ),
    .req_rd_req     (fifo_req_rd),
    .req_empty      (fifo_req_empty),
    .req_full       (fifo_req_full),

    .resp_wr_data   (fifo_resp_wr_data),
    .resp_wr_req    (fifo_resp_wr),
    .resp_rd_data   (fifo_resp_rd_data),
    .resp_rd_req    (fifo_resp_rd),
    .resp_empty     (fifo_resp_empty),
    .resp_full      (fifo_resp_full)
);

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- Send Request to the PHY  ------------------------------------------------------------------------------------------ //
// ------------------------------------------------------------------------------------------------------------------------- //
logic fifo_req_rd_ff;

always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        req_valid               <= 0;
        req                     <= 0;
        req_frm_crc_err         <= 0;
        fifo_req_rd             <= 0;
        fifo_req_rd_ff          <= 0;
    end
    else begin
        fifo_req_rd_ff          <= fifo_req_rd;

        if (!req_valid && !req_ack) begin
            if (!fifo_req_rd && !fifo_req_empty) begin
                fifo_req_rd     <= 1;
            end
            else if (fifo_req_rd) begin
                fifo_req_rd     <= 0;
            end
            else if (fifo_req_rd_ff) begin
                req             <= fifo_req_rd_data;
                req_frm_crc_err <= fifo_req_rd_frm_crc_error;
                req_valid       <= 1;
            end
        end
        else if (req_valid && req_ack) begin
            req                 <= 0;
            req_frm_crc_err     <= 0;
            req_valid           <= 0;
        end
    end
end

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- Receive Response from the PHY  ------------------------------------------------------------------------------------ //
// ------------------------------------------------------------------------------------------------------------------------- //
always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        fifo_resp_wr                <= 0;
        fifo_resp_wr_data           <= 0;
    end
    else begin
        if (!fifo_resp_full && resp_valid) begin
            fifo_resp_wr            <= 1;
            fifo_resp_wr_data       <= resp;
        end
        else begin
            fifo_resp_wr            <= 0;
            fifo_resp_wr_data       <= 0;
        end 
    end
end

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- Send Respond to the PHY  ------------------------------------------------------------------------------------------ //
// ------------------------------------------------------------------------------------------------------------------------- //
logic fifo_resp_rd_ff;

always_ff @ (posedge clk or posedge reset) begin
    if (reset) begin
        resp_rd_valid               <= 0;
        resp_fifo_rd                <= 0;
        fifo_resp_rd                <= 0;
        fifo_resp_rd_ff             <= 0; 
    end
    else begin
        fifo_resp_rd_ff <= fifo_resp_rd;
        if (!resp_rd_valid && !resp_rd_ack) begin
            if (!fifo_resp_rd && !fifo_resp_rd_ff && !fifo_resp_empty) begin
                fifo_resp_rd        <= 1;
            end
            else if (fifo_resp_rd ) begin
                fifo_resp_rd        <= 0;
            end
            else if(fifo_resp_rd_ff) begin
                resp_fifo_rd        <= fifo_resp_rd_data;
                resp_rd_valid       <= 1;
            end
        end
        else if (resp_rd_valid && resp_rd_ack) begin
            resp_fifo_rd            <= 0;
            resp_rd_valid           <= 0;
        end
    end
end

// ------------------------------------------------------------------------------------------------------------------------- //
// ----- AVMM FSM  --------------------------------------------------------------------------------------------------------- //
// ------------------------------------------------------------------------------------------------------------------------- //
always_ff @ (posedge clk or posedge reset or posedge data_channel_rst) begin
    if (reset || data_channel_rst ) begin
        avalon_mm_m.read                <= 0;
        avalon_mm_m.write               <= 0;
        avalon_mm_m.address             <= 0;
        avalon_mm_m.writedata           <= 0; 
        avalon_mm_m.byteenable          <= 0;
        
        resp_valid                      <= 0;
        resp.tag                        <= 0;
        resp.command                    <= READ_REQ;
        resp.address                    <= 0;
        resp.data                       <= 0;
        resp.byte_en                    <= 0;
        avmm_fsm                        <= AVMM_FSM_IDLE;
        timer_1ms_start                 <= 0;
        req_ack                         <= 0;
        resp                            <= 0;
    end
    else begin
        if(local_link_state == operational_st) begin
            case (avmm_fsm)
                AVMM_FSM_IDLE: begin
                    if(req_valid & !req_frm_crc_err) begin
                        if(req.command == READ_REQ) begin
                            avalon_mm_m.chipselect      <= 1;
                            avalon_mm_m.address         <= req.address;
                            avalon_mm_m.read            <= 1;
                            avalon_mm_m.byteenable      <= req.byte_en;
                            avmm_fsm                    <= AVMM_FSM_READ;
                        end
                        else if(req.command == WRITE_REQ) begin
                            avalon_mm_m.chipselect      <= 1;
                            avalon_mm_m.address         <= req.address;
                            avalon_mm_m.write           <= 1;
                            avalon_mm_m.byteenable      <= req.byte_en;
                            for (int b = 0; b < 4; b++) begin
                                if (req.byte_en[b]) begin
                                    avalon_mm_m.writedata[b] <= req.data[b];
                                end
                                else begin
                                    avalon_mm_m.writedata[b] <= 0;
                                end
                            end
                            avmm_fsm                    <= AVMM_FSM_WRITE;
                        end
                    end
                    else if(req_valid) begin
                        avmm_fsm                        <= AVMM_FSM_CRC_ERROR;
                        avalon_mm_m.address             <= req.address;
                        avalon_mm_m.byteenable          <= req.byte_en;
                    end
                    else begin
                        req_ack                         <= 0;
                        timer_1ms_start                 <= 0;
                        resp_valid                      <= 0;
                        avalon_mm_m.chipselect          <= 0;
                        avalon_mm_m.read                <= 0;
                        avalon_mm_m.write               <= 0;
                        avalon_mm_m.address             <= 0;
                        avalon_mm_m.writedata           <= 0; 
                        avalon_mm_m.byteenable          <= 0;
                    end
                end
                AVMM_FSM_WRITE: begin
                    //if(!avalon_mm_m.waitrequest) begin
                    timer_1ms_start <= 1; 
                    if(avalon_mm_m.writeresponsevalid) begin
                        if (avalon_mm_m.address >= DATA_CHNL_REGISTERS_BASE_ADDRESS && avalon_mm_m.address <= DATA_CHNL_REGISTERS_END_ADDRESS) begin
                            resp.command                <= WRITE_COMP;
                            resp.tag                    <= req.tag;
                            resp.address                <= avalon_mm_m.address;
                            resp.byte_en                <= avalon_mm_m.byteenable;
                            resp.operation_status       <= 0;
                            resp.data <= avalon_mm_m.writedata;
                        end
                        else begin
                            resp.command                <= WRITE_COMP;
                            resp.tag                    <= req.tag;
                            resp.address                <= avalon_mm_m.address;
                            resp.byte_en                <= avalon_mm_m.byteenable;
                            resp.operation_status       <= 1;
                            resp.data                   <= avalon_mm_m.writedata;
                        end

                        resp_valid                      <= 1;
                        avmm_fsm                        <= AVMM_FSM_REQ_ACK;
                        req_ack                         <= 1; 
                    end

                    if (timer_1ms_done) begin
                        resp.command                    <= WRITE_COMP;
                        resp.tag                        <= req.tag;
                        resp.address                    <= avalon_mm_m.address;
                        resp.byte_en                    <= avalon_mm_m.byteenable;
                        resp.operation_status           <= 1;
                        resp.data                       <= 0;
                        resp_valid                      <= 1;

                        avmm_fsm                        <= AVMM_FSM_REQ_ACK;
                        req_ack                         <= 1; 
                    end
                    
                end
                AVMM_FSM_READ: begin
                    timer_1ms_start <= 1; 
                    if (avalon_mm_m.address >= DATA_CHNL_REGISTERS_BASE_ADDRESS && avalon_mm_m.address <= DATA_CHNL_REGISTERS_END_ADDRESS) begin
                        if(avalon_mm_m.readdatavalid) begin
                            resp.command                <= READ_COMP;
                            resp.tag                    <= req.tag;
                            resp.address                <= avalon_mm_m.address;
                            resp.byte_en                <= avalon_mm_m.byteenable;
                            resp.operation_status       <= 0;

                            for (int b = 0; b < 4; b++) begin
                                if (avalon_mm_m.byteenable[b]) begin
                                    resp.data[b]        <= avalon_mm_m.readdata[b];
                                end
                                else begin
                                    resp.data[b]        <=0; 
                                end
                            end

                            resp_valid                  <= 1;
                            avmm_fsm                    <= AVMM_FSM_REQ_ACK;
                            req_ack                     <= 1; 
                        end
                    end
                    else begin
                        resp.command                    <= READ_COMP;
                        resp.tag                        <= req.tag;
                        resp.address                    <= avalon_mm_m.address;
                        resp.byte_en                    <= avalon_mm_m.byteenable;
                        resp.operation_status           <= 1;
                        resp.data                       <= '0;
                        resp_valid                      <= 1;

                        avmm_fsm                        <= AVMM_FSM_REQ_ACK;
                        req_ack                         <= 1; 

                    end

                    if (timer_1ms_done) begin
                        resp.command                    <= READ_COMP;
                        resp.tag                        <= req.tag;
                        resp.address                    <= avalon_mm_m.address;
                        resp.byte_en                    <= avalon_mm_m.byteenable;
                        resp.operation_status           <= 1;
                        resp.data                       <= 0;
                        resp_valid                      <= 1;

                        avmm_fsm                        <= AVMM_FSM_REQ_ACK;
                        req_ack                         <= 1; 

                    end
                end
                AVMM_FSM_CRC_ERROR: begin
                    resp.command                        <= CRC_ERROR;
                    resp.tag                            <= req.tag;
                    resp.address                        <= avalon_mm_m.address;
                    resp.byte_en                        <= avalon_mm_m.byteenable;
                    resp.operation_status               <= 1;
                    resp.data                           <= 0;
                    resp_valid                          <= 1;

                    avmm_fsm                            <= AVMM_FSM_REQ_ACK;
                    req_ack                             <= 1; 
                end
                
                AVMM_FSM_REQ_ACK: begin
                    avmm_fsm                            <= AVMM_FSM_IDLE;
                    resp_valid                          <= 0;
                    req_ack                             <= 0; 
                end

            endcase
        end
    end
end

logic [15:0] cnt;

always_ff @ (posedge clk or posedge reset or posedge data_channel_rst) begin
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