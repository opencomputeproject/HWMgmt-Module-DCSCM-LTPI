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

module altera_avalon_i2c #(
    parameter USE_AV_ST         = 0,    // parameter type -> integer
    parameter FIFO_DEPTH        = 8,    // parameter type -> integer
    parameter FIFO_DEPTH_LOG2   = 3     // parameter type -> integer
) (
    // clock and reset
    input           clk,
    input           rst_n,
    
    // AV MM Slave
    input [3:0]     addr,
    input           read,
    input           write,
    input [31:0]    writedata,
    output [31:0]   readdata,
    
    // AV ST Source
    output [7:0]    src_data,
    output          src_valid,
    input           src_ready,

    //AV ST Sink
    input [15:0]    snk_data,
    input           snk_valid,
    output          snk_ready,

    // Serial Interface
    output          scl_oe,
    output          sda_oe,
    input           scl_in,
    input           sda_in,

    // Interrupt
    output          intr

);

wire [7:0]  spike_len;
wire [15:0] scl_hcnt;
wire [15:0] scl_lcnt;
wire        speed_mode;
wire [15:0] sda_hold;

wire        ctrl_en;
wire [9:0]  tx_shifter;
wire        start_done;
wire        stop_done;
wire        restart_done;
wire        mst_tx_shift_done;
wire        mst_rx_shift_done;
wire        mst_rx_shift_check_hold;
wire        ack_det;
wire        bus_idle;
wire        arb_lost;
wire        txfifo_empty;
wire        txfifo_empty_nodly;
wire [9:0]  tx_fifo_data;
wire        flush_txfifo;
wire        mst_load_tx_shifter;
wire        mst_tx_en;
wire        mst_rx_en;
wire        start_en;
wire        restart_en;
wire        stop_en;
wire        mstfsm_emptyfifo_hold_en;
wire        mstfsm_b2b_rxshift;
wire        tx_byte_state;
wire        gen_7bit_addr_state;
wire        mstfsm_idle_state;
wire        pop_tx_fifo_state;
wire        pop_tx_fifo_state_dly;
wire        mst_rx_ack_nack;
wire        abrt_txdata_noack;
wire        abrt_7b_addr_noack;
wire        mst_rx_scl_high_cnt_complete;
wire        mst_rx_scl_low_cnt_complete;
wire        scl_int;
wire        sda_int;
wire        scl_edge_lh;
wire        push_rxfifo;
wire        mst_rx_scl_high_cnt_en;
wire        mst_rx_scl_low_cnt_en;
wire        mst_rx_scl_out;
wire        mst_rx_sda_out;
wire        load_mst_rx_scl_high_cnt;
wire        load_mst_rx_scl_low_cnt;
wire [7:0]  rx_shifter;
wire        mst_rxack_phase;
wire        mst_tx_scl_high_cnt_complete;
wire        mst_tx_scl_low_cnt_complete;
wire        mst_tx_scl_high_cnt_en;
wire        mst_tx_scl_low_cnt_en;
wire        mst_tx_chk_ack;
wire        mst_tx_scl_out;
wire        mst_tx_sda_out;
wire        load_mst_tx_scl_high_cnt;
wire        load_mst_tx_scl_low_cnt;
wire        mst_txdata_phase;
wire        tbuf_cnt_complete;
wire        load_tbuf_cnt;
wire        tbuf_cnt_en;
wire        start_hold_cnt_complete;
wire        restart_scl_low_cnt_complete;
wire        restart_setup_cnt_complete;
wire        restart_hold_cnt_complete;
wire        stop_scl_low_cnt_complete;
wire        stop_setup_cnt_complete;
wire        load_start_hold_cnt;
wire        start_hold_cnt_en;
wire        start_sda_out;
wire        load_restart_scl_low_cnt;
wire        restart_scl_low_cnt_en;
wire        load_restart_setup_cnt;
wire        restart_setup_cnt_en;
wire        load_restart_hold_cnt;
wire        restart_hold_cnt_en;
wire        restart_sda_out;
wire        restart_scl_out;
wire        load_stop_scl_low_cnt;
wire        stop_scl_low_cnt_en;
wire        load_stop_setup_cnt;
wire        stop_setup_cnt_en;
wire        stop_sda_out;
wire        stop_scl_out;
wire        put_txfifo;
wire        txfifo_full;
wire        put_rxfifo;
wire        get_rxfifo;
wire        rxfifo_full;
wire        rxfifo_empty;
wire [7:0]  rx_fifo_data_out;
wire        write_txfifo;
wire        read_rxfifo;
wire [9:0]  txfifo_writedata;

