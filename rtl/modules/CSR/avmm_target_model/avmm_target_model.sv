
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
// -- Date          : September 2022
// -- Project Name  : LTPI
// -- Description   :
// -- Test Avalone memory
// -------------------------------------------------------------------

`define MAX_ADDR         15
//Define Address for each regiter
`define ADDR_0          16'h00
`define ADDR_1          16'h04
`define ADDR_2          16'h08
`define ADDR_3          16'h0C
`define ADDR_4          16'h10
`define ADDR_5          16'h14
`define ADDR_6          16'h18
`define ADDR_7          16'h1C
`define ADDR_8          16'h20
`define ADDR_9          16'h24
`define ADDR_10         16'h28
`define ADDR_11         16'h2C
`define ADDR_12         16'h30
`define ADDR_13         16'h34
`define ADDR_14         16'h38
`define ADDR_15         16'h3C

module avmm_target_model
(
input             clk,
input             rst_n,
//AVMM Intf
input      [31:0] avmm_addr,
input             avmm_read,
input             avmm_write,
input      [31:0] avmm_wdata,
input      [ 3:0] avmm_byteen,
output reg        avmm_rdvalid,
output            avmm_waitrq,
output reg        avmm_wrvalid,
output reg [ 1:0] avmm_response,
output reg [31:0] avmm_rdata

);

wire [15:0] addr_local; 
reg  [31:0] mem_reg [`MAX_ADDR:0];      //local register
reg  [31:0] illegal_write;


assign avmm_waitrq = (avmm_write & !avmm_wrvalid) || (avmm_read || avmm_rdvalid);
assign addr_local       = avmm_addr[15:0];    //Only 16 bits out of 32 bits avmm_addr supported

//read registers
always @ ( posedge clk ) begin
    if ( !rst_n ) begin
        avmm_rdata <= 32'h0;
    end else begin
        if ( avmm_read && !( |avmm_addr[31:16]) && (&avmm_byteen)) begin
            case (addr_local)
                 `ADDR_0        : avmm_rdata <= mem_reg[`ADDR_0    / 4];
                 `ADDR_1        : avmm_rdata <= mem_reg[`ADDR_1    / 4];
                 `ADDR_2        : avmm_rdata <= mem_reg[`ADDR_2    / 4];
                 `ADDR_3        : avmm_rdata <= mem_reg[`ADDR_3    / 4];
                 `ADDR_4        : avmm_rdata <= mem_reg[`ADDR_4    / 4];
                 `ADDR_5        : avmm_rdata <= mem_reg[`ADDR_5    / 4];
                 `ADDR_6        : avmm_rdata <= mem_reg[`ADDR_6    / 4];
                 `ADDR_7        : avmm_rdata <= mem_reg[`ADDR_7    / 4];
                 `ADDR_8        : avmm_rdata <= mem_reg[`ADDR_8    / 4];
                 `ADDR_9        : avmm_rdata <= mem_reg[`ADDR_9    / 4];
                 `ADDR_10       : avmm_rdata <= mem_reg[`ADDR_10   / 4];
                 `ADDR_11       : avmm_rdata <= mem_reg[`ADDR_11   / 4];
                 `ADDR_12       : avmm_rdata <= mem_reg[`ADDR_12   / 4];
                 `ADDR_13       : avmm_rdata <= mem_reg[`ADDR_13   / 4];
                 `ADDR_14       : avmm_rdata <= mem_reg[`ADDR_14   / 4];
                 `ADDR_15       : avmm_rdata <= mem_reg[`ADDR_15   / 4];
                default         : avmm_rdata <= 32'h0BAD_0ADD; //reture bad addr
            endcase
        end
    end
end

//Wrire Register
integer i;
always @ ( posedge clk or negedge rst_n) begin
    if ( !rst_n ) begin
        for ( i=0; i<=`MAX_ADDR; i++ ) begin
            mem_reg[i] <= i;
        end
    end 
    else begin
        //write one clear
        if ( avmm_write && !( |avmm_addr[31:16]) && (&avmm_byteen)) begin
            case (addr_local)
                `ADDR_0         : begin mem_reg[`ADDR_0      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_1         : begin mem_reg[`ADDR_1      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_2         : begin mem_reg[`ADDR_2      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_3         : begin mem_reg[`ADDR_3      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_4         : begin mem_reg[`ADDR_4      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_5         : begin mem_reg[`ADDR_5      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_6         : begin mem_reg[`ADDR_6      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_7         : begin mem_reg[`ADDR_7      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_8         : begin mem_reg[`ADDR_8      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_9         : begin mem_reg[`ADDR_9      /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_10        : begin mem_reg[`ADDR_10     /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_11        : begin mem_reg[`ADDR_11     /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_12        : begin mem_reg[`ADDR_12     /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_13        : begin mem_reg[`ADDR_13     /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_14        : begin mem_reg[`ADDR_14     /4] <= avmm_wdata; avmm_response <= 0; end
                `ADDR_15        : begin mem_reg[`ADDR_15     /4] <= avmm_wdata; avmm_response <= 0; end
                default         : begin illegal_write            <= avmm_wdata; avmm_response <= 1; end
            endcase
        end
    end
end

//readvalid asserts one clock cycle after read assetted.
always @ ( posedge clk or negedge rst_n) begin
    if ( !rst_n ) begin
        avmm_rdvalid <= 1'b0;
    end else begin
        if ( avmm_read && (&avmm_byteen)) begin
            avmm_rdvalid <= 1'b1; 
        end else begin
            avmm_rdvalid <= 1'b0;
        end
    end
end

//readvalid asserts one clock cycle after read assetted.
always @ ( posedge clk or negedge rst_n) begin
    if ( !rst_n ) begin
        avmm_wrvalid <= 1'b0;
    end else begin
        if ( avmm_write && (&avmm_byteen)) begin
            avmm_wrvalid <= 1'b1; 
        end else begin
            avmm_wrvalid <= 1'b0;
        end
    end
end

endmodule