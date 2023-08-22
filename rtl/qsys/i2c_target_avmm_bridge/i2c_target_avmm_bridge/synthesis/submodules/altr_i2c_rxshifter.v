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
module altr_i2c_rxshifter #(
	parameter ADDRESS_STEALING = 0
)(
    input               i2c_clk,
    input               i2c_rst_n,
    input               mst_rx_scl_high_cnt_complete,
    input               mst_rx_scl_low_cnt_complete,
    input               mst_rx_en,
    input               slv_rx_en,
    input               scl_int,
    input               sda_int,
    input               mstfsm_emptyfifo_hold_en,
    input               scl_edge_hl,	
    input               scl_edge_lh,
    input               slv_1byte,
    input               slv_rx_10bit_2addr,
    input [9:0]         ic_sar,
    input               mstfsm_b2b_rxshift,
    input               mst_rx_ack_nack,
    input               slvfsm_b2b_rxshift,
    input               ic_slv_data_nack,
    input               rx_loop_state,
    input               ic_ack_general_call,
    input               ic_enable,
    input               ic_slv_en,
    input               start_det_dly,
    input               ic_10bit,
    input               mstfsm_sw_abort_det,
    input               ic_enable_txabort,
    input               txfifo_empty,
    input               clk_cnt_zero,

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
    output reg          slv_rx_sda_out,
    output              slv_rx_shift_done,
    output              rx_addr_match,
    output              gen_call_rcvd,
    output              mst_rxack_phase,
    output              slv_rxack_phase,
    output		gcall_addr_matched,
    output reg          ic_enable_txabort_m,
    output              ic_enable_hold_adv,
    output reg          txfifo_empty_m

);


localparam IDLE          = 3'b000;
localparam RX_CLK_LOAD   = 3'b001;
localparam RX_CLK_LOW    = 3'b010;
localparam RX_CLK_HIGH   = 3'b011;
localparam RX_HOLD       = 3'b100; 
localparam RX_SLV_SHIFT  = 3'b101;
localparam RX_DONE       = 3'b110;


// wires & registers declaration
reg [2:0]           rx_shiftfsm_state, rx_shiftfsm_nx_state;
reg [3:0]	    rx_shiftbit_counter;
reg [3:0]	    rx_shiftbit_counter_nxt;
reg                 push_rx_fifo_en_flp;
reg                 mst_rx_shift_done_gen;
reg                 mst_rx_shift_done_gen_dly;
reg                 slv_rx_shift_done_gen;
reg                 slv_rx_shift_done_gen_dly;

wire [3:0]	    rx_shiftbit_counter_init;
wire 		    rx_idle_state;
wire 		    rx_done_state;
wire 		    rx_clk_high_state;
wire 		    rx_clk_load_nx_state;
wire                rx_slv_shift_nx_state;
wire 		    arc_rx_done_load;
wire 		    arc_rx_clk_high_load;
wire		    rx_clk_hold_state;
wire		    rx_clk_hold_nx_state;
wire		    arc_rx_clk_high_hold;
wire                arc_rx_done_rx_slv_shift;
wire 		    load_cnt;
wire 		    decr_cnt;
wire                push_rx_fifo_en;
wire                rx_shiftbit_counter_notzero;

wire [7:0]	    gcall_addr;
wire [6:0]	    tenbit_addr1;	//FIXME: to be confirmed the total bit number
wire [7:0]	    tenbit_addr2;
wire [6:0]	    sevenbit_addr;
wire		    sevenbit_addr_matched;
wire		    tenbit_addr1_matched;
wire		    tenbit_addr2_matched;

wire                slv_rx_ack_nack;
wire                slv_rx_data_ack;

wire                ic_enable_txabort_hold;
wire [2:0]			addr_steal_bit;

assign addr_steal_bit = (ADDRESS_STEALING == 0) ? 3'b111 :
							(ADDRESS_STEALING == 1) ? 3'b110 :
								(ADDRESS_STEALING == 2) ? 3'b100 :
									(ADDRESS_STEALING == 3) ? 3'b000 : 3'b111;

