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
// -- LTPI Phy Tx Implementation 
// -------------------------------------------------------------------

module ltpi_phy_tx
import ltpi_pkg::*;
(
    input wire                  clk,
    input wire                  clk_link,
    input wire                  clk_link_90,
    input wire                  reset,
    input wire                  LVDS_DDR,
    //LVDS output pins
    output wire                 lvds_tx_data,
    output wire                 lvds_tx_clk,

    input LTPI_base_Frm_t       ltpi_frame_tx,

    //CSR package 
    input link_speed_t          link_speed,
    output logic [ 3:0]         tx_frm_offset

);

logic   [ 9:0]  data_tx_10b;
logic           wr_req;
logic           wr_req_d;
logic           wr_req_d2;
logic           phy_tx_dv;

logic   [ 3:0]  tx_frm_offset_d;
logic   [ 3:0]  tx_frm_offset_d2;
logic   [ 7:0]  frame_tx_data;

wire    [ 7:0]  crc_data;
logic   [ 5:0]  counter_offset;
logic   [ 5:0]  counter_offset_max;

//Encoder K character enable logic
wire            enc_kin_ena;
wire            enc_ein_ena;
wire            enc_rd;

//CRC generation
wire            crc_gen_Clr;

logic           LVDS_DDR_ff;
link_speed_t    link_speed_ff;
logic           reset_phy;

