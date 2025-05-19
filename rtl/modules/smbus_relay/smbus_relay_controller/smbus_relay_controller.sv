/////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2021 Intel Corporation
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

// smbus_filtered_relay
//
// This module implements an SMBus relay between a single controller and multiple
// target devices.
//
// The module uses clock stretching on the interface from the SMBus controller
// to allow time for the target to respond with ACK and read data.
//
// Required files:
//      async_input_filter.sv


`timescale 1 ns / 1 ps
//`default_nettype none

// `define USE_LVDS
// `define CRC_EN

module smbus_relay_controller import ltpi_pkg::*;
#(
    parameter CLOCK_PERIOD_PS       = 10000        // period of the input 'clock', in picoseconds (default 10,000 ps = 100 MHz)
) (
    input  wire                             clock,              // controller clock for this block
    input  wire                             i_resetn,           // controller reset, must be de-asserted synchronously with clock
    input  logic                            bus_speed,
    //ioc frames
    output reg  [ 3:0]                      ioc_frame_o,
    input  wire [ 3:0]                      ioc_frame_i,
    
    input  wire                             ia_controller_scl,      // asynchronous input from the SCL pin of the controller interface
    output logic                            o_controller_scl_oe,    // when asserted, drive the SCL pin of the controller interface low
    input  wire                             ia_controller_sda,      // asynchronous input from the SDA pin of the controller interface
    output logic                            o_controller_sda_oe,    // when asserted, drive the SDA pin of the controller interface low
    
    output                                  stretch_timeout,
    input logic [ 3:0]                      tx_frm_offset,
    output logic                            smbus_timeout,

    //DEBUG
    output logic [31:0]                     dbg_cntrl_controller_smbstate,
    output logic [31:0]                     dbg_cntrl_relay_state
);


///////////////////////////////////////
// Calculate timing parameters
// Uses timing parameters from the SMBus specification version 3.1
///////////////////////////////////////

// minimum time to hold the SCLK signal low, in clock cycles
// minimum time to hold SCLK high is less than this, but we will use this same number to simplify logic
int SCLK_HOLD_MIN_COUNT;
localparam int SCLK_HOLD_COUNTER_BIT_WIDTH  = 10; // counter will count from SCLK_HOLD_MIN_COUNT-1 downto -1
localparam int NOISE_FILTER_MIN_CLOCK_CYCLES = ((50000 + CLOCK_PERIOD_PS - 1) / CLOCK_PERIOD_PS);           // SMBus spec says to filter out pulses smaller than 50ns
localparam int NUM_FILTER_REGS = NOISE_FILTER_MIN_CLOCK_CYCLES >= 2 ? NOISE_FILTER_MIN_CLOCK_CYCLES : 2;    // always use at least 2 filter registers, to eliminate single-cycle pulses that might be caused during slow rising/falling edges
int SETUP_TIME_COUNT;

always@(posedge clock or negedge i_resetn) begin
    if(!i_resetn) begin
        SCLK_HOLD_MIN_COUNT     ='0;
        SETUP_TIME_COUNT        ='0;
    end
    else begin
        if(bus_speed == 1'b0) begin 
            SCLK_HOLD_MIN_COUNT = ((5000000 + CLOCK_PERIOD_PS - 1) / CLOCK_PERIOD_PS) - 6;
            //SETUP_TIME_COUNT    = 8;
            SETUP_TIME_COUNT    = (1000000)/CLOCK_PERIOD_PS - 1;   // from SMBUS spec: Data setup time min 0.25us
        end
        else if(bus_speed == 1'b1) begin
            SCLK_HOLD_MIN_COUNT = ((1300000 + CLOCK_PERIOD_PS - 1) / CLOCK_PERIOD_PS) - 6;
            //SETUP_TIME_COUNT    = 4;
            SETUP_TIME_COUNT    = 100000/CLOCK_PERIOD_PS - 1; //from SMBUS spec: Data setup time min 0.1 us
        end
    end
end

enum logic [3:0] {
    idle,
    start,
    start_rcv,
    stop,
    stop_rcv,
    bit_rcv,
    data_0,
    data_1
} ioc_frame_local, ioc_frame_remote;

//`ifdef USE_LVDS

assign ioc_frame_o = ioc_frame_local;

//RX    
always@(*)
    case(ioc_frame_i)
    4'h0: ioc_frame_remote = idle;
    4'h2: ioc_frame_remote = start_rcv;
    4'h4: ioc_frame_remote = stop_rcv;
    4'h5: ioc_frame_remote = bit_rcv;
    4'h6: ioc_frame_remote = data_0;
    4'h7: ioc_frame_remote = data_1;
    default: ioc_frame_remote = idle;
endcase


///////////////////////////////////////
// Synchronize asynchronous SMBus input signals to clock and detect edges and start/stop conditions
///////////////////////////////////////

// synchronized, metastability hardened versions of the scl and sda input signals for internal use in the rest of this module
logic controller_scl;
logic controller_sda;

// detection of positive and negative edges, asserted synchronous with the first '1' or '0' on the controller/target scl signals defined below
logic controller_scl_posedge;
logic controller_scl_negedge;
logic controller_sda_posedge;
logic controller_sda_negedge;

// SDA signals are delayed by 1 extra clock cycle, to provide a small amount of hold timing when sampling SDA on the rising edge of SCL
async_input_filter #(
    .NUM_METASTABILITY_REGS (2),
    .NUM_FILTER_REGS        (NUM_FILTER_REGS)
) sync_controller_scl_inst (
    .clock                  ( clock ),
    .ia_async_in            ( ia_controller_scl ),
    .o_sync_out             ( controller_scl ),
    .o_rising_edge          ( controller_scl_posedge ),
    .o_falling_edge         ( controller_scl_negedge )
);

async_input_filter #(
    .NUM_METASTABILITY_REGS (2),
    .NUM_FILTER_REGS        (NUM_FILTER_REGS+1)
) sync_controller_sda_inst (
    .clock                  ( clock ),
    .ia_async_in            ( ia_controller_sda ),        
    .o_sync_out             ( controller_sda ),
    .o_rising_edge          ( controller_sda_posedge ),
    .o_falling_edge         ( controller_sda_negedge )
);


