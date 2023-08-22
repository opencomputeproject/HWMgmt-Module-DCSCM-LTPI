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

module altera_avalon_i2c_clk_cnt (
    input           clk,
    input           rst_n,
    input           load_restart_scl_low_cnt,
    input           load_restart_setup_cnt,
    input           load_restart_hold_cnt,
    input           load_start_hold_cnt,
    input           load_stop_scl_low_cnt,
    input           load_stop_setup_cnt,
    input           load_tbuf_cnt,
    input           load_mst_tx_scl_high_cnt,
    input           load_mst_tx_scl_low_cnt,
    input           load_mst_rx_scl_high_cnt,
    input           load_mst_rx_scl_low_cnt,
    input           start_hold_cnt_en,
    input           restart_scl_low_cnt_en,
    input           restart_setup_cnt_en,
    input           restart_hold_cnt_en,
    input           stop_scl_low_cnt_en,
    input           stop_setup_cnt_en,
    input           tbuf_cnt_en,
    input           mst_tx_scl_high_cnt_en,
    input           mst_tx_scl_low_cnt_en,
    input           mst_rx_scl_high_cnt_en,
    input           mst_rx_scl_low_cnt_en,
    input           speed_mode,
    input [15:0]    scl_hcnt,
    input [15:0]    scl_lcnt,
    input [7:0]     spike_len,

    output reg      start_hold_cnt_complete,
    output reg      restart_scl_low_cnt_complete,
    output reg      restart_setup_cnt_complete,
    output reg      restart_hold_cnt_complete,
    output reg      stop_scl_low_cnt_complete,
    output reg      stop_setup_cnt_complete,
    output reg      tbuf_cnt_complete,
    output reg      mst_tx_scl_high_cnt_complete,
    output reg      mst_tx_scl_low_cnt_complete,
    output reg      mst_rx_scl_high_cnt_complete,
    output reg      mst_rx_scl_low_cnt_complete

);

reg [15:0]  clk_cnt;
reg [15:0]  clk_cnt_nxt;

wire        start_hold_cnt_complete_nxt;
wire        restart_scl_low_cnt_complete_nxt;
wire        restart_setup_cnt_complete_nxt;
wire        restart_hold_cnt_complete_nxt;
wire        stop_scl_low_cnt_complete_nxt;
wire        stop_setup_cnt_complete_nxt;
wire        tbuf_cnt_complete_nxt;
wire        mst_tx_scl_high_cnt_complete_nxt;
wire        mst_tx_scl_low_cnt_complete_nxt;
wire        mst_rx_scl_high_cnt_complete_nxt;
wire        mst_rx_scl_low_cnt_complete_nxt;
wire        load_cnt;
wire        load_high;
wire        load_low;
wire        ss_mode;
wire        fs_mode;
wire [15:0] scl_hcnt_int;
wire [15:0] scl_lcnt_int;
wire [15:0] load_cnt_val;
wire        cnt_en;
wire        decr_cnt;
wire [15:0] spike_len_int;
wire        clk_cnt_notzero;

