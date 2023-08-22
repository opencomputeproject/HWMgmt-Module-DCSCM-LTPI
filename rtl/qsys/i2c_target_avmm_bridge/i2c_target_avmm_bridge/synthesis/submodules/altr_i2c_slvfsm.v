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
module altr_i2c_slvfsm (
    input           i2c_clk,
    input           i2c_rst_n,
    input           ic_slv_en,
    input	    ic_enable,
    input	    start_det,
    input	    stop_det,
    input	    ack_det,
    input	    ic_10bit,
    input  [7:0]    rx_shifter,
    input	    slv_tx_shift_done,
    input	    slv_rx_shift_done,
    input	    txfifo_empty,
    input	    rx_addr_match,
    input [7:0]     ic_sda_setup,
    input	    pre_loaded_tx_fifo_rw,		// this bit is referring to 'pre loaded data_cmd[8] / tx_fifo_data[8] at top level' 
    input           gcall_addr_matched,
    input           abrt_slvflush_txfifo_intr,

    output reg	    slv_1byte,			// to rx shifter
    output reg	    slv_rx_10bit_2addr,		// to rx shifter
    output reg	    slv_rx_en,
    output reg	    slv_tx_en,
    output reg      slvfsm_b2b_txshift,
    output reg      slvfsm_b2b_rxshift,
    output          slvfsm_idle_state,
    output	    load_tx_shifter,
    output	    set_rd_req,
    output	    abrt_slvflush_txfifo,
    output	    abrt_slvrd_intx,
    output reg	    slv_tx_scl_out,
    output reg      rx_loop_state,
    output          set_rx_done,
    output reg      slv_rx_data_lost,
    output reg      slv_disabled_bsy,
    output reg      slv_rx_sop


);

reg [2:0]   slv_fsm_state;
reg [2:0]   slv_fsm_state_nxt;
reg	    slv_idle_state;
reg         slv_idle_state_nxt;
reg	    slv_1byte_nxt;
reg	    slv_rx_10bit_2addr_nxt;
reg	    wait_data_state_nxt;
reg	    wait_data_state;
reg         rx_loop_state_nxt;
reg	    tx_loop_state;
reg	    tx_loop_state_nxt;
reg         slv_tx_scl_out_nxt;
reg	    slv_tx_en_nxt;
reg	    slv_rx_en_nxt;
reg [7:0]   sda_setup_cnt;
reg [7:0]   sda_setup_cnt_nxt;
reg         read_10b;
reg         read_10b_nxt;
reg         slv_rx_data_lost_nxt;
reg         slv_disabled_bsy_nxt;
reg         arc_wait_data_tx_loop_flp;
reg         slv_rx_sop_nxt;

wire        set_slv_rx_data_lost;
wire        set_slv_disabled_bsy;
wire        set_addressed_10b;
wire        clear_addressed_10b;
wire	    arc_wait_data_tx_loop;
wire	    sda_setup_scl_out;
wire        slvfsm_b2b_txshift_pre_flp;
wire        slvfsm_b2b_rxshift_pre_flp;
wire        set_slv_rx_sop;
wire        clear_slv_rx_sop;


parameter [2:0]		IDLE		= 3'b000;
parameter [2:0]		RX_1BYTE	= 3'b001;
parameter [2:0]		RX_10BIT_2_ADDR = 3'b010;
parameter [2:0]		RX_LOOP		= 3'b011;
parameter [2:0]		WAIT_DATA	= 3'b100;
parameter [2:0]		TX_LOOP		= 3'b101;


always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        slv_fsm_state <= IDLE;
    else
        slv_fsm_state <= slv_fsm_state_nxt;
end


always @* begin
    case (slv_fsm_state)
        IDLE: begin
            if (ic_enable & ic_slv_en & start_det)
                slv_fsm_state_nxt = RX_1BYTE;
            else
                slv_fsm_state_nxt = IDLE;
        end

	RX_1BYTE:  begin
            if (stop_det | (slv_rx_shift_done & (~rx_addr_match | (rx_addr_match & rx_shifter[0] & ic_10bit & ~read_10b))))
                slv_fsm_state_nxt = IDLE;
	    else if (slv_rx_shift_done & rx_addr_match & rx_shifter[0] & (~ic_10bit | (ic_10bit & read_10b)))	//mst read
		slv_fsm_state_nxt = WAIT_DATA;
            else if (slv_rx_shift_done & rx_addr_match & ~rx_shifter[0] & (~ic_10bit | gcall_addr_matched))
                slv_fsm_state_nxt = RX_LOOP;
	    else if (slv_rx_shift_done & rx_addr_match & ~rx_shifter[0] & ic_10bit)  // 1st byte add of 10-bit addressing always write
		slv_fsm_state_nxt = RX_10BIT_2_ADDR;
	    else  
		slv_fsm_state_nxt = RX_1BYTE;
	end

	RX_10BIT_2_ADDR: begin
	    if (stop_det | (slv_rx_shift_done & ~rx_addr_match))
		slv_fsm_state_nxt = IDLE;
	    else if (slv_rx_shift_done & rx_addr_match)
		slv_fsm_state_nxt = RX_LOOP;
	    else
		slv_fsm_state_nxt = RX_10BIT_2_ADDR;
	end

	RX_LOOP: begin
	    if (stop_det | (slv_rx_shift_done & ~ic_enable))
		slv_fsm_state_nxt = IDLE;
	    else if (start_det)
		slv_fsm_state_nxt = RX_1BYTE;
	    else
		slv_fsm_state_nxt = RX_LOOP;
	end

        WAIT_DATA: begin
	    if (stop_det)
		slv_fsm_state_nxt = IDLE;
	    else if (~txfifo_empty & ~pre_loaded_tx_fifo_rw & ~abrt_slvflush_txfifo_intr)
		slv_fsm_state_nxt = TX_LOOP;
	    else
		slv_fsm_state_nxt = WAIT_DATA;
	end

	TX_LOOP: begin
	     if (stop_det | (slv_tx_shift_done & ~ack_det))
		slv_fsm_state_nxt = IDLE;
	     else if (slv_tx_shift_done & ack_det & txfifo_empty)
		slv_fsm_state_nxt = WAIT_DATA;
	     else
		slv_fsm_state_nxt = TX_LOOP;
	end	

        default: begin
            slv_fsm_state_nxt = 3'bxxx;
        end

    endcase
