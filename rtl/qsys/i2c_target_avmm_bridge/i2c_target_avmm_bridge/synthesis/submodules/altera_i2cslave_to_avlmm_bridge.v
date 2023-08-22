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
module altera_i2cslave_to_avlmm_bridge #(
	parameter BYTE_ADDRESSING			= 2,
	parameter READ_ONLY					= 0,
	parameter ADDRESS_STEALING			= 0,
	parameter I2C_SLAVE_ADDRESS         = 10'h055
) (
    input           clk,
    input           rst_n,
    input           i2c_data_in,
    input           i2c_clk_in,
    output wire     i2c_data_oe,
    output wire     i2c_clk_oe,
	
	//Avalon master signal
	output wire [31:0]  address,
	output wire			read,
	output wire			write,
	output wire [31:0]  writedata,
	output wire [ 3:0]  byteenable,
	input		[31:0]	readdata,
	input				readdatavalid,
	input				waitrequest      

);

function integer clog2;
   input [31:0] value;  // Input variable
   for (clog2=0; value>0; clog2=clog2+1) 
   value = value>>'d1;
endfunction

/* parameters that meant for master mode only */
localparam  IC_DEFAULT_TAR_SLAVE_ADDR     = 10'h055;
localparam  IC_EMPTYFIFO_HOLD_MASTER_EN   = 0;
localparam  IC_SS_SCL_HIGH_COUNT          = 16'h0190;
localparam  IC_SS_SCL_LOW_COUNT           = 16'h01d6;
localparam  IC_FS_SCL_HIGH_COUNT          = 16'h003c;
localparam  IC_FS_SCL_LOW_COUNT           = 16'h0082;
localparam  IC_DEFAULT_SDA_HOLD           = 16'h0001;
localparam  IC_DEFAULT_SDA_SETUP          = 8'h64;	
localparam  IC_DEFAULT_ACK_GENERAL_CALL   = 1;		
localparam  IC_DEFAULT_FS_SPKLEN          = 8'h02;	

localparam  IC_MAX_SPEED_MODE             = 2;
localparam  IC_10BITADDR_SLAVE            = 0;				// always 7 bit address width
localparam  IC_RX_BUFFER_DEPTH            = 1;
localparam  IC_TX_BUFFER_DEPTH            = 1;
localparam  TXFIFO_DSIZE        = 8;
localparam  TXFIFO_DSIZE_MASK   = (11 - TXFIFO_DSIZE); 
localparam  TXFIFO_ASIZE        = 1;
localparam  RXFIFO_ASIZE        = 1;
localparam  TXFIFO_MASK         = (8 - TXFIFO_ASIZE);
localparam  RXFIFO_MASK         = (8 - RXFIFO_ASIZE);

wire [7:0]  readdatabyte;
wire		avl_readdatavalid_reg;

wire        ic_slv_en;
wire        ic_enable_enable;
wire        ic_con_ic_10bitaddr_slave;
wire [9:0]  ic_tar_ic_tar;
wire [9:0]  ic_sar_ic_sar;
wire [1:0]  ic_con_speed;
wire [15:0] ic_ss_scl_hcnt;
wire [15:0] ic_ss_scl_lcnt;
wire [15:0] ic_fs_scl_hcnt;
wire [15:0] ic_fs_scl_lcnt;
wire [7:0]  ic_dma_tdlr_dmatdl;
wire [7:0]  ic_dma_rdlr_dmardl;
wire [7:0]  ic_fs_spklen_spklen;
wire        ic_slv_data_nack;
wire [15:0] ic_sda_hold_ic_sda_hold;
wire        ic_ack_general_call;
wire [7:0]  ic_sda_setup;

