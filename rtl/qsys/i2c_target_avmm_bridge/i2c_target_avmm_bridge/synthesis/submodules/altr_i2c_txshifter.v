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
module altr_i2c_txshifter (
    input               i2c_clk,
    input               i2c_rst_n,
    input               mst_tx_scl_high_cnt_complete,
    input               mst_tx_scl_low_cnt_complete,
    input               mst_tx_en,
    input               slv_tx_en,
    input               scl_int,
    input               scl_edge_hl,
    input               mstfsm_emptyfifo_hold_en,
    input               mstfsm_b2b_txshift,
    input               load_tx_shifter,
    input [10:0]        tx_fifo_data_in,
    input [9:0]         ic_tar,
    input               tx_byte_state,
    input               gcall_state,
    input               gen_sbyte_state,
    input               gen_10bit_addr1_state,
    input               gen_10bit_addr2_state,
    input               gen_7bit_addr_state,
    input               sent_10bit_addr2,
    input               slvfsm_b2b_txshift,
    input               ic_slv_en,
    input               start_det_dly,
  
    output reg          mst_tx_scl_high_cnt_en,
    output reg          mst_tx_scl_low_cnt_en,
    output reg          mst_tx_chk_ack,                 // to ack detector
    output              mst_tx_shift_done,
    output reg          mst_tx_scl_out,
    output reg          mst_tx_sda_out,
    output reg          slv_tx_chk_ack,                 // to ack detector
    output              slv_tx_shift_done,
    output reg          slv_tx_sda_out,
    output reg          load_mst_tx_scl_high_cnt,
    output reg          load_mst_tx_scl_low_cnt,
    output reg [10:0]   tx_shifter,
    output              mst_txdata_phase,
    output              slv_txdata_phase

);


parameter TX_IDLE       = 3'b000;
parameter TX_CLK_LOAD   = 3'b001;
parameter TX_CLK_LOW    = 3'b010;
parameter TX_CLK_HIGH   = 3'b011;
parameter TX_CLK_HOLD   = 3'b100;
parameter TX_SLV_SHIFT  = 3'b101;
parameter TX_DONE       = 3'b110;


// wires & registers declaration
reg [2:0]       tx_shiftfsm_state; 
reg [2:0]       tx_shiftfsm_nx_state;
reg [3:0]       tx_shiftbit_counter;
reg [3:0]       tx_shiftbit_counter_nxt;
reg             mst_tx_shift_done_gen;
reg             mst_tx_shift_done_gen_dly;
reg             slv_tx_shift_done_gen;
reg             slv_tx_shift_done_gen_dly;

wire            tx_idle_state;
wire            tx_done_state;
wire            tx_clk_high_state;
wire            tx_clk_load_nx_state;
wire            arc_tx_done_load;
wire            arc_tx_clk_high_load;
wire            load_cnt;
wire            decr_cnt;
wire            tx_slv_shift_nx_state;
wire [3:0]      tx_shiftbit_counter_init;
wire            arc_tx_done_slv_shift; 

wire [7:0]      tx_shift_data;
wire [7:0]      gcall_addr;
wire [7:0]      start_byte;
wire [7:0]      tenbit_addr1;
wire [7:0]      tenbit_addr2;
wire [7:0]      sevenbit_addr;
wire            tx_shift_data_phase;

wire [7:0]      write_txbyte;
wire [7:0]      write_gcall_addr;
wire [7:0]      write_start_byte;
wire [7:0]      write_10bit_addr1;
wire [7:0]      write_10bit_addr2;
wire [7:0]      write_7bit_addr;
wire            tenbit_addr1_cmd;
wire            tx_shiftbit_counter_notzero;

