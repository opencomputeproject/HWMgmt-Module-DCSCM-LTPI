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
// -- LTPI Phy Rx Implementation 
// -------------------------------------------------------------------

module ltpi_phy_rx 
import ltpi_pkg::*;
#(
    parameter CRC_REFLECTOR = 0
)
(
    input wire              clk,
    input wire              reset,
    input wire              LVDS_DDR,

    // Decode data output
    output LTPI_base_Frm_t  ltpi_frame_rx,
    output reg  [ 3:0]      rx_frm_offset,

    //LVDS output pins
    input wire              lvds_rx_data,
    input wire              lvds_rx_clk,

    output reg              frame_crc_err,
    output reg              aligned 

);

logic [ 7:0]    frame_rx_data;
//ALIGNED Lock state machine enum
typedef enum logic[1:0] {
    ST_INIT             = 2'd0,
    ST_CHECK_FRM        = 2'd1,
    ST_ALIGNED          = 2'd2
} state_t;

state_t state;

//signals for data recive 10b
logic [ 9:0]    data_rx_10b;
logic           data_rx_10b_dv;

//crc check result
logic [ 7:0]    crc_check_result;
logic           crc_check_clr;
logic           crc_check_en;
logic           dec_rd;

logic           rx_frame_bdry_found;

//deleyd 1 clock cycle signals
logic [ 3:0]    rx_frm_offset_d;

logic [ 7:0]    frame_rx_data_d;
logic           data_rx_10b_dv_d;
logic [ 7:0]    crc_check_result_d;

//there was Comma Symbol in stream
logic           rx_symbol_locked;

//signals to decine if frame is correct
logic           frame_crc_correct;

//count data from rx_symbol_locked 
logic [ 3:0]    read_data_cnt;

logic           sm_symbol_locked;

logic           reset_phy;

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        rx_frame_bdry_found <= 0;
    end
    else begin
        if(rx_symbol_locked ) begin
            if((frame_rx_data_d != K28_5 && frame_rx_data == K28_5) || (frame_rx_data_d != K28_6 && frame_rx_data == K28_6)) begin
                rx_frame_bdry_found <= 1;
            end
        end
        else begin
            rx_frame_bdry_found <= 0;
        end
    end
end

//assign crc_check_clr            = ((rx_frm_offset_d == 4'hf && rx_frm_offset == 4'hf));
//assign crc_check_clr            = ((rx_frm_offset_d == 4'h0 && rx_frm_offset == 4'h0));
assign crc_check_clr            = rx_frm_offset == 4'h0;
assign crc_check_en             = rx_frame_bdry_found && data_rx_10b_dv;

always_ff @(posedge clk) reset_phy <= reset;


//rx_frm_offset on rx side, 
//use to determine frame num in one payload package of each data received from link
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        rx_frm_offset               <=   4'd0;
    end
    else begin
        if(data_rx_10b_dv && rx_frame_bdry_found) begin
            if(rx_frm_offset == frame_length) begin
                rx_frm_offset       <= 4'd0;
            end
            else begin
                rx_frm_offset       <= rx_frm_offset + 1'b1;
            end
        end
        else if(!rx_frame_bdry_found) begin
            rx_frm_offset           <=   4'd0;
        end
    end
end 

//Delay signals
always @ (posedge clk or posedge reset) begin
    if (reset)begin
        frame_rx_data_d     <= '0;
        rx_frm_offset_d     <= '0;
        data_rx_10b_dv_d    <= '0;
    end
    else begin
        frame_rx_data_d     <= frame_rx_data;
        rx_frm_offset_d     <= rx_frm_offset;
        data_rx_10b_dv_d    <= data_rx_10b_dv;
    end
end

//Check if there is frame CRC error 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
       frame_crc_err            <= 1'b0;
    end
    else begin
        if(data_rx_10b_dv_d) begin
            if((rx_frm_offset == frame_length) && (crc_check_result != frame_rx_data)) begin
                frame_crc_err   <= 1'b1;
            end
            else if(rx_frm_offset != frame_length) begin
                frame_crc_err   <= 1'b0;
            end
        end
        else begin
            frame_crc_err   <= 1'b0;
        end
    end
end

//Assign Data to LTPI frame 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        ltpi_frame_rx                       <='0;
    end
    else begin
        case(rx_frm_offset) 
            4'd0: begin
                ltpi_frame_rx.comma_symbol  <= frame_rx_data;
            end
            4'd1: begin
                ltpi_frame_rx.frame_subtype <= frame_rx_data;
            end
            4'd2: begin
                ltpi_frame_rx.data[0]       <= frame_rx_data;
            end
            4'd3: begin
                ltpi_frame_rx.data[1]       <= frame_rx_data;
            end
            4'd4: begin
                ltpi_frame_rx.data[2]       <= frame_rx_data;
            end
            4'd5: begin
                ltpi_frame_rx.data[3]       <= frame_rx_data;
            end
            4'd6: begin
                ltpi_frame_rx.data[4]       <= frame_rx_data;
            end
            4'd7: begin
                ltpi_frame_rx.data[5]       <= frame_rx_data;
            end
            4'd8: begin
                ltpi_frame_rx.data[6]       <= frame_rx_data;
            end
             4'd9: begin
                ltpi_frame_rx.data[7]       <= frame_rx_data;
            end
            4'd10: begin
                ltpi_frame_rx.data[8]       <= frame_rx_data;
            end
            4'd11: begin
                ltpi_frame_rx.data[9]       <= frame_rx_data;
            end
             4'd12: begin
                ltpi_frame_rx.data[10]      <= frame_rx_data;
            end
            4'd13: begin
                ltpi_frame_rx.data[11]      <= frame_rx_data;
            end
            4'd14: begin
                ltpi_frame_rx.data[12]     <= frame_rx_data;
            end
        endcase
    end