wire        load_restart_scl_low_cnt;
wire        load_restart_setup_cnt;
wire        load_restart_hold_cnt;
wire        load_start_hold_cnt;
wire        load_stop_scl_low_cnt;
wire        load_stop_setup_cnt;
wire        load_tbuf_cnt;
wire        load_mst_tx_scl_high_cnt;
wire        load_mst_tx_scl_low_cnt;
wire        load_mst_rx_scl_high_cnt;
wire        load_mst_rx_scl_low_cnt;
wire        start_hold_cnt_en;
wire        restart_scl_low_cnt_en;
wire        restart_setup_cnt_en;
wire        restart_hold_cnt_en;
wire        stop_scl_low_cnt_en;
wire        stop_setup_cnt_en;
wire        tbuf_cnt_en;
wire        mst_tx_scl_high_cnt_en;
wire        mst_tx_scl_low_cnt_en;
wire        mst_rx_scl_high_cnt_en;
wire        mst_rx_scl_low_cnt_en;
wire        start_hold_cnt_complete;
wire        restart_scl_low_cnt_complete;
wire        restart_setup_cnt_complete;
wire        restart_hold_cnt_complete;
wire        stop_scl_low_cnt_complete;
wire        stop_setup_cnt_complete;
wire        tbuf_cnt_complete;
wire        mst_tx_scl_high_cnt_complete;
wire        mst_tx_scl_low_cnt_complete;
wire        mst_rx_scl_high_cnt_complete;
wire        mst_rx_scl_low_cnt_complete;

wire        scl_int;
wire        sda_int;
wire        scl_edge_hl;
wire        scl_edge_lh;
wire        ack_det;
wire        slv_arblost;
wire        arb_lost;
wire        start_det;
wire        start_det_dly;
wire        stop_det;
wire        bus_idle;
wire        mst_tx_en;
wire        mst_rx_en;
wire        mst_tx_chk_ack;
wire        mst_txdata_phase;
wire        slv_txdata_phase;
wire        mst_rxack_phase;
wire        slv_rxack_phase;
wire        mst_tx_shift_done;
wire        mst_rx_shift_done;
wire        slv_tx_chk_ack;
wire        load_tx_shifter;
wire        mst_load_tx_shifter;
wire        slv_load_tx_shifter;
wire        mstfsm_emptyfifo_hold_en;
wire        mstfsm_b2b_txshift;
wire        mstfsm_b2b_rxshift;
wire        slvfsm_b2b_rxshift;
wire        tx_byte_state;
wire        gcall_state;
wire        gen_sbyte_state;
wire        gen_10bit_addr1_state;
wire        gen_10bit_addr2_state;
wire        gen_7bit_addr_state;
wire        gen_stop_state;
wire        mstfsm_idle_state;
wire        slvfsm_idle_state;
wire [10:0] tx_shifter;
wire        tx_databuffer_empty;
wire        rx_databuffer_empty;
wire        txfifo_full;
wire        rxfifo_full;
wire        flush_tx_databuffer;
wire        pop_tx_fifo_state;
wire        pop_tx_fifo_state_dly;
wire        push_rx_fifo;
wire [7:0]  rx_shifter;
wire        mst_rx_shift_check_hold;
wire        mst_rx_ack_nack;
wire        sent_10bit_addr2;
wire        put_rx_databuffer;
wire        get_rx_databuffer;
wire        put_tx_databuffer;
wire        rx_loop_state;
wire        slv_rx_shift_done;
wire        slv_tx_shift_done;
wire        rx_addr_match;
wire        slv_rx_en;
wire        slv_tx_en;
wire        slv_1byte;
wire        slv_rx_10bit_2addr;
wire        slvfsm_b2b_txshift;
wire        set_rd_req;
wire        gen_call_rcvd;
wire        set_rx_done;
wire        slv_rx_data_lost;
wire        slv_disabled_bsy;
wire        gcall_addr_matched;
wire        mstfsm_sw_abort_det;
wire        ic_enable_hold_adv;
wire        clk_cnt_zero;

wire        start_sda_out;
wire        restart_sda_out;
wire        stop_sda_out;
wire        mst_tx_sda_out;
wire        mst_rx_sda_out;
wire        slv_tx_sda_out;
wire        slv_rx_sda_out;
wire        restart_scl_out;
wire        stop_scl_out;
wire        mst_tx_scl_out;
wire        mst_rx_scl_out;
wire        slv_tx_scl_out;


wire        ic_intr_mask_m_gen_call;
wire        ic_intr_mask_m_start_det;
wire        ic_intr_mask_m_stop_det;
wire        ic_intr_mask_m_activity;
wire        ic_intr_mask_m_rx_done;
wire        ic_intr_mask_m_tx_abrt;
wire        ic_intr_mask_m_rd_req;
wire        ic_intr_mask_m_tx_empty;
wire        ic_intr_mask_m_tx_over;
wire        ic_intr_mask_m_rx_full;
wire        ic_intr_mask_m_rx_over;
wire        ic_intr_mask_m_rx_under;