// detect start and stop conditions on the controller bus, asserted 1 clock cycle after the start/stop condition actually occurs
logic controller_start;
logic controller_stop;
logic controller_scl_dly;       // delayed version of controller_scl by 1 clock cycle

always_ff @(posedge clock or negedge i_resetn) begin
    if (!i_resetn) begin
        controller_start        <= '0;
        controller_stop         <= '0;
        controller_scl_dly      <= '0;
    end else begin
        controller_start        <= controller_scl & controller_sda_negedge;      // falling edge on SDA while SCL high is a start condition
        controller_stop         <= controller_scl & controller_sda_posedge;      // rising edge on SDA while SCL high is a stop condition
        controller_scl_dly      <= controller_scl;
    end
end


///////////////////////////////////////
// Track the 'phase' of the controller SMBus
///////////////////////////////////////

enum {
    SMBCONTROLLER_STATE_IDLE                , //0
    SMBCONTROLLER_STATE_START               ,//1
    SMBCONTROLLER_STATE_CONTROLLER_ADDR     , // 2
    SMBCONTROLLER_STATE_TARGET_ADDR_ACK     , //3
    SMBCONTROLLER_STATE_CONTROLLER_CMD      , //4
    SMBCONTROLLER_STATE_TARGET_CMD_ACK      , //5
    SMBCONTROLLER_STATE_CONTROLLER_WRITE    , //6
    SMBCONTROLLER_STATE_TARGET_WRITE_ACK    , //7
    SMBCONTROLLER_STATE_TARGET_READ         , //8
    SMBCONTROLLER_STATE_CONTROLLER_READ_ACK , // 9
    SMBCONTROLLER_STATE_STOP                , //a
    SMBCONTROLLER_STATE_STOP_THEN_START       //b
}controller_smbstate;                // current state of the controller SMBus

logic [ 3:0]                    controller_bit_count;               // number of bits received in the current byte (starts at 0, counts up to 8)
logic                           clear_controller_bit_count;         // reset the controller_bit_count to 0 when asserted
logic [ 7:0]                    controller_byte_in;                 // shift register to store incoming bits, shifted in starting at position 0 and shifting left (so first bit ends up as the msb)
logic                           command_rd_wrn;                 // captured during the target address phase, indicates if the current command is a READ (1) or WRITE (0) command
logic                           controller_read_nack;               // capture the ack/nack status from the controller after a read data byte has been sent
logic                           controller_read_nack_valid;         // used to ensure controller_read_nack is only captured on the first rising edge of clock after read data has been sent
logic                           controller_triggered_start;         // used to indicates that the next start condition is a repeated start


enum {
    RELAY_STATE_IDLE                                    , //0 
    RELAY_STATE_START_WAIT_TIMEOUT                      , //1
    RELAY_STATE_START_WAIT_SCL_LOW                      , // 2
    RELAY_STATE_START_CTOT_WAIT_START_RCV               , //3
    RELAY_STATE_STOP_WAIT_TIMEOUT                       , //4
    RELAY_STATE_STOP                                    , //5
    RELAY_STATE_WAIT_STOP_RCV                           ,//6
    // in all 'CTOT' (Controller to Target) states, the controller is driving the SDA signal to the target, so SDA must be relayed from the controller bus to the target bus (or sometimes a 'captured' version of SDA)
    RELAY_STATE_CTOT_SCL_LOW_WAIT_TIMEOUT               , //7
    RELAY_STATE_CTOT_WAIT_SCL_HIGH                      , //8
    RELAY_STATE_CTOT_WAIT_BIT_RCV                       , // 9
    RELAY_STATE_CTOT_WAIT_SCL_LOW                       , //a
    // in all 'TTOC' (Target to Controller) states, the target is driving the SDA signal to the controller, so SDA must be relayed from the target bus to the controller bus (or sometimes a 'captured' version of SDA)
    RELAY_STATE_TTOC_WAIT_EVENT                         , // b
    RELAY_STATE_TTOC_SCL_LOW_WAIT_SETUP_TIMEOUT         , //c
    RELAY_STATE_TTOC_WAIT_SCL_HIGH                      , //d
    RELAY_STATE_TTOC_WAIT_SCL_LOW
} relay_state;                    // current state of the relay between the controller and target busses

logic [SCLK_HOLD_COUNTER_BIT_WIDTH-1:0]     target_scl_hold_count;           // counter to determine how long to hold the target scl signal low/high, counts down to -1 then waits to be restarted (so msb=1 indicates the counter has timed out)
logic                                       target_scl_hold_count_restart;   // combinatorial signal, reset the target_scl_hold_count counter and start a new countdown
logic                                       target_scl_hold_count_timeout;   // combinatorial signal (copy of msb of target_scl_hold_count), indicates the counter has reached it's timeout value and is not about to be restarted

