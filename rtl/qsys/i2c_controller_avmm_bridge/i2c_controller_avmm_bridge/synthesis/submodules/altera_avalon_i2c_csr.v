// (C) 2001-2021 Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files from any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License Subscription 
// Agreement, Intel FPGA IP License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Intel and sold by 
// Intel or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module altera_avalon_i2c_csr #(
    parameter USE_AV_ST = 0,
    parameter FIFO_DEPTH = 8,
    parameter FIFO_DEPTH_LOG2 = 3
) (
    input                       clk,
    input                       rst_n,
    input [3:0]                 addr,
    input                       read,
    input                       write,
    input [31:0]                writedata,
    input                       arb_lost,
    input                       txfifo_empty,
    input                       txfifo_full,
    input                       mstfsm_idle_state,
    input                       abrt_txdata_noack,
    input                       abrt_7b_addr_noack,
    input                       rxfifo_full,
    input                       rxfifo_empty,
    input [7:0]                 rx_fifo_data_out,
    input                       push_rxfifo,
    input [15:0]                snk_data,
    input                       snk_valid,
    input                       src_ready,
    input [FIFO_DEPTH_LOG2:0]   txfifo_navail,
    input [FIFO_DEPTH_LOG2:0]   rxfifo_navail,
    
    output [7:0]        src_data,
    output              src_valid,
    output              snk_ready,
    output [31:0]       readdata,
    output reg          intr,
    output              ctrl_en,
    output              flush_txfifo,
    output              write_txfifo,
    output              read_rxfifo,
    output [9:0]        txfifo_writedata,
    output [15:0]       scl_lcnt,
    output [15:0]       scl_hcnt,
    output reg [15:0]   sda_hold,
    output              speed_mode


);


reg [5:0]   ctrl;
reg [4:0]   iser;
reg         rx_over;
reg         arblost_det;
reg         nack_det;
reg [15:0]  scl_low;
reg [15:0]  scl_high;
reg [31:0]  readdata_dly2;

reg [FIFO_DEPTH_LOG2:0]    txfifo_thd;
reg [FIFO_DEPTH_LOG2:0]    rxfifo_thd;

reg         rx_data_rden_dly;
reg         rx_data_rden_dly2;
reg         ctrl_rden_dly;
reg         iser_rden_dly;
reg         isr_rden_dly;
reg         status_rden_dly;
reg         tfr_cmd_fifo_lvl_rden_dly;
reg         rx_data_fifo_lvl_rden_dly;
reg         scl_low_rden_dly;
reg         scl_high_rden_dly;
reg         sda_hold_rden_dly;

wire    tfr_cmd_addr;
wire    rx_data_addr;
wire    ctrl_addr;
wire    iser_addr;
wire    isr_addr;
wire    status_addr;
wire    tfr_cmd_fifo_lvl_addr;
wire    rx_data_fifo_lvl_addr;
wire    scl_low_addr;
wire    scl_high_addr;
wire    sda_hold_addr;

wire    tfr_cmd_wren;
wire    ctrl_wren;
wire    iser_wren;
wire    isr_wren;
wire    scl_low_wren;
wire    scl_high_wren;
wire    sda_hold_wren;

wire    rx_data_rden;
wire    ctrl_rden;
wire    iser_rden;
wire    isr_rden;
wire    status_rden;
wire    tfr_cmd_fifo_lvl_rden;
wire    rx_data_fifo_lvl_rden;
wire    scl_low_rden;
wire    scl_high_rden;
wire    sda_hold_rden;


wire [31:0] rx_data_internal;
wire [31:0] ctrl_internal;
wire [31:0] iser_internal;
wire [31:0] isr_internal;
wire [31:0] status_internal;
wire [31:0] tfr_cmd_fifo_lvl_internal;
wire [31:0] rx_data_fifo_lvl_internal;
wire [31:0] scl_low_internal;
wire [31:0] scl_high_internal;
wire [31:0] sda_hold_internal;

wire [31:0] readdata_nxt;
wire        intr_nxt;

wire [1:0]  tfr_cmd_fifo_thd;
wire [1:0]  rx_data_fifo_thd;
wire        tx_ready;
wire        tx_ready_mask;
wire        rx_ready;

wire        src_valid_mask;


localparam FIFO_DEPTH_LOG2_MASK = 32 - (FIFO_DEPTH_LOG2 + 1);