end
 

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
        slv_tx_en                   <= 1'b0;
        slv_rx_en                   <= 1'b0;
	slv_idle_state		    <= 1'b1;
	slv_1byte		    <= 1'b0;
	slv_rx_10bit_2addr	    <= 1'b0;
	wait_data_state		    <= 1'b0;
	rx_loop_state		    <= 1'b0;
	tx_loop_state		    <= 1'b0;
	slv_tx_scl_out    <= 1'b1;

    end
    else begin
	slv_tx_en		    <= slv_tx_en_nxt;
        slv_rx_en		    <= slv_rx_en_nxt;
	slv_idle_state		    <= slv_idle_state_nxt;
	slv_1byte		    <= slv_1byte_nxt;
	slv_rx_10bit_2addr	    <= slv_rx_10bit_2addr_nxt;
	wait_data_state		    <= wait_data_state_nxt;
	rx_loop_state		    <= rx_loop_state_nxt;
	tx_loop_state		    <= tx_loop_state_nxt;
	slv_tx_scl_out              <= slv_tx_scl_out_nxt;
    end
end


always @* begin
    slv_tx_en_nxt                = 1'b0;
    slv_rx_en_nxt		 = 1'b0;
    slv_idle_state_nxt		 = 1'b0;
    slv_1byte_nxt		 = 1'b0;
    slv_rx_10bit_2addr_nxt	 = 1'b0;
    wait_data_state_nxt		 = 1'b0;
    rx_loop_state_nxt		 = 1'b0;
    tx_loop_state_nxt		 = 1'b0;
    slv_tx_scl_out_nxt           = 1'b1;

    case (slv_fsm_state_nxt)
	IDLE: begin
	    slv_idle_state_nxt = 1'b1;
	end

	RX_1BYTE: begin
	    slv_rx_en_nxt	= 1'b1;
	    slv_1byte_nxt	= 1'b1;
	end 

	RX_10BIT_2_ADDR: begin
	    slv_rx_en_nxt	    = 1'b1;
	    slv_rx_10bit_2addr_nxt  = 1'b1;
	end

	RX_LOOP: begin
	    rx_loop_state_nxt	= 1'b1;
	    slv_rx_en_nxt	= 1'b1;
	end

	WAIT_DATA: begin
	    wait_data_state_nxt	= 1'b1;
	    slv_tx_scl_out_nxt  = 1'b0;	// to hold SCL low
	end

	TX_LOOP: begin
	    tx_loop_state_nxt	= 1'b1;
	    slv_tx_en_nxt	= 1'b1;
	    slv_tx_scl_out_nxt  = sda_setup_scl_out;
	end	    

        default: begin
	    slv_tx_en_nxt  		 = 1'bx;
	    slv_rx_en_nxt  		 = 1'bx;
	    slv_idle_state_nxt		 = 1'bx;
	    slv_1byte_nxt		 = 1'bx;
	    slv_rx_10bit_2addr_nxt	 = 1'bx;
	    wait_data_state_nxt		 = 1'bx;
	    rx_loop_state_nxt		 = 1'bx;
            tx_loop_state_nxt		 = 1'bx;
	    slv_tx_scl_out_nxt           = 1'bx;
	end

    endcase
end


assign set_rd_req = (slv_1byte & wait_data_state_nxt) | (tx_loop_state & wait_data_state_nxt);	// to interrupt block ic_raw_intr_stat_rd_req  
assign abrt_slvflush_txfifo = (slv_1byte & wait_data_state_nxt & ~txfifo_empty) | (tx_loop_state & slv_idle_state_nxt & ~txfifo_empty);	// to interrupt block ic_raw_intr_stat_tx_abrt and ic_tx_abrt_source_abrt_slvflush_txfifo
assign abrt_slvrd_intx	= wait_data_state & ~txfifo_empty & pre_loaded_tx_fifo_rw;


