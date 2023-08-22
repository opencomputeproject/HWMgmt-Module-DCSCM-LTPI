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
// -- Management of UART interface
// -------------------------------------------------------------------

module mgmt_uart 
import ltpi_pkg::*;
#(
    parameter NUM_OF_UART_DEV  = 2,
    parameter DROP_SAMPLES_ON_CRC_ERROR = 1
)
(
    input wire                                  clk,
    input wire                                  reset,
    
    //signals from/to pins
    input           [ (NUM_OF_UART_DEV - 1):0]          uart_rxd, //UART interfaces tunneling through LVDS
    input           [ (NUM_OF_UART_DEV - 1):0]          uart_cts, //Clear To Send
    output reg      [ (NUM_OF_UART_DEV - 1):0]          uart_txd,
    output reg      [ (NUM_OF_UART_DEV - 1):0]          uart_rts, //Request To Send

    //signal from/to opertional frame managment
    output  reg     [ 1:0][3:0]     uart_i_array,
    input   wire    [ 1:0][3:0]     uart_o_array,

    //signals from phy managment
    input logic     [ 3:0]          rx_frm_offset,
    input logic     [ 3:0]          tx_frm_offset,
    input LTPI_Capabilites_t        config_capabilites,
    input link_state_t              local_link_state,
    input link_state_t              remote_link_state,
    input wire                      frame_crc_err
);

reg [ (NUM_OF_UART_DEV - 1):0]             uart_rxd_synced_0; 
reg [ (NUM_OF_UART_DEV - 1):0]             uart_rxd_synced_1;
reg [ (NUM_OF_UART_DEV - 1):0]             uart_rxd_synced_2;
reg [              3:0]             rx_frm_offset_ff;
reg [              1:0][3:0]        uart_o_array_buf;

always_ff @ (posedge clk) rx_frm_offset_ff <= rx_frm_offset;

//Generate input and output uart array
genvar j;
generate
    if(NUM_OF_UART_DEV == 0) begin
        assign uart_i_array = {4'h7,4'h7};
    end
    else begin
        for ( j = 0; j < 2 ; j = j+1 ) begin: UART
            if( j < NUM_OF_UART_DEV) begin
                always @ (posedge clk or posedge reset) begin
                    if(reset) begin
                        uart_i_array[j] <= 4'h7;
                    end 
                    else begin
                        if(local_link_state == operational_st && remote_link_state == operational_st)begin
                            if(tx_frm_offset == 11) begin 
                                if(config_capabilites.UART_Flow_ctrl) begin
                                    uart_i_array[j] <= {uart_cts[j], uart_rxd_synced_2[j], uart_rxd_synced_1[j], uart_rxd_synced_0[j]};
                                end
                                else begin
                                    uart_i_array[j] <= { 1'b0, uart_rxd_synced_2[j], uart_rxd_synced_1[j], uart_rxd_synced_0[j]};
                                end
                            end
                        end 
                        else begin //when not aligned, send 4'h7 to the other side and output txd tp 1'b1 and rts to 1'b0
                            uart_i_array[j] <= 4'h7;
                        end
                    end
                end
                //UART data are recived as 7th frame byte (rx_offset = 8) to make sure the data are correct, 
                //we start generate UART signal from rx_offset = 8
                always @ (posedge clk or posedge reset) begin
                    if(reset) begin
                        uart_txd[j]         <= 1'b1; //reset value for rts should be high value
                        uart_rts[j]         <= 1'b0; //reset value for rts should be low value
                    end 
                    else begin
                        if(local_link_state == operational_st && remote_link_state == operational_st) begin
                            if(rx_frm_offset_ff == 4'd8) begin 
                                uart_txd[j] <= uart_o_array_buf[j][0];
                                uart_rts[j] <= uart_o_array_buf[j][3];
                            end
                            if(rx_frm_offset_ff == 4'd13) begin
                                uart_txd[j] <= uart_o_array_buf[j][1];
                            end
                            if(rx_frm_offset_ff == 4'd2) begin
                                uart_txd[j] <= uart_o_array_buf[j][2];
                            end
                        end 
                        else begin //when not aligned, send 4'h7 to the other side and output txd tp 1'b1 and rts to 1'b0
                            uart_txd[j]     <= 1'b1;
                            uart_rts[j]     <= 1'b0; 
                        end
                    end
                end
            end
            else begin
                assign uart_i_array[j] = 4'h7;
            end
        end //for
    end
endgenerate

logic CRC_corect = 0;

typedef enum logic [1:0] {
    CRC_FSM_IDLE,
    CRC_FSM_ERR,
    CRC_FSM_OK
} crc_fsm_t;

crc_fsm_t          crc_fsm;

generate begin: uart_error_handling
    if(DROP_SAMPLES_ON_CRC_ERROR) begin
        always @ (posedge clk or posedge reset) begin
            if(reset) begin
                uart_o_array_buf        <= '1;
                crc_fsm                 <= CRC_FSM_IDLE;
            end 
            else begin 
                case(crc_fsm) 
                    CRC_FSM_IDLE: begin
                        if(rx_frm_offset_ff == frame_length) begin
                            if(frame_crc_err) begin
                                crc_fsm <= CRC_FSM_ERR;
                            end
                            else begin
                                crc_fsm <= CRC_FSM_OK;
                            end
                        end
                    end
                    CRC_FSM_ERR: begin
                        if(rx_frm_offset_ff == 6) begin
                            crc_fsm     <= CRC_FSM_IDLE;
                        end
                    end
                    CRC_FSM_OK: begin
                        if(rx_frm_offset_ff == 6) begin
                            uart_o_array_buf <= uart_o_array;
                            crc_fsm     <= CRC_FSM_IDLE;
                        end
                    end
                endcase
            end
        end
    end
    else begin
        assign uart_o_array_buf = uart_o_array;
    end
end
endgenerate

//sample uart input
generate
    if(NUM_OF_UART_DEV != 0) begin
        always @ (posedge clk or posedge reset) begin
            if(reset) begin
                uart_rxd_synced_0           <= '1; //reset value should be 1 to as UART idle is pulled high, to avoid glitch.
                uart_rxd_synced_1           <= '1;
                uart_rxd_synced_2           <= '1;
            end 
            else begin
                if(local_link_state == operational_st && remote_link_state == operational_st) begin
                    if (tx_frm_offset == 4'd0 ) begin
                        uart_rxd_synced_0   <= uart_rxd;
                    end 
                    else if (tx_frm_offset == 4'd5) begin
                        uart_rxd_synced_1   <= uart_rxd;
                    end 
                    else if (tx_frm_offset == 4'd10) begin
                        uart_rxd_synced_2   <= uart_rxd;
                    end 
                    else begin
                        uart_rxd_synced_0   <= uart_rxd_synced_0;
                        uart_rxd_synced_1   <= uart_rxd_synced_1;
                        uart_rxd_synced_2   <= uart_rxd_synced_2;
                    end
                end
            end
        end
    end
    else begin
        assign uart_rxd_synced_0  = '1; //reset value should be 1 to as UART idle is pulled high, to avoid glitch.
        assign uart_rxd_synced_1  = '1;
        assign uart_rxd_synced_2  = '1;
    end
endgenerate

endmodule