logic [24:0]                                event_waiting_count;
logic                                       event_waiting_count_restart;


logic [ 9:0]                                setup_timeout;

always_ff @(posedge clock or negedge i_resetn) begin
    if (!i_resetn) begin
        controller_smbstate             <= SMBCONTROLLER_STATE_IDLE;
        controller_bit_count            <= 4'h0;
        clear_controller_bit_count      <= '0;
        controller_byte_in              <= 8'h00;
        command_rd_wrn                  <= '0;
        controller_read_nack            <= '0;
        controller_read_nack_valid      <= '0;
        controller_triggered_start      <= '0;
        ioc_frame_local                 <= idle;
        smbus_timeout                   <= 1'b0;
    end
    else if(event_waiting_count == 25'b0) begin
        controller_smbstate             <= SMBCONTROLLER_STATE_IDLE;
        controller_bit_count            <= 4'h0;
        clear_controller_bit_count      <= '0;
        controller_byte_in              <= 8'h00;
        command_rd_wrn                  <= '0;
        controller_read_nack            <= '0;
        controller_read_nack_valid      <= '0;
        controller_triggered_start      <= '0;
        ioc_frame_local                 <= idle;
        smbus_timeout                   <= 1'b1;
    end
    else begin
        case ( controller_smbstate )
            // IDLE state
            // This is the reset state.  Wait here until a valid START condition is detected on the controller smbus
            SMBCONTROLLER_STATE_IDLE: begin
                smbus_timeout         <= 1'b0;
                if (controller_start) begin                  // only way to leave the idle state is if we detect a 'start' condition
                    controller_smbstate <= SMBCONTROLLER_STATE_START;
                    ioc_frame_local <= start;
                end
                else begin
                    ioc_frame_local <= idle;
                end
                clear_controller_bit_count <= '1;                               // hold the bit counter at 0 until we have exited the idle state
            end
            // START state
            // A start condition was detected on the controller bus, 
            // the FSM stays here and clock-stretches the controller bus as required until the target bus has 'caught up' and then issued a start condition
            SMBCONTROLLER_STATE_START: begin
                if (controller_stop) begin                                      // start followed immediately by stop is strange, but not necessarily invalid
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                end 
                else begin
                    if(controller_scl == 1'b0) begin
                        controller_smbstate <= SMBCONTROLLER_STATE_CONTROLLER_ADDR;
                    end
                end
                ioc_frame_local <= idle;
                clear_controller_bit_count <= '1;                               // hold the bit counter at 0
            end
            // CONTROLLER_ADDR state
            // In this state the 7 bits target address and the read/write bit are received. Leave this state when all 8 bits have been received 
            // and the clock has been driven low again by the controller
            SMBCONTROLLER_STATE_CONTROLLER_ADDR: begin
                if (controller_stop || controller_start) begin                      // unexpected stop/start condition, ignore further controller bus activity until we can issue a 'stop' condition on the target bus
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                    ioc_frame_local <= idle;
                end 
                else begin                        
                    if (controller_scl_negedge == 1'b1 && controller_bit_count == 4'h8) begin   // we have received all 8 data bits, time for the ACK
                        controller_smbstate <= SMBCONTROLLER_STATE_TARGET_ADDR_ACK;            // not our address, send a 'stop' condition on the target bus and stop forwarding from the controller until the next 'start'
                        ioc_frame_local <= idle;
                    end

                    if(controller_scl_negedge == 1'b1) begin    
                        if(controller_sda == 1'b0)
                            ioc_frame_local <= data_0;
                        else
                            ioc_frame_local <= data_1;
                    end
                    else begin
                        ioc_frame_local <= idle;
                    end
                    clear_controller_bit_count <= '0;                           // do not reset the bit counter in this state, it will be reset during the next ACK state
                end
            end
            // TARGET_ADDR_ACK state
            // SCL signal is driven low during this state to clock-stretch while awaiting an ACK from the target bus. 
            // Always enter this state after a SCL falling edge. 
            // Leave this state on SCL falling edge and when the ack/nack bit has been sent or when unexpected stop/start condition occurred
            SMBCONTROLLER_STATE_TARGET_ADDR_ACK: begin
                if (controller_stop || controller_start) begin                      // unexpected stop/start condition, ignore further controller bus activity until we can issue a 'stop' condition on the target bus
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                    ioc_frame_local <= idle;
                end 
                else begin
                    if (controller_scl_negedge) begin                           // ack/nack sent on clock rising edge, then need to wait for clock to go low again before leaving this state so it's safe to stop driving sda
                        if(!o_controller_sda_oe) begin
                            controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                            ioc_frame_local <= idle;
                        end 
                        else if (command_rd_wrn) begin
                            controller_smbstate <= SMBCONTROLLER_STATE_TARGET_READ;              // this is a read command, start sending data back from target
                        end 
                        else begin
                            controller_smbstate <= SMBCONTROLLER_STATE_CONTROLLER_CMD;              // receive the command on the next clock cycle
                        end
                        ioc_frame_local <= bit_rcv;
                    end
                    else begin
                        ioc_frame_local <= idle;
                    end
                end
                clear_controller_bit_count <= '1;                               // hold the counter at 0 through this state, so it has the correct value at the start of the next state
                
            end
            // CONTROLLER_CMD state
            // Received the 8 bits SMBus command (the first data byte after the address is called the 'command' in SMBus Specification). 
            // Always enter this state after an SCL falling edge. 
            // Leave this state when all 8 bits have been received and the clock has been driven low again by the controller
            SMBCONTROLLER_STATE_CONTROLLER_CMD: begin
                if (controller_stop || controller_start) begin                      // unexpected stop/start condition, ignore further controller bus activity until we can issue a 'stop' condition on the target bus
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                    ioc_frame_local <= idle;
                end else begin
                    if (controller_scl_negedge == 1'b1 && controller_bit_count == 4'h8) begin   // we have received all 8 data bits, time for the ACK
                        controller_smbstate <= SMBCONTROLLER_STATE_TARGET_CMD_ACK;
                        ioc_frame_local <= idle;
                    end
                    if(controller_scl_negedge == 1'b1) begin    
                        if(controller_sda == 1'b0)
                            ioc_frame_local <= data_0;
                        else
                            ioc_frame_local <= data_1;
                    end
                    else begin
                        ioc_frame_local <= idle;
                    end
                end
                clear_controller_bit_count <= '0;                           // do not reset the bit counter in this state, it will be reset during the next ACK state
            end
            // TARGET_CMD_ACK or TARGET_WRITE_ACK state
            // SCL signal is driven low during this state to clock-stretch while awaiting an ACK from the target bus. 
            // Always enter this state after an SCL falling edge. 
            // Leave this state when the ack/nack bit has been sent and the clock has been driven low again by the controller
            SMBCONTROLLER_STATE_TARGET_CMD_ACK,
            SMBCONTROLLER_STATE_TARGET_WRITE_ACK: begin
                if (controller_stop || controller_start) begin                      // unexpected stop/start condition, ignore further controller bus activity until we can issue a 'stop' condition on the target bus
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                    ioc_frame_local <= idle;
                end 
                else begin
                    if (controller_scl_negedge) begin                           // ack/nack sent on clock rising edge, then need to wait for clock to go low again before leaving this state so it's safe to stop driving sda
                        if(!o_controller_sda_oe) begin
                            controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                            ioc_frame_local <= idle;
                        end 
                        else begin
                            controller_smbstate <= SMBCONTROLLER_STATE_CONTROLLER_WRITE;
                        end
                        ioc_frame_local <= bit_rcv;
                    end
                    else begin
                        ioc_frame_local <= idle;
                    end
                end
                clear_controller_bit_count <= '1;                               // hold the counter at 0 through this state, so it has the correct value (0) at the start of the next state        
            end
            // CONTROLLER_WRITE state
            // Enter the state after write command - received a byte to write to the target device.  
            // Always enter this state after a SCL falling edge, 
            // leave this state when 8 bites were sent to target devices and clock has been driven low again by the controller
            SMBCONTROLLER_STATE_CONTROLLER_WRITE: begin
                if (controller_stop) begin                                      // unexpected stop condition, ignore further controller bus activity until we can issue a 'stop' condition on the target bus
                    //$display("Controller state: ns is SMBCONTROLLER_STATE_STOP");
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                    ioc_frame_local <= idle;
                end
                else if(controller_start) begin
                    controller_smbstate <= SMBCONTROLLER_STATE_START;
                    ioc_frame_local <= start;
                end
                else begin
                    if(controller_scl_negedge == 1'b1) begin    
                        if (controller_bit_count == 4'h8) 
                            controller_smbstate <= SMBCONTROLLER_STATE_TARGET_WRITE_ACK;
                            
                        if(controller_sda == 1'b0)
                            ioc_frame_local <= data_0;
                        else
                            ioc_frame_local <= data_1;
                    end
                    else begin
                        ioc_frame_local <= idle;
                    end               
                end
                clear_controller_bit_count <= '0;                           // do not reset the bit counter in this state, it will be reset during the next ACK state
            end
            // TARGET_READ state
            // Enter this state after read command and after a SCL falling edge, 
            // leave this state after received byte from target device
            SMBCONTROLLER_STATE_TARGET_READ: begin
                if (controller_stop || controller_start) begin                      // unexpected stop/start condition, ignore further controller bus activity until we can issue a 'stop' condition on the target bus
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                    ioc_frame_local <= idle;
                end else begin
                    if (controller_bit_count == 4'h8 && controller_scl_negedge == 1'b1) begin   // we have sent all 8 data bits, time for the ACK (from the controller)
                        controller_smbstate <= SMBCONTROLLER_STATE_CONTROLLER_READ_ACK;
                    end
                    
                    if(controller_scl_negedge == 1'b1) begin
                        ioc_frame_local <= bit_rcv;
                    end
                    else begin
                        ioc_frame_local <= idle;
                    end               
                end
                clear_controller_bit_count <= '0;                           // do not reset the bit counter in this state, it will be reset during the next ACK state
            end
            // CONTROLLER_READ_ACK
            // Enter this state after a SCL falling edge, 
            // leave this state when the ack/nack bit has been received and the controller drive SCL low again
            SMBCONTROLLER_STATE_CONTROLLER_READ_ACK: begin
                if (controller_stop || controller_start) begin                      // unexpected stop/start condition, ignore further controller bus activity until we can issue a 'stop' condition on the target bus
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP;
                    ioc_frame_local <= idle;
                end else begin
                    if (controller_scl_negedge) begin
                        if (~controller_read_nack) begin                        // if we received an ack (not a nack) from the controller, continue reading data from target
                            controller_smbstate <= SMBCONTROLLER_STATE_TARGET_READ;
                        end else begin                                      // on a nack, send a stop condition on the target bus and wait for a stop on the controller bus
                            controller_smbstate <= controller_smbstate; //wait for stop
                            ioc_frame_local <= idle;
                        end
                    end

                    if(controller_scl_negedge == 1'b1) begin    
                        if(controller_sda == 1'b0)
                            ioc_frame_local <= data_0;
                        else
                            ioc_frame_local <= data_1;
                    end
                    else begin
                        ioc_frame_local <= idle;
                    end
                end
                clear_controller_bit_count <= '1;                               // hold the counter at 0 through this state, so it has the correct value (0) at the start of the next state
            end
            // STOP
            // Enter this state to indicate a STOP condition should be sent to the target bus
            // Once the STOP has been sent on the target bus, we return to the idle state and wait for another start condition
            // We can enter this state if a stop condition has been received on the controller bus, or if we EXPECT a start condition on the controller busses
            // We do not wait to actually see a stop condition on the controller bus before issuing the stop on the target bus and proceeding to the IDLE state
            SMBCONTROLLER_STATE_STOP: begin
                if (controller_start) begin
                    controller_smbstate <= SMBCONTROLLER_STATE_STOP_THEN_START;     // we may receive a valid start condition while waiting to send a stop, we need to track that case
                end 
                else if (relay_state == RELAY_STATE_STOP) begin
                    ioc_frame_local <= stop;
                end
                else if (relay_state == RELAY_STATE_IDLE) begin
                    controller_smbstate <= SMBCONTROLLER_STATE_IDLE;
                end
                else begin
                    ioc_frame_local <= idle;
                end
                clear_controller_bit_count <= '1;                               // hold the counter at 0 through this state, so it has the correct value (0) at the start of the next state
            end
            // STOP_THEN_START
            // While waiting to send a STOP on the target bus, we receive a new start condition on the controller busses
            // Must finish sending the stop condition on the target bus, then send a start condition on the target bus
            SMBCONTROLLER_STATE_STOP_THEN_START: begin
                if (relay_state == RELAY_STATE_STOP) begin
                    ioc_frame_local <= stop;
                end
                else begin
                    ioc_frame_local <= idle;
                end

                if (/*relay_state == RELAY_STATE_IDLE || */relay_state == RELAY_STATE_START_CTOT_WAIT_START_RCV) begin
                    controller_smbstate <= SMBCONTROLLER_STATE_START;
                    ioc_frame_local <= start;
                end
                clear_controller_bit_count <= '1;                               // hold the counter at 0 through this state, so it has the correct value (0) at the start of the next state
            end
            default: begin                                                  // illegal state, should never get here
                controller_smbstate <= SMBCONTROLLER_STATE_IDLE;
                clear_controller_bit_count <= '1;
                ioc_frame_local <= idle;
            end
            
        endcase  
        
        // counter for bits received on the controller bus
        // the controller SMBus state machine will clear the counter at the appropriate times, otherwise it increments on every controller scl rising edge
        if (clear_controller_bit_count || controller_start) begin       // need to reset the counter on a start condition to handle the repeated start (simpler than assigning clear signal in this one special case)
            controller_bit_count <= 4'h0;
        end else begin
            if (controller_scl_posedge) begin
                controller_bit_count <= controller_bit_count + 4'b0001;
            end
        end

        // shift register to store incoming bits from the controller bus
        // shifts on every clock edge regardless of bus state, rely on controller_smbstate and controller_bit_count to determine when a byte is fully formed
        if (controller_scl_posedge) begin
            controller_byte_in[7:0] <= {controller_byte_in[6:0], controller_sda};
        end
        
        if ( (controller_smbstate == SMBCONTROLLER_STATE_CONTROLLER_ADDR) && (controller_bit_count == 4'h8) ) begin  // 8th bit is captured on the next clock cycle, so that's when it's safe to check the full byte contents
            command_rd_wrn <= controller_byte_in[0];
        end
        
        // capture the read data ACK/NACK from the controller after read data has been sent
        // make sure to only capture ack/nack on the first rising edge of SCL using the controller_read_nack_valid signal
        if (controller_smbstate == SMBCONTROLLER_STATE_CONTROLLER_READ_ACK) begin
            if (controller_scl_posedge) begin
                if (!controller_read_nack_valid) begin
                    controller_read_nack <= controller_sda;
                end
                controller_read_nack_valid <= '1;
            end
        end else begin
            controller_read_nack_valid <= '0;
            controller_read_nack <= '1;
        end
        
        // repeated start can only be used to switch from write mode to read mode in SMBus protocol
        if (controller_smbstate == SMBCONTROLLER_STATE_CONTROLLER_CMD) begin
            controller_triggered_start <= '1;
        end else if ((controller_smbstate == SMBCONTROLLER_STATE_STOP) || (controller_smbstate == SMBCONTROLLER_STATE_IDLE)) begin            
            controller_triggered_start <= '0;
        end                        
    end
    
end
    
///////////////////////////////////////
// Determine the state of the relay, and drive the target and controller SMBus signals based on the state of the controller and target busses
///////////////////////////////////////

always_ff @(posedge clock or negedge i_resetn) begin
    if (!i_resetn) begin
        relay_state                     <= RELAY_STATE_IDLE;
        o_controller_scl_oe                 <= '0;
        o_controller_sda_oe                 <= '0;
        target_scl_hold_count            <= {SCLK_HOLD_COUNTER_BIT_WIDTH{1'b0}};
        setup_timeout                   <= 10'b0;
        
    end else begin
    
        case ( relay_state )
        
            // IDLE state
            // waiting for a start condition on the controller busses
            RELAY_STATE_IDLE: begin
                if (controller_smbstate == SMBCONTROLLER_STATE_START) begin
                    relay_state <= RELAY_STATE_START_WAIT_TIMEOUT;
                end
                o_controller_scl_oe <= '0;
                o_controller_sda_oe <= '0;
            end
            // START_WAIT_TIMEOUT
            // Start condition has been received on the controller bus
            // Drive a start condition on the target bus (SDA goes low while SCL is high) and wait for a timeout
            // If controller SCL goes low during this state, hold it there to prvent further progress on the controller bus until the target bus can 'catch up'
            RELAY_STATE_START_WAIT_TIMEOUT: begin
                relay_state <= RELAY_STATE_START_CTOT_WAIT_START_RCV;
                o_controller_scl_oe <= '0;             // if controller SCL goes low, we hold it low
                o_controller_sda_oe <= '0; 
            end

            // START_WAIT_MSCL_LOW
            // Start condition has been received on the controller bus
            // Continue to drive a start condition on the target bus (SDA low while SCL is high) and wait for controller scl to go low
            // If controller SCL is low during this state, continue to hold it there to prvent further progress on the controller bus until the target bus can 'catch up'
            RELAY_STATE_START_WAIT_SCL_LOW: begin
                if (~controller_scl) begin
                    relay_state <= RELAY_STATE_CTOT_WAIT_SCL_HIGH;     // after a start, the controller is driving the bus
                end 
                else if (controller_smbstate == SMBCONTROLLER_STATE_STOP) begin        // stop right after start may not be legal, but safter to handle this case anyway
                    relay_state <= RELAY_STATE_STOP_WAIT_TIMEOUT;
                end
                o_controller_scl_oe <= '0;             // if controller SCL goes low, we hold it low
                o_controller_sda_oe <= '0; 
            end
            // Add by Jiayi
            // CTOT_MSCL_LOW_WAIT_SSCL_LOW
            // This state exists to provide some hold time on the target SDA signal, we drive target SCL low and wait until we observe it low (which has several clock cycles of delay) before proceeding
            // While in this state, we hold the old value of o_target_sda_oe
            // Clockstretch the controller SCL (which is also low) during this state
            RELAY_STATE_START_CTOT_WAIT_START_RCV: begin
                    if(event_waiting_count == 25'b0) begin //timeout
                    relay_state <= RELAY_STATE_IDLE;                                                            
                end
                else if(ioc_frame_remote == start_rcv && ~controller_scl) begin
                    relay_state <= RELAY_STATE_CTOT_WAIT_SCL_HIGH;
                end
                else if(ioc_frame_remote == start_rcv && controller_scl) begin
                    relay_state <= RELAY_STATE_START_WAIT_SCL_LOW;
                end
                o_controller_scl_oe <= ~controller_scl;             // when controller SCL is low here, we continue to hold it low, until we recive start recv
                o_controller_sda_oe <= '0; 
            end
            // CTOT_WAIT_MSCL_HIGH
            // Controller is driving the bus, SDA from the controller bus to the target bus
            // Release controller SCL and wait for it to go high, while continuing to hold target scl low
            RELAY_STATE_CTOT_WAIT_SCL_HIGH: begin
                if (controller_scl) begin
                    relay_state <= RELAY_STATE_CTOT_WAIT_BIT_RCV;
                end
                o_controller_scl_oe <= '0;
                o_controller_sda_oe <= '0; 
            end
            // CTOT_WAIT_MSCL_LOW
            // Controller is driving the bus, SDA from the controller bus to the target bus
            // Wait for controller SCL to go low, then hold it low (clockstretch) and proceed to state where we drive the target scl low
            RELAY_STATE_CTOT_WAIT_SCL_LOW: begin

                if (~controller_scl) begin      // need to look at a delayed version of controller scl, to give controller_smbstate state machine time to update
                    relay_state <= RELAY_STATE_CTOT_SCL_LOW_WAIT_TIMEOUT;
                end
                o_controller_scl_oe <= '0;             // if controller SCL is low, we hold it low
                o_controller_sda_oe <= '0; 
            end                
            // CTOT_WAIT_SSCL_HIGH
            // Controller is driving the bus, SDA from the controller bus to the target bus
            // Release target SCL and wait for it to go high
            // If controller SCL goes low again during this state, hold it there to prvent further progress on the controller bus until the target bus can 'catch up'
            RELAY_STATE_CTOT_WAIT_BIT_RCV: begin
                if(event_waiting_count == 25'b0) begin //timeout
                    relay_state <= RELAY_STATE_IDLE;                                                            
                end    
                else if (controller_smbstate == SMBCONTROLLER_STATE_START) begin
                    relay_state <= RELAY_STATE_START_WAIT_TIMEOUT;
                end 
                else if (controller_smbstate == SMBCONTROLLER_STATE_STOP /*|| controller_smbstate == SMBCONTROLLER_STATE_STOP_THEN_START*/) begin
                    relay_state <= RELAY_STATE_STOP_WAIT_TIMEOUT;
                end
                else if(ioc_frame_remote == bit_rcv && ~controller_scl_dly/*|| ioc_frame_remote == stop_rcv*/) begin
                    if( (controller_smbstate == SMBCONTROLLER_STATE_TARGET_ADDR_ACK)     ||
                        (controller_smbstate == SMBCONTROLLER_STATE_TARGET_CMD_ACK)      ||
                        (controller_smbstate == SMBCONTROLLER_STATE_TARGET_WRITE_ACK)    ||
                        (controller_smbstate == SMBCONTROLLER_STATE_TARGET_READ) )   begin
                        relay_state <= RELAY_STATE_TTOC_WAIT_EVENT;
                    end
                    else begin
                        relay_state <= RELAY_STATE_CTOT_SCL_LOW_WAIT_TIMEOUT;
                    end
                end
                else if(ioc_frame_remote == bit_rcv && controller_scl_dly) begin
                    relay_state <= RELAY_STATE_CTOT_WAIT_SCL_LOW;
                end
                o_controller_scl_oe <= ~controller_scl;             // if controller SCL goes low, we hold it low
                o_controller_sda_oe <= '0; 
            end
            // CTOT_SSCL_LOW_WAIT_TIMEOUT
            // Controller is driving the bus, SDA from the controller bus to the target bus
            // We are driving target SCL low, wait for a timeout before allowing it to go high
            // Clockstretch the controller SCL (which is also low) during this state
            RELAY_STATE_CTOT_SCL_LOW_WAIT_TIMEOUT: begin
                relay_state <= RELAY_STATE_CTOT_WAIT_SCL_HIGH;
                o_controller_scl_oe <= ~controller_scl;             // we know controller SCL is low here, we continue to hold it low
                o_controller_sda_oe <= '0; 
            end
            // TTOC_MSCL_LOW_WAIT_SSCL_LOW
            // We start driving target SCL low, wait to observe it actually going low before releasing the o_target_sda_oe signal
            // This state exists to provide some hold timing on target SDA after target SCL goes low
            // Clockstretch the controller SCL (which is also low) during this state
            RELAY_STATE_TTOC_WAIT_EVENT: begin
                if(event_waiting_count == 25'b0) begin //timeout
                    relay_state <= RELAY_STATE_IDLE;                                
                    o_controller_scl_oe <= '0;             // we know controller SCL is low here, we continue to hold it low
                    o_controller_sda_oe <= '0;              // drive sda from the target bus to the controller bus                            
                end
                else if(ioc_frame_remote == data_0) begin
                    relay_state <= RELAY_STATE_TTOC_SCL_LOW_WAIT_SETUP_TIMEOUT;                                
                    o_controller_scl_oe <= '1;             // we know controller SCL is low here, we continue to hold it low
                    o_controller_sda_oe <= '1;              // drive sda from the target bus to the controller bus
                end
                else if(ioc_frame_remote == data_1) begin
                    relay_state <= RELAY_STATE_TTOC_SCL_LOW_WAIT_SETUP_TIMEOUT;                                
                    o_controller_scl_oe <= '1;             // we know controller SCL is low here, we continue to hold it low
                    o_controller_sda_oe <= '0;              // drive sda from the target bus to the controller bus
                end
                else begin
                    o_controller_scl_oe <= '1;             // we know controller SCL is low here, we continue to hold it low
                    o_controller_sda_oe <= o_controller_sda_oe;
                end
            end
            // TTOC_SSCL_LOW_WAIT_TIMEOUT
            // Target is driving data, SDA from the target bus to the controller
            // We are driving target SCL low, wait for a timeout before allowing it to go high
            // Clockstretch the controller SCL (which is also low) during this state
            RELAY_STATE_TTOC_SCL_LOW_WAIT_SETUP_TIMEOUT: begin
                if(setup_timeout == SETUP_TIME_COUNT) begin
                    setup_timeout <= 10'b0;
                    relay_state <= RELAY_STATE_TTOC_WAIT_SCL_HIGH;
                end
                else begin
                    setup_timeout <= setup_timeout + 10'd1;
                end
                o_controller_scl_oe <= '1;             // we know controller SCL is low here, we continue to hold it low
                o_controller_sda_oe <= o_controller_sda_oe;
            end

            // TTOC_SSCL_HIGH_WAIT_MSCL_HIGH
            // Target is driving data, SDA from the target bus to the controller
            // Target SCL is high, release controller SCL and wait for it to go high
            // Continue to clockstretch (hold SCL low) on the controller bus until we have received data from the target bus
            RELAY_STATE_TTOC_WAIT_SCL_HIGH: begin
                if (controller_scl) begin
                    relay_state <= RELAY_STATE_TTOC_WAIT_SCL_LOW;
                end
                o_controller_scl_oe <= '0;
                o_controller_sda_oe <= o_controller_sda_oe;
            end
            // TTOC_SSCL_HIGH_WAIT_MSCL_LOW
            // Target is driving data, SDA from the target bus to the controller
            // Target and controller SCL are high, we are waiting for controller SCL to go low
            RELAY_STATE_TTOC_WAIT_SCL_LOW: begin
                if (controller_smbstate == SMBCONTROLLER_STATE_STOP /*|| controller_smbstate == SMBCONTROLLER_STATE_STOP_THEN_START*/) begin
                    relay_state <= RELAY_STATE_STOP_WAIT_TIMEOUT;
                end else begin
                    if (~controller_scl_dly) begin      // need to look at a delayed version of controller scl, to give controller_smbstate state machine time to update
                        if ( controller_smbstate == SMBCONTROLLER_STATE_TARGET_READ ) begin      // only in the TARGET_READ state do we have two SMBus cycles in a row where the target drives data to the controller
                            relay_state <= RELAY_STATE_TTOC_WAIT_EVENT;                                
                        end 
                        else begin
                            relay_state <= RELAY_STATE_CTOT_SCL_LOW_WAIT_TIMEOUT;
                        end
                    end
                end
                o_controller_scl_oe <= '0;
                o_controller_sda_oe <= o_controller_sda_oe;
            end
            // STOP_WAIT_SSCL_LOW
            // Sending a stop condition on the target bus
            // Drive target SCL low, wait to see it has gone low before driving SDA low (which happens in the next state)
            // Clockstretch the controller bus if controller SCL is driven low, to prevent the controller bus from getting 'ahead' of the target bus
            RELAY_STATE_STOP_WAIT_TIMEOUT: begin            
                if (target_scl_hold_count_timeout) begin
                    relay_state <= RELAY_STATE_STOP;
                end
                o_controller_scl_oe <= /*~controller_scl*/1'b1;             // clockstretch on the controller bus if controller scl is driven low
                o_controller_sda_oe <= '0;
            end
            RELAY_STATE_STOP: begin
                relay_state <= RELAY_STATE_WAIT_STOP_RCV;
                o_controller_scl_oe <= ~controller_scl;             // clockstretch on the controller bus if controller scl is driven low
                o_controller_sda_oe <= '0;    
            end
            RELAY_STATE_WAIT_STOP_RCV: begin
                if(event_waiting_count == 25'b0) begin //timeout
                    relay_state <= RELAY_STATE_IDLE;
                end
                else if(ioc_frame_remote == stop_rcv) begin
                    if(controller_smbstate == SMBCONTROLLER_STATE_STOP_THEN_START)
                        relay_state <= RELAY_STATE_START_CTOT_WAIT_START_RCV;
                    else
                        relay_state <= RELAY_STATE_IDLE;
                end
                o_controller_scl_oe <= ~controller_scl;             // clockstretch on the controller bus if controller scl is driven low
                o_controller_sda_oe <= '0;
            end
            default: begin
                relay_state <= RELAY_STATE_IDLE;
                o_controller_scl_oe <= '0;             // clockstretch on the controller bus if controller scl is driven low
                o_controller_sda_oe <= '0;
            end
        endcase

        // counter to determine how long to hold target_scl low or high 
        // used when creating 'artificial' scl clock pulses on target while clock stretching the controller during ack and read data phases
        // counter counts from some positive value down to -1, thus checking the highest bit (sign bit) is adequate to determine if the count is 'done'
        if (target_scl_hold_count_restart) begin
            target_scl_hold_count <= SCLK_HOLD_MIN_COUNT[SCLK_HOLD_COUNTER_BIT_WIDTH-1:0] - {{SCLK_HOLD_COUNTER_BIT_WIDTH-1{1'b0}}, 1'b1}; 
        end else if (!target_scl_hold_count[SCLK_HOLD_COUNTER_BIT_WIDTH-1]) begin        // count down to -1 (first time msb goes high) and then stop
            target_scl_hold_count <= target_scl_hold_count - {{SCLK_HOLD_COUNTER_BIT_WIDTH-1{1'b0}}, 1'b1};
        end

        if (!event_waiting_count_restart) begin 
            //event_waiting_count <= 20'd600000; 
            event_waiting_count <= 25'd1500000;
        end 
        else begin        // count down to -1 (first time msb goes high) and then stop
            event_waiting_count <= event_waiting_count - 25'd1;
        end
    end
end

// when the msb of target_scl_hold_count = 1, that indicates a negative number, which means the timeout has occurred
assign target_scl_hold_count_timeout = target_scl_hold_count[SCLK_HOLD_COUNTER_BIT_WIDTH-1];
assign stretch_timeout = target_scl_hold_count_timeout;

// determine when to reset the counter based on the current relay state
// creatre this signal with combinatorial logic so counter will be reset as we enter the next state
// we never have two states in a row that both require this counter
assign target_scl_hold_count_restart = ( (relay_state == RELAY_STATE_START_WAIT_TIMEOUT)                 ||
                                        (relay_state == RELAY_STATE_CTOT_SCL_LOW_WAIT_TIMEOUT)          ||
                                        (relay_state == RELAY_STATE_STOP_WAIT_TIMEOUT)                  ||
                                        (relay_state == RELAY_STATE_TTOC_SCL_LOW_WAIT_SETUP_TIMEOUT)    ||
                                        (relay_state == RELAY_STATE_TTOC_WAIT_SCL_HIGH)
                                        ) ? '0 : '1;
                                        

assign event_waiting_count_restart = ( (relay_state == RELAY_STATE_START_CTOT_WAIT_START_RCV)           ||
                                        (relay_state == RELAY_STATE_WAIT_STOP_RCV)                      ||
                                        (relay_state == RELAY_STATE_CTOT_WAIT_BIT_RCV)                  ||
                                        (relay_state == RELAY_STATE_TTOC_WAIT_EVENT)
                                        ) ? '1 : '0;

/////////////////DEBUG///////////

assign dbg_cntrl_controller_smbstate           = controller_smbstate;
assign dbg_cntrl_relay_state                   = relay_state;

/////////////////////////////////

endmodule