wire [FIFO_DEPTH_LOG2:0] txfifo_navail;    
wire [FIFO_DEPTH_LOG2:0] rxfifo_navail;    


//assign scl_hcnt     = SCL_HIGH_COUNT;
//assign scl_lcnt     = SCL_LOW_COUNT;
//assign sda_hold     = SDA_HOLD_COUNT;
//assign speed_mode   = (SPEED_MODE == 1) ? 1'b1 : 1'b0;
assign spike_len    = 8'h1;


altera_avalon_i2c_csr #(
    .USE_AV_ST          (USE_AV_ST),
    .FIFO_DEPTH         (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2    (FIFO_DEPTH_LOG2)
) u_csr (
    //inputs
    .clk                (clk),
    .rst_n              (rst_n),
    .addr               (addr),
    .read               (read),
    .write              (write),
    .writedata          (writedata),
    .arb_lost           (arb_lost),
    .txfifo_empty       (txfifo_empty),
    .txfifo_full        (txfifo_full),
    .mstfsm_idle_state  (mstfsm_idle_state),
    .abrt_txdata_noack  (abrt_txdata_noack),
    .abrt_7b_addr_noack (abrt_7b_addr_noack),
    .rxfifo_full        (rxfifo_full),
    .rxfifo_empty       (rxfifo_empty),
    .rx_fifo_data_out   (rx_fifo_data_out),
    .push_rxfifo        (push_rxfifo),
    .src_ready          (src_ready),
    .snk_data           (snk_data),
    .snk_valid          (snk_valid),
    .txfifo_navail      (txfifo_navail),
    .rxfifo_navail      (rxfifo_navail),
    //outputs
    .src_data           (src_data),
    .src_valid          (src_valid),
    .snk_ready          (snk_ready),
    .readdata           (readdata),
    .intr               (intr),
    .ctrl_en            (ctrl_en),
    .flush_txfifo       (flush_txfifo),
    .write_txfifo       (write_txfifo),
    .read_rxfifo        (read_rxfifo),
    .txfifo_writedata   (txfifo_writedata),
    .scl_lcnt           (scl_lcnt),
    .scl_hcnt           (scl_hcnt),
    .sda_hold           (sda_hold),
    .speed_mode         (speed_mode)

);

//altera_avalon_i2c_st u_st (
//    //inputs
//    .clk            (clk),
//    .rst_n          (rst_n),
//    .src_ready      (src_ready),
//    .snk_data       (snk_data),
//    .snk_valid      (snk_valid),
//    //outputs
//    .src_data       (src_data),
//    .src_valid      (src_valid),
//    .snk_ready      (snk_ready)
//
//);

altera_avalon_i2c_mstfsm u_mstfsm (
    //inputs
    .clk                        (clk),
    .rst_n                      (rst_n),
    .ctrl_en                    (ctrl_en),
    .tfr_cmd                    (tx_shifter),                   // TX shifter
    .start_done                 (start_done),                   // Start gen
    .stop_done                  (stop_done),                    // Stop gen
    .restart_done               (restart_done),                 // Restart gen
    .mst_tx_shift_done          (mst_tx_shift_done),            // TX shifter
    .mst_rx_shift_done          (mst_rx_shift_done),            // RX shifter
    .mst_rx_shift_check_hold    (mst_rx_shift_check_hold),      // TX shifter
    .ack_det                    (ack_det),
    .bus_idle                   (bus_idle),
    .arb_lost                   (arb_lost),
    .txfifo_empty               (txfifo_empty),
    .txfifo_empty_nodly         (txfifo_empty_nodly),
    .pre_loaded_restart_bit     (tx_fifo_data[9]),
    .flush_txfifo               (flush_txfifo),
    //outputs
    .load_tx_shifter            (mst_load_tx_shifter),          // TX shifter
    .mst_tx_en                  (mst_tx_en),                    // TX shifter
    .mst_rx_en                  (mst_rx_en),                    // RX shifter
    .start_en                   (start_en),                     // Start gen
    .restart_en                 (restart_en),                   // Restart gen
    .stop_en                    (stop_en),                      // Stop gen
    .mstfsm_emptyfifo_hold_en   (mstfsm_emptyfifo_hold_en),     // Master fsm
    .mstfsm_b2b_rxshift         (mstfsm_b2b_rxshift),
    .tx_byte_state              (tx_byte_state),
    .gen_7bit_addr_state        (gen_7bit_addr_state),
    .mstfsm_idle_state          (mstfsm_idle_state),
    .pop_tx_fifo_state          (pop_tx_fifo_state),
    .pop_tx_fifo_state_dly      (pop_tx_fifo_state_dly),
    .mst_rx_ack_nack            (mst_rx_ack_nack),
    .abrt_txdata_noack          (abrt_txdata_noack),
    .abrt_7b_addr_noack         (abrt_7b_addr_noack),
    .gen_stop_state             ()                              // Not used


);


