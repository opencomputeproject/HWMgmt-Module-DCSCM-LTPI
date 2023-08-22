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
// -- Author        : Jakub Wiczynski
// -- Date          : 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Data channel controller CSR
// -------------------------------------------------------------------

`include "logic.svh"

import ltpi_data_channel_controller_csr_rdl_pkg::*;
import ltpi_pkg::*;

module ltpi_data_channel_controller_csr
#(
    parameter                                   QUEUE_DEPTH = 16
)(
    input                                       clk,
    input                                       reset,
    `LOGIC_MODPORT(logic_avalon_mm_if, slave)   avalon_mm_s,
    // -------------------------------------------------------------- //
    output logic                                req_valid,
    input                                       req_ack,
    output Data_channel_payload_t               req,
    input  logic                                resp_valid,
    input  Data_channel_payload_t               resp
);

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- RDL module instance  ---------------------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------------------------------------------------- //
    logic                                   rdl_csr_req;
    logic                                   rdl_csr_wr_en;
    logic [10:0]                            rdl_csr_addr;
    logic [7:0]                             rdl_csr_wr_data;
    logic                                   rdl_csr_wr_ack;
    logic [7:0]                             rdl_csr_rd_data;
    logic                                   rdl_csr_rd_ack;
    ltpi_data_channel_controller_csr_rdl__in_t  rdl_csr_hwin;
    ltpi_data_channel_controller_csr_rdl__out_t rdl_csr_hwout;

    ltpi_data_channel_controller_csr_rdl u_rdl_csr (
        .clk                    (clk),
        .rst                    (reset),
        .s_cpuif_req            (rdl_csr_req),
        .s_cpuif_req_is_wr      (rdl_csr_wr_en),
        .s_cpuif_addr           (rdl_csr_addr),
        .s_cpuif_wr_data        (rdl_csr_wr_data),
        .s_cpuif_req_stall_wr   (),
        .s_cpuif_req_stall_rd   (),
        .s_cpuif_rd_ack         (rdl_csr_rd_ack),
        .s_cpuif_rd_err         (),
        .s_cpuif_rd_data        (rdl_csr_rd_data),
        .s_cpuif_wr_ack         (rdl_csr_wr_ack),
        .s_cpuif_wr_err         (),
        .hwif_in                (rdl_csr_hwin),
        .hwif_out               (rdl_csr_hwout)
    );
    // ------------------------------------------------------------------------------------------------------------------------- //

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- Avalon FSM -------------------------------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------------------------------------------------- //
    typedef enum logic [2:0] {
        AVMM_FSM_IDLE,
        AVMM_FSM_WRITE,
        AVMM_FSM_WRITE_RDL,
        AVMM_FSM_READ,
        AVMM_FSM_READ_RDL,
        AVMM_FSM_RESP
    } avmm_fsm_t;

    avmm_fsm_t          avmm_fsm;
    logic [10:0]        avmm_address;
    logic [ 3:0]        avmm_byte_enable;
    logic [ 3:0][ 7:0]  avmm_data;
    logic [ 1:0]        avmm_response;
    logic               avmm_done;
    logic               avmm_read;
    logic               avmm_write;
    logic [ 1:0]        byte_counter;
    logic               avmm_readdatavalid;
    logic               avmm_writeresponsevalid;

    //assign avalon_mm_s.waitrequest = (avmm_write | avmm_read) & !avmm_done;
    assign avalon_mm_s.waitrequest          = (avmm_write | avmm_read) | avmm_done;
    assign avalon_mm_s.readdatavalid        = avmm_readdatavalid;
    assign avalon_mm_s.writeresponsevalid   = avmm_writeresponsevalid;

    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            avalon_mm_s.readdata    <= 0;
            avalon_mm_s.response    <= 0;

            rdl_csr_req             <= 0;
            rdl_csr_wr_en           <= 0;
            rdl_csr_addr            <= 0;
            rdl_csr_wr_data         <= 0;

            avmm_fsm                <= AVMM_FSM_IDLE;
            avmm_address            <= 0;
            avmm_byte_enable        <= 0;
            avmm_response           <= 0;
            avmm_data[0]            <= 0;
            avmm_data[1]            <= 0;
            avmm_data[2]            <= 0;
            avmm_data[3]            <= 0;
            avmm_done               <= 0;

            avmm_read               <= 0;
            avmm_write              <= 0;
            avmm_readdatavalid      <= 0; 
            avmm_writeresponsevalid <= 0;
            byte_counter            <= 0;
        end
        else begin
            case (avmm_fsm)
                AVMM_FSM_IDLE: begin

                    if (avalon_mm_s.write) begin
                        avmm_address            <= avalon_mm_s.address[10:0];
                        avmm_byte_enable        <= avalon_mm_s.byteenable;
                        avmm_data               <= avalon_mm_s.writedata;
                        avmm_write              <= 1;

                        if      (avalon_mm_s.byteenable[0]) begin
                            byte_counter    <= 0;
                            avmm_fsm        <= AVMM_FSM_WRITE;
                        end
                        else if (avalon_mm_s.byteenable[1]) begin
                            byte_counter    <= 1;
                            avmm_fsm        <= AVMM_FSM_WRITE;
                        end
                        else if (avalon_mm_s.byteenable[2]) begin
                            byte_counter    <= 2;
                            avmm_fsm        <= AVMM_FSM_WRITE;
                        end
                        else if (avalon_mm_s.byteenable[3]) begin
                            byte_counter    <= 3;
                            avmm_fsm        <= AVMM_FSM_WRITE;
                        end
                        else begin
                            avmm_fsm        <= AVMM_FSM_RESP;
                        end
                    end
                    else if (avalon_mm_s.read) begin
                        avmm_address            <= avalon_mm_s.address[10:0];
                        avmm_byte_enable        <= avalon_mm_s.byteenable;

                        avmm_data[0]            <= 0;
                        avmm_data[1]            <= 0;
                        avmm_data[2]            <= 0;
                        avmm_data[3]            <= 0;
                        avmm_read               <= 1;

                        if      (avalon_mm_s.byteenable[0]) begin
                            byte_counter    <= 0;
                            avmm_fsm        <= AVMM_FSM_READ;
                        end
                        else if (avalon_mm_s.byteenable[1]) begin
                            byte_counter    <= 1;
                            avmm_fsm        <= AVMM_FSM_READ;
                        end
                        else if (avalon_mm_s.byteenable[2]) begin
                            byte_counter    <= 2;
                            avmm_fsm        <= AVMM_FSM_READ;
                        end
                        else if (avalon_mm_s.byteenable[3]) begin
                            byte_counter    <= 3;
                            avmm_fsm        <= AVMM_FSM_READ;
                        end
                        else begin
                            avmm_fsm        <= AVMM_FSM_RESP;
                        end
                    end
                    else begin
                        avmm_read               <= 0;
                        avmm_write              <= 0;
                        avmm_readdatavalid      <= 0;
                    end;
                end
                AVMM_FSM_WRITE: begin
                    if (byte_counter == 0) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 1;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b00 };
                        rdl_csr_wr_data     <= avmm_data[0];
                        avmm_fsm            <= AVMM_FSM_WRITE_RDL;
                    end
                    else if (byte_counter == 1) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 1;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b01 };
                        rdl_csr_wr_data     <= avmm_data[1];
                        avmm_fsm            <= AVMM_FSM_WRITE_RDL;
                    end
                    else if (byte_counter == 2) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 1;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b10 };
                        rdl_csr_wr_data     <= avmm_data[2];
                        avmm_fsm            <= AVMM_FSM_WRITE_RDL;
                    end
                    else if (byte_counter == 3) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 1;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b11 };
                        rdl_csr_wr_data     <= avmm_data[3];
                        avmm_fsm            <= AVMM_FSM_WRITE_RDL;
                    end
                    else begin
                        avmm_fsm <= AVMM_FSM_RESP;
                    end
                end
                AVMM_FSM_WRITE_RDL: begin
                    rdl_csr_req        <= 0;
                    rdl_csr_wr_en      <= 0;
                    rdl_csr_addr       <= 0;
                    rdl_csr_wr_data    <= 0;

                    if (rdl_csr_wr_ack) begin
                        if (byte_counter == 0) begin
                            if      (avmm_byte_enable[1]) begin
                                byte_counter <= 1;
                                avmm_fsm     <= AVMM_FSM_WRITE;
                            end
                            else if (avmm_byte_enable[2]) begin
                                byte_counter <= 2;
                                avmm_fsm     <= AVMM_FSM_WRITE;
                            end
                            else if (avmm_byte_enable[3]) begin
                                byte_counter <= 3;
                                avmm_fsm     <= AVMM_FSM_WRITE;
                            end
                            else begin
                                byte_counter <= 0;
                                avmm_fsm     <= AVMM_FSM_RESP;
                            end
                        end
                        else if (byte_counter == 1) begin
                            if (avmm_byte_enable[2]) begin
                                byte_counter <= 2;
                                avmm_fsm     <= AVMM_FSM_WRITE;
                            end
                            else if (avmm_byte_enable[3]) begin
                                byte_counter <= 3;
                                avmm_fsm     <= AVMM_FSM_WRITE;
                            end
                            else begin
                                byte_counter <= 0;
                                avmm_fsm     <= AVMM_FSM_RESP;
                            end
                        end
                        else if (byte_counter == 2) begin
                            if (avmm_byte_enable[3]) begin
                                byte_counter <= 3;
                                avmm_fsm     <= AVMM_FSM_WRITE;
                            end
                            else begin
                                byte_counter <= 0;
                                avmm_fsm     <= AVMM_FSM_RESP;
                            end
                        end
                        else if (byte_counter == 3) begin
                            byte_counter <= 0;
                            avmm_fsm     <= AVMM_FSM_RESP;
                        end
                    end
                end
                AVMM_FSM_READ: begin
                    if (byte_counter == 0) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 0;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b00 };
                        rdl_csr_wr_data     <= 0;
                        avmm_fsm            <= AVMM_FSM_READ_RDL;
                    end
                    else if (byte_counter == 1) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 0;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b01 };
                        rdl_csr_wr_data     <= 0;
                        avmm_fsm            <= AVMM_FSM_READ_RDL;
                    end
                    else if (byte_counter == 2) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 0;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b10 };
                        rdl_csr_wr_data     <= 0;
                        avmm_fsm            <= AVMM_FSM_READ_RDL;
                    end
                    else if (byte_counter == 3) begin
                        rdl_csr_req         <= 1;
                        rdl_csr_wr_en       <= 0;
                        rdl_csr_addr        <= { avmm_address[10:2], 2'b11 };
                        rdl_csr_wr_data     <= 0;
                        avmm_fsm            <= AVMM_FSM_READ_RDL;
                    end
                    else begin
                        avmm_fsm <= AVMM_FSM_RESP;
                    end
                end
                AVMM_FSM_READ_RDL: begin
                    rdl_csr_req        <= 0;
                    rdl_csr_wr_en      <= 0;
                    rdl_csr_addr       <= 0;
                    rdl_csr_wr_data    <= 0;

                    if (rdl_csr_rd_ack) begin
                        if (byte_counter == 0) begin
                            avmm_data[0] <= rdl_csr_rd_data;

                            if      (avmm_byte_enable[1]) begin
                                byte_counter <= 1;
                                avmm_fsm     <= AVMM_FSM_READ;
                            end
                            else if (avmm_byte_enable[2]) begin
                                byte_counter <= 2;
                                avmm_fsm     <= AVMM_FSM_READ;
                            end
                            else if (avmm_byte_enable[3]) begin
                                byte_counter <= 3;
                                avmm_fsm     <= AVMM_FSM_READ;
                            end
                            else begin
                                byte_counter <= 0;
                                avmm_fsm     <= AVMM_FSM_RESP;
                            end
                        end
                        else if (byte_counter == 1) begin
                            avmm_data[1]  <= rdl_csr_rd_data;

                            if (avmm_byte_enable[2]) begin
                                byte_counter <= 2;
                                avmm_fsm     <= AVMM_FSM_READ;
                            end
                            else if (avmm_byte_enable[3]) begin
                                byte_counter <= 3;
                                avmm_fsm     <= AVMM_FSM_READ;
                            end
                            else begin
                                byte_counter <= 0;
                                avmm_fsm     <= AVMM_FSM_RESP;
                            end
                        end
                        else if (byte_counter == 2) begin
                            avmm_data[2]    <= rdl_csr_rd_data;

                            if (avmm_byte_enable[3]) begin
                                byte_counter <= 3;
                                avmm_fsm     <= AVMM_FSM_READ;
                            end
                            else begin
                                byte_counter <= 0;
                                avmm_fsm     <= AVMM_FSM_RESP;
                            end
                        end
                        else if (byte_counter == 3) begin
                            avmm_data[3]    <= rdl_csr_rd_data;
                            byte_counter    <= 0;
                            avmm_fsm        <= AVMM_FSM_RESP;
                        end
                    end
                end
                AVMM_FSM_RESP: begin
                    if (avmm_write) begin
                        avmm_done               <= 1;
                        avmm_write              <= 0;
                        avmm_writeresponsevalid <= 1; 
                        avalon_mm_s.response    <= avmm_response;
                        avalon_mm_s.readdata    <= 0;
                    end
                    else if (avmm_read) begin
                        avmm_done               <= 1;
                        avmm_read               <= 0;
                        avmm_readdatavalid      <= 1;
                        avalon_mm_s.response    <= avmm_response;
                        avalon_mm_s.readdata    <= avmm_data;
                    end
                    else begin
                        avmm_done               <= 0;
                        avmm_read               <= 0;
                        avmm_write              <= 0;
                        avmm_readdatavalid      <= 0;
                        avmm_writeresponsevalid <= 0;
                        avalon_mm_s.response    <= 0;
                        avalon_mm_s.readdata    <= 0;
                        avmm_fsm                <= AVMM_FSM_IDLE;
                    end
                end
            endcase
        end
    end
    // ------------------------------------------------------------------------------------------------------------------------- //

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- REQ/RESP FIFO instance -------------------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------------------------------------------------- //
    logic                   fifo_req_wr_en;
    Data_channel_payload_t  fifo_req_wr_data;
    logic                   fifo_req_wr_ack;
    logic                   fifo_req_rd_en;
    Data_channel_payload_t  fifo_req_rd_data;
    logic                   fifo_req_rd_ack;
    logic                   fifo_req_empty;
    logic                   fifo_req_full;

    logic                   fifo_resp_wr_en;
    Data_channel_payload_t  fifo_resp_wr_data;
    logic                   fifo_resp_wr_ack;
    logic                   fifo_resp_rd_en;
    Data_channel_payload_t  fifo_resp_rd_data;
    logic                   fifo_resp_rd_ack;
    logic                   fifo_resp_empty;
    logic                   fifo_resp_full;

    ltpi_data_channel_controller_fifo #(
        .REQ_WIDTH      ($bits(Data_channel_payload_t)),
        .REQ_DEPTH      (QUEUE_DEPTH),
        .RESP_WIDTH     ($bits(Data_channel_payload_t)),
        .RESP_DEPTH     (QUEUE_DEPTH)
    ) u_fifo (
        .clk            (clk),
        .reset          (reset),
        .req_wr_en      (fifo_req_wr_en),
        .req_wr_data    (fifo_req_wr_data),
        .req_wr_ack     (fifo_req_wr_ack),    
        .req_rd_en      (fifo_req_rd_en),
        .req_rd_data    (fifo_req_rd_data),
        .req_rd_ack     (fifo_req_rd_ack),
        .req_empty      (fifo_req_empty),
        .req_full       (fifo_req_full),
        .resp_wr_en     (fifo_resp_wr_en),
        .resp_wr_data   (fifo_resp_wr_data),
        .resp_wr_ack    (fifo_resp_wr_ack),
        .resp_rd_en     (fifo_resp_rd_en),
        .resp_rd_data   (fifo_resp_rd_data),
        .resp_rd_ack    (fifo_resp_rd_ack),
        .resp_empty     (fifo_resp_empty),
        .resp_full      (fifo_resp_full)
    );
    // ------------------------------------------------------------------------------------------------------------------------- //

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- Write Request to FIFO  -------------------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------------------------------------------------- //

    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            fifo_req_wr_en                          <= 0;
            fifo_req_wr_data                        <= 0;
            rdl_csr_hwin.STATUS.request_write.hwclr <= 0;
        end
        else begin
            if (!fifo_req_wr_en && !fifo_req_wr_ack && !fifo_req_full && rdl_csr_hwout.STATUS.request_write.value && !rdl_csr_hwin.STATUS.request_write.hwclr) begin
                fifo_req_wr_en                      <= 1;
                fifo_req_wr_data.tag                <= rdl_csr_hwout.REQ_TAG.tag.value;
                fifo_req_wr_data.command            <= data_chnl_comand_t'(rdl_csr_hwout.REQ_CMD.cmd.value);
                fifo_req_wr_data.address[0]         <= rdl_csr_hwout.REQ_ADDR0.addr.value;
                fifo_req_wr_data.address[1]         <= rdl_csr_hwout.REQ_ADDR1.addr.value;
                fifo_req_wr_data.address[2]         <= rdl_csr_hwout.REQ_ADDR2.addr.value;
                fifo_req_wr_data.address[3]         <= rdl_csr_hwout.REQ_ADDR3.addr.value;
                fifo_req_wr_data.operation_status   <= 0;
                fifo_req_wr_data.byte_en            <= rdl_csr_hwout.REQ_BEN.ben.value;
                fifo_req_wr_data.data[0]            <= rdl_csr_hwout.REQ_DATA0.data.value;
                fifo_req_wr_data.data[1]            <= rdl_csr_hwout.REQ_DATA1.data.value;
                fifo_req_wr_data.data[2]            <= rdl_csr_hwout.REQ_DATA2.data.value;
                fifo_req_wr_data.data[3]            <= rdl_csr_hwout.REQ_DATA3.data.value;
            end
            else if (fifo_req_wr_en && fifo_req_wr_ack) begin
                fifo_req_wr_en                          <= 0;
                fifo_req_wr_data                        <= 0;
                rdl_csr_hwin.STATUS.request_write.hwclr <= 1;
            end
            else begin
                rdl_csr_hwin.STATUS.request_write.hwclr <= 0;
            end
        end
    end
    // ------------------------------------------------------------------------------------------------------------------------- //

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- Read Response from FIFO  ------------------------------------------------------------------------------------------ //
    // ------------------------------------------------------------------------------------------------------------------------- //
    logic fifo_resp_avaliable;

    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            fifo_resp_rd_en                         <= 0;
            rdl_csr_hwin.STATUS.response_read.hwclr <= 0;

            rdl_csr_hwin.RESP_CMD.cmd.next          <= 0;
            rdl_csr_hwin.RESP_TAG.tag.next          <= 0;
            rdl_csr_hwin.RESP_BEN.ben.next          <= 0;
            rdl_csr_hwin.RESP_STATUS.status.next    <= 0;
            rdl_csr_hwin.RESP_ADDR0.addr.next       <= 0;
            rdl_csr_hwin.RESP_ADDR1.addr.next       <= 0;
            rdl_csr_hwin.RESP_ADDR2.addr.next       <= 0;
            rdl_csr_hwin.RESP_ADDR3.addr.next       <= 0;
            rdl_csr_hwin.RESP_DATA0.data.next       <= 0;
            rdl_csr_hwin.RESP_DATA1.data.next       <= 0;
            rdl_csr_hwin.RESP_DATA2.data.next       <= 0;
            rdl_csr_hwin.RESP_DATA3.data.next       <= 0;
        end
        else begin
            if (!fifo_resp_rd_en && !fifo_resp_rd_ack && !fifo_resp_empty && rdl_csr_hwout.STATUS.response_read.value && !rdl_csr_hwin.STATUS.response_read.hwclr) begin
                fifo_resp_rd_en                         <= 1;
                rdl_csr_hwin.RESP_CMD.cmd.next          <= 0;
                rdl_csr_hwin.RESP_TAG.tag.next          <= 0;
                rdl_csr_hwin.RESP_BEN.ben.next          <= 0;
                rdl_csr_hwin.RESP_STATUS.status.next    <= 0;
                rdl_csr_hwin.RESP_ADDR0.addr.next       <= 0;
                rdl_csr_hwin.RESP_ADDR1.addr.next       <= 0;
                rdl_csr_hwin.RESP_ADDR2.addr.next       <= 0;
                rdl_csr_hwin.RESP_ADDR3.addr.next       <= 0;
                rdl_csr_hwin.RESP_DATA0.data.next       <= 0;
                rdl_csr_hwin.RESP_DATA1.data.next       <= 0;
                rdl_csr_hwin.RESP_DATA2.data.next       <= 0;
                rdl_csr_hwin.RESP_DATA3.data.next       <= 0;
            end
            else if (fifo_resp_rd_en && fifo_resp_rd_ack) begin
                fifo_resp_rd_en                         <= 0;
                rdl_csr_hwin.STATUS.response_read.hwclr <= 1;
                rdl_csr_hwin.RESP_CMD.cmd.next          <= fifo_resp_rd_data.command;
                rdl_csr_hwin.RESP_TAG.tag.next          <= fifo_resp_rd_data.tag;
                rdl_csr_hwin.RESP_BEN.ben.next          <= fifo_resp_rd_data.byte_en;
                rdl_csr_hwin.RESP_STATUS.status.next    <= fifo_resp_rd_data.operation_status;
                rdl_csr_hwin.RESP_ADDR0.addr.next       <= fifo_resp_rd_data.address[0];
                rdl_csr_hwin.RESP_ADDR1.addr.next       <= fifo_resp_rd_data.address[1];
                rdl_csr_hwin.RESP_ADDR2.addr.next       <= fifo_resp_rd_data.address[2];
                rdl_csr_hwin.RESP_ADDR3.addr.next       <= fifo_resp_rd_data.address[3];
                rdl_csr_hwin.RESP_DATA0.data.next       <= fifo_resp_rd_data.data[0];
                rdl_csr_hwin.RESP_DATA1.data.next       <= fifo_resp_rd_data.data[1];
                rdl_csr_hwin.RESP_DATA2.data.next       <= fifo_resp_rd_data.data[2];
                rdl_csr_hwin.RESP_DATA3.data.next       <= fifo_resp_rd_data.data[3];       
            end
            else begin
                rdl_csr_hwin.STATUS.response_read.hwclr <= 0;
            end
        end
    end
    // ------------------------------------------------------------------------------------------------------------------------- //

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- Status  ----------------------------------------------------------------------------------------------------------- //
    // ------------------------------------------------------------------------------------------------------------------------- //
    assign rdl_csr_hwin.STATUS.request_ready.next   = !fifo_req_full;
    assign rdl_csr_hwin.STATUS.response_ready.next  = !fifo_resp_empty;
    // ------------------------------------------------------------------------------------------------------------------------- //

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- Send Request to the PHY  ------------------------------------------------------------------------------------------ //
    // ------------------------------------------------------------------------------------------------------------------------- //
    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            req_valid       <= 0;
            req             <= 0;
            fifo_req_rd_en  <= 0;
        end
        else begin
            if (!req_valid && !req_ack) begin
                if (!fifo_req_rd_en && !fifo_req_rd_ack && !fifo_req_empty) begin
                    fifo_req_rd_en  <= 1;
                end
                else if (fifo_req_rd_en && fifo_req_rd_ack) begin
                    fifo_req_rd_en  <= 0;
                    req             <= fifo_req_rd_data;
                    req_valid       <= 1;
                end
            end
            else if (req_valid && req_ack) begin
                req         <= 0;
                req_valid   <= 0;
            end
        end
    end
    // ------------------------------------------------------------------------------------------------------------------------- //

    // ------------------------------------------------------------------------------------------------------------------------- //
    // ----- Receive Response from the PHY  ------------------------------------------------------------------------------------ //
    // ------------------------------------------------------------------------------------------------------------------------- //
    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            fifo_resp_wr_en    <= 0;
            fifo_resp_wr_data  <= 0;
        end
        else begin
            if (!fifo_resp_full && !fifo_resp_wr_ack && resp_valid) begin
                fifo_resp_wr_en     <= 1;
                fifo_resp_wr_data   <= resp;
            end
            else if (fifo_resp_wr_ack) begin
                fifo_resp_wr_en     <= 0;
                fifo_resp_wr_data   <= 0;
            end 
        end
    end
    // ------------------------------------------------------------------------------------------------------------------------- //
endmodule
