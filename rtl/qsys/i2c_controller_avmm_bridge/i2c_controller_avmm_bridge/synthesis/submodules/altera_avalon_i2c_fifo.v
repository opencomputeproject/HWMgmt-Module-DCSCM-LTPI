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


// synthesis translate_off
`timescale 1ns / 1ps
// synthesis translate_on

module altera_avalon_i2c_fifo #(
    parameter DSIZE = 8,
    parameter FIFO_DEPTH = 256,
    parameter FIFO_DEPTH_LOG2 = 8,
    parameter LATENCY = 2
) (
    input                       clk,
    input                       rst_n,
    input                       s_rst,
    input [DSIZE-1:0]           wdata,
    input                       put,
    input                       get,
    
    output                      full,
    output                      empty,
    output                      empty_dly,
    output [FIFO_DEPTH_LOG2:0]  navail,
    output [DSIZE-1:0]          rdata
);


reg [FIFO_DEPTH_LOG2-1:0]  write_address;
reg [FIFO_DEPTH_LOG2-1:0]  read_address;
reg [FIFO_DEPTH_LOG2:0] internal_used;
reg empty_d1;
reg empty_d2;

wire internal_full;
wire internal_empty;
wire [(DSIZE/8)-1:0]  write_byteenables;


  always @ (posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      write_address <= 0;
    end
    else
    begin
      if (s_rst)
      begin
        write_address <= 0;
      end
      else if (put == 1)
      begin
        write_address <= write_address + 1'b1;
      end
    end
  end

  always @ (posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      read_address <= 0;
    end
    else
    begin
      if (s_rst)
      begin
        read_address <= 0;
      end
      else if (get == 1)
      begin
        read_address <= read_address + 1'b1;
      end
    end
  end

  assign write_byteenables = {(DSIZE/8){1'b1}};

  // TODO:  Change this to an inferrered RAM when Quartus II supports byte enables for inferred RAM
  altsyncram the_dp_ram (
    .clock0 (clk),
    .wren_a (put),
    .byteena_a (write_byteenables),
    .data_a (wdata),
    .address_a (write_address),
    .q_b (rdata),
    .address_b (read_address)
  );
  defparam the_dp_ram.operation_mode = "DUAL_PORT";  // simple dual port (one read, one write port)
  defparam the_dp_ram.lpm_type = "altsyncram";
  defparam the_dp_ram.read_during_write_mode_mixed_ports = "DONT_CARE";
  defparam the_dp_ram.power_up_uninitialized = "TRUE";
  defparam the_dp_ram.byte_size = 8;
  defparam the_dp_ram.width_a = DSIZE;
  defparam the_dp_ram.width_b = DSIZE;
  defparam the_dp_ram.widthad_a = FIFO_DEPTH_LOG2;
  defparam the_dp_ram.widthad_b = FIFO_DEPTH_LOG2;
  defparam the_dp_ram.width_byteena_a = (DSIZE/8);
  defparam the_dp_ram.numwords_a = FIFO_DEPTH;
  defparam the_dp_ram.numwords_b = FIFO_DEPTH;
  defparam the_dp_ram.address_reg_b = "CLOCK0";
  defparam the_dp_ram.outdata_reg_b = (LATENCY == 2)? "CLOCK0" : "UNREGISTERED";

  always @ (posedge clk or negedge rst_n)
  begin
    if (!rst_n)
    begin
      internal_used <= 0;
    end
    else
    begin
      if (s_rst)
      begin
        internal_used <= 0;
      end
      else
      begin
        case ({put, get})
          2'b01: internal_used <= internal_used - 1'b1;
          2'b10: internal_used <= internal_used + 1'b1;
          default: internal_used <= internal_used;
        endcase
      end
    end
  end


  assign internal_empty = (read_address == write_address) & (internal_used == 0);
  assign internal_full = (write_address == read_address) & (internal_used != 0);

  assign navail = internal_used;    // this signal reflects the number of words in the FIFO
  assign empty = internal_empty;  // combinational so it'll glitch a little bit
  assign full = internal_full;    // dito

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        empty_d1    <= 1'b1;
        empty_d2    <= 1'b1;
    end
    else begin
        empty_d1    <= empty;
        empty_d2    <= empty_d1;
    end
  end

  assign empty_dly = empty | empty_d1 | empty_d2;

endmodule