wire        ic_intr_stat_r_gen_call;
wire        ic_intr_stat_r_start_det;
wire        ic_intr_stat_r_stop_det;
wire        ic_intr_stat_r_activity;
wire        ic_intr_stat_r_rx_done;
wire        ic_intr_stat_r_tx_abrt;
wire        ic_intr_stat_r_rd_req;
wire        ic_intr_stat_r_tx_empty;
wire        ic_intr_stat_r_tx_over;
wire        ic_intr_stat_r_rx_full;
wire        ic_intr_stat_r_rx_over;
wire        ic_intr_stat_r_rx_under;
wire        ic_raw_intr_stat_gen_call;
wire        ic_raw_intr_stat_start_det;
wire        ic_raw_intr_stat_stop_det;
wire        ic_raw_intr_stat_activity;
wire        ic_raw_intr_stat_rx_done;
wire        ic_raw_intr_stat_tx_abrt;
wire        ic_raw_intr_stat_rd_req;
wire        ic_raw_intr_stat_tx_empty;
wire        ic_raw_intr_stat_tx_over;
wire        ic_raw_intr_stat_rx_full;
wire        ic_raw_intr_stat_rx_over;
wire        ic_raw_intr_stat_rx_under;
wire        raw_intr_stat;
wire        ic_status_slv_activity;
wire        ic_status_mst_activity;
wire        ic_status_rff;
wire        ic_status_rfne;
wire        ic_status_tfe;
wire        ic_status_tfnf;
wire        ic_status_activity;
wire        ic_enable_txabort;
wire        ic_enable_txabort_m;        // masked version of ic_enable_txabort 
                                        // don't allow tx abort during master receive ack/nack phase
wire        ic_enable_txabort_clear;

wire        ic_enable_m;                // masked version of ic_enable
                                        // don't allow fifo flush during master receive ack/nack phase,gen_start,gen_sbyte

wire        tx_databuffer_empty_m;             // masked version of tx_databuffer_empty
                                        // don't allow tx_databuffer_empty status to change during master receive ack/nack phase

wire [7:0]  ic_tx_abrt_source_tx_flush_cnt;
wire        ic_tx_abrt_source_abrt_user_abrt;
wire        ic_tx_abrt_source_abrt_slvrd_intx;
wire        ic_tx_abrt_source_abrt_slv_arblost;
wire        ic_tx_abrt_source_abrt_slvflush_tx_databuffer;
wire        ic_tx_abrt_source_arb_lost;
wire        ic_tx_abrt_source_abrt_master_dis;
wire        ic_tx_abrt_source_abrt_10b_rd_norstrt;
wire        ic_tx_abrt_source_abrt_sbyte_norstrt;
wire        ic_tx_abrt_source_abrt_hs_norstrt;
wire        ic_tx_abrt_source_abrt_sbyte_ackdet;
wire        ic_tx_abrt_source_abrt_hs_ackdet;
wire        ic_tx_abrt_source_abrt_gcall_read;
wire        ic_tx_abrt_source_abrt_gcall_noack;
wire        ic_tx_abrt_source_abrt_txdata_noack;
wire        ic_tx_abrt_source_abrt_10addr2_noack;
wire        ic_tx_abrt_source_abrt_10addr1_noack;
wire        ic_tx_abrt_source_abrt_7b_addr_noack;

wire        abrt_gcall_read;
wire        abrt_10b_rd_norstrt;
wire        abrt_sbyte_norstrt;
wire        abrt_sbyte_ackdet;
wire        abrt_gcall_noack;
wire        abrt_txdata_noack;
wire        abrt_10addr2_noack;
wire        abrt_10addr1_noack;
wire        abrt_7b_addr_noack;
wire        abrt_slvflush_tx_databuffer;
wire        abrt_slvrd_intx;
wire        clear_abrt_sbyte_norstrt;

