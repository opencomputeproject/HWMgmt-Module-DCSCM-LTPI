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
// -- Author        : Katarzyna Krzewska 
// -- Date          : Junuary 2023
// -- Project Name  : LTPI
// -- Description   : Read PLL configuration value from .sv file
// -- 

module m10_pll_reconfig_file 
(
    input   wire                clock,
    input   wire                reset,
    input   wire    [10:0]      address,

    input   wire                rden,
    output  logic               q
);

typedef struct packed{

    logic [7:0] M_cnt_low;
    logic       M_cnt_odd_div;
    logic [7:0] M_cnt_high;
    logic       M_cnt_bypass;

    logic [7:0] N_cnt_low;
    logic       N_cnt_odd_div;
    logic [7:0] N_cnt_high;
    logic       N_cnt_bypass;

    logic [2:0] charge_pump_current;
    logic [4:0] rsrv_2;
    logic       vco_post_scale;
    logic [4:0] loop_filter_res;
    logic [1:0] loop_filter_capac;
    logic [1:0] rsrv_1;
} PLL_reconfig_t;

typedef struct packed{

    logic [7:0] clk1_cnt_low;
    logic       clk1_odd_div;
    logic [7:0] clk1_cnt_high;
    logic       clk1_bypass;

    logic [7:0] clk0_cnt_low;
    logic       clk0_odd_div;
    logic [7:0] clk0_cnt_high;
    logic       clk0_bypass;

} PLL_CLK_reconfig_t;

typedef struct packed{

    logic [7:0] clk4_cnt_low;
    logic       clk4_odd_div;
    logic [7:0] clk4_cnt_high;
    logic       clk4_bypass;

    logic [7:0] clk3_cnt_low;
    logic       clk3_odd_div;
    logic [7:0] clk3_cnt_high;
    logic       clk3_bypass;

    logic [7:0] clk2_cnt_low;
    logic       clk2_odd_div;
    logic [7:0] clk2_cnt_high;
    logic       clk2_bypass;

} PLL_CLK_reconfig_const_t;

PLL_reconfig_t  PLL_reconfig;
PLL_CLK_reconfig_t [6:0] PLL_CLK_reconfig;
PLL_CLK_reconfig_const_t PLL_CLK_reconfig_const;

assign PLL_reconfig.rsrv_1                      = 0;
assign PLL_reconfig.loop_filter_capac           = 2'b11;//3;
assign PLL_reconfig.loop_filter_res             = 5'b1111_0;//15;
assign PLL_reconfig.vco_post_scale              = 1;
assign PLL_reconfig.rsrv_2                      = 0;
assign PLL_reconfig.charge_pump_current         = 3'b111;//7;
assign PLL_reconfig.N_cnt_bypass                = 0;
assign PLL_reconfig.N_cnt_high                  = 8'b1000_0000;//1;
assign PLL_reconfig.N_cnt_odd_div               = 0;
assign PLL_reconfig.N_cnt_low                   = 8'b1000_0000;//1;
assign PLL_reconfig.M_cnt_bypass                = 0;
assign PLL_reconfig.M_cnt_high                  = address[10:8] != 6 ? 8'b0000_1100 : 8'b0001_0100;//48 || 40;
assign PLL_reconfig.M_cnt_odd_div               = 0;
assign PLL_reconfig.M_cnt_low                   = address[10:8] != 6 ? 8'b0000_1100 : 8'b0001_0100;//48 || 40;

assign PLL_CLK_reconfig_const.clk2_bypass       = 1;
assign PLL_CLK_reconfig_const.clk2_cnt_high     = 8'b0001_1000;//24;
assign PLL_CLK_reconfig_const.clk2_odd_div      = 0;
assign PLL_CLK_reconfig_const.clk2_cnt_low      = 8'b0001_1000;//24;
assign PLL_CLK_reconfig_const.clk3_bypass       = 1;
assign PLL_CLK_reconfig_const.clk3_cnt_high     = 8'b0101_0000;//10;
assign PLL_CLK_reconfig_const.clk3_odd_div      = 0;
assign PLL_CLK_reconfig_const.clk3_cnt_low      = 8'b0101_0000;//10;
assign PLL_CLK_reconfig_const.clk4_bypass       = 1;
assign PLL_CLK_reconfig_const.clk4_cnt_high     = 0;
assign PLL_CLK_reconfig_const.clk4_odd_div      = 0;
assign PLL_CLK_reconfig_const.clk4_cnt_low      = 0;

