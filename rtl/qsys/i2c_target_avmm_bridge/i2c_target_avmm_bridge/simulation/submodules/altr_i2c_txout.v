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


`timescale 1 ps / 1 ps
module altr_i2c_txout (
    input           i2c_clk,
    input           i2c_rst_n,
    input [15:0]    ic_sda_hold,
    input           start_sda_out,
    input           restart_sda_out,
    input           stop_sda_out,
    input           mst_tx_sda_out,
    input           mst_rx_sda_out,
    input           slv_tx_sda_out,
    input           slv_rx_sda_out,
    input           restart_scl_out,
    input           stop_scl_out,
    input           mst_tx_scl_out,
    input           mst_rx_scl_out,
    input           slv_tx_scl_out,
    input           pop_tx_fifo_state,
    input           pop_tx_fifo_state_dly,
    input           ic_slv_en,
    input           scl_edge_hl,

    output          i2c_data_oe,
    output          i2c_clk_oe

);

reg         data_oe;
reg         clk_oe;
reg         clk_oe_nxt_dly;
reg [15:0]  sda_hold_cnt;
reg [15:0]  sda_hold_cnt_nxt;

wire        data_oe_nxt;
wire        clk_oe_nxt;
wire        clk_oe_nxt_hl;
wire        load_sda_hold_cnt;
wire        sda_hold_en;

assign data_oe_nxt  =   ~start_sda_out   |
                        ~restart_sda_out |
                        ~stop_sda_out    |
                        ~mst_tx_sda_out  |
                        ~mst_rx_sda_out |
                        ~slv_tx_sda_out |
                        ~slv_rx_sda_out;

assign clk_oe_nxt   =   ~restart_scl_out |
                        ~stop_scl_out    |
                        ~mst_tx_scl_out  |
                        ~mst_rx_scl_out |
                        ~slv_tx_scl_out;

assign clk_oe_nxt_hl        = clk_oe_nxt & ~clk_oe_nxt_dly;
assign load_sda_hold_cnt    = ic_slv_en ? scl_edge_hl : clk_oe_nxt_hl;
assign sda_hold_en          = (sda_hold_cnt_nxt != 16'h0) | pop_tx_fifo_state | pop_tx_fifo_state_dly;

assign i2c_data_oe  = data_oe;
assign i2c_clk_oe   = clk_oe;

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        clk_oe_nxt_dly <= 1'b0;
    else
        clk_oe_nxt_dly <= clk_oe_nxt;
end

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        data_oe <= 1'b0;
    else if (sda_hold_en)
        data_oe <= data_oe;
    else
        data_oe <= data_oe_nxt;
end

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        clk_oe <= 1'b0;
    else if (pop_tx_fifo_state_dly)
        clk_oe <= clk_oe;
    else
        clk_oe <= clk_oe_nxt;
end

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        sda_hold_cnt <= 16'h0;
    else
        sda_hold_cnt <= sda_hold_cnt_nxt;
end

always @* begin
    if (load_sda_hold_cnt)
        sda_hold_cnt_nxt = (ic_sda_hold - 16'h1);
    else if (sda_hold_cnt != 16'h0)
        sda_hold_cnt_nxt = sda_hold_cnt - 16'h1;
    else
        sda_hold_cnt_nxt = sda_hold_cnt;
end

endmodule