wire        ic_con_ic_slave_disable;
wire        ic_con_master_mode;
wire        ic_con_ic_10bitaddr_master_write_access;
wire        ic_con_ic_10bitaddr_master_write_data;
wire        ic_con_speed_write_access;
wire [1:0]  ic_con_speed_write_data;
wire        ic_tar_write_access;
wire [31:0] ic_tar_write_data;
wire        ic_tar_write_allowed;
wire [31:0] ic_tar_read_data;
wire        ic_data_cmd_read_access;
wire        ic_data_cmd_write_access;
wire [31:0] ic_data_cmd_write_data;
wire [31:0] ic_data_cmd_read_data;
wire        ic_ss_scl_hcnt_write_access;
wire [15:0] ic_ss_scl_hcnt_write_data;
wire        ic_ss_scl_lcnt_write_access;
wire [15:0] ic_ss_scl_lcnt_write_data;
wire        ic_fs_scl_hcnt_write_access;
wire [15:0] ic_fs_scl_hcnt_write_data;
wire        ic_fs_scl_lcnt_write_access;
wire [15:0] ic_fs_scl_lcnt_write_data;
wire        ic_rx_tl_write_access;
wire [7:0]  ic_rx_tl_write_data;
wire        ic_tx_tl_write_access;
wire [7:0]  ic_tx_tl_write_data;
wire        ic_clr_intr_read_access;
wire        ic_clr_rx_under_read_access;
wire        ic_clr_rx_over_read_access;
wire        ic_clr_tx_over_read_access;
wire        ic_clr_rd_req_read_access;
wire        ic_clr_tx_abrt_read_access;
wire        ic_clr_rx_done_read_access;
wire        ic_clr_activity_read_access;
wire        ic_clr_stop_det_read_access;
wire        ic_clr_start_det_read_access;
wire        ic_clr_gen_call_read_access;
wire        ic_slv_data_nack_only_write_access;
wire        ic_slv_data_nack_only_write_data;
wire        ic_dma_cr_tdmae_write_access;
wire        ic_dma_cr_tdmae_write_data;
wire        ic_dma_cr_rdmae_write_access;
wire        ic_dma_cr_rdmae_write_data;
wire        ic_dma_tdlr_dmatdl_write_access;
wire [7:0]  ic_dma_tdlr_dmatdl_write_data;
wire        ic_dma_rdlr_dmardl_write_access;
wire [7:0]  ic_dma_rdlr_dmardl_write_data;
wire        ic_ack_general_call_ack_gen_call_reset_value;
wire        ic_fs_spklen_spklen_write_access;
wire [7:0]  ic_fs_spklen_spklen_write_data;

wire        ic_con_ic_slave_disable_reset_value;
wire        ic_con_ic_restart_en_reset_value;
wire        ic_con_ic_10bitaddr_slave_reset_value;
wire        ic_con_master_mode_reset_value;
wire [9:0]  ic_sar_ic_sar_reset_value;
wire [15:0] ic_sda_hold_ic_sda_hold_reset_value;
wire [7:0]  ic_sda_setup_sda_setup_reset_value;

wire [7:0]  ic_comp_param_1_tx_buffer_depth;
wire [7:0]  ic_comp_param_1_rx_buffer_depth;
wire        ic_comp_param_1_add_encoded_params;
wire        ic_comp_param_1_has_dma;
wire        ic_comp_param_1_intr_io;
wire        ic_comp_param_1_hc_count_values;
wire [1:0]  ic_comp_param_1_max_speed_mode;
wire [1:0]  ic_comp_param_1_apb_data_width;

wire [10:0]                 tx_fifo_data;
wire [TXFIFO_DSIZE-1:0]     tx_databuffer_data_out;
wire [TXFIFO_ASIZE:0]       txfifo_navail;

wire [8:0]                  rx_fifo_data_out;
wire [RXFIFO_ASIZE:0]       rxfifo_navail;

wire [TXFIFO_ASIZE:0]       ic_txflr_txflr;
wire [RXFIFO_ASIZE:0]       ic_rxflr_rxflr;

wire        slv_rx_sop;
wire [7:0]  wdata_rx_databuffer;
wire [7:0]  rdata_rx_databuffer;

generate
if (IC_EMPTYFIFO_HOLD_MASTER_EN == 1)
    assign tx_fifo_data = tx_databuffer_data_out[TXFIFO_DSIZE-1:0];
