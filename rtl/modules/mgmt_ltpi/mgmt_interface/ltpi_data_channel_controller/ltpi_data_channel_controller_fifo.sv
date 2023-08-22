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
// -- Data channel controller FIFO
// -------------------------------------------------------------------

module ltpi_data_channel_controller_fifo #(
    parameter REQ_WIDTH     = 32,
    parameter REQ_DEPTH     = 32,
    parameter RESP_WIDTH    = 32,
    parameter RESP_DEPTH    = 32
)(
    input                           clk,
    input                           reset,
    input                           req_wr_en,
    input        [REQ_WIDTH-1:0]    req_wr_data,
    output logic                    req_wr_ack,
    input                           req_rd_en,
    output logic [REQ_WIDTH-1:0]    req_rd_data,
    output logic                    req_rd_ack,
    output logic                    req_empty,
    output logic                    req_full,
    input                           resp_wr_en,
    input        [RESP_WIDTH-1:0]   resp_wr_data,
    output logic                    resp_wr_ack,
    input                           resp_rd_en,
    output logic [RESP_WIDTH-1:0]   resp_rd_data,
    output logic                    resp_rd_ack,
    output logic                    resp_empty,
    output logic                    resp_full
);


    // ---------------------------------------------------------------------------------------------------------
    // ----- Memory instance
    // ---------------------------------------------------------------------------------------------------------

    localparam MEM_WIDTH = (REQ_WIDTH >= RESP_WIDTH) ? REQ_WIDTH : RESP_WIDTH;
    localparam MEM_DEPTH = REQ_DEPTH + RESP_DEPTH;

    logic                           mem_wr_en;
    logic [$clog2(MEM_DEPTH)-1:0]   mem_wr_address;
    logic [        MEM_WIDTH-1:0]   mem_wr_data;
    logic [$clog2(MEM_DEPTH)-1:0]   mem_rd_address;
    logic [        MEM_WIDTH-1:0]   mem_rd_data;

    logic [        MEM_WIDTH-1:0]   data_zeros;
    assign data_zeros = 0;

    altsyncram #(
        .operation_mode             ("DUAL_PORT"),
        .width_a                    (MEM_WIDTH),
        .width_b                    (MEM_WIDTH),
        .numwords_a                 (MEM_DEPTH),
        .numwords_b                 (MEM_DEPTH),
        .widthad_a                  ($clog2(MEM_DEPTH)),
        .widthad_b                  ($clog2(MEM_DEPTH)),
        .ram_block_type             ("M9K"),
        .address_reg_b              ("CLOCK0"),
        .indata_reg_b 	            ("CLOCK0"),
        .wrcontrol_wraddress_reg_b  ("CLOCK0")
    ) u0 (		
        .address_a      (mem_wr_address),
        .address_b      (mem_rd_address),
        .clock0         (clk),
        .data_a         (mem_wr_data),
        .data_b         (data_zeros),
        .wren_a         (mem_wr_en),
        .wren_b         (1'b0),
        .q_a            (),
        .q_b            (mem_rd_data),
        .aclr0          (1'b0),
        .aclr1          (1'b0),
        .addressstall_a (1'b0),
        .addressstall_b (1'b0),
        .byteena_a      (1'b1),
        .byteena_b      (1'b1),
        .clock1         (1'b1),
        .clocken0       (1'b1),
        .clocken1       (1'b1),
        .clocken2       (1'b1),
        .clocken3       (1'b1),
        .eccstatus      (),
        .rden_a         (1'b0),
        .rden_b         (1'b1)
    );

    localparam logic [$clog2(MEM_DEPTH)-1:0] REQ_BASE_ADDRESS       = 0;
    localparam logic [$clog2(MEM_DEPTH)-1:0] RESP_BASE_ADDRESS      = REQ_BASE_ADDRESS  + REQ_DEPTH;

    // ---------------------------------------------------------------------------------------------------------

    // ---------------------------------------------------------------------------------------------------------
    // ----- FIFO data count
    // ---------------------------------------------------------------------------------------------------------
    logic [$clog2(REQ_DEPTH)+1-1:0]     req_data_count;
    logic [$clog2(REQ_DEPTH)+1-1:0]     req_wr_data_count;
    logic [$clog2(REQ_DEPTH)+1-1:0]     req_rd_data_count;

    logic [$clog2(RESP_DEPTH)+1-1:0]    resp_data_count;
    logic [$clog2(RESP_DEPTH)+1-1:0]    resp_wr_data_count;
    logic [$clog2(RESP_DEPTH)+1-1:0]    resp_rd_data_count;


    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            req_data_count        <= 0;
            resp_data_count       <= 0;
        end
        else begin
            if (req_wr_data_count >= req_rd_data_count) begin
                req_data_count <= req_wr_data_count - req_rd_data_count;
            end
            else begin
                req_data_count <= (2 * REQ_DEPTH - req_rd_data_count) + req_wr_data_count;
            end    
            
            if (resp_wr_data_count >= resp_rd_data_count) begin
                resp_data_count <= resp_wr_data_count - resp_rd_data_count;
            end
            else begin
                resp_data_count <= (2 * RESP_DEPTH - resp_rd_data_count) + resp_wr_data_count;
            end 
        end
    end
    // ---------------------------------------------------------------------------------------------------------

    // ---------------------------------------------------------------------------------------------------------
    // ----- Write to FIFO
    // ---------------------------------------------------------------------------------------------------------
    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            req_wr_data_count   <= 0;
            resp_wr_data_count  <= 0;
            req_wr_ack          <= 0;
            resp_wr_ack         <= 0;
            mem_wr_en           <= 0;
            mem_wr_address      <= 0;
            mem_wr_data         <= 0;
        end
        else begin
            if (resp_wr_en && !resp_wr_ack) begin
                mem_wr_en       <= 1;
                mem_wr_data     <= resp_wr_data;
                mem_wr_address  <= RESP_BASE_ADDRESS + resp_wr_data_count[$clog2(RESP_DEPTH)-1:0];
                if (resp_wr_data_count == 2*RESP_DEPTH-1) begin
                    resp_wr_data_count  <= 0;
                end
                else begin
                    resp_wr_data_count  <= resp_wr_data_count + 1;
                end
                resp_wr_ack       <= 1;
            end
            else if (req_wr_en && !req_wr_ack) begin
                mem_wr_en       <= 1;
                mem_wr_data     <= req_wr_data;
                mem_wr_address  <= REQ_BASE_ADDRESS + req_wr_data_count[$clog2(REQ_DEPTH)-1:0];
                if (req_wr_data_count == 2*REQ_DEPTH-1) begin
                    req_wr_data_count  <= 0;
                end
                else begin
                    req_wr_data_count  <= req_wr_data_count + 1;
                end
                req_wr_ack        <= 1;
            end
            else begin
                mem_wr_en                   <= 0;
                mem_wr_data                 <= 0;
                mem_wr_address              <= 0;
            end

            if (!req_wr_en  && req_wr_ack)  req_wr_ack  <= 0;
            if (!resp_wr_en && resp_wr_ack) resp_wr_ack <= 0;
        end
    end
    // ---------------------------------------------------------------------------------------------------------

    // ---------------------------------------------------------------------------------------------------------
    // ----- Read from FIFO
    // ---------------------------------------------------------------------------------------------------------
    logic req_rd_ack_set;
    logic resp_rd_ack_set;

    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            mem_rd_address      <= 0;
            req_rd_data_count   <= 0;
            resp_rd_data_count  <= 0;
            req_rd_ack_set      <= 0;
            resp_rd_ack_set     <= 0;
        end
        else begin
            if (req_rd_en && !req_rd_ack_set) begin
                mem_rd_address <= REQ_BASE_ADDRESS + req_rd_data_count[$clog2(REQ_DEPTH)-1:0];
                if (req_rd_data_count == 2*REQ_DEPTH-1) begin
                    req_rd_data_count <= 0;
                end
                else begin
                    req_rd_data_count <= req_rd_data_count + 1;
                end
                req_rd_ack_set <= 1;
            end
            else if (resp_rd_en && !resp_rd_ack_set) begin
                mem_rd_address <= RESP_BASE_ADDRESS + resp_rd_data_count[$clog2(RESP_DEPTH)-1:0];
                if (resp_rd_data_count == 2*RESP_DEPTH-1) begin
                    resp_rd_data_count <= 0;
                end
                else begin
                    resp_rd_data_count <= resp_rd_data_count + 1;
                end
                resp_rd_ack_set <= 1;
            end

            if (!req_rd_en)       req_rd_ack_set <= 0;
            if (!resp_rd_en)      resp_rd_ack_set <= 0;
        end
    end

    logic [1:0] req_rd_ack_set_ff;
    logic [1:0] resp_rd_ack_set_ff;

    always_ff @ (posedge clk or posedge reset) begin
        if (reset) begin
            req_rd_data               <= 0;
            resp_rd_data              <= 0;
            req_rd_ack                <= 0;
            resp_rd_ack               <= 0;
            req_rd_ack_set_ff         <= 0;
            resp_rd_ack_set_ff        <= 0;
        end
        else begin
            if (!req_rd_ack) begin
                if (req_rd_ack_set_ff == 2'b01) begin
                    req_rd_data   <= mem_rd_data;
                    req_rd_ack    <= 1;
                end
            end
            else begin
                if (!req_rd_en) begin
                    req_rd_data   <= 0;
                    req_rd_ack    <= 0;
                end
            end
            
            if (!resp_rd_ack) begin
                if (resp_rd_ack_set_ff == 2'b01) begin
                    resp_rd_data   <= mem_rd_data;
                    resp_rd_ack    <= 1;
                end
            end
            else begin
                if (!resp_rd_en) begin
                    resp_rd_data   <= 0;
                    resp_rd_ack    <= 0;
                end
            end

            req_rd_ack_set_ff[0]          <= req_rd_ack_set;
            resp_rd_ack_set_ff[0]         <= resp_rd_ack_set;

            req_rd_ack_set_ff[1]          <= req_rd_ack_set_ff[0];
            resp_rd_ack_set_ff[1]         <= resp_rd_ack_set_ff[0];
        end
    end
    // ---------------------------------------------------------------------------------------------------------

    // ---------------------------------------------------------------------------------------------------------
    // ----- Empty & full
    // ---------------------------------------------------------------------------------------------------------
    assign req_empty          = (req_wr_data_count == req_rd_data_count) ? 1 : 0;
    assign req_full           = ((req_wr_data_count[$clog2(REQ_DEPTH)+1-1] != req_rd_data_count[$clog2(REQ_DEPTH)+1-1]) 
                              && (req_wr_data_count[$clog2(REQ_DEPTH)-1:0] == req_rd_data_count[$clog2(REQ_DEPTH)-1:0])) ? 1 : 0;

    assign resp_empty         = (resp_wr_data_count == resp_rd_data_count) ? 1 : 0;
    assign resp_full          = ((resp_wr_data_count[$clog2(RESP_DEPTH)+1-1] != resp_rd_data_count[$clog2(RESP_DEPTH)+1-1]) 
                              && (resp_wr_data_count[$clog2(RESP_DEPTH)-1:0] == resp_rd_data_count[$clog2(RESP_DEPTH)-1:0])) ? 1 : 0;
    // ---------------------------------------------------------------------------------------------------------
endmodule