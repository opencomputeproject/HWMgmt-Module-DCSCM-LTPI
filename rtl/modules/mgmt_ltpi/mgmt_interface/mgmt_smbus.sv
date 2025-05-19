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
// -- Date          : August 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Management of SMBUS interface
// -------------------------------------------------------------------

module mgmt_smbus
import ltpi_pkg::*;
#(
    parameter NUM_OF_SMBUS_DEV  = 6,
    parameter CONTROLLER        = 0
)
(
    input wire                  clk,
    input wire                  reset,

    //signals from/to pins
    inout             [ (NUM_OF_SMBUS_DEV - 1):0]    smb_scl,        //I2C interfaces tunneling through LVDS 
    inout             [ (NUM_OF_SMBUS_DEV - 1):0]    smb_sda,

    //signal from/to opertional frame managment
    input wire  [ 5:0][ 3:0]    i2c_event_i,
    output wire [ 5:0][ 3:0]    i2c_event_o,

    //signals from phy managment
    input logic       [ 5:0]    soft_i2c_channel_rst,
    input logic                 DDR_MODE,
    input link_speed_t          link_speed,
    input logic       [ 3:0]    tx_frm_offset,
    input LTPI_Capabilites_t    config_capabilites,
    input link_state_t          local_link_state,
    input link_state_t          remote_link_state,

    //Debug
    output logic [5:0][31:0] smb_dbg_cntrl_controller_smbstate,
    output logic [5:0][31:0] smb_dbg_cntrl_relay_state,
    output logic [5:0][19:0] smb_dbg_cntrl_relay_event_ioc_frame_bus,

    output logic [5:0][31:0] smb_dbg_trg_controller_smbstate,
    output logic [5:0][31:0] smb_dbg_trg_relay_state,
    output logic [5:0][19:0] smb_dbg_trg_relay_event_ioc_frame_bus,
    output logic [5:0][31:0] smb_dbg_recovery_cnt
);

wire   [ 5:0]           relay_scl_i;
wire   [ 5:0]           relay_sda_i;
wire   [ 5:0]           relay_scl_en;
wire   [ 5:0]           relay_sda_en;
wire   [ 5:0]           i2c_channel_timeout;
logic  [ 5:0][3:0]      i2c_event_o_array;
logic  [ 5:0][3:0]      i2c_event_i_echo_array;
logic  [ 5:0][3:0]      i2c_event_o_echo_array;
logic                   smb_relay_reset;
logic  [ 5:0]           smbus_rst_n;
logic  [ 5:0]           smbus_timeout;

assign i2c_event_o = i2c_event_o_echo_array;