assign enc_kin_ena      = ((tx_frm_offset_d2 == 4'd0) ? 1'b1 : 1'b0);
assign enc_ein_ena      = wr_req_d2;
assign crc_gen_Clr      = ((tx_frm_offset_d == 4'hf) ? 1'b1 : 1'b0); 

always @ (posedge clk) LVDS_DDR_ff      <= LVDS_DDR;
always @ (posedge clk) link_speed_ff    <= link_speed;
always @ (posedge clk) reset_phy      <= reset;

// Find counter max value depends on frequency which is used
// counter_offset_max - time for one data change - txframeOfsset , 
// it depends on which frequency LTPI is working
always @ (posedge clk) begin
    if (reset)begin
        // default outputs
        counter_offset_max  <= '0;
    end
    else begin
        case (link_speed_ff)
            base_freq_x1: begin
                if(LVDS_DDR_ff) begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_1_DDR; //frame size 3.2us*60MHz/16
                end
                else begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_1_SDR;
                end
            end
            base_freq_x2: begin
                if(LVDS_DDR_ff) begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_2_DDR; //frame size 1.6us*60MHz/16
                end
                else begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_2_SDR;
                end
            end
            base_freq_x3: begin
                if(LVDS_DDR_ff) begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_3_DDR; //frame size 1.067us*60MHz/16
                end
                else begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_3_SDR;
                end
            end
            base_freq_x4: begin
                if(LVDS_DDR_ff) begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_4_DDR; //frame size 0.8us*60MHz/16
                end
                else begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_4_SDR;
                end
            end
            base_freq_x6: begin
                if(LVDS_DDR_ff) begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_6_DDR; //frame size 0.533us*60MHz/16
                end
                else begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_6_SDR;
                end
            end
            base_freq_x8: begin
                if(LVDS_DDR_ff) begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_8_DDR; //frame size 0.4us*60MHz/16
                end
                else begin
                    counter_offset_max <= TX_OFFSET_CNT_FREQ_8_SDR;
                end
            end
            default: begin
                counter_offset_max       <= 6'd24;
            end
        endcase
    end
end

//Create tx_frm_offset
always @ (posedge clk) begin
    if (reset)begin
        // default outputs
        wr_req              <= '0;
        tx_frm_offset       <= '1;
        counter_offset      <= '0;
    end
    else begin
        if(counter_offset == (counter_offset_max - 6'd1) ) begin
            tx_frm_offset   <= tx_frm_offset + 4'd1;
            wr_req          <= 1'b1;
            counter_offset  <= '0;
        end
        else begin
            counter_offset  <= counter_offset  + 6'd1;
            wr_req          <= 1'b0;
        end
    end
end

//Delay signals
always @ (posedge clk) begin
    if (reset)begin
        tx_frm_offset_d     <= '0;
        wr_req_d            <= '0;
        phy_tx_dv           <= '0;
    end
    else begin
        tx_frm_offset_d     <= tx_frm_offset;
        tx_frm_offset_d2    <= tx_frm_offset_d; 
        wr_req_d            <= wr_req;
        wr_req_d2           <= wr_req_d;
        phy_tx_dv           <= wr_req_d2;
    end
end

//Data from ltpi_frame_tx are put into FIFO in each chage of tx_frame_offset
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        frame_tx_data        <= '0; 
    end
    else begin
        case(tx_frm_offset)
            4'd0: begin
                frame_tx_data <= ltpi_frame_tx.comma_symbol;
            end
            4'd1: begin
                frame_tx_data <= ltpi_frame_tx.frame_subtype;
            end
            4'd2: begin
                frame_tx_data <= ltpi_frame_tx.data[0];
            end
            4'd3: begin
                frame_tx_data <= ltpi_frame_tx.data[1];
            end
            4'd4: begin
                frame_tx_data <= ltpi_frame_tx.data[2];
            end
            4'd5: begin
                frame_tx_data <= ltpi_frame_tx.data[3];
            end
            4'd6: begin
                frame_tx_data <= ltpi_frame_tx.data[4];
            end
            4'd7: begin
                frame_tx_data <= ltpi_frame_tx.data[5];
            end
            4'd8: begin
                frame_tx_data <= ltpi_frame_tx.data[6];
            end
             4'd9: begin
                frame_tx_data <= ltpi_frame_tx.data[7];
            end
            4'd10: begin
                frame_tx_data <= ltpi_frame_tx.data[8];
            end
            4'd11: begin
                frame_tx_data <= ltpi_frame_tx.data[9];
            end
             4'd12: begin
                frame_tx_data <= ltpi_frame_tx.data[10];
            end
            4'd13: begin
                frame_tx_data <= ltpi_frame_tx.data[11];
            end
            4'd14: begin
                 frame_tx_data <= ltpi_frame_tx.data[12];
            end
            4'd15: begin
                frame_tx_data <= crc_data;//CRC
            end
            default: begin
                frame_tx_data <= '0;
            end //end case of default
        endcase
    end 
end

encoder_8b10b 
#(
    .METHOD         (   0    )
)
encoder_8b10b (
    .clk            (clk                   ),
    .rst            (reset                 ),
    .kin_ena        (enc_kin_ena           ),
    .ein_ena        (enc_ein_ena           ),
    .ein_dat        (frame_tx_data         ),
    .ein_rd         (enc_rd                ),
    .eout_val       (                      ),
    .eout_dat       (data_tx_10b           ),
    .eout_rdcomb    (                      ),
    .eout_rdreg     (enc_rd                )
);

crc8 crc8_gen 
(
    .iClk           (clk                   ),
    .iRst           (reset                 ),
    .iClr           (crc_gen_Clr           ),   //Clear    CRC-8
    .iEn            (wr_req_d2             ),   //Clock    enable
    .ivByte         (frame_tx_data         ),   //Inbound  byte
    .ovCrc8         (crc_data              )    //Outbound CRC-8 byte
);

lvds_phy_tx #(
    .CYCLONE_V (0)
)
lvds_phy_tx(
    .clk            (clk                   ),
    .clk_link       (clk_link              ),
    .clk_link_90    (clk_link_90           ),
    .reset          (reset_phy             ),

    .LVDS_DDR       (LVDS_DDR_ff           ),
    // encoder input
    .phy_tx_in      (data_tx_10b           ),
    .phy_tx_dv      (phy_tx_dv             ),

    // LVDS interface signals
    .lvds_tx_data   (lvds_tx_data          ),
    .lvds_tx_clk    (lvds_tx_clk           ),

    // optional signals
    .txfifo_full        ()
);

endmodule