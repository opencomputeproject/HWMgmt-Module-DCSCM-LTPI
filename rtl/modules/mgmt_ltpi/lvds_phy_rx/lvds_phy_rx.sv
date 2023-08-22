/////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2022 Intel Corporation
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
/////////////////////////////////////////////////////////////////////////////////

// -------------------------------------------------------------------
// -- Author        : Reid McClain, Katarzyna Krzewska
// -- Date          : July 2022
// -- Project Name  : LTPI
// -- Description   :
// -- LVDS Phy Rx Implementation based on Nodlink project (author Reid McClain)
// -------------------------------------------------------------------


module lvds_phy_rx
#(
    parameter CYCLONE_V = 0
)
(
    input wire          clk,
    input wire          reset_phy,

    input wire          LVDS_DDR,

    // Parallel encoded data out
    output reg          phy_rx_dv,
    output reg  [ 9:0]  phy_rx_out,

    // nodelink interface signals
    input  wire         lvds_rx_data,
    input  wire         lvds_rx_clk,
    input  wire         sm_symbol_locked,
    output reg          rx_symbol_locked,
    input wire          frame_correct

);

// localparam K28_5P = 10'b10_1000_0011;//283
// localparam K28_5N = 10'b01_0111_1100;//17C

// localparam K28_6P = 10'b10_0100_0011;//243
// localparam K28_6N = 10'b01_1011_1100;//1BC

localparam K28_5P = 10'b11_0000_0101;
localparam K28_5N = 10'b00_1111_1010;

localparam K28_6P = 10'b11_0000_1001;
localparam K28_6N = 10'b00_1111_0110;


// state machine states 
localparam  SYMLOCK_UNLOCKED     = 2'h0;
localparam  SYMLOCK_TX_K28_5     = 2'h1;
localparam  SYMLOCK_SEARCH       = 2'h2;
localparam  SYMLOCK_SYMLOCK      = 2'h3;

// internal logic signals
reg [1:0] sl_state ;//= SYMLOCK_UNLOCKED;

// phy clk - clk link clock 
//reg  [ 9:0] rx_data         = 10'h0 /* synthesis syn_noprune */;
wire [ 1:0] lvds_data_ddr;