altera_avalon_i2c_rxshifter u_rxshifter (
    //inputs
    .clk                            (clk),
    .rst_n                          (rst_n),
    .mst_rx_scl_high_cnt_complete   (mst_rx_scl_high_cnt_complete),
    .mst_rx_scl_low_cnt_complete    (mst_rx_scl_low_cnt_complete),
    .mst_rx_en                      (mst_rx_en),
    .scl_int                        (scl_int),
    .sda_int                        (sda_int),
    .mstfsm_emptyfifo_hold_en       (mstfsm_emptyfifo_hold_en),
    .scl_edge_lh                    (scl_edge_lh),
    .mstfsm_b2b_rxshift             (mstfsm_b2b_rxshift),
    .mst_rx_ack_nack                (mst_rx_ack_nack),
    //outputs
    .push_rx_fifo                   (push_rxfifo),
    .mst_rx_scl_high_cnt_en         (mst_rx_scl_high_cnt_en),
    .mst_rx_scl_low_cnt_en          (mst_rx_scl_low_cnt_en),
    .mst_rx_shift_done              (mst_rx_shift_done),
    .mst_rx_shift_check_hold        (mst_rx_shift_check_hold),
    .mst_rx_scl_out                 (mst_rx_scl_out),
    .mst_rx_sda_out                 (mst_rx_sda_out),
    .load_mst_rx_scl_high_cnt       (load_mst_rx_scl_high_cnt),
    .load_mst_rx_scl_low_cnt        (load_mst_rx_scl_low_cnt),
    .rx_shifter                     (rx_shifter),
    .mst_rxack_phase                (mst_rxack_phase)

);


altera_avalon_i2c_txshifter u_txshifter (
    //inputs
    .clk                            (clk),
    .rst_n                          (rst_n),
    .mst_tx_scl_high_cnt_complete   (mst_tx_scl_high_cnt_complete),
    .mst_tx_scl_low_cnt_complete    (mst_tx_scl_low_cnt_complete),
    .mst_tx_en                      (mst_tx_en),
    .scl_int                        (scl_int),
    .mstfsm_emptyfifo_hold_en       (mstfsm_emptyfifo_hold_en), // Master fsm
    .load_tx_shifter                (mst_load_tx_shifter),
    .tx_fifo_data_in                (tx_fifo_data),                    // TX FIFO
    .tx_byte_state                  (tx_byte_state),
    .gen_7bit_addr_state            (gen_7bit_addr_state),

    //outputs
    .mst_tx_scl_high_cnt_en         (mst_tx_scl_high_cnt_en),
    .mst_tx_scl_low_cnt_en          (mst_tx_scl_low_cnt_en),
    .mst_tx_chk_ack                 (mst_tx_chk_ack),           // to ack detector
    .mst_tx_shift_done              (mst_tx_shift_done),
    .mst_tx_scl_out                 (mst_tx_scl_out),
    .mst_tx_sda_out                 (mst_tx_sda_out),
    .load_mst_tx_scl_high_cnt       (load_mst_tx_scl_high_cnt),
    .load_mst_tx_scl_low_cnt        (load_mst_tx_scl_low_cnt),
    .tx_shifter                     (tx_shifter),
    .mst_txdata_phase               (mst_txdata_phase)

);


altera_avalon_i2c_spksupp u_spksupp (
    .clk                (clk),
    .rst_n              (rst_n),
    .spike_len          (spike_len),
    .sda_in             (sda_in),
    .scl_in             (scl_in),
    .sda_int            (sda_int),
    .scl_int            (scl_int)
);