assign mst_txdata_phase         = mst_tx_en & (tx_shiftbit_counter > 4'b0000);
assign slv_txdata_phase         = slv_tx_en & (tx_shiftbit_counter > 4'b0000);

assign tx_idle_state            = (tx_shiftfsm_state == TX_IDLE);
assign tx_done_state            = (tx_shiftfsm_state == TX_DONE);
assign tx_clk_high_state        = (tx_shiftfsm_state == TX_CLK_HIGH);

assign tx_clk_load_nx_state     = (tx_shiftfsm_nx_state == TX_CLK_LOAD);
assign tx_slv_shift_nx_state    = (tx_shiftfsm_nx_state == TX_SLV_SHIFT);

assign arc_tx_done_load         = tx_done_state & tx_clk_load_nx_state;
assign arc_tx_clk_high_load     = tx_clk_high_state & tx_clk_load_nx_state;
assign arc_tx_done_slv_shift    = tx_done_state & tx_slv_shift_nx_state; 

assign load_cnt                 = tx_idle_state | arc_tx_done_load | arc_tx_done_slv_shift | (ic_slv_en & start_det_dly);
assign decr_cnt                 = (arc_tx_clk_high_load | (slv_tx_en & scl_edge_hl)) & tx_shiftbit_counter_notzero;

assign tx_shiftbit_counter_notzero = | tx_shiftbit_counter;

assign tx_shiftbit_counter_init = (ic_slv_en & start_det_dly) ? 4'b1001 : 4'b1000;

always @* begin
    if (load_cnt)
        tx_shiftbit_counter_nxt = tx_shiftbit_counter_init;
    else if (decr_cnt)
        tx_shiftbit_counter_nxt = tx_shiftbit_counter - 4'b0001;
    else
        tx_shiftbit_counter_nxt = tx_shiftbit_counter;
end

// bit number counter
always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if(!i2c_rst_n)
        tx_shiftbit_counter <= 4'b1000;
    else
        tx_shiftbit_counter <= tx_shiftbit_counter_nxt;
end




// TX shifter fsm 
always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        tx_shiftfsm_state <= TX_IDLE;
    else
        tx_shiftfsm_state <= tx_shiftfsm_nx_state;
end

always @* begin
    case(tx_shiftfsm_state)
        TX_IDLE	: begin
            if (mst_tx_en) 
                tx_shiftfsm_nx_state = TX_CLK_LOAD;
            else if (slv_tx_en)
                tx_shiftfsm_nx_state = TX_SLV_SHIFT;
            else 
                tx_shiftfsm_nx_state = TX_IDLE;
        end

        TX_CLK_LOAD : begin
            if (~mst_tx_en)
                tx_shiftfsm_nx_state = TX_IDLE;
            else if (mst_tx_scl_low_cnt_complete)
                tx_shiftfsm_nx_state = TX_CLK_HIGH;
            else
                tx_shiftfsm_nx_state = TX_CLK_LOW;
        end

        TX_CLK_LOW : begin
            if (~mst_tx_en)
                tx_shiftfsm_nx_state = TX_IDLE;
            else if (mst_tx_scl_low_cnt_complete)
                tx_shiftfsm_nx_state = TX_CLK_LOAD;
            else
                tx_shiftfsm_nx_state = TX_CLK_LOW;
        end

        TX_CLK_HIGH : begin
            if (~mst_tx_en)
                tx_shiftfsm_nx_state = TX_IDLE; 
            else if ((tx_shiftbit_counter != 4'b0000) & (mst_tx_scl_high_cnt_complete | (mst_tx_scl_high_cnt_en & ~scl_int)))
                tx_shiftfsm_nx_state = TX_CLK_LOAD;
            else if ((tx_shiftbit_counter == 4'b0000) & (mst_tx_scl_high_cnt_complete | (mst_tx_scl_high_cnt_en & ~scl_int)))
                tx_shiftfsm_nx_state = TX_DONE; 
            else
                tx_shiftfsm_nx_state = TX_CLK_HIGH;
        end

        TX_CLK_HOLD : begin
            if (~mst_tx_en)
                tx_shiftfsm_nx_state = TX_IDLE; 
            else
                tx_shiftfsm_nx_state = TX_CLK_HOLD;
        end

        TX_SLV_SHIFT : begin 
            if (~slv_tx_en)
                tx_shiftfsm_nx_state = TX_IDLE;
            else if ((tx_shiftbit_counter == 4'b0000) & scl_edge_hl)
                tx_shiftfsm_nx_state = TX_DONE;
            else
                tx_shiftfsm_nx_state = TX_SLV_SHIFT;
        end

        TX_DONE	: begin
            if (~slv_tx_en & ~mst_tx_en)
                tx_shiftfsm_nx_state = TX_IDLE;
            else if (mst_tx_en & mstfsm_b2b_txshift)
                tx_shiftfsm_nx_state = TX_CLK_LOAD;
            else if (mst_tx_en & mstfsm_emptyfifo_hold_en)
                tx_shiftfsm_nx_state = TX_CLK_HOLD;
            else if (slv_tx_en & slvfsm_b2b_txshift)
                tx_shiftfsm_nx_state = TX_SLV_SHIFT;
            else
                tx_shiftfsm_nx_state = TX_DONE;
        end

	default: tx_shiftfsm_nx_state = 3'bx;

    endcase
end



always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
        mst_tx_scl_high_cnt_en      <= 1'b0;
        mst_tx_scl_low_cnt_en       <= 1'b0;
        mst_tx_sda_out              <= 1'b1;
        mst_tx_scl_out              <= 1'b1;
        mst_tx_chk_ack              <= 1'b0;
        mst_tx_shift_done_gen       <= 1'b0;
        load_mst_tx_scl_low_cnt     <= 1'b0;
        load_mst_tx_scl_high_cnt    <= 1'b0;
        slv_tx_chk_ack              <= 1'b0;
        slv_tx_shift_done_gen       <= 1'b0;
        slv_tx_sda_out              <= 1'b1;
    end
    else begin
        case(tx_shiftfsm_nx_state)
            TX_IDLE : begin
                mst_tx_scl_high_cnt_en      <= 1'b0;
                mst_tx_scl_low_cnt_en       <= 1'b0;
                mst_tx_sda_out              <= 1'b1;
                mst_tx_scl_out              <= 1'b1;
                mst_tx_chk_ack              <= 1'b0;
                mst_tx_shift_done_gen       <= 1'b0;
                load_mst_tx_scl_low_cnt     <= 1'b0;
                load_mst_tx_scl_high_cnt    <= 1'b0;
                slv_tx_chk_ack              <= 1'b0;
                slv_tx_shift_done_gen       <= 1'b0;
                slv_tx_sda_out              <= 1'b1;
            end

            TX_CLK_LOAD : begin
                mst_tx_scl_high_cnt_en  <= 1'b0;
                mst_tx_scl_low_cnt_en   <= 1'b0;
                mst_tx_shift_done_gen   <= 1'b0;
                slv_tx_chk_ack          <= 1'b0;
                slv_tx_shift_done_gen   <= 1'b0;
                slv_tx_sda_out          <= 1'b1;

                if ((tx_shiftbit_counter_nxt == 4'b0000) & mst_tx_scl_low_cnt_complete) begin
                    load_mst_tx_scl_low_cnt     <= 1'b0;
                    load_mst_tx_scl_high_cnt    <= 1'b1;
                    mst_tx_sda_out              <= 1'b1;
                    mst_tx_scl_out              <= 1'b1;
                    mst_tx_chk_ack              <= 1'b1;
                end
                else if (tx_shiftbit_counter_nxt == 4'b0000) begin
                    load_mst_tx_scl_low_cnt     <= 1'b1;
                    load_mst_tx_scl_high_cnt    <= 1'b0;
                    mst_tx_sda_out              <= 1'b1;
                    mst_tx_scl_out              <= 1'b0;
                    mst_tx_chk_ack              <= 1'b1;
                end
                else if (mst_tx_scl_low_cnt_complete) begin
                    load_mst_tx_scl_low_cnt     <= 1'b0;
                    load_mst_tx_scl_high_cnt    <= 1'b1;
                    mst_tx_sda_out              <= tx_shift_data[tx_shiftbit_counter_nxt-1];
                    mst_tx_scl_out              <= 1'b1;
                    mst_tx_chk_ack              <= 1'b0;
                end
                else begin
                    load_mst_tx_scl_low_cnt     <= 1'b1;
                    load_mst_tx_scl_high_cnt    <= 1'b0;
                    mst_tx_sda_out              <= tx_shift_data[tx_shiftbit_counter_nxt-1];
                    mst_tx_scl_out              <= 1'b0;
                    mst_tx_chk_ack              <= 1'b0;
                end
            end

	    TX_CLK_LOW : begin
                mst_tx_scl_high_cnt_en      <= 1'b0;
                mst_tx_scl_low_cnt_en       <= 1'b1;
                mst_tx_shift_done_gen       <= 1'b0;
                mst_tx_scl_out              <= 1'b0;
                load_mst_tx_scl_low_cnt     <= 1'b0;
                load_mst_tx_scl_high_cnt    <= 1'b0;
                slv_tx_chk_ack              <= 1'b0;
                slv_tx_shift_done_gen       <= 1'b0;
                slv_tx_sda_out              <= 1'b1;

                if (tx_shiftbit_counter_nxt == 4'b0000) begin // 4'b000 is ACK waiting bit
                    mst_tx_sda_out          <= 1'b1;
                    mst_tx_chk_ack          <= 1'b1;
                end
                else begin
                    mst_tx_sda_out          <= tx_shift_data[tx_shiftbit_counter_nxt-1];
                    mst_tx_chk_ack          <= 1'b0;
                end
            end

            TX_CLK_HIGH : begin
                mst_tx_scl_low_cnt_en       <= 1'b0;
                mst_tx_shift_done_gen       <= 1'b0;
                mst_tx_scl_out              <= 1'b1;
                load_mst_tx_scl_low_cnt     <= 1'b0;
                load_mst_tx_scl_high_cnt    <= 1'b0;
                slv_tx_chk_ack              <= 1'b0;
                slv_tx_shift_done_gen       <= 1'b0;
                slv_tx_sda_out              <= 1'b1;

                if ((tx_shiftbit_counter_nxt == 4'b0000) & scl_int) begin // FIXME: CLK synchronization to SCL is one clock after
                    mst_tx_sda_out          <= 1'b1;
                    mst_tx_chk_ack          <= 1'b1;
                    mst_tx_scl_high_cnt_en  <= 1'b1;
                end
                else if (tx_shiftbit_counter_nxt == 4'b0000) begin
                    mst_tx_sda_out          <= 1'b1;
                    mst_tx_chk_ack          <= 1'b1;
                    mst_tx_scl_high_cnt_en  <= 1'b0;
                end
                else if (scl_int) begin
                    mst_tx_sda_out          <= tx_shift_data[tx_shiftbit_counter_nxt-1];
                    mst_tx_chk_ack          <= 1'b0;
                    mst_tx_scl_high_cnt_en  <= 1'b1;
                end
                else begin
                    mst_tx_sda_out          <= tx_shift_data[tx_shiftbit_counter_nxt-1];
                    mst_tx_chk_ack          <= 1'b0;
                    mst_tx_scl_high_cnt_en  <= 1'b0;
                end
            end

            TX_CLK_HOLD : begin
                mst_tx_scl_high_cnt_en      <= 1'b0;
                mst_tx_scl_low_cnt_en       <= 1'b0;
                mst_tx_sda_out              <= 1'b1;
                mst_tx_chk_ack              <= 1'b0;
                mst_tx_shift_done_gen       <= 1'b0;
                load_mst_tx_scl_low_cnt     <= 1'b0;
                load_mst_tx_scl_high_cnt    <= 1'b0;
                slv_tx_chk_ack              <= 1'b0;
                slv_tx_shift_done_gen       <= 1'b0;
                slv_tx_sda_out              <= 1'b1;
                
                if (mst_tx_en) 
                    mst_tx_scl_out          <= 1'b0;
                else	// slv TX
                    mst_tx_scl_out          <= 1'b1;
            end


            TX_SLV_SHIFT : begin
                mst_tx_scl_high_cnt_en      <= 1'b0;
                mst_tx_scl_low_cnt_en       <= 1'b0;
                mst_tx_sda_out              <= 1'b1;
                mst_tx_scl_out              <= 1'b1;
                mst_tx_chk_ack              <= 1'b0;
                mst_tx_shift_done_gen       <= 1'b0;
                load_mst_tx_scl_low_cnt     <= 1'b0;
                load_mst_tx_scl_high_cnt    <= 1'b0;
                slv_tx_shift_done_gen       <= 1'b0;

                if (tx_shiftbit_counter_nxt == 4'b0000) begin	//4'b0000 is bit-8 ACK waiting
                    slv_tx_chk_ack          <= 1'b1;
                    slv_tx_sda_out          <= 1'b1;
                end
                else begin
                    slv_tx_chk_ack          <= 1'b0;
                    slv_tx_sda_out          <= tx_shift_data[tx_shiftbit_counter_nxt-1];
                end
            end

	    TX_DONE	: begin
                mst_tx_scl_high_cnt_en      <= 1'b0;
                mst_tx_scl_low_cnt_en       <= 1'b0;
                mst_tx_scl_out              <= 1'b1;
                mst_tx_sda_out              <= 1'b1;
                mst_tx_chk_ack              <= 1'b1;
                load_mst_tx_scl_low_cnt     <= 1'b0;
                load_mst_tx_scl_high_cnt    <= 1'b0;
                slv_tx_chk_ack              <= 1'b1;
                slv_tx_sda_out              <= 1'b1;

                if (mst_tx_en) begin
                    mst_tx_shift_done_gen   <= 1'b1;
                    slv_tx_shift_done_gen   <= 1'b0;
                end
                else begin 
                    mst_tx_shift_done_gen   <= 1'b0;
                    slv_tx_shift_done_gen   <= 1'b1;
                end
	    end

	    default: begin
                mst_tx_scl_high_cnt_en      <= 1'bx;
                mst_tx_scl_low_cnt_en       <= 1'bx;
                mst_tx_scl_out              <= 1'bx;
                mst_tx_sda_out              <= 1'bx;
                mst_tx_chk_ack              <= 1'bx;
                mst_tx_shift_done_gen       <= 1'bx;
                load_mst_tx_scl_low_cnt     <= 1'bx;
                load_mst_tx_scl_high_cnt    <= 1'bx;
                slv_tx_chk_ack              <= 1'bx;
                slv_tx_shift_done_gen       <= 1'bx;
                slv_tx_sda_out              <= 1'bx;
	    end
        endcase
    end
end


always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        tx_shifter  <= 11'h0;
    else if (load_tx_shifter)
        tx_shifter  <= tx_fifo_data_in;
    else
        tx_shifter  <= tx_shifter;
end

assign tenbit_addr1_cmd = tx_shifter[8] & sent_10bit_addr2;

assign gcall_addr       = 8'b00000000;
assign start_byte       = 8'b00000001;
assign tenbit_addr1     = {5'b11110, ic_tar[9:8], tenbit_addr1_cmd};
assign tenbit_addr2     = ic_tar[7:0];
assign sevenbit_addr    = {ic_tar[6:0], tx_shifter[8]};

assign tx_shift_data_phase = tx_byte_state | slv_tx_en;

assign write_txbyte         = tx_shifter[7:0]   & {8{tx_shift_data_phase}};
assign write_gcall_addr     = gcall_addr        & {8{gcall_state}};
assign write_start_byte     = start_byte        & {8{gen_sbyte_state}};
assign write_10bit_addr1    = tenbit_addr1      & {8{gen_10bit_addr1_state}};
assign write_10bit_addr2    = tenbit_addr2      & {8{gen_10bit_addr2_state}};
assign write_7bit_addr      = sevenbit_addr     & {8{gen_7bit_addr_state}};

assign tx_shift_data =  write_txbyte        |
                        write_gcall_addr    |
                        write_start_byte    |
                        write_10bit_addr1   |
                        write_10bit_addr2   |
                        write_7bit_addr;

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
        mst_tx_shift_done_gen_dly   <= 1'b0;
        slv_tx_shift_done_gen_dly   <= 1'b0;
    end
    else begin
        mst_tx_shift_done_gen_dly   <= mst_tx_shift_done_gen;
        slv_tx_shift_done_gen_dly   <= slv_tx_shift_done_gen;
    end
end

assign mst_tx_shift_done    = mst_tx_shift_done_gen & ~mst_tx_shift_done_gen_dly;
assign slv_tx_shift_done    = slv_tx_shift_done_gen & ~slv_tx_shift_done_gen_dly;

endmodule