else
    assign tx_fifo_data = {{TXFIFO_DSIZE_MASK{1'b0}}, tx_databuffer_data_out[TXFIFO_DSIZE-1:0]};
endgenerate

assign ic_fs_spklen_spklen = IC_DEFAULT_FS_SPKLEN;

altr_i2c_spksupp i_altr_i2c_spksupp (
    .i2c_clk            (clk),
    .i2c_rst_n          (rst_n),
    .ic_fs_spklen       (ic_fs_spklen_spklen),
    .sda_in             (i2c_data_in),
    .scl_in             (i2c_clk_in),
    .sda_int            (sda_int),
    .scl_int            (scl_int)
);

altr_i2c_condt_det i_altr_i2c_condt_det (
    //inputs
    .i2c_clk            (clk),
    .i2c_rst_n          (rst_n),
    .sda_int            (sda_int),
    .scl_int            (scl_int),
    .mst_tx_chk_ack     (mst_tx_chk_ack),           // from tx shifter
    .slv_tx_chk_ack     (slv_tx_chk_ack),           // from tx shifter
    .i2c_data_oe        (i2c_data_oe),
    .mst_txdata_phase   (mst_txdata_phase),         // from tx shifter, indicates mst data/addr transmission (excludes ack/nack) 
    .mst_rxack_phase    (mst_rxack_phase),	    // from rx shifter, indicates mst ack/nack reception 
    .slv_txdata_phase   (slv_txdata_phase),         // from tx shifter, indicates slv data/addr transmission (excludes ack/nack) 
    .slv_rxack_phase    (slv_rxack_phase),	    // from rx shifter, indicates slv ack/nack reception 
    .tbuf_cnt_complete  (tbuf_cnt_complete),
    //outputs
    .scl_edge_hl        (scl_edge_hl),
    .scl_edge_lh        (scl_edge_lh),
    .sda_edge_hl        (),
    .sda_edge_lh        (),
    .start_det          (start_det),
    .start_det_dly      (start_det_dly),
    .stop_det           (stop_det),
    .ack_det            (ack_det),
    .slv_arblost        (slv_arblost),
    .arb_lost           (arb_lost),
    .bus_idle           (bus_idle),
    .load_tbuf_cnt      (load_tbuf_cnt),
    .tbuf_cnt_en        (tbuf_cnt_en)

);

assign put_tx_databuffer = avl_readdatavalid_reg;
assign flush_tx_databuffer = 1'b0;

altr_i2c_databuffer #(
   .DSIZE(8)
) tx_databuffer (
   .clk(clk),
   .rst_n(rst_n),
   .s_rst(flush_tx_databuffer),
   .put(put_tx_databuffer),
   .get(load_tx_shifter),
   .empty(tx_databuffer_empty),                                                      
   .wdata(readdatabyte),						
   .rdata(tx_databuffer_data_out)
);

altr_i2c_databuffer #(
   .DSIZE(8)
) rx_databuffer (
	.clk(clk),
   .rst_n(rst_n),
   .s_rst(flush_tx_databuffer), // both tx and rx fifo are flushed when tx_abort occurs
   .put(put_rx_databuffer),
   .get(get_rx_databuffer),                       
   .empty(rx_databuffer_empty),
   .wdata(wdata_rx_databuffer),
   .rdata(rdata_rx_databuffer)
);

assign put_rx_databuffer = push_rx_fifo;
assign get_rx_databuffer = ~rx_databuffer_empty;
assign wdata_rx_databuffer = rx_shifter;

assign ic_con_ic_10bitaddr_slave        = (IC_10BITADDR_SLAVE == 1) ? 1'b1 : 1'b0;
assign ic_slv_en = 1'b1;
assign ic_enable_enable = 1'b1;
assign ic_sda_setup = IC_DEFAULT_SDA_SETUP;
assign ic_tx_abrt_source_abrt_slvflush_tx_databuffer = 1'b0;

altr_i2c_slvfsm i_altr_i2c_slvfsm (
    //inputs
    .i2c_clk                    (clk),
    .i2c_rst_n                  (rst_n),
    .ic_slv_en                  (ic_slv_en),
    .ic_enable                  (ic_enable_enable),
    .start_det                  (start_det),
    .stop_det                   (stop_det),
    .ack_det                    (ack_det),
    .ic_10bit                   (ic_con_ic_10bitaddr_slave),
    .rx_shifter                 (rx_shifter),
    .slv_tx_shift_done          (slv_tx_shift_done),
    .slv_rx_shift_done          (slv_rx_shift_done),
    .txfifo_empty        		(tx_databuffer_empty),
    .rx_addr_match              (rx_addr_match),
    .ic_sda_setup               (ic_sda_setup),
    .pre_loaded_tx_fifo_rw      (tx_fifo_data[8]),
    .gcall_addr_matched         (gcall_addr_matched),
    .abrt_slvflush_txfifo_intr  (ic_tx_abrt_source_abrt_slvflush_tx_databuffer),
	
    //outputs
    .slv_1byte                  (slv_1byte),
    .slv_rx_10bit_2addr         (slv_rx_10bit_2addr),
    .slv_rx_en                  (slv_rx_en),
    .slv_tx_en                  (slv_tx_en),
    .slvfsm_b2b_txshift         (slvfsm_b2b_txshift),
    .slvfsm_b2b_rxshift         (slvfsm_b2b_rxshift),
    .slvfsm_idle_state          (slvfsm_idle_state),
    .load_tx_shifter            (slv_load_tx_shifter),
    .set_rd_req                 (set_rd_req),
    .abrt_slvflush_txfifo       (abrt_slvflush_tx_databuffer),
    .abrt_slvrd_intx            (abrt_slvrd_intx),
    .slv_tx_scl_out             (slv_tx_scl_out),
    .rx_loop_state              (rx_loop_state),
    .set_rx_done                (set_rx_done),
    .slv_rx_data_lost           (slv_rx_data_lost),
    .slv_disabled_bsy           (slv_disabled_bsy),
    .slv_rx_sop                 (slv_rx_sop)
);

altr_i2c_avl_mst_intf_gen #( 
	.BYTE_ADDRESSING			(BYTE_ADDRESSING),
	.READ_ONLY					(READ_ONLY),
	.ADDRESS_STEALING			(ADDRESS_STEALING)
) i_altr_i2c_avl_mst_intf_gen (
	//inputs
	.i2c_clk                    (clk),
    .i2c_rst_n                  (rst_n),
	.waitrequest				(waitrequest),
	.put_rx_databuffer			(put_rx_databuffer),
	.set_rd_req					(set_rd_req),
	.stop_det					(stop_det),
	.start_det                  (start_det),
	.rdata_rx_databuffer		(rdata_rx_databuffer),
	.avl_readdata				(readdata),
	.avl_readdatavalid			(readdatavalid),
	.slv_tx_chk_ack				(slv_tx_chk_ack),
	.ack_det					(ack_det),
	.rx_addr_match              (rx_addr_match),
	.lsb_rx_shifter             (rx_shifter[3:1]),
	
	//output
	.avl_read					(read),
	.avl_write					(write),
	.avl_writedata				(writedata),
	.avl_byteenable				(byteenable),
	.readdatabyte				(readdatabyte),
	.avl_readdatavalid_reg		(avl_readdatavalid_reg),
	.avl_addr					(address)
);
assign load_tx_shifter = slv_load_tx_shifter;
assign ic_tar_ic_tar = IC_DEFAULT_TAR_SLAVE_ADDR;
assign mst_tx_en = 1'b0;
assign mstfsm_emptyfifo_hold_en = 1'b0;
assign mstfsm_b2b_txshift = 1'b0;
assign tx_byte_state = 1'b0;
assign gcall_state = 1'b0;
assign gen_sbyte_state = 1'b0;
assign gen_10bit_addr1_state = 1'b0;
assign gen_10bit_addr2_state = 1'b0;
assign gen_7bit_addr_state = 1'b0;
assign sent_10bit_addr2 = 1'b0;