assign mst_rxack_phase          = mst_rx_en & (rx_shiftbit_counter == 4'b0000);
assign slv_rxack_phase          = slv_rx_en & (rx_shiftbit_counter == 4'b0000);

assign rx_idle_state            = (rx_shiftfsm_state == IDLE);
assign rx_done_state            = (rx_shiftfsm_state == RX_DONE);
assign rx_clk_high_state        = (rx_shiftfsm_state == RX_CLK_HIGH);
assign rx_clk_hold_state        = (rx_shiftfsm_state == RX_HOLD);

assign rx_clk_load_nx_state     = (rx_shiftfsm_nx_state == RX_CLK_LOAD);
assign rx_clk_hold_nx_state     = (rx_shiftfsm_nx_state == RX_HOLD);
assign rx_slv_shift_nx_state    = (rx_shiftfsm_nx_state == RX_SLV_SHIFT);

assign arc_rx_done_load         = rx_done_state & rx_clk_load_nx_state;
assign arc_rx_clk_high_load	= rx_clk_high_state & rx_clk_load_nx_state;
assign arc_rx_clk_high_hold	= rx_clk_high_state & rx_clk_hold_nx_state;
assign arc_rx_done_rx_slv_shift = rx_done_state & rx_slv_shift_nx_state;

assign load_cnt                 = rx_idle_state | arc_rx_done_load | arc_rx_done_rx_slv_shift | (ic_slv_en & start_det_dly);
assign decr_cnt                 = (arc_rx_clk_high_load | arc_rx_clk_high_hold | (slv_rx_en & scl_edge_hl)) & rx_shiftbit_counter_notzero;

assign rx_shiftbit_counter_notzero = | rx_shiftbit_counter;

assign push_rx_fifo		= (mst_rx_en | (slv_rx_en & ~ic_slv_data_nack & rx_loop_state)) & push_rx_fifo_en_flp;

assign push_rx_fifo_en          = (rx_shiftbit_counter == 4'b0001) & (rx_shiftbit_counter_nxt == 4'b0000);

assign mst_rx_shift_check_hold  = rx_clk_hold_state;

assign rx_shiftbit_counter_init = (ic_slv_en & start_det_dly) ? 4'b1001 : 4'b1000;

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if(!i2c_rst_n)
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
always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if(!i2c_rst_n)
        rx_shiftbit_counter <= 4'b1000;
    else
        rx_shiftbit_counter <= rx_shiftbit_counter_nxt;
end




// TX shifter fsm 
always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
       rx_shiftfsm_state <= IDLE;
    else
       rx_shiftfsm_state <= rx_shiftfsm_nx_state;
end

always @* begin
    case(rx_shiftfsm_state)
        IDLE	: begin
            if (mst_rx_en)
                rx_shiftfsm_nx_state = RX_CLK_LOAD;
	    else if (slv_rx_en)
	    	rx_shiftfsm_nx_state = RX_SLV_SHIFT;
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
	    if (~mst_rx_en | mstfsm_sw_abort_det)
		//rx_shiftfsm_nx_state = IDLE; 
		rx_shiftfsm_nx_state = RX_CLK_LOAD; 
	    //else if (~mstfsm_emptyfifo_hold_en)
		//rx_shiftfsm_nx_state = RX_CLK_LOAD; 
	    else 
		rx_shiftfsm_nx_state = RX_HOLD;
	end 

	RX_SLV_SHIFT : begin
	    if (~slv_rx_en)
		rx_shiftfsm_nx_state = IDLE;
	    else if ((rx_shiftbit_counter == 4'b0000) & scl_edge_hl)
		rx_shiftfsm_nx_state = RX_DONE;
	    else
		rx_shiftfsm_nx_state = RX_SLV_SHIFT;
	end

	RX_DONE	: begin
	    if (~slv_rx_en & ~mst_rx_en)
		rx_shiftfsm_nx_state = IDLE;
            else if (mst_rx_en & mstfsm_b2b_rxshift)
		rx_shiftfsm_nx_state = RX_CLK_LOAD;
            else if (slv_rx_en & slvfsm_b2b_rxshift)
		rx_shiftfsm_nx_state = RX_SLV_SHIFT;
	    else
		rx_shiftfsm_nx_state = RX_DONE;
	end

	default: rx_shiftfsm_nx_state = 3'bx;
      endcase
  end



always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
    mst_rx_scl_high_cnt_en      <= 1'b0;
	mst_rx_scl_low_cnt_en       <= 1'b0;
	mst_rx_shift_done_gen       <= 1'b0;
	mst_rx_scl_out              <= 1'b1;
	mst_rx_sda_out              <= 1'b1;
	load_mst_rx_scl_high_cnt    <= 1'b0;
	load_mst_rx_scl_low_cnt     <= 1'b0;
	slv_rx_sda_out              <= 1'b1;
	slv_rx_shift_done_gen       <= 1'b0;
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
                slv_rx_sda_out              <= 1'b1;
                slv_rx_shift_done_gen       <= 1'b0;
	    end

            RX_CLK_LOAD : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_shift_done_gen       <= 1'b0;
                slv_rx_sda_out              <= 1'b1;
                slv_rx_shift_done_gen       <= 1'b0;
		
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
                slv_rx_sda_out              <= 1'b1;
                slv_rx_shift_done_gen       <= 1'b0;

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
                slv_rx_sda_out              <= 1'b1;
                slv_rx_shift_done_gen       <= 1'b0;
	        
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
                slv_rx_sda_out              <= 1'b1;
                slv_rx_shift_done_gen       <= 1'b0;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;
	    end

            RX_SLV_SHIFT : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_sda_out              <= 1'b1;
                mst_rx_shift_done_gen       <= 1'b0;
                mst_rx_scl_out              <= 1'b1;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;
		
                if (rx_shiftbit_counter_nxt == 4'b0000) begin
					slv_rx_sda_out          <= slv_rx_ack_nack;
					slv_rx_shift_done_gen   <= 1'b0;
				end
				else if ((rx_shiftbit_counter_nxt != 4'b0000) & scl_edge_lh) begin
					slv_rx_sda_out          <= 1'b1;
					slv_rx_shift_done_gen   <= 1'b0;
				end
				else begin
					slv_rx_sda_out          <= 1'b1;
					slv_rx_shift_done_gen   <= 1'b0;
				end
            end

	    RX_DONE : begin
                mst_rx_scl_high_cnt_en      <= 1'b0;
                mst_rx_scl_low_cnt_en       <= 1'b0;
                mst_rx_scl_out              <= 1'b1;
                load_mst_rx_scl_high_cnt    <= 1'b0;
                load_mst_rx_scl_low_cnt     <= 1'b0;

			if (mst_rx_en) begin
					mst_rx_shift_done_gen   <= 1'b1;
					slv_rx_shift_done_gen   <= 1'b0;
					mst_rx_sda_out          <= mst_rx_ack_nack;
					slv_rx_sda_out          <= 1'b1;
			end
			else begin 
					mst_rx_shift_done_gen   <= 1'b0;
					slv_rx_shift_done_gen   <= 1'b1;
					mst_rx_sda_out          <= 1'b1;
					slv_rx_sda_out          <= slv_rx_ack_nack;
			end
	    end

	    default: begin
		 mst_rx_scl_high_cnt_en     <= 1'bx;
		 mst_rx_scl_low_cnt_en      <= 1'bx;
		 mst_rx_sda_out             <= 1'bx;
		 mst_rx_shift_done_gen      <= 1'bx;
		 mst_rx_scl_out             <= 1'bx;
		 load_mst_rx_scl_high_cnt   <= 1'bx;
		 load_mst_rx_scl_low_cnt    <= 1'bx;
		 slv_rx_sda_out             <= 1'bx;
		 slv_rx_shift_done_gen      <= 1'bx;
	    end
	  endcase
	end
  end


always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        rx_shifter <= 8'h0;
    else if ((mst_rx_en | slv_rx_en) & scl_edge_lh)
        rx_shifter[rx_shiftbit_counter - 1] <= sda_int;
end


assign gcall_addr       = 8'b00000000;
assign tenbit_addr1     = {5'b11110, ic_sar[9:8]};
assign tenbit_addr2     = ic_sar[7:0];
assign sevenbit_addr    = ic_sar[6:0];


assign gcall_addr_matched	= ic_ack_general_call ? (rx_shifter[7:0] == gcall_addr) : 1'b0;
assign sevenbit_addr_matched	= ((rx_shifter[7:1] & {{4{1'b1}}, addr_steal_bit}) == sevenbit_addr) & ~ic_10bit;
assign tenbit_addr1_matched	= (rx_shifter[7:1] == tenbit_addr1) & ic_10bit;
assign tenbit_addr2_matched	= (rx_shifter[7:0] == tenbit_addr2) & ic_10bit;

assign gen_call_rcvd    = ic_enable & slv_rx_shift_done & slv_1byte & gcall_addr_matched;

assign rx_addr_match	= ic_enable & 
                          ((slv_1byte & (sevenbit_addr_matched | tenbit_addr1_matched | gcall_addr_matched)) | 
                          (slv_rx_10bit_2addr & tenbit_addr2_matched));

assign slv_rx_data_ack  = ic_slv_data_nack ? 1'b1 : ~ic_enable;
			  
assign slv_rx_ack_nack  = (slv_1byte | slv_rx_10bit_2addr) ? ~rx_addr_match : slv_rx_data_ack; 

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
        mst_rx_shift_done_gen_dly   <= 1'b0;
        slv_rx_shift_done_gen_dly   <= 1'b0;
    end
    else begin
        mst_rx_shift_done_gen_dly   <= mst_rx_shift_done_gen;
        slv_rx_shift_done_gen_dly   <= slv_rx_shift_done_gen;
    end
end

assign mst_rx_shift_done    = mst_rx_shift_done_gen & ~mst_rx_shift_done_gen_dly;
assign slv_rx_shift_done    = slv_rx_shift_done_gen & ~slv_rx_shift_done_gen_dly;


assign ic_enable_txabort_hold   = (rx_shiftbit_counter == 4'b0000) & ~rx_clk_hold_state;

assign ic_enable_hold_adv       = (clk_cnt_zero & (rx_shiftbit_counter == 4'b0001)) |
                                    ((rx_shiftbit_counter == 4'b0000) & ~rx_clk_hold_state);

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
        ic_enable_txabort_m     <= 1'b0;
        txfifo_empty_m          <= 1'b1;
    end
    else if (ic_enable_txabort_hold) begin
        ic_enable_txabort_m     <= ic_enable_txabort_m;
        txfifo_empty_m          <= txfifo_empty_m;
    end
    else begin
        ic_enable_txabort_m     <= ic_enable_txabort;
        txfifo_empty_m          <= txfifo_empty;
    end
end

endmodule