// Address Decode
assign tfr_cmd_addr             = (addr == 4'h0);
assign rx_data_addr             = (addr == 4'h1);
assign ctrl_addr                = (addr == 4'h2);
assign iser_addr                = (addr == 4'h3);
assign isr_addr                 = (addr == 4'h4);
assign status_addr              = (addr == 4'h5);
assign tfr_cmd_fifo_lvl_addr    = (addr == 4'h6);
assign rx_data_fifo_lvl_addr    = (addr == 4'h7);
assign scl_low_addr             = (addr == 4'h8);
assign scl_high_addr            = (addr == 4'h9);
assign sda_hold_addr            = (addr == 4'ha);

// Write access
assign tfr_cmd_wren     = tfr_cmd_addr & write;
assign ctrl_wren        = ctrl_addr & write;
assign iser_wren        = iser_addr & write;
assign isr_wren         = isr_addr & write;
assign scl_low_wren     = scl_low_addr & write;
assign scl_high_wren    = scl_high_addr & write;
assign sda_hold_wren    = sda_hold_addr & write;

// Read access
assign rx_data_rden             = rx_data_addr & read;
assign ctrl_rden                = ctrl_addr & read;
assign iser_rden                = iser_addr & read;
assign isr_rden                 = isr_addr & read;
assign status_rden              = status_addr & read;
assign tfr_cmd_fifo_lvl_rden    = tfr_cmd_fifo_lvl_addr & read;
assign rx_data_fifo_lvl_rden    = rx_data_fifo_lvl_addr & read;
assign scl_low_rden             = scl_low_addr & read;
assign scl_high_rden            = scl_high_addr & read;
assign sda_hold_rden            = sda_hold_addr & read;

// CTRL Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ctrl    <= 6'h0;
    else if (ctrl_wren) 
        ctrl    <= writedata[5:0];
end

// ISER Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        iser    <= 5'h0;
    else if (iser_wren) 
        iser    <= writedata[4:0];
end

// RX_OVER bit
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_over     <= 1'b0;
    else if (rxfifo_full & push_rxfifo) 
        rx_over     <= 1'b1;
    else if (isr_wren & writedata[4])
        rx_over     <= 1'b0;
end

// ARBLOST_DET bit
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        arblost_det     <= 1'b0;
    else if (arb_lost) 
        arblost_det     <= 1'b1;
    else if (isr_wren & writedata[3])
        arblost_det     <= 1'b0;
end

// NACK_DET bit
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        nack_det    <= 1'b0;
    else if (abrt_txdata_noack | abrt_7b_addr_noack) 
        nack_det    <= 1'b1;
    else if (isr_wren & writedata[2])
        nack_det    <= 1'b0;
end

// SCL_LOW Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        scl_low     <= 16'h1;
    else if (scl_low_wren) 
        scl_low     <= writedata[15:0];
end

// SCL_HIGH Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        scl_high    <= 16'h1;
    else if (scl_high_wren) 
        scl_high    <= writedata[15:0];
end

// SDA_HOLD Register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sda_hold    <= 16'h1;
    else if (sda_hold_wren) 
        sda_hold    <= writedata[15:0];
end

// rx_ready and tx_ready generation
assign rx_ready = rxfifo_navail >= rxfifo_thd;

always @* begin
    case (rx_data_fifo_thd)
    2'b00: rxfifo_thd = {{FIFO_DEPTH_LOG2{1'b0}}, 1'b1};
    2'b01: rxfifo_thd = FIFO_DEPTH[FIFO_DEPTH_LOG2+2:2];
    2'b10: rxfifo_thd = FIFO_DEPTH[FIFO_DEPTH_LOG2+1:1];
    2'b11: rxfifo_thd = FIFO_DEPTH[FIFO_DEPTH_LOG2:0];
    endcase
end

assign tx_ready = txfifo_navail <= txfifo_thd;
assign tx_ready_mask = tx_ready & ctrl_en;

always @* begin
    case (tfr_cmd_fifo_thd)
    2'b00: txfifo_thd = {(FIFO_DEPTH_LOG2+1){1'b0}};
    2'b01: txfifo_thd = FIFO_DEPTH[FIFO_DEPTH_LOG2+2:2];
    2'b10: txfifo_thd = FIFO_DEPTH[FIFO_DEPTH_LOG2+1:1];
    2'b11: txfifo_thd = (FIFO_DEPTH[FIFO_DEPTH_LOG2:0] - {{FIFO_DEPTH_LOG2{1'b0}}, 1'b1});
    endcase
end


// AVMM read data path
assign rx_data_internal             = {24'h0, rx_fifo_data_out};
assign ctrl_internal                = {26'h0, ctrl};
assign iser_internal                = {27'h0, iser};
//assign isr_internal                 = {27'h0, rx_over, arblost_det, nack_det, rxfifo_full, txfifo_empty};
assign isr_internal                 = {27'h0, rx_over, arblost_det, nack_det, rx_ready, tx_ready_mask};
assign status_internal              = {31'h0, ~mstfsm_idle_state};
assign tfr_cmd_fifo_lvl_internal    = {{FIFO_DEPTH_LOG2_MASK{1'b0}}, txfifo_navail};
assign rx_data_fifo_lvl_internal    = {{FIFO_DEPTH_LOG2_MASK{1'b0}}, rxfifo_navail};
assign scl_low_internal             = {16'h0, scl_low};
assign scl_high_internal            = {16'h0, scl_high};
assign sda_hold_internal            = {16'h0, sda_hold};

//assign readdata_nxt     =   (rx_data_internal & {32{rx_data_rden_dly}})                     |
assign readdata_nxt     =   (ctrl_internal & {32{ctrl_rden_dly}})                           |
                            (iser_internal & {32{iser_rden_dly}})                           |
                            (isr_internal & {32{isr_rden_dly}})                             |
                            (status_internal & {32{status_rden_dly}})                       |
                            (tfr_cmd_fifo_lvl_internal & {32{tfr_cmd_fifo_lvl_rden_dly}})   |
                            (rx_data_fifo_lvl_internal & {32{rx_data_fifo_lvl_rden_dly}})   |
                            (scl_low_internal & {32{scl_low_rden_dly}})                     |
                            (scl_high_internal & {32{scl_high_rden_dly}})                   |
                            (sda_hold_internal & {32{sda_hold_rden_dly}});



                            
// AVMM readdata register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        readdata_dly2 <= 32'h0;
    else
        readdata_dly2 <= readdata_nxt;
end

assign readdata = (rx_data_rden_dly2) ? rx_data_internal : readdata_dly2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_data_rden_dly            <= 1'b0;
        rx_data_rden_dly2           <= 1'b0;
        ctrl_rden_dly               <= 1'b0;
        iser_rden_dly               <= 1'b0;
        isr_rden_dly                <= 1'b0;
        status_rden_dly             <= 1'b0;
        tfr_cmd_fifo_lvl_rden_dly   <= 1'b0;
        rx_data_fifo_lvl_rden_dly   <= 1'b0;
        scl_low_rden_dly            <= 1'b0;
        scl_high_rden_dly           <= 1'b0;
        sda_hold_rden_dly           <= 1'b0;
    end
    else begin
        rx_data_rden_dly            <= rx_data_rden;
        rx_data_rden_dly2           <= rx_data_rden_dly;
        ctrl_rden_dly               <= ctrl_rden;
        iser_rden_dly               <= iser_rden;
        isr_rden_dly                <= isr_rden;
        status_rden_dly             <= status_rden;
        tfr_cmd_fifo_lvl_rden_dly   <= tfr_cmd_fifo_lvl_rden;
        rx_data_fifo_lvl_rden_dly   <= rx_data_fifo_lvl_rden;
        scl_low_rden_dly            <= scl_low_rden;
        scl_high_rden_dly           <= scl_high_rden;
        sda_hold_rden_dly           <= sda_hold_rden;
    end
end


assign intr_nxt =   (iser[4] & rx_over)         |
                    (iser[3] & arblost_det)     |
                    (iser[2] & nack_det)        |
                    (iser[1] & rx_ready)     |
                    (iser[0] & tx_ready_mask);

// Interrupt register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        intr <= 1'b0;
    else
        intr <= intr_nxt;
end



// output assignment
assign write_txfifo     = (USE_AV_ST == 1) ? (snk_valid & snk_ready) : tfr_cmd_wren;
assign read_rxfifo      = (USE_AV_ST == 1) ? (src_valid & src_ready) : rx_data_rden;
assign ctrl_en          = ctrl[0];
assign speed_mode       = ctrl[1];
assign tfr_cmd_fifo_thd = ctrl[3:2];
assign rx_data_fifo_thd = ctrl[5:4];
assign flush_txfifo     = arblost_det | nack_det;
assign scl_lcnt         = scl_low;
assign scl_hcnt         = scl_high;

assign src_data         = (USE_AV_ST == 1) ? rx_fifo_data_out : 8'h0;
//assign src_valid        = (USE_AV_ST == 1) ? ~rxfifo_empty : 1'b0; 
assign src_valid        = (USE_AV_ST == 1) ? src_valid_mask : 1'b0; 
assign snk_ready        = (USE_AV_ST == 1) ? ~txfifo_full : 1'b0;
assign txfifo_writedata = (USE_AV_ST == 1) ? snk_data[9:0] : writedata[9:0];

generate
if (USE_AV_ST == 1) begin
    
    reg [1:0] mask_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mask_cnt <= 2'h0;
        else if (src_valid & src_ready)
            mask_cnt <= 2'h2;
        else if (mask_cnt != 2'h0)
            mask_cnt <= mask_cnt - 1'b1;
        else
            mask_cnt <= mask_cnt;
    end

    assign src_valid_mask = (mask_cnt == 2'h0) & ~rxfifo_empty;

end
else begin

    assign src_valid_mask = 1'b0;

end
endgenerate

endmodule
