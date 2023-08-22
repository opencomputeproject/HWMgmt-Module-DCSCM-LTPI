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

module altera_avalon_i2c_rxshifter (
    input               clk,
    input               rst_n,
    input               mst_rx_scl_high_cnt_complete,
    input               mst_rx_scl_low_cnt_complete,
    input               mst_rx_en,
    input               scl_int,
    input               sda_int,
    input               mstfsm_emptyfifo_hold_en,
    input               scl_edge_lh,
    input               mstfsm_b2b_rxshift,
    input               mst_rx_ack_nack,

    output              push_rx_fifo,
    output reg          mst_rx_scl_high_cnt_en,
    output reg          mst_rx_scl_low_cnt_en,
    output              mst_rx_shift_done,
    output              mst_rx_shift_check_hold,
    output reg          mst_rx_scl_out,
    output reg          mst_rx_sda_out,
    output reg          load_mst_rx_scl_high_cnt,
    output reg          load_mst_rx_scl_low_cnt,
    output reg [7:0]    rx_shifter,
    output              mst_rxack_phase

);


parameter IDLE          = 3'b000;
parameter RX_CLK_LOAD   = 3'b001;
parameter RX_CLK_LOW    = 3'b010;
parameter RX_CLK_HIGH   = 3'b011;
parameter RX_HOLD       = 3'b100; 
parameter RX_DONE       = 3'b101;


// wires & registers declaration
reg [2:0]           rx_shiftfsm_state, rx_shiftfsm_nx_state;
reg [3:0]	    rx_shiftbit_counter;
reg [3:0]	    rx_shiftbit_counter_nxt;
reg                 push_rx_fifo_en_flp;
reg                 mst_rx_shift_done_gen;
reg                 mst_rx_shift_done_gen_dly;

wire [3:0]	    rx_shiftbit_counter_init;
wire 		    rx_idle_state;
wire 		    rx_done_state;
wire 		    rx_clk_high_state;
wire 		    rx_clk_load_nx_state;
wire 		    arc_rx_done_load;
wire 		    arc_rx_clk_high_load;
wire		    rx_clk_hold_state;
wire		    rx_clk_hold_nx_state;
wire		    arc_rx_clk_high_hold;
wire 		    load_cnt;
wire 		    decr_cnt;
wire                push_rx_fifo_en;
wire                rx_shiftbit_counter_notzero;


