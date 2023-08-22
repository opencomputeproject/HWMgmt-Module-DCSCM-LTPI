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
///////////clk_25HMZ//////////////////////////////////////////////////////////////////////

// -------------------------------------------------------------------
// -- Author        : Katarzyna Krzewska
// -- Date          : July 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Management of GPIO interface
// -------------------------------------------------------------------

module mgmt_gpio 
import ltpi_pkg::*;
#(
    parameter NUM_OF_NL_GPIO    = 1024,
    parameter LL_GPIO_RST_VALUE = 16'hFF_FF, 
    parameter NL_GPIO_RST_VALUE =  {112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                    112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                    112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF,
                                    112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF, 112'hFF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF_FF}
)
(
    input wire                      clk,
    input wire                      reset,

    //signal from/to opertional frame managment
    input   logic   [  15:0]        ll_gpio_in,  //LOW LATANCY GPIO input tunneling through LVDS
    output  logic   [  15:0]        ll_gpio_out, //LOW LATANCY GPIO input tunneling through LVDS

    input           [(NUM_OF_NL_GPIO - 1):0]        nl_gpio_in,  //NORMAL LATANCY GPIO input tunneling through LVDS
    output reg      [(NUM_OF_NL_GPIO - 1):0]        nl_gpio_out, //NORMAL LATANCYGPIO output tunneling through LVDS
    
    //signal from/to opertional frame managment
    output logic    [ 1:0][ 7:0]    LL_GPIO_i,
    output logic    [ 1:0][ 7:0]    NL_GPIO_i,
    output logic    [ 7:0]          NL_GPIO_index_i,

    input logic     [ 6:0]          NL_GPIO_MAX_FRM_CNT,
    input logic     [ 7:0]          NL_GPIO_index_o,
    input logic     [ 1:0][ 7:0]    LL_GPIO_o,
    input logic     [ 1:0][ 7:0]    NL_GPIO_o,
    output logic                    NL_gpio_stable,

    //signals from phy managment
    input logic     [ 3:0]          rx_frm_offset,
    input logic     [ 3:0]          tx_frm_offset,

    input reg                      aligned,
    input reg                      frame_crc_err,
    input reg                      data_channel_req,

    input link_state_t             local_link_state,
    input link_state_t             remote_link_state
);

logic           gpio_i_sample_en;
logic           gpio_o_sample_en;
logic           gpio_i_sample_en_ff;
logic           gpio_i_sample_en_r_edge;

logic           NL_GPIO_index_i_increase;
logic           NL_GPIO_index_i_increase_ff;
logic           NL_GPIO_index_i_increase_r_edge;
logic [ 3:0]    rx_frm_offset_ff;
logic [ 6:0]    NL_GPIO_index_o_ff;

assign NL_GPIO_index_i_increase = aligned && (tx_frm_offset == frame_length) && (local_link_state == operational_st);
assign gpio_i_sample_en = aligned && (tx_frm_offset == 8'h01) && (local_link_state == operational_st);

always_ff @ (posedge clk) gpio_i_sample_en_ff <= gpio_i_sample_en;
assign gpio_i_sample_en_r_edge = ~gpio_i_sample_en_ff & gpio_i_sample_en;

always_ff @ (posedge clk) if(!data_channel_req) NL_GPIO_index_i_increase_ff <= NL_GPIO_index_i_increase;
assign NL_GPIO_index_i_increase_r_edge = ~NL_GPIO_index_i_increase_ff & NL_GPIO_index_i_increase;

always_ff @ (posedge clk) rx_frm_offset_ff <= rx_frm_offset;

always_ff @ (posedge clk) NL_GPIO_index_o_ff <= NL_GPIO_index_o;

//Low Latancy GPIO input management
always @ (posedge clk or posedge reset) begin
    if(reset) begin  
        LL_GPIO_i       <= LL_GPIO_RST_VALUE;
    end 
    else begin
        LL_GPIO_i[0]    <= ll_gpio_in[ 7:0];
        LL_GPIO_i[1]    <= ll_gpio_in[15:8];
    end
end

//Low Latancy GPIO output management
always @ (posedge clk or posedge reset) begin
    if(reset) begin  
        ll_gpio_out             <= '1;
    end 
    else begin
        if((local_link_state == operational_st) && (remote_link_state == operational_st)) begin
            if((gpio_o_sample_en) && (!frame_crc_err)) begin
                ll_gpio_out     <= {LL_GPIO_o[1] , LL_GPIO_o[0]};
            end
        end
    end
end

always @ (posedge clk or posedge reset) begin
    if(reset) begin
        NL_GPIO_index_i             <='0;
    end
    else begin
        if(NL_GPIO_index_i_increase_r_edge) begin
            if(NL_GPIO_MAX_FRM_CNT == 0) begin
                NL_GPIO_index_i     <= '0;
            end
            else if(NL_GPIO_index_i < (NL_GPIO_MAX_FRM_CNT - 6'd1)) begin
                NL_GPIO_index_i     <= NL_GPIO_index_i + 8'd1;
            end
            else if(NL_GPIO_index_i == (NL_GPIO_MAX_FRM_CNT- 6'd1)) begin
                NL_GPIO_index_i     <= '0;
            end
        end
    end
end

//Normla latancy GPIO input management
always @ (posedge clk or posedge reset)begin
    if(reset) begin 
        NL_GPIO_i       <='1;
    end 
    else begin 
        if(gpio_i_sample_en_r_edge) begin
            NL_GPIO_i   <= nl_gpio_in[NL_GPIO_index_i*16+:16];
        end 
    end
end

//Normla latancy GPIO output management
always @ (posedge clk or posedge reset)begin
    if(reset) begin 
        nl_gpio_out <= NL_GPIO_RST_VALUE;
    end 
    else begin 
        if((local_link_state == operational_st) && (remote_link_state == operational_st)) begin
            if((gpio_o_sample_en) && (!frame_crc_err)) begin
                nl_gpio_out[NL_GPIO_index_o*16+:16] <= NL_GPIO_o;
            end 
        end
    end
end

//GPIO handling
always @ (posedge clk or posedge reset) begin
    if(reset) begin  
        gpio_o_sample_en        <= 1'b0;
    end
    else begin
        if((local_link_state  == operational_st) && (rx_frm_offset_ff == (frame_length - 4'd1) && rx_frm_offset == frame_length)) begin
            gpio_o_sample_en    <= 1'b1;
        end
        else begin
            gpio_o_sample_en    <= 1'b0;
        end
    end
end

//Normal Latency GPIO Stable Indication
//Normal latency needs couple LTPI Frame to update the entire GPIO
//platform logic need to wait until NL_gpio_stable asserts before using GPIO_OUT
always @ (posedge clk or posedge reset) begin
    if(reset) begin  
        NL_gpio_stable <= 1'b0;
    end 
    else if((local_link_state == operational_st) && (remote_link_state == operational_st) ) begin
        if(NL_GPIO_index_o_ff == (NL_GPIO_MAX_FRM_CNT - 7'h1) &&  NL_GPIO_index_o == 7'h0) begin
            NL_gpio_stable <= 1'b1;
        end
        else begin
            NL_gpio_stable <= 1'b0;
        end
    end
end

endmodule