altera_avalon_i2c_condt_det u_condt_det (
    //inputs
    .clk                (clk),
    .rst_n              (rst_n),
    .sda_int            (sda_int),
    .scl_int            (scl_int),
    .mst_tx_chk_ack     (mst_tx_chk_ack),           // from tx shifter
    .sda_oe             (sda_oe),
    .mst_txdata_phase   (mst_txdata_phase),         // from tx shifter, indicates mst data/addr transmission (excludes ack/nack) 
    .mst_rxack_phase    (mst_rxack_phase),	    // from rx shifter, indicates mst ack/nack reception 
    .tbuf_cnt_complete  (tbuf_cnt_complete),
    //outputs
    .scl_edge_hl        (),
    .scl_edge_lh        (scl_edge_lh),
    .sda_edge_hl        (),
    .sda_edge_lh        (),
    .start_det          (),
    .start_det_dly      (),
    .stop_det           (),
    .ack_det            (ack_det),
    .arb_lost           (arb_lost),
    .bus_idle           (bus_idle),
    .load_tbuf_cnt      (load_tbuf_cnt),
    .tbuf_cnt_en        (tbuf_cnt_en)

);


altera_avalon_i2c_condt_gen u_condt_gen (
    //inputs
    .clk                            (clk),
    .rst_n                          (rst_n),
    .start_hold_cnt_complete        (start_hold_cnt_complete),
    .start_en                       (start_en),
    .scl_int                        (scl_int),
    .restart_scl_low_cnt_complete   (restart_scl_low_cnt_complete),
    .restart_setup_cnt_complete     (restart_setup_cnt_complete),
    .restart_hold_cnt_complete      (restart_hold_cnt_complete),
    .restart_en                     (restart_en),
    .stop_scl_low_cnt_complete      (stop_scl_low_cnt_complete),
    .stop_setup_cnt_complete        (stop_setup_cnt_complete),
    .stop_en                        (stop_en),
    //outputs
    .load_start_hold_cnt            (load_start_hold_cnt),
    .start_hold_cnt_en              (start_hold_cnt_en),
    .start_done                     (start_done),
    .start_sda_out                  (start_sda_out),
    .load_restart_scl_low_cnt       (load_restart_scl_low_cnt),
    .restart_scl_low_cnt_en         (restart_scl_low_cnt_en),
    .load_restart_setup_cnt         (load_restart_setup_cnt),
    .restart_setup_cnt_en           (restart_setup_cnt_en),
    .load_restart_hold_cnt          (load_restart_hold_cnt),
    .restart_hold_cnt_en            (restart_hold_cnt_en),
    .restart_done                   (restart_done),
    .restart_sda_out                (restart_sda_out),
    .restart_scl_out                (restart_scl_out),
    .load_stop_scl_low_cnt          (load_stop_scl_low_cnt),
    .stop_scl_low_cnt_en            (stop_scl_low_cnt_en),
    .load_stop_setup_cnt            (load_stop_setup_cnt),
    .stop_setup_cnt_en              (stop_setup_cnt_en),
    .stop_done                      (stop_done),
    .stop_sda_out                   (stop_sda_out),
    .stop_scl_out                   (stop_scl_out)
);