assign spike_len_int    = {8'h0, spike_len};
assign load_cnt         = load_high | load_low;

assign load_high    = load_start_hold_cnt                   |
                      (load_restart_setup_cnt & fs_mode)    |
                      load_restart_hold_cnt                 |
                      load_stop_setup_cnt                   |
                      load_mst_tx_scl_high_cnt              |
                      load_mst_rx_scl_high_cnt;

assign load_low     = load_restart_scl_low_cnt              |
                      (load_restart_setup_cnt & ss_mode)    |
                      load_stop_scl_low_cnt                 |
                      load_tbuf_cnt                         |
                      load_mst_tx_scl_low_cnt               |
                      load_mst_rx_scl_low_cnt;

assign ss_mode      = speed_mode == 1'b0;
assign fs_mode      = speed_mode == 1'b1;
assign load_cnt_val = load_high ? scl_hcnt_int : scl_lcnt_int;

assign scl_hcnt_int = 
    (load_mst_tx_scl_high_cnt | load_mst_rx_scl_high_cnt) ? (scl_hcnt - 16'h7) :
    (load_start_hold_cnt | load_restart_hold_cnt) ? (scl_hcnt + spike_len_int) :
        scl_hcnt;
                            
assign scl_lcnt_int = 
    (load_mst_tx_scl_low_cnt | load_mst_rx_scl_low_cnt) ?
        (scl_lcnt - 16'h3) :
        scl_lcnt;

assign cnt_en       =   start_hold_cnt_en       |
                        restart_scl_low_cnt_en  |
                        restart_setup_cnt_en    |
                        restart_hold_cnt_en     |
                        stop_scl_low_cnt_en     |
                        stop_setup_cnt_en       |
                        tbuf_cnt_en             |
                        mst_tx_scl_high_cnt_en  |
                        mst_tx_scl_low_cnt_en   |
                        mst_rx_scl_high_cnt_en  |
                        mst_rx_scl_low_cnt_en;

assign decr_cnt         = cnt_en & clk_cnt_notzero;
assign clk_cnt_notzero  = | clk_cnt;

//assign decr_cnt     = cnt_en & (clk_cnt != 16'h0);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        clk_cnt <= 16'hffff;
    else
        clk_cnt <= clk_cnt_nxt;
end

always @* begin
    if (load_cnt)
        clk_cnt_nxt = load_cnt_val;
    else if (decr_cnt)
        clk_cnt_nxt = clk_cnt - 16'h1;
    else
        clk_cnt_nxt = clk_cnt;
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        start_hold_cnt_complete         <= 1'b0;
        restart_scl_low_cnt_complete    <= 1'b0;
        restart_setup_cnt_complete      <= 1'b0;
        restart_hold_cnt_complete       <= 1'b0;
        stop_scl_low_cnt_complete       <= 1'b0;
        stop_setup_cnt_complete         <= 1'b0;
        tbuf_cnt_complete               <= 1'b0;
        mst_tx_scl_high_cnt_complete    <= 1'b0;
        mst_tx_scl_low_cnt_complete     <= 1'b0;
        mst_rx_scl_high_cnt_complete    <= 1'b0;
        mst_rx_scl_low_cnt_complete     <= 1'b0;
    end
    else begin
        start_hold_cnt_complete         <= start_hold_cnt_complete_nxt;
        restart_scl_low_cnt_complete    <= restart_scl_low_cnt_complete_nxt;
        restart_setup_cnt_complete      <= restart_setup_cnt_complete_nxt;
        restart_hold_cnt_complete       <= restart_hold_cnt_complete_nxt;
        stop_scl_low_cnt_complete       <= stop_scl_low_cnt_complete_nxt;
        stop_setup_cnt_complete         <= stop_setup_cnt_complete_nxt;
        tbuf_cnt_complete               <= tbuf_cnt_complete_nxt;
        mst_tx_scl_high_cnt_complete    <= mst_tx_scl_high_cnt_complete_nxt;
        mst_tx_scl_low_cnt_complete     <= mst_tx_scl_low_cnt_complete_nxt;
        mst_rx_scl_high_cnt_complete    <= mst_rx_scl_high_cnt_complete_nxt;
        mst_rx_scl_low_cnt_complete     <= mst_rx_scl_low_cnt_complete_nxt;
    end
end

assign start_hold_cnt_complete_nxt      = ~clk_cnt_notzero & start_hold_cnt_en;
assign restart_scl_low_cnt_complete_nxt = ~clk_cnt_notzero & restart_scl_low_cnt_en;
assign restart_setup_cnt_complete_nxt   = ~clk_cnt_notzero & restart_setup_cnt_en;
assign restart_hold_cnt_complete_nxt    = ~clk_cnt_notzero & restart_hold_cnt_en;
assign stop_scl_low_cnt_complete_nxt    = ~clk_cnt_notzero & stop_scl_low_cnt_en;
assign stop_setup_cnt_complete_nxt      = ~clk_cnt_notzero & stop_setup_cnt_en;
assign tbuf_cnt_complete_nxt            = ~clk_cnt_notzero & tbuf_cnt_en;
assign mst_tx_scl_high_cnt_complete_nxt = ~clk_cnt_notzero & mst_tx_scl_high_cnt_en;
assign mst_tx_scl_low_cnt_complete_nxt  = ~clk_cnt_notzero & mst_tx_scl_low_cnt_en;
assign mst_rx_scl_high_cnt_complete_nxt = ~clk_cnt_notzero & mst_rx_scl_high_cnt_en;
assign mst_rx_scl_low_cnt_complete_nxt  = ~clk_cnt_notzero & mst_rx_scl_low_cnt_en;


endmodule

