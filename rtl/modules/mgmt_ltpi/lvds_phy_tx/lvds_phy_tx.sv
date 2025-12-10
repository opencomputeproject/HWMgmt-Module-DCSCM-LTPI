/////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 Intel Corporation
//
// The source code contained or described herein and all documents related
// to the source code ("Material") are owned by Intel Corporation or its
// suppliers or licensors. Title to the Material remains with Intel
// Corporation or its suppliers and licensors. The Material contains trade
// secrets and proprietary and confidential information of Intel or its
// suppliers and licensors. The Material is protected by worldwide copyright
// and trade secret laws and treaty provisions. No part of the Material may
// be used, copied, reproduced, modified, published, uploaded, posted,
// transmitted, distributed, or disclosed in any way without Intel
// prior express written permission.
// 
// No license under any patent, copyright, trade secret or other intellectual
// property right is granted to or conferred upon you by disclosure or 
// delivery of the Materials, either expressly, by implication, inducement,
// estoppel or otherwise. Any license under such intellectual property rights
// must be express and approved by Intel in writing.
//
// -------------------------------------------------------------------
// -- Author        : Katarzyna Krzewska , Reid McClain
// -- Date          : July 2022
// -- Project Name  : LTPI
// -- Description   :
// -- LVDS Phy Tx Implementation based on Nodlink project (author Reid McClain)
// -------------------------------------------------------------------

module lvds_phy_tx
#(
    parameter CYCLONE_V = 0
    //parameter FPGA = "CYCLONEV" //MAX10
)
(
    input wire clk,
    input wire clk_link,//clk_link
    input wire clk_link_90,//clk_link_90
    input wire reset,

    input wire LVDS_DDR,

    // encoder input
    input wire [ 9:0] phy_tx_in,
    input wire        phy_tx_dv,

    // LVDS interface signals
    output wire        lvds_tx_data,
    output wire        lvds_tx_clk,
    
    // optional signals
    output wire         txfifo_full
);

// TX Logic 
reg [ 3:0] clk_link_counter;
reg [ 1:0] txdata_sdr;
reg        read_req;
//reg        phy_tx_rfd;
//reg        tx_fifo_half_full;

wire [ 5:0] txfifo_words;
wire [ 5:0] rd_words;
wire        rdempty;
wire [ 9:0] read_data;

wire        clk_link_counter_tc;

assign clk_link_counter_tc = LVDS_DDR ? clk_link_counter == 4'h4 : clk_link_counter == 4'h9;

// Keep nominal level of fifo 8 or less to minimize avmm latency
// always @ (posedge clk)
//     phy_tx_rfd <= txfifo_words <= 8'd8;

// don't allow arbiter to grant access if fifo is more than half full
// always @ (posedge clk)
//     tx_fifo_half_full <= txfifo_words[4] == 1'b1;

lvds_cdc_fifo_m10 lvds_cdc_fifo_m10 (
    .aclr    ( reset       ),
    // Write side
    .wrclk   ( clk              ),
    .wrreq   ( phy_tx_dv        ),
    .data    ( phy_tx_in        ),
    .wrfull  ( txfifo_full      ),
    .wrusedw ( txfifo_words     ),
    // Read side
    .rdclk   ( clk_link         ),
    .rdreq   ( read_req         ),
    .q       ( read_data        ),
    .rdempty ( rdempty          ),
    .rdusedw ( rd_words         )
);

// Sync reset to faster clock
//sync_level_bus #(.WIDTH(1)) sync_rst (.clk (clk_link), .sync_in(reset), .sync_out(reset_link));
//always @ (posedge clk_link) reset_link <= reset;

// Link clock domain
// Counter in clk_link domain, synchronized such that count aligns with SDR link clock
always @ (posedge clk_link or posedge reset) begin
    if(reset) begin
        clk_link_counter <= '0;
    end
    else begin
        if (clk_link_counter_tc) begin
            clk_link_counter <= 4'h0;
        end
        else begin
            clk_link_counter <= clk_link_counter + 1'b1;
        end
    end
end

always @ (posedge clk_link or posedge reset) begin
    if(reset) begin
        read_req<='0;
    end
    else begin
        if(LVDS_DDR) begin
            read_req <= clk_link_counter == 4'h3;
        end
        else begin
            read_req <= clk_link_counter == 4'h8;
        end
    end
end

// Multiplex 10 bit data into 2 bit clk_link domain
always @ (posedge clk_link or posedge reset) begin
    if(reset) begin
        txdata_sdr <= 2'h0;
    end
    else begin
        if(LVDS_DDR) begin
            case (clk_link_counter)
                4'h0:    txdata_sdr <= {read_data[0],read_data[1]};
                4'h1:    txdata_sdr <= {read_data[2],read_data[3]};
                4'h2:    txdata_sdr <= {read_data[4],read_data[5]};
                4'h3:    txdata_sdr <= {read_data[6],read_data[7]};
                default: txdata_sdr <= {read_data[8],read_data[9]};
            endcase
        end
        else begin
            case (clk_link_counter)
                4'h0:    txdata_sdr <= {2{read_data[0]}};
                4'h1:    txdata_sdr <= {2{read_data[1]}};
                4'h2:    txdata_sdr <= {2{read_data[2]}};
                4'h3:    txdata_sdr <= {2{read_data[3]}};
                4'h4:    txdata_sdr <= {2{read_data[4]}};
                4'h5:    txdata_sdr <= {2{read_data[5]}};
                4'h6:    txdata_sdr <= {2{read_data[6]}};
                4'h7:    txdata_sdr <= {2{read_data[7]}};
                4'h8:    txdata_sdr <= {2{read_data[8]}};
                default: txdata_sdr <= {2{read_data[9]}};
            endcase
        end
    end
end

reg [1:0] txdata_sdr_1d;
// Pipeline txdata_sdr to ease timing
always @ (posedge clk_link)
    txdata_sdr_1d <= txdata_sdr;

reg [1:0] txclk_sdr_1d/* synthesis preserve */;
// Pipeline txdata_sdr to ease timing
always @ (posedge clk_link_90)
    txclk_sdr_1d <= 2'b10; 

// 200 MHz domain
generate
    if (CYCLONE_V == 1) 
    begin: gen_cyclone_v
        // LVDS data output implemented in DDIO output cell
        alt_ddio_out lvdstxdata_inst (
          .outclock   (clk_link         ),
          .datain_h   (txdata_sdr_1d[1] ),
          .datain_l   (txdata_sdr_1d[0] ),
          .dataout    (lvds_tx_data     )
        );
        // LVDS output clock implemented in DDIO output cell
        // Use 90 degree shifted clock so receiver has maximum setup/hold margins
        alt_ddio_out lvdstxclk_inst (
          .outclock   (clk_link_90     ),
          .datain_h   (txclk_sdr_1d[0] ),
          .datain_l   (txclk_sdr_1d[1] ),
          .dataout    (lvds_tx_clk     )
        );
    end
    else
    begin: gen_max_10
        // LVDS data output implemented in DDIO output cell
        gpio_ddr_out lvdstxdata_inst (
            .outclock   (clk_link                                   ),
            .din        ({txdata_sdr_1d[0], txdata_sdr_1d[1]}       ),
            .pad_out    (lvds_tx_data                               )
        );
    
        // LVDS output clock implemented in DDIO output cell
        // Use 90 degree shifted clock so receiver has maximum setup/hold margins
        gpio_ddr_out lvdstxclk_inst (
            .outclock   (clk_link_90  ),
            .din        (txclk_sdr_1d ),
            .pad_out    (lvds_tx_clk  )
        );
    end
endgenerate
endmodule