end

// ALIGNED Lock state machine
//
// ST_INIT
// Enter not aligned state on reset
//
//ST_CHECK_FRM
//Exit ST_INIT state when commma symbol was found, check if cought frame is correct 
//enter aligned state
//
//ST_ALIGNED
//Exit ST_CHECK_FRM state and enter ST_ALIGNED when frame is correct. 
//Exit if PHY is reset.
always @ (posedge clk or posedge reset) begin
    if(reset) begin
       state                                <= ST_INIT;
       sm_symbol_locked                     <= 1'b0;
       frame_crc_correct                    <= 1'b1;
       aligned                              <= 1'b0;

    end
    else begin
        case (state)
            ST_INIT: begin
                aligned                     <= 1'b0;
                sm_symbol_locked            <= 1'b0;
                frame_crc_correct           <= 1'b1;
                if(rx_symbol_locked && rx_frm_offset_d == '0) begin
                    sm_symbol_locked        <= 1'b1;
                    state                   <= ST_CHECK_FRM;
                end
            end
            ST_CHECK_FRM: begin
                aligned <= 1'b0;
                if(rx_frame_bdry_found && rx_frm_offset_d == frame_length) begin
                    if(!frame_crc_err && ltpi_frame_rx.frame_subtype == 8'h0) begin //to make sure we will find only detect frame or advertise frame
                        state               <= ST_ALIGNED;
                        frame_crc_correct   <= '1 ;
                    end
                    else begin
                        state               <= ST_INIT;
                        sm_symbol_locked    <= 1'b0;
                        frame_crc_correct   <= '0;
                    end
                end
                else if(!rx_symbol_locked) begin
                    state <= ST_INIT;
                    sm_symbol_locked        <= 1'b0;
                    frame_crc_correct       <= '0;
                end
            end
            ST_ALIGNED: begin
                aligned                     <= 1'b1;
            end
            default: begin
                state                       <= ST_INIT;
            end //end case of default
        endcase
    end
end

generate 
    if(CRC_REFLECTOR == 0) begin : gen_crc8_no_ref
        crc8 crc8_check (
            .iClk               (clk                    ), 
            .iRst               (reset                  ),
            .iClr               (crc_check_clr          ),   //Clear    CRC-8
            .iEn                (crc_check_en           ),   //Clock    enable
            .ivByte             (frame_rx_data[7:0]     ),   //Inbound  byte
            .ovCrc8             (crc_check_result       )    //Outbound CRC-8 byte
        );
    end
    else begin: gen_crc8_ref
        logic [7:0] frame_rx_data_swap;
        logic [7:0] crc_check_result_swap;

        assign frame_rx_data_swap = {frame_rx_data[0], frame_rx_data[1], frame_rx_data[2],frame_rx_data[3],frame_rx_data[4],
                    frame_rx_data[5],frame_rx_data[6],frame_rx_data[7]};

        assign crc_check_result = {crc_check_result_swap[0], crc_check_result_swap[1], crc_check_result_swap[2],crc_check_result_swap[3],crc_check_result_swap[4],
                    crc_check_result_swap[5],crc_check_result_swap[6],crc_check_result_swap[7]};

        crc8 crc8_check (
            .iClk               (clk                        ), 
            .iRst               (reset                      ),
            .iClr               (crc_check_clr              ),   //Clear    CRC-8
            .iEn                (crc_check_en               ),   //Clock    enable
            .ivByte             (frame_rx_data_swap[7:0]    ),   //Inbound  byte
            .ovCrc8             (crc_check_result_swap      )    //Outbound CRC-8 byte
        );
    end
endgenerate

decoder_8b10b 
    #(
    .METHOD             (   0    ),
    .RDERR              (   0    ),
    .KERR               (   0    )
    )
decoder_8b10b (
    .clk                (clk                    ),
    .rst                (reset                  ),
    .din_ena            (data_rx_10b_dv         ),
    .din_dat            (data_rx_10b            ),
    .din_rd             (dec_rd                 ),
    .dout_val           (                       ),
    .dout_dat           (frame_rx_data          ),
    .dout_k             (                       ),
    .dout_kerr          (                       ),
    .dout_rderr         (                       ),
    .dout_rdcomb        (                       ),
    .dout_rdreg         (dec_rd                 )
    );

lvds_phy_rx #(
    .CYCLONE_V (0)
)
lvds_phy_rx (
    .clk                (clk                    ),
    .reset_phy          (reset_phy              ),
    .LVDS_DDR           (LVDS_DDR               ),

    // Parallel encoded data out
    .phy_rx_dv          (data_rx_10b_dv         ),
    .phy_rx_out         (data_rx_10b            ),

    // nodelink interface signals
    .lvds_rx_data       (lvds_rx_data           ),
    .lvds_rx_clk        (lvds_rx_clk            ),
    .sm_symbol_locked   (sm_symbol_locked       ),
    .rx_symbol_locked   (rx_symbol_locked       ),
    .frame_correct      (frame_crc_correct      )
);

endmodule