assign arc_wait_data_tx_loop        = wait_data_state & tx_loop_state_nxt;
assign load_tx_shifter              = arc_wait_data_tx_loop_flp | slvfsm_b2b_txshift;
assign slvfsm_b2b_txshift_pre_flp   = tx_loop_state & slv_tx_shift_done & ack_det & ~txfifo_empty & ~stop_det;
assign slvfsm_b2b_rxshift_pre_flp   = (rx_loop_state & slv_rx_shift_done & ic_enable & ~stop_det & ~start_det) | 
                                        (slv_1byte & slv_rx_10bit_2addr_nxt) |
                                        (slv_1byte & rx_loop_state_nxt) |
                                        (slv_rx_10bit_2addr & rx_loop_state_nxt);

assign slvfsm_idle_state        = slv_idle_state;
assign set_rx_done              = tx_loop_state & slv_tx_shift_done & ~ack_det; 


assign set_addressed_10b    = slv_rx_10bit_2addr & rx_loop_state_nxt;
assign clear_addressed_10b  = (slv_1byte & ~slv_1byte_nxt) | slv_idle_state;

// Register arc_wait_data_tx_loop to improve timing
always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        arc_wait_data_tx_loop_flp    <= 1'b0;
    else
        arc_wait_data_tx_loop_flp    <= arc_wait_data_tx_loop;
end

// This control bit is used to remember whether both 10bit address phases (1st and 2nd address) are matching with SAR 
always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        read_10b    <= 1'b0;
    else
        read_10b    <= read_10b_nxt;
end

always @* begin
    case ({set_addressed_10b, clear_addressed_10b})
        2'b00: read_10b_nxt = read_10b;
        2'b01: read_10b_nxt = 1'b0;
        2'b10: read_10b_nxt = 1'b1;
        2'b11: read_10b_nxt = read_10b;
        default: read_10b_nxt = 1'bx;
    endcase
end

// sda_setup counter
assign sda_setup_scl_out  = ((sda_setup_cnt_nxt != 8'h0) | arc_wait_data_tx_loop) ? 1'b0 : 1'b1;

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        sda_setup_cnt <= 8'h0;
    else
        sda_setup_cnt <= sda_setup_cnt_nxt;
end

always @* begin
    if (arc_wait_data_tx_loop_flp)
        sda_setup_cnt_nxt = ic_sda_setup;
    else if (sda_setup_cnt != 8'h0)
        sda_setup_cnt_nxt = sda_setup_cnt - 8'h1;
    else
        sda_setup_cnt_nxt = sda_setup_cnt;
end



// Slave Receive Data Lost status
assign set_slv_rx_data_lost = rx_loop_state & slv_rx_shift_done & ~ic_enable;

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        slv_rx_data_lost    <= 1'b0;
    else
        slv_rx_data_lost    <= slv_rx_data_lost_nxt;
end

always @* begin
    case ({ic_enable, set_slv_rx_data_lost})
        2'b00: slv_rx_data_lost_nxt = slv_rx_data_lost;
        2'b01: slv_rx_data_lost_nxt = 1'b1;
        2'b10: slv_rx_data_lost_nxt = 1'b0;
        2'b11: slv_rx_data_lost_nxt = slv_rx_data_lost;
        default: slv_rx_data_lost_nxt = 1'bx;
    endcase
end

// Slave Disabled While Busy status
assign set_slv_disabled_bsy =   (slv_1byte | slv_rx_10bit_2addr | rx_loop_state) & slv_rx_shift_done & ~ic_enable;

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        slv_disabled_bsy    <= 1'b0;
    else
        slv_disabled_bsy    <= slv_disabled_bsy_nxt;
end

always @* begin
    case ({ic_enable, set_slv_disabled_bsy})
        2'b00: slv_disabled_bsy_nxt = slv_disabled_bsy;
        2'b01: slv_disabled_bsy_nxt = 1'b1;
        2'b10: slv_disabled_bsy_nxt = 1'b0;
        2'b11: slv_disabled_bsy_nxt = slv_disabled_bsy;
        default: slv_disabled_bsy_nxt = 1'bx;
    endcase
end

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
        slvfsm_b2b_txshift <= 1'b0;
        slvfsm_b2b_rxshift <= 1'b0;
    end
    else begin
        slvfsm_b2b_txshift <= slvfsm_b2b_txshift_pre_flp;
        slvfsm_b2b_rxshift <= slvfsm_b2b_rxshift_pre_flp;
    end
end

// Slave receiver start of packet indication
assign set_slv_rx_sop   = (slv_1byte | slv_rx_10bit_2addr) & rx_loop_state_nxt; 
assign clear_slv_rx_sop = slv_idle_state | slv_rx_shift_done; 

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        slv_rx_sop  <= 1'b0;
    else
        slv_rx_sop  <= slv_rx_sop_nxt;
end

always @* begin
    if (set_slv_rx_sop)
        slv_rx_sop_nxt = 1'b1;
    else if (clear_slv_rx_sop)
        slv_rx_sop_nxt = 1'b0;
    else
        slv_rx_sop_nxt = slv_rx_sop;
end

endmodule