assign PLL_CLK_reconfig[0].clk0_bypass          = 0;
assign PLL_CLK_reconfig[0].clk0_cnt_high        = 8'b0001_1000;//24;
assign PLL_CLK_reconfig[0].clk0_odd_div         = 0;
assign PLL_CLK_reconfig[0].clk0_cnt_low         = 8'b0001_1000;//24;
assign PLL_CLK_reconfig[0].clk1_bypass          = 0;
assign PLL_CLK_reconfig[0].clk1_cnt_high        = 8'b0001_1000;//24;
assign PLL_CLK_reconfig[0].clk1_odd_div         = 0;
assign PLL_CLK_reconfig[0].clk1_cnt_low         = 8'b0001_1000;//24;

assign PLL_CLK_reconfig[1].clk0_bypass          = 0;
assign PLL_CLK_reconfig[1].clk0_cnt_high        = 8'b0011_0000;//12;
assign PLL_CLK_reconfig[1].clk0_odd_div         = 0;
assign PLL_CLK_reconfig[1].clk0_cnt_low         = 8'b0011_0000;//12;
assign PLL_CLK_reconfig[1].clk1_bypass          = 0;
assign PLL_CLK_reconfig[1].clk1_cnt_high        = 8'b0011_0000;//12;
assign PLL_CLK_reconfig[1].clk1_odd_div         = 0;
assign PLL_CLK_reconfig[1].clk1_cnt_low         = 8'b0011_0000;//12;

assign PLL_CLK_reconfig[2].clk0_bypass          = 0;
assign PLL_CLK_reconfig[2].clk0_cnt_high        = 8'b0001_0000;//8;
assign PLL_CLK_reconfig[2].clk0_odd_div         = 0;
assign PLL_CLK_reconfig[2].clk0_cnt_low         = 8'b0001_0000;//8;
assign PLL_CLK_reconfig[2].clk1_bypass          = 0;
assign PLL_CLK_reconfig[2].clk1_cnt_high        = 8'b0001_0000;//8;
assign PLL_CLK_reconfig[2].clk1_odd_div         = 0;
assign PLL_CLK_reconfig[2].clk1_cnt_low         = 8'b0001_0000;//8;

assign PLL_CLK_reconfig[3].clk0_bypass          = 0;
assign PLL_CLK_reconfig[3].clk0_cnt_high        = 8'b0110_0000;//6;
assign PLL_CLK_reconfig[3].clk0_odd_div         = 0;
assign PLL_CLK_reconfig[3].clk0_cnt_low         = 8'b0110_0000;//6;
assign PLL_CLK_reconfig[3].clk1_bypass          = 0;
assign PLL_CLK_reconfig[3].clk1_cnt_high        = 8'b0110_0000;//6;
assign PLL_CLK_reconfig[3].clk1_odd_div         = 0;
assign PLL_CLK_reconfig[3].clk1_cnt_low         = 8'b0110_0000;//6;

assign PLL_CLK_reconfig[4].clk0_bypass          = 0;
assign PLL_CLK_reconfig[4].clk0_cnt_high        = 8'b0010_0000;//4;
assign PLL_CLK_reconfig[4].clk0_odd_div         = 0;
assign PLL_CLK_reconfig[4].clk0_cnt_low         = 8'b0010_0000;//4;
assign PLL_CLK_reconfig[4].clk1_bypass          = 0;
assign PLL_CLK_reconfig[4].clk1_cnt_high        = 8'b0010_0000;//4;
assign PLL_CLK_reconfig[4].clk1_odd_div         = 0;
assign PLL_CLK_reconfig[4].clk1_cnt_low         = 8'b0010_0000;//4;