altera_avalon_i2c_clk_cnt u_clk_cnt (
    //inputs
    .clk                            (clk),
    .rst_n                          (rst_n),
    .load_restart_scl_low_cnt       (load_restart_scl_low_cnt),
    .load_restart_setup_cnt         (load_restart_setup_cnt),
    .load_restart_hold_cnt          (load_restart_hold_cnt),
    .load_start_hold_cnt            (load_start_hold_cnt),
    .load_stop_scl_low_cnt          (load_stop_scl_low_cnt),
    .load_stop_setup_cnt            (load_stop_setup_cnt),
    .load_tbuf_cnt                  (load_tbuf_cnt),
    .load_mst_tx_scl_high_cnt       (load_mst_tx_scl_high_cnt),
    .load_mst_tx_scl_low_cnt        (load_mst_tx_scl_low_cnt),
    .load_mst_rx_scl_high_cnt       (load_mst_rx_scl_high_cnt),
    .load_mst_rx_scl_low_cnt        (load_mst_rx_scl_low_cnt),
    .start_hold_cnt_en              (start_hold_cnt_en),
    .restart_scl_low_cnt_en         (restart_scl_low_cnt_en),
    .restart_setup_cnt_en           (restart_setup_cnt_en),
    .restart_hold_cnt_en            (restart_hold_cnt_en),
    .stop_scl_low_cnt_en            (stop_scl_low_cnt_en),
    .stop_setup_cnt_en              (stop_setup_cnt_en),
    .tbuf_cnt_en                    (tbuf_cnt_en),
    .mst_tx_scl_high_cnt_en         (mst_tx_scl_high_cnt_en),
    .mst_tx_scl_low_cnt_en          (mst_tx_scl_low_cnt_en),
    .mst_rx_scl_high_cnt_en         (mst_rx_scl_high_cnt_en),
    .mst_rx_scl_low_cnt_en          (mst_rx_scl_low_cnt_en),
    .speed_mode                     (speed_mode),
    .scl_hcnt                       (scl_hcnt),
    .scl_lcnt                       (scl_lcnt),
    .spike_len                      (spike_len),
    //outputs
    .start_hold_cnt_complete        (start_hold_cnt_complete),
    .restart_scl_low_cnt_complete   (restart_scl_low_cnt_complete),
    .restart_setup_cnt_complete     (restart_setup_cnt_complete),
    .restart_hold_cnt_complete      (restart_hold_cnt_complete),
    .stop_scl_low_cnt_complete      (stop_scl_low_cnt_complete),
    .stop_setup_cnt_complete        (stop_setup_cnt_complete),
    .tbuf_cnt_complete              (tbuf_cnt_complete),
    .mst_tx_scl_high_cnt_complete   (mst_tx_scl_high_cnt_complete),
    .mst_tx_scl_low_cnt_complete    (mst_tx_scl_low_cnt_complete),
    .mst_rx_scl_high_cnt_complete   (mst_rx_scl_high_cnt_complete),
    .mst_rx_scl_low_cnt_complete    (mst_rx_scl_low_cnt_complete)

);


altera_avalon_i2c_txout u_txout (
    //inputs
    .clk                    (clk),
    .rst_n                  (rst_n),
    .sda_hold               (sda_hold),
    .start_sda_out          (start_sda_out),
    .restart_sda_out        (restart_sda_out),
    .stop_sda_out           (stop_sda_out),
    .mst_tx_sda_out         (mst_tx_sda_out),
    .mst_rx_sda_out         (mst_rx_sda_out),
    .restart_scl_out        (restart_scl_out),
    .stop_scl_out           (stop_scl_out),
    .mst_tx_scl_out         (mst_tx_scl_out),
    .mst_rx_scl_out         (mst_rx_scl_out),
    .pop_tx_fifo_state      (pop_tx_fifo_state),
    .pop_tx_fifo_state_dly  (pop_tx_fifo_state_dly),
    //outputs
    .sda_oe                 (sda_oe),
    .scl_oe                 (scl_oe)

);

assign put_rxfifo = push_rxfifo & ~rxfifo_full;
assign put_txfifo = write_txfifo & ~txfifo_full;
assign get_rxfifo = read_rxfifo & ~rxfifo_empty;

altera_avalon_i2c_fifo #(
    .DSIZE              (10),
    .FIFO_DEPTH         (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2    (FIFO_DEPTH_LOG2),
    .LATENCY            (2)
) u_txfifo (
    //inputs
    .clk        (clk),
    .rst_n      (rst_n),
    .put        (put_txfifo),
    .get        (mst_load_tx_shifter),
    .s_rst      (flush_txfifo), // when abort condition happens
    .wdata      (txfifo_writedata),
    //outputs
    .full       (txfifo_full),
    .empty      (txfifo_empty_nodly),
    .empty_dly  (txfifo_empty),
    .navail     (txfifo_navail),
    .rdata      (tx_fifo_data)
);


altera_avalon_i2c_fifo #(
    .DSIZE              (8),
    .FIFO_DEPTH         (FIFO_DEPTH),
    .FIFO_DEPTH_LOG2    (FIFO_DEPTH_LOG2),
    .LATENCY            (2)
) u_rxfifo (
    //inputs
    .clk        (clk),
    .rst_n      (rst_n),
    .put        (put_rxfifo),
    .get        (get_rxfifo),
    .s_rst      (flush_txfifo), // both tx and rx fifo are flushed when tx_abort occurs
    .wdata      (rx_shifter),
    //outputs
    .full       (rxfifo_full),
    .empty      (),
    .empty_dly  (rxfifo_empty),
    .navail     (rxfifo_navail),
    .rdata      (rx_fifo_data_out)
);




endmodule