assign mst_rxack_phase          = mst_rx_en & (rx_shiftbit_counter == 4'b0000);

assign rx_idle_state            = (rx_shiftfsm_state == IDLE);
assign rx_done_state            = (rx_shiftfsm_state == RX_DONE);
assign rx_clk_high_state        = (rx_shiftfsm_state == RX_CLK_HIGH);
assign rx_clk_hold_state        = (rx_shiftfsm_state == RX_HOLD);

assign rx_clk_load_nx_state     = (rx_shiftfsm_nx_state == RX_CLK_LOAD);
assign rx_clk_hold_nx_state     = (rx_shiftfsm_nx_state == RX_HOLD);

assign arc_rx_done_load         = rx_done_state & rx_clk_load_nx_state;
assign arc_rx_clk_high_load	= rx_clk_high_state & rx_clk_load_nx_state;
assign arc_rx_clk_high_hold	= rx_clk_high_state & rx_clk_hold_nx_state;

assign load_cnt                 = rx_idle_state | arc_rx_done_load;
assign decr_cnt                 = (arc_rx_clk_high_load | arc_rx_clk_high_hold) & rx_shiftbit_counter_notzero;

assign rx_shiftbit_counter_notzero = | rx_shiftbit_counter;

assign push_rx_fifo		= mst_rx_en & push_rx_fifo_en_flp;

assign push_rx_fifo_en          = (rx_shiftbit_counter == 4'b0001) & (rx_shiftbit_counter_nxt == 4'b0000);

assign mst_rx_shift_check_hold  = rx_clk_hold_state;

assign rx_shiftbit_counter_init = 4'b1000;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        push_rx_fifo_en_flp <= 1'b0;
    else
        push_rx_fifo_en_flp <= push_rx_fifo_en;
end

always @* begin
    if (load_cnt)
        rx_shiftbit_counter_nxt = rx_shiftbit_counter_init;
    else if (decr_cnt)
        rx_shiftbit_counter_nxt = rx_shiftbit_counter - 4'b0001;
    else
        rx_shiftbit_counter_nxt = rx_shiftbit_counter;
end


// bit number counter
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        rx_shiftbit_counter <= 4'b1000;
    else
        rx_shiftbit_counter <= rx_shiftbit_counter_nxt;
end




// TX shifter fsm 
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
       rx_shiftfsm_state <= IDLE;
    else
       rx_shiftfsm_state <= rx_shiftfsm_nx_state;
end

always @* begin
    case(rx_shiftfsm_state)
        IDLE	: begin
            if (mst_rx_en)
                rx_shiftfsm_nx_state = RX_CLK_LOAD;
	    else 
	    	rx_shiftfsm_nx_state = IDLE;
	end

	RX_CLK_LOAD : begin
	    if (~mst_rx_en)
		rx_shiftfsm_nx_state = IDLE;
	    else if (mst_rx_scl_low_cnt_complete)
		rx_shiftfsm_nx_state = RX_CLK_HIGH;
	    else 
		rx_shiftfsm_nx_state = RX_CLK_LOW;
	end

	RX_CLK_LOW : begin
	    if (~mst_rx_en)
		rx_shiftfsm_nx_state = IDLE;
	    else if (mst_rx_scl_low_cnt_complete)
		rx_shiftfsm_nx_state = RX_CLK_LOAD;
	    else 
		rx_shiftfsm_nx_state = RX_CLK_LOW;
	end

	RX_CLK_HIGH : begin 
	    if (~mst_rx_en) 
	    	rx_shiftfsm_nx_state = IDLE;
	    else if ((rx_shiftbit_counter == 4'b0001) & mstfsm_emptyfifo_hold_en & (mst_rx_scl_high_cnt_complete | (mst_rx_scl_high_cnt_en & ~scl_int)))
	    	rx_shiftfsm_nx_state = RX_HOLD;
	    else if ((rx_shiftbit_counter >= 4'b0001) & (mst_rx_scl_high_cnt_complete | (mst_rx_scl_high_cnt_en & ~scl_int)))
	    	rx_shiftfsm_nx_state = RX_CLK_LOAD;
	    else if (mst_rx_scl_high_cnt_complete | (mst_rx_scl_high_cnt_en & ~scl_int))
	    	rx_shiftfsm_nx_state = RX_DONE;
	    else
	    	rx_shiftfsm_nx_state = RX_CLK_HIGH;
	end

	RX_HOLD	: begin
	    if (~mst_rx_en)
		rx_shiftfsm_nx_state = RX_CLK_LOAD; 
	    else 
		rx_shiftfsm_nx_state = RX_HOLD;
	end 

	RX_DONE	: begin
	    if (~mst_rx_en)
		rx_shiftfsm_nx_state = IDLE;
            else if (mst_rx_en & mstfsm_b2b_rxshift)
		rx_shiftfsm_nx_state = RX_CLK_LOAD;
	    else
		rx_shiftfsm_nx_state = RX_DONE;
	end

	default: rx_shiftfsm_nx_state = 3'bx;
      endcase
  end



always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mst_rx_scl_high_cnt_en      <= 1'b0;
	mst_rx_scl_low_cnt_en       <= 1'b0;
	mst_rx_shift_done_gen       <= 1'b0;
	mst_rx_scl_out              <= 1'b1;
	mst_rx_sda_out              <= 1'b1;
	load_mst_rx_scl_high_cnt    <= 1'b0;
	load_mst_rx_scl_low_cnt     <= 1'b0;
    end
    else begin
	case(rx_shiftfsm_nx_state)
            IDLE : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_shift_done_gen       <= 1'b0;
                mst_rx_scl_out              <= 1'b1;
                mst_rx_sda_out              <= 1'b1;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;
	    end

            RX_CLK_LOAD : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_shift_done_gen       <= 1'b0;
		
                if ((rx_shiftbit_counter_nxt == 4'b0000) & mst_rx_scl_low_cnt_complete) begin
		    mst_rx_scl_out              <= 1'b1;
		    mst_rx_sda_out              <= mst_rx_ack_nack;
		    load_mst_rx_scl_high_cnt    <= 1'b1;
		    load_mst_rx_scl_low_cnt     <= 1'b0;
		 end
                 else if (rx_shiftbit_counter_nxt == 4'b0000) begin
		    mst_rx_scl_out              <= 1'b0;
                    mst_rx_sda_out              <= mst_rx_ack_nack;
		    load_mst_rx_scl_high_cnt    <= 1'b0;
		    load_mst_rx_scl_low_cnt     <= 1'b1;
                 end
                 else if (mst_rx_scl_low_cnt_complete) begin
                    mst_rx_scl_out              <= 1'b1;
                    mst_rx_sda_out              <= 1'b1;
		    load_mst_rx_scl_high_cnt    <= 1'b1;
		    load_mst_rx_scl_low_cnt     <= 1'b0;
                 end
		 else begin
                    mst_rx_scl_out              <= 1'b0;
                    mst_rx_sda_out              <= 1'b1;
		    load_mst_rx_scl_high_cnt    <= 1'b0;
		    load_mst_rx_scl_low_cnt     <= 1'b1;
                 end
	    end

	    RX_CLK_LOW : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b1;
                mst_rx_shift_done_gen       <= 1'b0;
                mst_rx_scl_out              <= 1'b0;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;

		if (rx_shiftbit_counter_nxt == 4'b0000)  // 4'b000 is ACK waiting bit
		    mst_rx_sda_out <= mst_rx_ack_nack;
		else
		    mst_rx_sda_out <= 1'b1;
	    end

            RX_CLK_HIGH : begin
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_shift_done_gen       <= 1'b0;
                mst_rx_scl_out              <= 1'b1;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;
	        
                if ((rx_shiftbit_counter_nxt == 4'b0000) & scl_int) begin	// FIXME: CLK synchronization to SCL is one clock after
		    mst_rx_sda_out          <= mst_rx_ack_nack;
		    mst_rx_scl_high_cnt_en  <= 1'b1;
		end
		else if (rx_shiftbit_counter_nxt == 4'b0000) begin
                    mst_rx_sda_out          <= mst_rx_ack_nack;
		    mst_rx_scl_high_cnt_en  <= 1'b0;
		end
		else if (scl_int) begin
                    mst_rx_sda_out          <= 1'b1;
                    mst_rx_scl_high_cnt_en  <= 1'b1;
		end
		else begin
                    mst_rx_sda_out          <= 1'b1;
                    mst_rx_scl_high_cnt_en  <= 1'b0;
		end
            end

            RX_HOLD : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_sda_out              <= 1'b1;
                mst_rx_shift_done_gen       <= 1'b0;
                mst_rx_scl_out              <= 1'b0;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;
	    end

	    RX_DONE : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_scl_out              <= 1'b1;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;
	        mst_rx_shift_done_gen       <= 1'b1;
		mst_rx_sda_out              <= mst_rx_ack_nack;
	    end

	    default: begin
		 mst_rx_scl_high_cnt_en     <= 1'bx;
		 mst_rx_scl_low_cnt_en      <= 1'bx;
		 mst_rx_sda_out             <= 1'bx;
		 mst_rx_shift_done_gen      <= 1'bx;
		 mst_rx_scl_out             <= 1'bx;
		 load_mst_rx_scl_high_cnt   <= 1'bx;
		 load_mst_rx_scl_low_cnt    <= 1'bx;
	    end
	  endcase
	end
  end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_shifter <= 8'h0;
    else if (mst_rx_en & scl_edge_lh)
        rx_shifter[rx_shiftbit_counter - 1] <= sda_int;
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mst_rx_shift_done_gen_dly   <= 1'b0;
    end
    else begin
        mst_rx_shift_done_gen_dly   <= mst_rx_shift_done_gen;
    end
end

assign mst_rx_shift_done    = mst_rx_shift_done_gen & ~mst_rx_shift_done_gen_dly;




endmodule