assign PLL_CLK_reconfig[5].clk0_bypass          = 0;
assign PLL_CLK_reconfig[5].clk0_cnt_high        = 8'b1100_0000;//3;
assign PLL_CLK_reconfig[5].clk0_odd_div         = 0;
assign PLL_CLK_reconfig[5].clk0_cnt_low         = 8'b1100_0000;//3;
assign PLL_CLK_reconfig[5].clk1_bypass          = 0;
assign PLL_CLK_reconfig[5].clk1_cnt_high        = 8'b1100_0000;//3;
assign PLL_CLK_reconfig[5].clk1_odd_div         = 0;
assign PLL_CLK_reconfig[5].clk1_cnt_low         = 8'b1100_0000;//3;

//6-7 are the same , with diffrent M N settings 
assign PLL_CLK_reconfig[6].clk0_bypass          = 0;
assign PLL_CLK_reconfig[6].clk0_cnt_high        = 8'b0100_0000;//2;
assign PLL_CLK_reconfig[6].clk0_odd_div         = 0;
assign PLL_CLK_reconfig[6].clk0_cnt_low         = 8'b0100_0000;//2;
assign PLL_CLK_reconfig[6].clk1_bypass          = 0;
assign PLL_CLK_reconfig[6].clk1_cnt_high        = 8'b0100_0000;//2;
assign PLL_CLK_reconfig[6].clk1_odd_div         = 0;
assign PLL_CLK_reconfig[6].clk1_cnt_low         = 8'b0100_0000;//2;

logic [7:0] address_low;
logic [2:0] address_high;

//assign address_low  = address[7:0] < 8'h36 ? address[7:0] : address[7:0] - 8'h36;
typedef enum logic [1:0] {
    RD_CONF_FSM_IDLE,
    RD_CONF_FSM,
    RD_CONF_CLK_FSM,
    RD_CONF_CLK_CONST_FSM
} read_config_fsm_t;

read_config_fsm_t          read_config_fsm;

always @ (posedge clock or posedge reset) begin
    if(reset) begin
        q                               <= 0;
        address_low                     <= 0;
        address_high                    <= 0;
        read_config_fsm                 <= RD_CONF_FSM_IDLE;
    end
    else begin
        if(rden) begin
            case (read_config_fsm)
                RD_CONF_FSM_IDLE: begin
                    read_config_fsm     <= RD_CONF_FSM;
                    address_low         <= address[7:0];
                    address_high        <= address[10:8];
                end

                RD_CONF_FSM: begin
                    address_high        <= address[10:8];
                    q                   <= PLL_reconfig[address_low];

                    if(address_low < 8'h35) begin
                        address_low <= address[7:0];
                    end
                    else begin
                        address_low     <= address[7:0] - 8'h36;
                        read_config_fsm <= RD_CONF_CLK_FSM;
                        
                    end
                end

                RD_CONF_CLK_FSM: begin
                    case(address_high)
                        0: begin
                            q           <= PLL_CLK_reconfig[0][address_low];
                        end
                        1: begin
                            q           <= PLL_CLK_reconfig[1][address_low];
                        end
                        2: begin
                            q           <= PLL_CLK_reconfig[2][address_low];
                        end
                        3: begin
                            q           <= PLL_CLK_reconfig[3][address_low];
                        end
                        4: begin
                            q           <= PLL_CLK_reconfig[4][address_low];
                        end
                        5: begin
                            q           <= PLL_CLK_reconfig[5][address_low];
                        end
                        6: begin
                            q           <= PLL_CLK_reconfig[6][address_low];
                        end
                        7: begin //6-7 are the same , with diffrent M N settings 
                            q           <= PLL_CLK_reconfig[6][address_low];
                        end
                    endcase

                    if(address_low < 8'h23) begin
                        address_low     <= address[7:0] - 8'h36;
                    end
                    else begin
                        address_low     <= address[7:0] - 8'h5A;
                        read_config_fsm <= RD_CONF_CLK_CONST_FSM;
                    end
                end

                RD_CONF_CLK_CONST_FSM: begin
                    address_low <= address[7:0] - 8'h5A;
                    q           <= PLL_CLK_reconfig_const[address_low];
                end
            endcase
        end
        else  begin
            read_config_fsm     <= RD_CONF_FSM_IDLE;
            address_low         <= 0;
            address_high        <= 0;
            q                   <= 0;
        end
    end
end
endmodule