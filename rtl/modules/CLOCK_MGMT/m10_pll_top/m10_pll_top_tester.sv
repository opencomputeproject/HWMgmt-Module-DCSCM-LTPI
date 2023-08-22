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
// -- Author        : Maciej Barzowski, Katarzyna Krzewska
// -- Date          : July 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Tester for PLL reconfiguration SW version
// -------------------------------------------------------------------

`timescale 1 ps / 1 ps

module m10_pll_top_tester 
import ltpi_pkg::*;
(
    input  wire     ref_clk,
    input  wire     mgmt_clk, 
    input  wire     reset_n,

    output wire     clk_out,
    output wire     clk_out_90,
    output wire     locked,
    output wire     reconfig

);

logic c0;
logic c1;

logic reset;

//assign pll_reset    = reset;
assign clk_out      = c0;
assign clk_out_90   = c1;

assign reset = ~reset_n;

logic [2:0] mgmt_clk_configuration;
logic       mgmt_clk_reconfig;
logic       mgmt_clk_configuration_done;  

assign reconfig = mgmt_clk_reconfig;

m10_pll_top m10_pll_top_inst (
    .ref_clk                        (ref_clk),
    .reset                          (reset),
    .mgmt_clk                       (mgmt_clk),
    .mgmt_reset                     (reset),

    .mgmt_clk_configuration         (mgmt_clk_configuration),
    .mgmt_clk_reconfig              (mgmt_clk_reconfig),    
    .mgmt_clk_configuration_done    (mgmt_clk_configuration_done),  

    .c0                             (c0),
    .c1                             (c1),

    .locked                         (locked)
);

logic [11:0] delay_cntr; 

always_ff @(posedge mgmt_clk or posedge reset) begin
    if (reset) begin
        delay_cntr <= '0;
        mgmt_clk_configuration <= '0;
        mgmt_clk_reconfig <= 1'b0;
    end
    else begin
        if (&delay_cntr) begin
            delay_cntr <= '0;

            mgmt_clk_reconfig <= 1'b1;

            if (&mgmt_clk_configuration) begin
                mgmt_clk_configuration <= '0;
            end
            else begin
                mgmt_clk_configuration <= mgmt_clk_configuration + 3'h1;
            end
        end
        else begin
            mgmt_clk_reconfig <= 1'b0;
            delay_cntr <= delay_cntr + 27'h0000_0001;
        end
    end
end

endmodule