altr_i2c_txshifter i_altr_i2c_txshifter (
    //inputs
    .i2c_clk                        (clk),
    .i2c_rst_n                      (rst_n),
    .mst_tx_scl_high_cnt_complete   (mst_tx_scl_high_cnt_complete),
    .mst_tx_scl_low_cnt_complete    (mst_tx_scl_low_cnt_complete),
    .mst_tx_en                      (mst_tx_en),
    .slv_tx_en                      (slv_tx_en),                     // Slave fsm
    .scl_int                        (scl_int),
    .scl_edge_hl                    (scl_edge_hl),
    .mstfsm_emptyfifo_hold_en       (mstfsm_emptyfifo_hold_en), // Master fsm
    .mstfsm_b2b_txshift             (mstfsm_b2b_txshift),       // Master fsm
    .load_tx_shifter                (load_tx_shifter),
    .tx_fifo_data_in                (tx_fifo_data),                    // TX FIFO
    .ic_tar                         (ic_tar_ic_tar),
    .tx_byte_state                  (tx_byte_state),
    .gcall_state                    (gcall_state),
    .gen_sbyte_state                (gen_sbyte_state),
    .gen_10bit_addr1_state          (gen_10bit_addr1_state),
    .gen_10bit_addr2_state          (gen_10bit_addr2_state),
    .gen_7bit_addr_state            (gen_7bit_addr_state),
    .sent_10bit_addr2               (sent_10bit_addr2),
    .slvfsm_b2b_txshift             (slvfsm_b2b_txshift),
    .ic_slv_en                      (ic_slv_en),
    .start_det_dly                  (start_det_dly),

    //outputs
    .mst_tx_scl_high_cnt_en         (mst_tx_scl_high_cnt_en),
    .mst_tx_scl_low_cnt_en          (mst_tx_scl_low_cnt_en),
    .mst_tx_chk_ack                 (mst_tx_chk_ack),           // to ack detector
    .mst_tx_shift_done              (mst_tx_shift_done),
    .mst_tx_scl_out                 (mst_tx_scl_out),
    .mst_tx_sda_out                 (mst_tx_sda_out),
    .slv_tx_chk_ack                 (slv_tx_chk_ack),           // to ack detector
    .slv_tx_shift_done              (slv_tx_shift_done),                         // ??
    .slv_tx_sda_out                 (slv_tx_sda_out),
    .load_mst_tx_scl_high_cnt       (load_mst_tx_scl_high_cnt),
    .load_mst_tx_scl_low_cnt        (load_mst_tx_scl_low_cnt),
    .tx_shifter                     (tx_shifter),
    .mst_txdata_phase               (mst_txdata_phase),
    .slv_txdata_phase               (slv_txdata_phase)

);