genvar i;
generate 
for(i = 0; i < 6; i = i+1) begin : SMBus
    
    if( i < NUM_OF_SMBUS_DEV) begin
        assign smb_scl[i]       = relay_scl_en[i] ? 1'b0 : 1'bz;
        assign relay_scl_i[i]   = smb_scl[i];
        assign smb_sda[i]       = relay_sda_en[i] ? 1'b0 : 1'bz;
        assign relay_sda_i[i]   = smb_sda[i];
        assign smbus_rst_n[i]   = !reset & !soft_i2c_channel_rst[i] & !smb_relay_reset; //

        if(CONTROLLER) begin
            smbus_relay_controller 
            #(
                .CLOCK_PERIOD_PS        (16666         )     // 60MHZ //Period of the input 'clock', in picoseconds (default 10,000 ps = 100 MHz) 
            )
            smbus_relay_controller_0 (
                .clock                                  (clk                                    ),  // 60MHZ // controller clock for this block                                              
                .i_resetn                               (smbus_rst_n[i]                         ),  // controller reset, must be de-asserted synchronously with clock                                                                                                                     
                .bus_speed                              (config_capabilites.I2C_channel_cpbl[i] ),
                .ioc_frame_i                            (i2c_event_i_echo_array[i]              ),
                .ioc_frame_o                            (i2c_event_o_array[i]                   ), 
                .ia_controller_scl                      (relay_scl_i[i]                         ),   // asynchronous input from the SCL pin of the controller interface
                .o_controller_scl_oe                    (relay_scl_en[i]                        ),   // when asserted, drive the SCL pin of the controller interface low
                .ia_controller_sda                      (relay_sda_i[i]                         ),   // asynchronous input from the SDA pin of the controller interface
                .o_controller_sda_oe                    (relay_sda_en[i]                        ),   // when asserted, drive the SDA pin of the controller interface low
                .stretch_timeout                        (i2c_channel_timeout[i]                 ),
                .tx_frm_offset                          (tx_frm_offset                          ),
                .smbus_timeout                          (smbus_timeout[i]                       ),
                .dbg_cntrl_controller_smbstate          (smb_dbg_cntrl_controller_smbstate[i]   ),
                .dbg_cntrl_relay_state                  (smb_dbg_cntrl_relay_state[i]           )
            );
            assign smb_dbg_recovery_cnt[i] = 32'hA0A0_A0A0;
            assign smb_dbg_cntrl_relay_event_ioc_frame_bus[i] = {i2c_event_i[i], i2c_event_o[i], i2c_event_i_echo_array[i], i2c_event_o_array[i], relay_scl_en[i], relay_sda_en[i], relay_scl_i[i], relay_sda_i[i]};
        end 
        else begin
            smbus_relay_target 
            #(
                .CLOCK_PERIOD_PS        ( 16666         )   // 60MHZ //Period of the input 'clock', in picoseconds (default 10,000 ps = 100 MHz) 
            )          
            smbus_relay_target_0 (
                .clock                              (clk                                    ), // 60MHZ
                .i_resetn                           (smbus_rst_n[i]                         ), 
                .bus_speed                          (config_capabilites.I2C_channel_cpbl[i] ),
                .ioc_frame_i                        (i2c_event_i_echo_array[i]              ),
                .ioc_frame_o                        (i2c_event_o_array[i]                   ),
                .ia_controller_scl                  (relay_scl_i[i]                         ),
                .o_controller_scl_oe                (relay_scl_en[i]                        ),
                .ia_controller_sda                  (relay_sda_i[i]                         ),
                .o_controller_sda_oe                (relay_sda_en[i]                        ),
                .stretch_timeout                    (i2c_channel_timeout[i]                 ),
                .tx_frm_offset                      (tx_frm_offset                          ),
                .smbus_timeout                      (smbus_timeout[i]                       ),
                .dbg_trg_controller_smbstate        (smb_dbg_trg_controller_smbstate[i]     ),
                .dbg_trg_relay_state                (smb_dbg_trg_relay_state[i]             ),
                .dbg_recovery_cnt                   (smb_dbg_recovery_cnt[i]                )
            );

            assign smb_dbg_trg_relay_event_ioc_frame_bus[i] = {i2c_event_i[i], i2c_event_o[i], i2c_event_i_echo_array[i], i2c_event_o_array[i], relay_scl_en[i], relay_sda_en[i], relay_scl_i[i], relay_sda_i[i]};
        end //if_CONTROLLER

        smbus_echo smbus_echo_inst
        (
            .clk                        (clk                                    ),
            .reset                      (!smbus_rst_n[i] | smbus_timeout[i]     ),

            .i2c_event_i_array          (i2c_event_i[i]                         ),
            .i2c_event_o_echo_array     (i2c_event_o_echo_array[i]              ),

            .i2c_event_o_array          (i2c_event_o_array[i]                   ),
            .i2c_event_i_echo_array     (i2c_event_i_echo_array[i]              ),
            .DDR_MODE                   (DDR_MODE                               ),
            .link_speed                 (link_speed                             ),
            .echo_en                    (config_capabilites.I2C_Echo_support    )
        
        );
    end
    else begin
        assign i2c_event_o_echo_array[i] = 0;
    end
end//for
endgenerate

//Keep SMBUS Relay in reset while devices are not in operational state 
always @ (posedge clk or posedge reset) begin
    if(reset) begin
        smb_relay_reset <= 1'b1;
    end
    else begin
        if(local_link_state == operational_st && remote_link_state == operational_st) begin
            smb_relay_reset <= 1'b0;
        end
        else begin
            smb_relay_reset <= 1'b1;
        end
    end
end
endmodule