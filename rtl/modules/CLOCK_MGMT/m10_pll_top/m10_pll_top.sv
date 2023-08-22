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
// -- State machine for dynamic PLL reconfiguration 
// -------------------------------------------------------------------

`timescale 1 ps / 1 ps

module m10_pll_top 
import ltpi_pkg::*;
#(
    parameter RECONF_FROM_ROM = 0
)
(
    input  wire         ref_clk,
    input  wire         reset,
    input  wire         mgmt_clk,
    input  wire         mgmt_reset,

    input  wire [ 2:0]  mgmt_clk_configuration,
    input  wire         mgmt_clk_reconfig,    
    output reg          mgmt_clk_configuration_done,  

    output logic        c0,
    output logic        c1,
    output logic        locked
);

logic        reconfig_pll_areset;
logic        reconfig_pll_scandataout;
logic        reconfig_pll_scandone;
logic        reconfig_pll_configupdate;
logic        reconfig_pll_scanclk;
logic        reconfig_pll_scanclkena;
logic        reconfig_pll_scandata;

logic [ 2:0] mgmt_counter_param;
logic [ 3:0] mgmt_counter_type;
logic [ 8:0] mgmt_data_in;
logic        mgmt_read_param;
logic        mgmt_reconfig;
logic        mgmt_write_param;
logic        mgmt_busy;
logic [ 8:0] mgmt_data_out;

assign mgmt_counter_param = '0;
assign mgmt_counter_type  = '0;
assign mgmt_data_in       = '0;
assign mgmt_write_param   = 1'b0;
assign mgmt_read_param    = 1'b0;

logic [ 7:0] rom_address_out;
logic        write_from_rom;

logic [10:0] mem_address;
logic        mem_read_data;
logic        mem_read_data_en;
logic        mem_read_data_en_ff;
logic        mem_read_data_en_f_edge;

typedef enum logic [3:0]{
    ST_INIT             ,
    ST_DLY_RECONF       ,
    ST_RECONF           ,
    ST_BUSY             ,
    ST_PHASE_SHIFT      ,
    ST_PHASE_DONE       ,
    ST_RECONE_DONE
} rstate_t;

logic [10:0] init_delay_cnt;
logic [10:0] busy_delay_cnt;
rstate_t     rstate;

logic        mgmt_clk_reconfig_start;
logic        mgmt_clk_reconfig_ff;

logic        mgmt_clk_reconfig_r_edge; 
logic [ 2:0] mgmt_clk_configuration_latch;
logic        pll_reconf_done;

logic [ 2:0] phasecounterselect;
logic        phasestep;
logic        phaseupdown;

wire         phasedone;
logic        phasedone_r_edge_ff;
logic        phasedone_n_edge_ff;
logic [ 9:0] phase_shift_cnt;
logic [ 9:0] PHASE_SHIFTS_90_DEG;

logic pll_locked;
logic pll_locked_ff;
logic pll_locked_r_edge;

logic phase_shift_done;

assign write_from_rom = mgmt_clk_reconfig_start;

always_ff @(posedge mgmt_clk) pll_locked_ff <= pll_locked;
assign pll_locked_r_edge = ~pll_locked_ff & pll_locked;


//assign locked = phase_shift_done && pll_locked;
always_ff @(posedge mgmt_clk) locked <= (phase_shift_done && pll_locked);

always_ff @(posedge mgmt_clk) mem_read_data_en_ff <= mem_read_data_en;
assign mem_read_data_en_f_edge = mem_read_data_en_ff & ~mem_read_data_en;

always_ff @(posedge mgmt_clk) mgmt_clk_reconfig_ff <= mgmt_clk_reconfig;
assign mgmt_clk_reconfig_r_edge = ~mgmt_clk_reconfig_ff & mgmt_clk_reconfig;

always_ff @(posedge mgmt_clk) phasedone_r_edge_ff <= phasedone; 
always_ff @(negedge mgmt_clk) phasedone_n_edge_ff <= phasedone; 

assign mgmt_clk_configuration_done = pll_reconf_done;

always_ff @(posedge mgmt_clk or posedge mgmt_reset) begin
    if (mgmt_reset) begin
        mgmt_clk_configuration_latch <='0;
    end
    else begin
        if( rstate == ST_INIT ) begin
            if(mgmt_clk_reconfig_r_edge) begin
                mgmt_clk_configuration_latch <= mgmt_clk_configuration;
            end
        end
    end
end

assign mem_address = {mgmt_clk_configuration_latch, rom_address_out};

always_ff @(posedge mgmt_clk or posedge mgmt_reset) begin
    if (mgmt_reset) begin
        mgmt_reconfig <= 1'b0;
    end
    else begin
        mgmt_reconfig <= mem_read_data_en_f_edge;
    end
end

// delay counter
always @ (posedge mgmt_clk or posedge mgmt_reset) begin
    if( mgmt_reset ) begin
        init_delay_cnt                   <= 11'b0;
    end
    else begin
        if( rstate == ST_DLY_RECONF ) begin
            init_delay_cnt               <= init_delay_cnt + 1'b1;
        end
        else begin
            init_delay_cnt               <= 11'b0;
        end
    end

end

// delay counter
always @ (posedge mgmt_clk or posedge mgmt_reset) begin
    if(mgmt_reset) begin
        busy_delay_cnt                   <= '0;
    end
    else begin
        if(rstate == ST_BUSY) begin
            busy_delay_cnt               <= busy_delay_cnt + 1'b1;
        end
        else begin
            busy_delay_cnt               <= '0;
        end
    end
end

logic[3:0] phase_done_delay_cnt;

always @ (posedge mgmt_clk or posedge mgmt_reset) begin
    if( mgmt_reset ) begin
        phase_done_delay_cnt                   <= '0;
    end
    else begin
        if(rstate == ST_PHASE_DONE) begin
            phase_done_delay_cnt               <= phase_done_delay_cnt + 1'b1;
        end
        else begin
            phase_done_delay_cnt               <= '0;
        end
    end
end

always @ (posedge mgmt_clk or posedge mgmt_reset) begin
    if(mgmt_reset) begin
        PHASE_SHIFTS_90_DEG                   <= PHASE_SHIFTS_90_DEG_FREQ_x1;
    end
    else begin
        case(mgmt_clk_configuration_latch)
            base_freq_x1:   PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x1;
            base_freq_x2:   PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x2;
            base_freq_x3:   PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x3;
            base_freq_x4:   PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x4;
            base_freq_x6:   PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x6;
            base_freq_x8:   PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x8;
            base_freq_x10:  PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x10;
            base_freq_x12:  PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x12;
            base_freq_x16:  PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x16;
            default:        PHASE_SHIFTS_90_DEG <= PHASE_SHIFTS_90_DEG_FREQ_x1;
        endcase
    end
end

// State machine for reconfiguration PLL and phase shifts to 90 deegree
always_ff @(posedge mgmt_clk or posedge mgmt_reset) begin
    if (mgmt_reset) begin
        //int_reconf                              <= 1'b1;
        mgmt_clk_reconfig_start                 <= 1'b0;
        pll_reconf_done                         <= 1'b0;
        phasecounterselect                      <= 3'b011;
        phaseupdown                             <= 1'b1;
        phasestep                               <= 1'b0;
        phase_shift_cnt                         <= '0;
        phase_shift_done                        <= 1'b1;
        rstate                                  <= ST_INIT;
    end
    else begin
        case(rstate) 
            ST_INIT:begin
                phasestep                       <= 1'b0;
                phase_shift_cnt                 <= '0;
                mgmt_clk_reconfig_start         <= 1'b0;
                pll_reconf_done                 <= 1'b0;
                if( !mgmt_busy ) begin
                    if(mgmt_clk_reconfig_r_edge) begin
                        rstate                  <= ST_DLY_RECONF;
                    end
                end
            end
            ST_DLY_RECONF: begin
                //delay to make sure, remote device is in Link Speed Change state
                pll_reconf_done                 <= 1'b0;
                mgmt_clk_reconfig_start         <= 1'b0;
                if(init_delay_cnt == 11'd1800) begin//1800*0,0167 us = 30us
                    rstate                      <= ST_RECONF;
                end
            end
            ST_RECONF: begin
                mgmt_clk_reconfig_start         <= 1'b1;
                phase_shift_done                <= 1'b0;
                rstate                          <= ST_BUSY;
            end
            ST_BUSY: begin 
                mgmt_clk_reconfig_start         <= '0;
                if(busy_delay_cnt == 12'd1700) begin//1700*0,0167 us = 28 us
                    if(pll_locked) begin
                        rstate                      <= ST_PHASE_SHIFT;
                        pll_reconf_done             <= '1;
                    end
                end
            end
            ST_PHASE_SHIFT: begin 
                phasestep           <= 1'b1;
                if(phasedone && (phase_shift_cnt < PHASE_SHIFTS_90_DEG)) begin
                    phase_shift_cnt             <= phase_shift_cnt + 1;
                    rstate                      <= ST_PHASE_DONE;
                end
                else if (phase_shift_cnt >= PHASE_SHIFTS_90_DEG )begin
                    rstate                      <= ST_RECONE_DONE;
                    phase_shift_done            <= 1'b1;
                end

            end
            ST_PHASE_DONE: begin
                if(phase_done_delay_cnt == 4'd10) begin 
                //if (!phasedone_r_edge_ff || !phasedone_n_edge_ff) begin
                    phasestep                   <= 1'b0;
                    rstate                      <= ST_PHASE_SHIFT;
                end
            end
            ST_RECONE_DONE: begin
                rstate                          <= ST_INIT;
            end
            default: begin
                rstate                          <= ST_INIT;
        end //end case of default
        endcase
    end
end

generate 
    if(RECONF_FROM_ROM) begin: gen_rd_rom_reconfig
        m10_pll_reconfig_memory m10_pll_reconfig_memory_inst (
            .clock              (mgmt_clk                   ),
            .address            (mem_address                ),
            .rden               (mem_read_data_en           ),
            .q                  (mem_read_data              )
        );
    end
    else begin: gen_rd_file_reconfig
        m10_pll_reconfig_file m10_pll_reconfig_file_inst(
            .clock              (mgmt_clk                   ),
            .reset              (reset                      ),
            .address            (mem_address                ),
            .rden               (mem_read_data_en           ),
            .q                  (mem_read_data              )
        );
    end
endgenerate


m10_pll_reconfig m10_pll_reconfig_inst (
    .clock              (mgmt_clk                   ),
    .counter_param      (mgmt_counter_param         ),
    .counter_type       (mgmt_counter_type          ),
    .data_in            (mgmt_data_in               ),
    .pll_areset_in      (reset                      ),
    .pll_scandataout    (reconfig_pll_scandataout   ),
    .pll_scandone       (reconfig_pll_scandone      ),
    .read_param         (mgmt_read_param            ),
    .reconfig           (mgmt_reconfig              ),
    .reset              (mgmt_reset                 ),
    .write_param        (mgmt_write_param           ),
    .busy               (mgmt_busy                  ),
    .data_out           (mgmt_data_out              ),
    .pll_areset         (reconfig_pll_areset        ),
    .pll_configupdate   (reconfig_pll_configupdate  ),
    .pll_scanclk        (reconfig_pll_scanclk       ),
    .pll_scanclkena     (reconfig_pll_scanclkena    ),
    .pll_scandata       (reconfig_pll_scandata      ),
    .reset_rom_address  (mgmt_reset                 ),
    .rom_address_out    (rom_address_out            ),
    .rom_data_in        (mem_read_data              ),
    .write_from_rom     (write_from_rom             ),
    .write_rom_ena      (mem_read_data_en           )
);

pll_lvds pll_inst(
    .areset             (reconfig_pll_areset        ),
    .configupdate       (reconfig_pll_configupdate  ),
    .inclk0             (ref_clk                    ),
    .scanclk            (reconfig_pll_scanclk       ),
    .scanclkena         (reconfig_pll_scanclkena    ),
    .scandata           (reconfig_pll_scandata      ),
    .c0                 (c0                         ),
    .c1                 (c1                         ),
    .locked             (pll_locked                 ),
    .scandataout        (reconfig_pll_scandataout   ),
    .scandone           (reconfig_pll_scandone      ),
    .phasecounterselect (phasecounterselect         ),
    .phasestep          (phasestep                  ),
    .phaseupdown        (phaseupdown                ),
    .phasedone          (phasedone                  )
);

endmodule