logic reset;
always_ff @(posedge clk) reset <= reset_phy;
// RX PHY: DDR input cell
//
// Instantiate DDR input macro to capture input signal using
// received clock (90 degree shift provided by transmitter)
//
 generate
    if (CYCLONE_V == 1) 
    begin: gen_cyclone_v
        alt_ddio_in alt_ddio_in (
            .aclr      (1'b0),
            .datain    (lvds_rx_data),
            .inclock   (lvds_rx_clk),
            .dataout_h (lvds_data_ddr[0]),
            .dataout_l (lvds_data_ddr[1])
        );
    end
    else
    begin: gen_max_10
        // MAX 10 IO Bank 3 does not support DDIO, banks 5/6 do support DDIO
        gpio_ddr_in gpio_ddr_in (
            .pad_in    (lvds_rx_data),
            .inclock   (lvds_rx_clk),
            .dout      ({lvds_data_ddr[0], lvds_data_ddr[1]})
        );
    end
endgenerate

wire [ 7:0]  fast_fifo_data_100;
wire [ 7:0]  fast_fifo_data_100_swap;
wire         fast_fifo_re_100;
wire         fast_fifo_mt_100;
reg  [ 1:0]  lvds_data_ddr_1d = 2'b0;

// Pipeline 1/2 cycle path
always @ (posedge lvds_rx_clk)
    lvds_data_ddr_1d <= lvds_data_ddr;

// CDC FIFO
// Minimize number of loads on lvds_rx_clk
//
// Write 2 bits @ DDR link clock Line clock
// Read  8 bits @ SDR link clock, 50% duty cycle
//
logic wrfull;
logic wrreq;

 assign wrreq = ~wrfull;

lvds_2to8bit_fifo_m10 lvds_2to8bit_fifo_m10 
(
    // Write side
    .wrclk        (lvds_rx_clk),
    .wrreq        (wrreq),
    .data         (lvds_data_ddr_1d),
    .wrfull       (wrfull),
    // Read side
    .rdclk        (clk),
    .rdreq        (fast_fifo_re_100),
    .q            (fast_fifo_data_100_swap),
    .rdempty      (fast_fifo_mt_100),
    
    .rdusedw      (),
    .wrusedw      (),
    .aclr         ()
);

reg [39:0]  last_four_symbols_100;
reg [48:0]  symbol_shifter_100;
reg [ 3:0]  eight_to_forty_cntr_100;
wire        symbol_shifter_we_100;

assign fast_fifo_re_100   = ~fast_fifo_mt_100;

assign fast_fifo_data_100 = LVDS_DDR ?  {fast_fifo_data_100_swap[1:0], fast_fifo_data_100_swap[3:2],fast_fifo_data_100_swap[5:4], fast_fifo_data_100_swap[7:6]}
                                        : {fast_fifo_data_100_swap[0], fast_fifo_data_100_swap[2],fast_fifo_data_100_swap[4], fast_fifo_data_100_swap[6]};

// 4 bit to 40 bit counter
//  Count from 0 to 4, write every 5th cycle to symbol shifter
always @ (posedge clk or posedge reset) begin
//always @ (posedge clk ) begin
    if (reset) begin
        eight_to_forty_cntr_100    <= '0;
    end 
    else begin
        if (fast_fifo_re_100 == 1'b1)begin
            if (symbol_shifter_we_100)begin
                eight_to_forty_cntr_100 <= 4'h0;
            end
            else begin
                eight_to_forty_cntr_100 <= eight_to_forty_cntr_100 + 1'b1;
            end
        end
    end
end

assign symbol_shifter_we_100 = eight_to_forty_cntr_100 == 4'h4 & fast_fifo_re_100;

// last four symbols 
always @ (posedge clk or posedge reset) begin
    if (reset) begin
        last_four_symbols_100    <= 40'h0; 
    end 
    else begin
        if(LVDS_DDR) begin
            if (fast_fifo_re_100) begin
                last_four_symbols_100 <= {last_four_symbols_100[31:0], fast_fifo_data_100[7:0]};
            end
        end
        else begin
            if (fast_fifo_re_100) begin
                last_four_symbols_100 <= {last_four_symbols_100[15:0], fast_fifo_data_100[3:0]};
            end
        end
    end
end


logic [9:0] k28_5_matched;
// symbol shifter (holding register) - 
//   symbol alignment performed on this data
//   symbol generation from this data
//   only need 40 bits plus 9
always @ (posedge clk or posedge reset ) begin
    if (reset) begin
        symbol_shifter_100 <= '0;
    end
    else begin 
        if(LVDS_DDR) begin
            if (symbol_shifter_we_100 ) begin 
                symbol_shifter_100 <= {symbol_shifter_100[8:0], last_four_symbols_100[39:0]};
            end
        end
        else begin
            if (symbol_shifter_we_100) begin
                symbol_shifter_100 <= {symbol_shifter_100[15:0], last_four_symbols_100[19:0]};
            end
        end
    end
end


typedef enum logic[1:0] {
    ST_INIT             = 2'd0,
    ST_MATCH_SYMBOL     = 2'd1,
    ST_MATCHED          = 2'd2
} state_t;
state_t state;

logic [48:0] symbol_shifter;
logic [2:0] shift;
logic [2:0] BIT_SHIFT_CNT; 

always @ (posedge clk or posedge reset ) begin
    if (reset) begin
        k28_5_matched   <= 0;
        shift           <= 0;
        state           <= ST_INIT;
        BIT_SHIFT_CNT   <= 3;
    end
    else begin 

        case (state)
            ST_INIT: begin
                k28_5_matched               <= 0;
                shift                       <= 0;
                if (eight_to_forty_cntr_100 == 4'd4 ) begin
                    state                   <= ST_MATCH_SYMBOL;
                    shift                   <= 1;
                    //symbol_shifter          <= last_four_symbols_100[18:0];
                    if(LVDS_DDR) begin
                        symbol_shifter  <= {symbol_shifter_100[8:0], last_four_symbols_100[39:0]};
                        BIT_SHIFT_CNT   <= 5; 
                    end
                    else begin
                        symbol_shifter  <= {symbol_shifter_100[15:0], last_four_symbols_100[19:0]};
                        BIT_SHIFT_CNT   <= 3; 
                    end

                end
            end
            ST_MATCH_SYMBOL: begin
                if (k28_5_matched) begin
                    state               <= ST_MATCHED;
                end
                else if(shift == BIT_SHIFT_CNT) begin
                    state               <= ST_INIT;
                end
                else begin
                    k28_5_matched [ 0] <= (symbol_shifter[09: 0] == K28_5P) || (symbol_shifter[09: 0] == K28_5N) || (symbol_shifter[09: 0] == K28_6P) || (symbol_shifter[09: 0] == K28_6N); 
                    k28_5_matched [ 1] <= (symbol_shifter[10: 1] == K28_5P) || (symbol_shifter[10: 1] == K28_5N) || (symbol_shifter[10: 1] == K28_6P) || (symbol_shifter[10: 1] == K28_6N); 
                    k28_5_matched [ 2] <= (symbol_shifter[11: 2] == K28_5P) || (symbol_shifter[11: 2] == K28_5N) || (symbol_shifter[11: 2] == K28_6P) || (symbol_shifter[11: 2] == K28_6N); 
                    k28_5_matched [ 3] <= (symbol_shifter[12: 3] == K28_5P) || (symbol_shifter[12: 3] == K28_5N) || (symbol_shifter[12: 3] == K28_6P) || (symbol_shifter[12: 3] == K28_6N); 
                    k28_5_matched [ 4] <= (symbol_shifter[13: 4] == K28_5P) || (symbol_shifter[13: 4] == K28_5N) || (symbol_shifter[13: 4] == K28_6P) || (symbol_shifter[13: 4] == K28_6N); 
                    k28_5_matched [ 5] <= (symbol_shifter[14: 5] == K28_5P) || (symbol_shifter[14: 5] == K28_5N) || (symbol_shifter[14: 5] == K28_6P) || (symbol_shifter[14: 5] == K28_6N); 
                    k28_5_matched [ 6] <= (symbol_shifter[15: 6] == K28_5P) || (symbol_shifter[15: 6] == K28_5N) || (symbol_shifter[15: 6] == K28_6P) || (symbol_shifter[15: 6] == K28_6N); 
                    k28_5_matched [ 7] <= (symbol_shifter[16: 7] == K28_5P) || (symbol_shifter[16: 7] == K28_5N) || (symbol_shifter[16: 7] == K28_6P) || (symbol_shifter[16: 7] == K28_6N); 
                    k28_5_matched [ 8] <= (symbol_shifter[17: 8] == K28_5P) || (symbol_shifter[17: 8] == K28_5N) || (symbol_shifter[17: 8] == K28_6P) || (symbol_shifter[17: 8] == K28_6N); 
                    k28_5_matched [ 9] <= (symbol_shifter[18: 9] == K28_5P) || (symbol_shifter[18: 9] == K28_5N) || (symbol_shifter[18: 9] == K28_6P) || (symbol_shifter[18: 9] == K28_6N); 
                    
                    symbol_shifter <= (symbol_shifter >> 10);
                    shift <= shift + 1;
                end
            end
            ST_MATCHED: begin
                if (sl_state == SYMLOCK_SYMLOCK ) begin
                end
                else begin
                    state               <= ST_INIT;
                end
            end
            default: begin
                state               <= ST_INIT;
            end

        endcase
    end
end
// Link clock div 2 domain logic
//  Convert DDR link clock Mpbs data (8 bits @ 100 Mhz local clock, 50 % duty cycle)
//
// eight_to_forty_cntr_100
// 0 - store forty bits into holding register
// 1 - symbol 0 data valid
// 2 - symbol 1 data valid
// 3 - symbol 2 data valid
// 4 - symbol 3 data valid

reg   [ 9:0]    symbol_0;
reg   [ 9:0]    symbol_1;
reg   [ 9:0]    symbol_2;
reg   [ 9:0]    symbol_3;

// Select 4 symbols based on fifo counter
always @ (posedge clk or posedge reset) begin
    if (reset) begin
        phy_rx_out <= 10'b0;
        phy_rx_dv  <= 1'b0;
    end
    else begin
        if(LVDS_DDR) begin
            if (eight_to_forty_cntr_100 == 4'd1 & fast_fifo_re_100) begin
                phy_rx_out <= symbol_0;
                phy_rx_dv  <= 1'b1;
            end
            else if (eight_to_forty_cntr_100 == 4'd2 & fast_fifo_re_100) begin
                phy_rx_out <= symbol_1;
                phy_rx_dv  <= 1'b1;
            end
            else if (eight_to_forty_cntr_100 == 4'd3 & fast_fifo_re_100) begin
                phy_rx_out <= symbol_2;
                phy_rx_dv  <= 1'b1;
            end
            else if (eight_to_forty_cntr_100 == 4'd4 & fast_fifo_re_100) begin
                phy_rx_out <= symbol_3;
                phy_rx_dv  <= 1'b1;
            end
            else begin
                phy_rx_out <= phy_rx_out;
                phy_rx_dv  <= 1'b0;
            end
        end
        else begin
            if (eight_to_forty_cntr_100 == 4'd1 & fast_fifo_re_100) begin
                phy_rx_out <= symbol_0;
                phy_rx_dv  <= 1'b1;
            end
            else if (eight_to_forty_cntr_100 == 4'd3 & fast_fifo_re_100) begin
                phy_rx_out <= symbol_1;
                phy_rx_dv  <= 1'b1;
            end
            else begin
                phy_rx_out <= phy_rx_out;
                phy_rx_dv  <= 1'b0;
            end
        end
    end
end

`define SHIFTER_DDR(offset) \
symbol_3 <= {symbol_shifter_100[ 0 + ``offset``],symbol_shifter_100[ 1 + ``offset``],symbol_shifter_100[ 2 + ``offset``],symbol_shifter_100[ 3 + ``offset``],symbol_shifter_100[ 4 + ``offset``],\
             symbol_shifter_100[ 5 + ``offset``],symbol_shifter_100[ 6 + ``offset``],symbol_shifter_100[ 7 + ``offset``],symbol_shifter_100[ 8 + ``offset``],symbol_shifter_100[ 9 + ``offset``]};\
symbol_2 <= {symbol_shifter_100[10 + ``offset``],symbol_shifter_100[11 + ``offset``],symbol_shifter_100[12 + ``offset``],symbol_shifter_100[13 + ``offset``],symbol_shifter_100[14 + ``offset``],\
             symbol_shifter_100[15 + ``offset``],symbol_shifter_100[16 + ``offset``],symbol_shifter_100[17 + ``offset``],symbol_shifter_100[18 + ``offset``],symbol_shifter_100[19 + ``offset``]};\
symbol_1 <= {symbol_shifter_100[20 + ``offset``],symbol_shifter_100[21 + ``offset``],symbol_shifter_100[22 + ``offset``],symbol_shifter_100[23 + ``offset``],symbol_shifter_100[24 + ``offset``],\
             symbol_shifter_100[25 + ``offset``],symbol_shifter_100[26 + ``offset``],symbol_shifter_100[27 + ``offset``],symbol_shifter_100[28 + ``offset``],symbol_shifter_100[29 + ``offset``]};\
symbol_0 <= {symbol_shifter_100[30 + ``offset``],symbol_shifter_100[31 + ``offset``],symbol_shifter_100[32 + ``offset``],symbol_shifter_100[33 + ``offset``],symbol_shifter_100[34 + ``offset``],\
             symbol_shifter_100[35 + ``offset``],symbol_shifter_100[36 + ``offset``],symbol_shifter_100[37 + ``offset``],symbol_shifter_100[38 + ``offset``],symbol_shifter_100[39 + ``offset``]};\

`define SHIFTER_SDR(offset) \
symbol_1 <= {symbol_shifter_100[ 0 + ``offset``],symbol_shifter_100[ 1 + ``offset``],symbol_shifter_100[ 2 + ``offset``],symbol_shifter_100[ 3 + ``offset``],symbol_shifter_100[ 4 + ``offset``],\
             symbol_shifter_100[ 5 + ``offset``],symbol_shifter_100[ 6 + ``offset``],symbol_shifter_100[ 7 + ``offset``],symbol_shifter_100[ 8 + ``offset``],symbol_shifter_100[ 9 + ``offset``]};\
symbol_0 <= {symbol_shifter_100[10 + ``offset``],symbol_shifter_100[11 + ``offset``],symbol_shifter_100[12 + ``offset``],symbol_shifter_100[13 + ``offset``],symbol_shifter_100[14 + ``offset``],\
             symbol_shifter_100[15 + ``offset``],symbol_shifter_100[16 + ``offset``],symbol_shifter_100[17 + ``offset``],symbol_shifter_100[18 + ``offset``],symbol_shifter_100[19 + ``offset``]};\


// Registered Mux
always @ (posedge clk or posedge reset) begin
    if (reset)begin
        symbol_3 <= 10'h0;
        symbol_2 <= 10'h0;
        symbol_1 <= 10'h0;
        symbol_0 <= 10'h0;
    end
    else begin
        //if (LVDS_DDR & eight_to_forty_cntr_100 == 4'd0) begin
        if (LVDS_DDR ) begin
            if (k28_5_matched[0]) begin
                `SHIFTER_DDR(0)
            end
            else if (k28_5_matched[1]) begin
                `SHIFTER_DDR(1)
            end
            else if (k28_5_matched[2]) begin
                `SHIFTER_DDR(2)
            end
            else if (k28_5_matched[3]) begin
                `SHIFTER_DDR(3)
            end
            else if (k28_5_matched[4]) begin
                `SHIFTER_DDR(4)
            end
            else if (k28_5_matched[5]) begin
                `SHIFTER_DDR(5)
            end
            else if (k28_5_matched[6]) begin
                `SHIFTER_DDR(6)
            end
            else if (k28_5_matched[7]) begin
                `SHIFTER_DDR(7)
            end
            else if (k28_5_matched[8]) begin
                `SHIFTER_DDR(8)
            end
            else if (k28_5_matched[9]) begin
                `SHIFTER_DDR(9)
            end
            else begin
                `SHIFTER_DDR(0)
            end
        end
        //else if( eight_to_forty_cntr_100 == 4'd0) begin
        else begin
            if (k28_5_matched[0]) begin
                `SHIFTER_SDR(0)
            end
            else if (k28_5_matched[1]) begin
                `SHIFTER_SDR(1)
            end
            else if (k28_5_matched[2]) begin
                `SHIFTER_SDR(2)
            end
            else if (k28_5_matched[3]) begin
                `SHIFTER_SDR(3)
            end
            else if (k28_5_matched[4]) begin
                `SHIFTER_SDR(4)
            end
            else if (k28_5_matched[5]) begin
                `SHIFTER_SDR(5)
            end
            else if (k28_5_matched[6]) begin
                `SHIFTER_SDR(6)
            end
            else if (k28_5_matched[7]) begin
                `SHIFTER_SDR(7)
            end
            else if (k28_5_matched[8]) begin
                `SHIFTER_SDR(8)
            end
            else if (k28_5_matched[9]) begin
                `SHIFTER_SDR(9)
            end
            else begin
                `SHIFTER_SDR(0)
            end
            
        end
    end
end

// SYMBOL Lock state machine
//
// SYMLOCK_UNLOCKED
// Enter unlocked state on reset
//
// SYMLOCK_SEARCH
// Exit unlocked state and go to SYMLOCK_SEARCH state
//  Wait for k28_5_match to assert, enter SYMLOCK_SYMLOCK
//
// SYMLOCK_SYMLOCK
// Exit SYMLOCK_SEARCH and enter SYMLOCK_SYMLOCK state
//  Stay here until we either lose sync (reset ) or catched frame is not corect.  
//  If we lose sync,go to SYMLOCK_UNLOCKED
//

always @ (posedge clk) begin
    if (reset) begin
        // default outputs
        sl_state         <= SYMLOCK_UNLOCKED;
        rx_symbol_locked <= 1'b0;
    end
    else
        case(sl_state)
            SYMLOCK_UNLOCKED: begin
                rx_symbol_locked <= 1'b0;
                sl_state         <= SYMLOCK_SEARCH;
            end
            SYMLOCK_SEARCH: begin
                rx_symbol_locked <= 1'b0;
                //Enter symlock state on find any K28_5 symbol
                if(k28_5_matched) begin
                    sl_state <= SYMLOCK_SYMLOCK;
                end
            end
            SYMLOCK_SYMLOCK: begin

                if(shift == 2) begin
                    if(LVDS_DDR) begin
                        if(eight_to_forty_cntr_100 == 4'd4) begin
                            rx_symbol_locked <= 1'b1;
                        end
                    end
                    else begin
                        if(eight_to_forty_cntr_100 == 4'd3) begin
                            rx_symbol_locked <= 1'b1;
                        end
                    end
                end
                else if (shift == 3 ) begin
                    if(LVDS_DDR) begin
                        if(eight_to_forty_cntr_100 == 4'd3) begin//3
                            rx_symbol_locked <= 1'b1;
                        end
                    end
                    else begin
                        if(eight_to_forty_cntr_100 == 4'd1) begin
                            rx_symbol_locked <= 1'b1;
                        end
                    end
                end
                else if (shift == 4 ) begin
                    if(eight_to_forty_cntr_100 == 4'd2) begin
                        rx_symbol_locked <= 1'b1;
                    end
                end
                else if (shift == 5 ) begin
                    if(eight_to_forty_cntr_100 == 4'd1) begin
                        rx_symbol_locked <= 1'b1;
                    end
                end

                if (~frame_correct) begin
                    rx_symbol_locked <= 1'b0;
                    sl_state         <= SYMLOCK_UNLOCKED;
                end
            end
            default: begin
                rx_symbol_locked    <= 1'b0;
                sl_state            <= SYMLOCK_UNLOCKED;
            end
    endcase // case(sl_state)
end

endmodule