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
// -- Author        : Jakub Wiczynski, Katarzyna Krzewska 
// -- Date          : September 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Avalone 1 to 4 multiplexer
// -------------------------------------------------------------------


`include "logic.svh"

module avmm_mux #(
    parameter ADDR_WIDTH     = 32,
    parameter DATA_WIDTH     = 32,
    parameter MST0_ADDR_LOW  = 32'h0000_0000,
    parameter MST0_ADDR_HIGH = 32'h0000_01FF,
    parameter MST1_ADDR_LOW  = 32'h0000_0200,
    parameter MST1_ADDR_HIGH = 32'h0000_02FF,
    parameter MST2_ADDR_LOW  = 32'h0000_0300,
    parameter MST2_ADDR_HIGH = 32'h0000_03FF,
    parameter MST3_ADDR_LOW  = 32'h0000_0400,
    parameter MST3_ADDR_HIGH = 32'hFFFF_FFFF
)(
    input                                               clk,
    input                                               rstn,
    `LOGIC_MODPORT(logic_avalon_mm_if,  slave)          avmm_s,
    `LOGIC_MODPORT(logic_avalon_mm_if,  master)         avmm_m_0,
    `LOGIC_MODPORT(logic_avalon_mm_if,  master)         avmm_m_1,
    `LOGIC_MODPORT(logic_avalon_mm_if,  master)         avmm_m_2,
    `LOGIC_MODPORT(logic_avalon_mm_if,  master)         avmm_m_3
);
    //AVMM masters 0 to 3
    logic [ 3:0][31:0]  avmm_m_addr;
    logic [ 3:0]        avmm_m_read;
    logic [ 3:0]        avmm_m_write;
    logic [ 3:0][31:0]  avmm_m_wdata;
    logic [ 3:0][ 3:0]  avmm_m_byteen;
    logic [ 3:0][31:0]  avmm_m_rdata;
    logic [ 3:0]        avmm_m_rdvalid;
    logic [ 3:0]        avmm_m_waitrq;
    logic [ 3:0]        avmm_m_chipselect;
    logic [ 3:0]        avmm_m_wrvalid;
    logic [ 3:0][ 1:0]  avmm_m_response;

     `define AVMM_ASSIGN(index) \
    assign avmm_m_``index``.address         = avmm_m_addr[index];\
    assign avmm_m_``index``.read            = avmm_m_read[index];\
    assign avmm_m_``index``.write           = avmm_m_write[index];\
    assign avmm_m_``index``.writedata[0]    = avmm_m_wdata[index][ 7: 0];\
    assign avmm_m_``index``.writedata[1]    = avmm_m_wdata[index][15: 8];\
    assign avmm_m_``index``.writedata[2]    = avmm_m_wdata[index][23:16];\
    assign avmm_m_``index``.writedata[3]    = avmm_m_wdata[index][31:24];\
    assign avmm_m_``index``.byteenable      = avmm_m_byteen[index];\
    assign avmm_m_rdata[index][ 7: 0] = avmm_m_``index``.readdata[0];\
    assign avmm_m_rdata[index][15: 8] = avmm_m_``index``.readdata[1];\
    assign avmm_m_rdata[index][23:16] = avmm_m_``index``.readdata[2];\
    assign avmm_m_rdata[index][31:24] = avmm_m_``index``.readdata[3];\
    assign avmm_m_rdvalid[index]      = avmm_m_``index``.readdatavalid;\
    assign avmm_m_waitrq [index]      = avmm_m_``index``.waitrequest;\
    assign avmm_m_response[index]     = avmm_m_``index``.response;\
    assign avmm_m_wrvalid[index]      = avmm_m_``index``.writeresponsevalid;\
    assign avmm_m_``index``.chipselect=avmm_m_chipselect[index];\

    `AVMM_ASSIGN(0)
    `AVMM_ASSIGN(1)
    `AVMM_ASSIGN(2)
    `AVMM_ASSIGN(3)

    typedef enum logic {
        FSM_REQ,
        FSM_RESP
    } fsm_t;

    fsm_t s_fsm;

    localparam int MST_ADDR_LOW     [3:0] = '{ MST3_ADDR_LOW, MST2_ADDR_LOW, MST1_ADDR_LOW, MST0_ADDR_LOW};
    localparam int MST_ADDR_HIGH    [3:0] = '{ MST3_ADDR_HIGH, MST2_ADDR_HIGH, MST1_ADDR_HIGH, MST0_ADDR_HIGH};

    logic        avmm_req;
    logic        avmm_ack     [3:0];
    logic        avmm_rnw;
    logic [31:0] avmm_address;
    logic [31:0] avmm_wr_data;
    logic [31:0] avmm_rd_data [3:0];
    logic [ 3:0] avmm_ben;
    logic [ 1:0] avmm_mst_idx;
    logic [ 1:0] avmm_respons[3:0];

    always_ff @ (posedge clk or negedge rstn) begin
        if (!rstn) begin
            avmm_s.waitrequest          <= 1;
            avmm_s.response             <= 0;
            avmm_s.writeresponsevalid   <= 0;
            avmm_s.readdatavalid        <= 0;
            for (int b = 0; b < DATA_WIDTH/8; b++) begin
                avmm_s.readdata[b]      <= 0;
            end
            avmm_req                    <= 0;
            avmm_wr_data                <= 0;
            s_fsm                       <= FSM_REQ;
        end
        else begin
            case(s_fsm)
                FSM_REQ: begin
                    if (!avmm_req) begin
                        if (avmm_s.chipselect && avmm_s.read && !avmm_s.waitrequest) begin //read
                            avmm_s.waitrequest              <= 1;
                            if(avmm_s.address >= MST_ADDR_LOW[0] && avmm_s.address <= MST_ADDR_HIGH[0] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 1;
                                avmm_address                <= avmm_s.address;
                                avmm_wr_data                <= 0;
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 0;
                                s_fsm                       <= FSM_RESP; 
                            end
                            else if (avmm_s.address >= MST_ADDR_LOW[1] && avmm_s.address <= MST_ADDR_HIGH[1] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 1;
                                avmm_address                <= avmm_s.address;
                                avmm_wr_data                <= 0;
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 1;
                                s_fsm                       <= FSM_RESP; 
                            end
                            else if (avmm_s.address >= MST_ADDR_LOW[2] && avmm_s.address <= MST_ADDR_HIGH[2] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 1;
                                avmm_address                <= avmm_s.address;
                                avmm_wr_data                <= 0;
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 2;
                                s_fsm                       <= FSM_RESP; 
                            end
                            else if (avmm_s.address >= MST_ADDR_LOW[3] && avmm_s.address <= MST_ADDR_HIGH[3] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 1;
                                avmm_address                <= avmm_s.address;
                                avmm_wr_data                <= 0;
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 3;
                                s_fsm                       <= FSM_RESP; 
                            end
                        end
                        else if (avmm_s.chipselect && avmm_s.write && !avmm_s.waitrequest) begin//write
                            avmm_s.waitrequest                  <= 1;
                            if(avmm_s.address >= MST_ADDR_LOW[0] && avmm_s.address <= MST_ADDR_HIGH[0] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 0;
                                avmm_address                <= avmm_s.address;
                                for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                    avmm_wr_data[b*8 +: 8]  <= avmm_s.writedata[b];
                                end
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 0;
                                s_fsm                       <= FSM_RESP; 
                            end
                            else if (avmm_s.address >= MST_ADDR_LOW[1] && avmm_s.address <= MST_ADDR_HIGH[1] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 0;
                                avmm_address                <= avmm_s.address;
                                for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                    avmm_wr_data[b*8 +: 8]  <= avmm_s.writedata[b];
                                end
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 1;
                                s_fsm                       <= FSM_RESP; 
                            end
                            else if (avmm_s.address >= MST_ADDR_LOW[2] && avmm_s.address <= MST_ADDR_HIGH[2] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 0;
                                avmm_address                <= avmm_s.address;
                                for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                    avmm_wr_data[b*8 +: 8]  <= avmm_s.writedata[b];
                                end
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 2;
                                s_fsm                       <= FSM_RESP; 
                            end
                            else if (avmm_s.address >= MST_ADDR_LOW[3] && avmm_s.address <= MST_ADDR_HIGH[3] ) begin
                                avmm_req                    <= 1;
                                avmm_rnw                    <= 0;
                                avmm_address                <= avmm_s.address;
                                for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                    avmm_wr_data[b*8 +: 8]  <= avmm_s.writedata[b];
                                end
                                avmm_ben                    <= avmm_s.byteenable;
                                avmm_mst_idx                <= 3;
                                s_fsm                       <= FSM_RESP; 
                            end
                        end
                        else begin
                            avmm_s.waitrequest              <= 0;
                            avmm_s.response                 <= 0;
                            avmm_s.writeresponsevalid       <= 0;
                            avmm_s.readdatavalid            <= 0;
                            for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                avmm_s.readdata[b]          <= 0;
                            end
                        end
                    end
                    else begin
                        if (avmm_ack[avmm_mst_idx]) begin
                            avmm_req                        <= 0;
                            avmm_rnw                        <= 0;
                            avmm_s.readdatavalid            <= 0;
                            avmm_s.waitrequest              <= 0;
                            avmm_s.response                 <= 0;
                            avmm_s.writeresponsevalid       <= 0;
                        end
                    end
                end
                FSM_RESP: begin
                    if (avmm_ack[avmm_mst_idx]) begin
                        if (avmm_rnw ) begin//read
                            avmm_s.readdatavalid            <= 1;
                            avmm_s.writeresponsevalid       <= 0;
                            avmm_s.response                 <= 0;
                            for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                avmm_s.readdata[b]          <= avmm_rd_data[avmm_mst_idx][b*8 +: 8];
                            end
                        end
                        else begin//write
                            avmm_s.readdatavalid            <= 0;
                            avmm_s.writeresponsevalid       <= 1;
                            avmm_s.response                 <= avmm_respons[avmm_mst_idx];
                            for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                avmm_s.readdata[b]          <= 0;
                            end
                        end
                        s_fsm                               <= FSM_REQ;
                    end
                end
            endcase
        end
    end

    fsm_t m_fsm[3:0] ;

    genvar i;
    generate 
    for(i = 0; i < 4; i = i+1) begin : avmm_m_FSM
        always_ff @ (posedge clk or negedge rstn) begin
            if (!rstn) begin
                avmm_m_chipselect[i]   <= 0;
                avmm_m_read      [i]   <= 0;
                avmm_m_write     [i]   <= 0;
                avmm_m_addr      [i]   <= 0;
                avmm_m_byteen    [i]   <= 0;
                avmm_ack         [i]   <= 0;
                avmm_respons     [i]   <= 0;

                for (int b = 0; b < DATA_WIDTH/8; b++) begin
                    avmm_m_wdata[i][b*8 +: 8] <= 0;
                end
                m_fsm[i]       <= FSM_REQ;
            end
            else begin
                case (m_fsm[i])
                    FSM_REQ: begin
                        if (avmm_req && avmm_mst_idx == i) begin
                            avmm_m_chipselect[i]   <= 1;
                            avmm_m_read      [i]   <=  avmm_rnw;
                            avmm_m_write     [i]   <= ~avmm_rnw;
                            avmm_m_addr      [i]   <=  avmm_address;
                            for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                avmm_m_wdata[i][b*8 +: 8]  <= avmm_wr_data[b*8 +: 8];
                            end
                            avmm_m_byteen[i] <= avmm_ben;
                            m_fsm[i] <= FSM_RESP;
                        end
                    end
                    FSM_RESP: begin
                        if(!avmm_m_waitrq[i]) begin

                            avmm_m_read      [i]   <= 0;
                            avmm_m_write     [i]   <= 0;
                            avmm_m_addr      [i]   <= 0;
                            avmm_m_byteen    [i]   <= 0;
                            for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                avmm_m_wdata[i][b] <= 0;
                            end
                        end
                        else if(avmm_m_waitrq[i]) begin
                            if(avmm_m_wrvalid[i]) begin
                                avmm_ack[i]      <= 1;
                                avmm_respons [i] <= avmm_m_response[i];
                            end
                            else if (avmm_m_rdvalid[i]) begin
                                avmm_ack[i]      <= 1;
                                avmm_respons[i]  <= 0;
                                for (int b = 0; b < DATA_WIDTH/8; b++) begin
                                    avmm_rd_data[i][b*8 +: 8] <= avmm_m_rdata[i][b*8 +: 8];
                                end
                            end
                        end
                        if (!avmm_req) begin
                            avmm_m_chipselect[i]<= 0;
                            avmm_ack    [i]     <= 0;
                            avmm_respons[i]     <= 0;
                            avmm_m_read [i]     <= 0;
                            avmm_m_write[i]     <= 0;
                            avmm_rd_data[i]     <= 0;
                            m_fsm       [i]     <= FSM_REQ;
                        end
                    end
                endcase
            end
        end
    end
    endgenerate
endmodule