assign ic_sar_ic_sar = I2C_SLAVE_ADDRESS;
assign ic_ack_general_call = (IC_DEFAULT_ACK_GENERAL_CALL == 1) ? 1'b1 : 1'b0;
assign ic_slv_data_nack = 1'b0;
assign mst_rx_en = 1'b0;
assign mstfsm_b2b_rxshift = 1'b0;
assign mst_rx_ack_nack = 1'b0;
assign mstfsm_sw_abort_det = 1'b0;
assign ic_enable_txabort = 1'b0;

altr_i2c_rxshifter #(
	.ADDRESS_STEALING	(ADDRESS_STEALING)
) i_altr_i2c_rxshifter (
    //inputs
    .i2c_clk                        (clk),
    .i2c_rst_n                      (rst_n),
    .mst_rx_scl_high_cnt_complete   (mst_rx_scl_high_cnt_complete),
    .mst_rx_scl_low_cnt_complete    (mst_rx_scl_low_cnt_complete),
    .mst_rx_en                      (mst_rx_en),
    .slv_rx_en                      (slv_rx_en),
    .scl_int                        (scl_int),
    .sda_int                        (sda_int),
    .mstfsm_emptyfifo_hold_en       (mstfsm_emptyfifo_hold_en),
    .scl_edge_hl                    (scl_edge_hl),	
    .scl_edge_lh                    (scl_edge_lh),
    .slv_1byte                      (slv_1byte),
    .slv_rx_10bit_2addr             (slv_rx_10bit_2addr),
    .ic_sar                         (ic_sar_ic_sar),
    .mstfsm_b2b_rxshift             (mstfsm_b2b_rxshift),
    .mst_rx_ack_nack                (mst_rx_ack_nack),
    .slvfsm_b2b_rxshift             (slvfsm_b2b_rxshift),
    .ic_slv_data_nack               (ic_slv_data_nack),
    .rx_loop_state                  (rx_loop_state),
    .ic_ack_general_call            (ic_ack_general_call),
    .ic_enable                      (ic_enable_enable),
    .ic_slv_en                      (ic_slv_en),
    .start_det_dly                  (start_det_dly),
    .ic_10bit                       (ic_con_ic_10bitaddr_slave),
    .mstfsm_sw_abort_det            (mstfsm_sw_abort_det),
    .ic_enable_txabort              (ic_enable_txabort),
    .txfifo_empty            		(tx_databuffer_empty),
    .clk_cnt_zero                   (clk_cnt_zero),
    //outputs
	.push_rx_fifo                   (push_rx_fifo),
    .mst_rx_scl_high_cnt_en         (mst_rx_scl_high_cnt_en),
    .mst_rx_scl_low_cnt_en          (mst_rx_scl_low_cnt_en),
    .mst_rx_shift_done              (mst_rx_shift_done),
    .mst_rx_shift_check_hold        (mst_rx_shift_check_hold),
    .mst_rx_scl_out                 (mst_rx_scl_out),
    .mst_rx_sda_out                 (mst_rx_sda_out),
    .load_mst_rx_scl_high_cnt       (load_mst_rx_scl_high_cnt),
    .load_mst_rx_scl_low_cnt        (load_mst_rx_scl_low_cnt),
    .rx_shifter                     (rx_shifter),
    .slv_rx_sda_out                 (slv_rx_sda_out),
    .slv_rx_shift_done              (slv_rx_shift_done),
    .rx_addr_match                  (rx_addr_match),
    .gen_call_rcvd                  (gen_call_rcvd),
    .mst_rxack_phase                (mst_rxack_phase),
    .slv_rxack_phase                (slv_rxack_phase),
    .gcall_addr_matched             (gcall_addr_matched),
    .ic_enable_txabort_m            (ic_enable_txabort_m),
    .ic_enable_hold_adv             (ic_enable_hold_adv),
    .txfifo_empty_m                 (tx_databuffer_empty_m)

);

assign ic_sda_hold_ic_sda_hold = IC_DEFAULT_SDA_HOLD;
assign start_sda_out = 1'b1;
assign restart_sda_out = 1'b1;
assign stop_sda_out = 1'b1;
assign restart_scl_out = 1'b1;
assign stop_scl_out = 1'b1;
assign pop_tx_fifo_state = 1'b0;
assign pop_tx_fifo_state_dly = 1'b0;

altr_i2c_txout i_altr_i2c_txout (
    //inputs
    .i2c_clk                (clk),
    .i2c_rst_n              (rst_n),
    .ic_sda_hold            (ic_sda_hold_ic_sda_hold),
    .start_sda_out          (start_sda_out),
    .restart_sda_out        (restart_sda_out),
    .stop_sda_out           (stop_sda_out),
    .mst_tx_sda_out         (mst_tx_sda_out),
    .mst_rx_sda_out         (mst_rx_sda_out),
    .slv_tx_sda_out         (slv_tx_sda_out),
    .slv_rx_sda_out         (slv_rx_sda_out),
    .restart_scl_out        (restart_scl_out),
    .stop_scl_out           (stop_scl_out),
    .mst_tx_scl_out         (mst_tx_scl_out),
    .mst_rx_scl_out         (mst_rx_scl_out),
    .slv_tx_scl_out         (slv_tx_scl_out),
    .pop_tx_fifo_state      (pop_tx_fifo_state),
    .pop_tx_fifo_state_dly  (pop_tx_fifo_state_dly),
    .ic_slv_en              (ic_slv_en),
    .scl_edge_hl            (scl_edge_hl),
    //outputs
    .i2c_data_oe            (i2c_data_oe),
    .i2c_clk_oe             (i2c_clk_oe)

);

assign ic_ss_scl_hcnt = IC_SS_SCL_HIGH_COUNT;
assign ic_ss_scl_lcnt = IC_SS_SCL_LOW_COUNT;
assign ic_fs_scl_hcnt = IC_FS_SCL_HIGH_COUNT;
assign ic_fs_scl_lcnt = IC_FS_SCL_LOW_COUNT;
assign ic_con_speed   = IC_MAX_SPEED_MODE;

assign load_restart_scl_low_cnt = 1'b0;
assign load_restart_setup_cnt = 1'b0;
assign load_restart_hold_cnt = 1'b0;
assign load_start_hold_cnt = 1'b0;
assign load_stop_scl_low_cnt = 1'b0;
assign load_stop_setup_cnt = 1'b0;
assign start_hold_cnt_en = 1'b0;
assign restart_scl_low_cnt_en = 1'b0;
assign restart_setup_cnt_en = 1'b0;
assign restart_hold_cnt_en = 1'b0;
assign stop_scl_low_cnt_en = 1'b0;
assign stop_setup_cnt_en = 1'b0;

altr_i2c_clk_cnt i_altr_i2c_clk_cnt (
    //inputs
    .i2c_clk                        (clk),
    .i2c_rst_n                      (rst_n),
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
    .ic_speed                       (ic_con_speed),
    .ic_ss_scl_hcnt                 (ic_ss_scl_hcnt),
    .ic_ss_scl_lcnt                 (ic_ss_scl_lcnt),
    .ic_fs_scl_hcnt                 (ic_fs_scl_hcnt),
    .ic_fs_scl_lcnt                 (ic_fs_scl_lcnt),
    .ic_fs_spklen                   (ic_fs_spklen_spklen),
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
    .mst_rx_scl_low_cnt_complete    (mst_rx_scl_low_cnt_complete),
    .clk_cnt_zero                   (clk_cnt_zero)

);





endmodule
