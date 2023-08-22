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

module altera_avalon_i2c_mstfsm (
    input           clk,
    input           rst_n,
    input           ctrl_en,
    input [9:0]     tfr_cmd,                   // TX shifter
    input           start_done,                 // Start gen
    input           stop_done,                  // Stop gen
    input           restart_done,               // Restart gen
    input           mst_tx_shift_done,          // TX shifter
    input           mst_rx_shift_done,          // RX shifter
    input           mst_rx_shift_check_hold,
    input           ack_det,
    input           bus_idle,
    input           arb_lost,
    input           txfifo_empty,
    input           txfifo_empty_nodly,
    input           pre_loaded_restart_bit,
    input           flush_txfifo,

    output          load_tx_shifter,            // TX shifter
    output reg      mst_tx_en,                  // TX shifter
    output reg      mst_rx_en,                  // RX shifter
    output reg      start_en,                   // Start gen
    output reg      restart_en,                 // Restart gen
    output reg      stop_en,                    // Stop gen
    output          mstfsm_emptyfifo_hold_en,  
    output reg      mstfsm_b2b_rxshift,
    output reg      tx_byte_state,
    output reg      gen_7bit_addr_state,
    output          mstfsm_idle_state,
    output reg      pop_tx_fifo_state,
    output reg      pop_tx_fifo_state_dly,
    output          mst_rx_ack_nack,
    output          abrt_txdata_noack,
    output          abrt_7b_addr_noack,  
    output reg      gen_stop_state

);

reg [3:0]   mst_fsm_state;
reg [3:0]   mst_fsm_state_nxt;
reg         rw_cmd;

wire        restart_cmd;
wire        stop_cmd;

reg         sent_7bit_addr;
reg         rx_hold_flag;

reg         gen_7bit_addr_state_nxt;
reg         pop_tx_fifo_state_nxt;
reg         tx_byte_state_nxt;

//reg         gen_start_state;
//reg         gen_start_state_nxt;
reg         idle_state;
reg         idle_state_nxt;
reg         rx_byte_state;
reg         rx_byte_state_nxt;
//reg         hold_state;
reg         hold_state_nxt;
reg         gen_stop_state_nxt;
reg         pre_idle_state_nxt;
reg         pre_idle_state;

reg         mst_tx_en_nxt;
reg         mst_rx_en_nxt;
reg         start_en_nxt;
reg         restart_en_nxt;
reg         stop_en_nxt;
reg         ctrl_en_dly;

wire        set_rx_hold_flag;
wire        set_7bit_addr;
wire        clear_rx_hold_flag;
wire        clear_sent_7bit_addr;
wire        gen_restart_7bit_state_nxt;
wire        mstfsm_b2b_rxshift_pre_flp;
wire        ctrl_en_pulse;
wire        rw_cmd_mux;



localparam [3:0]    IDLE                = 4'b0000;
localparam [3:0]    PRE_START           = 4'b0001;
localparam [3:0]    GEN_START           = 4'b0010;
localparam [3:0]    POP_TX_FIFO         = 4'b0011;
localparam [3:0]    TX_BYTE             = 4'b0100;
localparam [3:0]    RX_BYTE             = 4'b0101;
localparam [3:0]    GEN_7BIT_ADDR       = 4'b0110;
localparam [3:0]    GEN_RESTART_7BIT    = 4'b0111;
localparam [3:0]    BUS_HOLD            = 4'b1000; // Rename to BUS_HOLD, HOLD is EDIF, SDF keyword - Spyglass STARC05-1.1.1.3
localparam [3:0]    GEN_STOP            = 4'b1001;
localparam [3:0]    PRE_IDLE            = 4'b1010;


// Transfer Command bits mapping
assign  restart_cmd = tfr_cmd[9];
assign  stop_cmd    = tfr_cmd[8];

// Misc assignments
assign gen_restart_7bit_state_nxt   = (mst_fsm_state_nxt == GEN_RESTART_7BIT);
assign load_tx_shifter              = pop_tx_fifo_state_nxt;
assign set_7bit_addr                = gen_7bit_addr_state & ~gen_7bit_addr_state_nxt;
assign mstfsm_emptyfifo_hold_en     = txfifo_empty & ~stop_cmd & ((tx_byte_state & ack_det) | rx_byte_state | (gen_7bit_addr_state & ack_det));
assign mstfsm_b2b_rxshift_pre_flp   = rx_byte_state & rx_byte_state_nxt & rx_hold_flag;

assign mst_rx_ack_nack              =   (pre_loaded_restart_bit & ~txfifo_empty & ~rx_hold_flag) |
                                        (restart_cmd & rx_hold_flag) |
                                        (stop_cmd & ~rx_hold_flag);

assign mstfsm_idle_state    =   idle_state | pre_idle_state;
assign abrt_txdata_noack    =   tx_byte_state & gen_stop_state_nxt & ~ack_det;
assign abrt_7b_addr_noack   =   gen_7bit_addr_state & gen_stop_state_nxt;



// FSM registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        mst_fsm_state <= IDLE;
    else
        mst_fsm_state <= mst_fsm_state_nxt;
end

// FSM state transition
always @* begin
    case (mst_fsm_state)
        IDLE: begin
            if (ctrl_en_pulse)
                mst_fsm_state_nxt = PRE_START;
            else
                mst_fsm_state_nxt = IDLE;
        end
        
        PRE_START: begin
            if (~flush_txfifo & bus_idle & ~txfifo_empty)
                mst_fsm_state_nxt = GEN_START;
            else
                mst_fsm_state_nxt = PRE_START;
        end

        GEN_START: begin
            if (start_done)
                mst_fsm_state_nxt = POP_TX_FIFO;
            else
                mst_fsm_state_nxt = GEN_START;
        end

        POP_TX_FIFO: begin
            if (~sent_7bit_addr)
                mst_fsm_state_nxt = GEN_7BIT_ADDR;
            else if (sent_7bit_addr & restart_cmd & ~rx_hold_flag)
                mst_fsm_state_nxt = GEN_RESTART_7BIT;
            else if (~restart_cmd & ~rw_cmd)
                mst_fsm_state_nxt = TX_BYTE;
            else if ((~restart_cmd & rw_cmd) | rx_hold_flag)
                mst_fsm_state_nxt = RX_BYTE;
            else
                mst_fsm_state_nxt = POP_TX_FIFO;
        end

        TX_BYTE: begin
            if (arb_lost)
                mst_fsm_state_nxt = PRE_IDLE;
            else if (mst_tx_shift_done & ack_det & ~txfifo_empty & ~stop_cmd)
                mst_fsm_state_nxt = POP_TX_FIFO;
            else if (mst_tx_shift_done & ack_det & txfifo_empty & ~stop_cmd)
                mst_fsm_state_nxt = BUS_HOLD;
            else if (mst_tx_shift_done & (~ack_det | stop_cmd))
                mst_fsm_state_nxt = GEN_STOP;
            else
                mst_fsm_state_nxt = TX_BYTE;
        end

        RX_BYTE: begin
            if (arb_lost)
                mst_fsm_state_nxt = PRE_IDLE;
            else if (mst_rx_shift_check_hold & ~stop_cmd)
                mst_fsm_state_nxt = BUS_HOLD;
            else if (mst_rx_shift_done & ~txfifo_empty & ~stop_cmd & ~rx_hold_flag)
                mst_fsm_state_nxt = POP_TX_FIFO;
            else if (mst_rx_shift_done & stop_cmd & ~rx_hold_flag)
                mst_fsm_state_nxt = GEN_STOP;
            else if (mst_rx_shift_done & restart_cmd & rx_hold_flag)
                mst_fsm_state_nxt = GEN_RESTART_7BIT;
            else
                mst_fsm_state_nxt = RX_BYTE;
        end

        GEN_7BIT_ADDR: begin
            if (arb_lost)
                mst_fsm_state_nxt = PRE_IDLE;
            else if (mst_tx_shift_done & ~ack_det)
                mst_fsm_state_nxt = GEN_STOP;
            else if (mst_tx_shift_done & ack_det & ~txfifo_empty)
                mst_fsm_state_nxt = POP_TX_FIFO;
            else if (mst_tx_shift_done & ack_det & txfifo_empty)
                mst_fsm_state_nxt = BUS_HOLD;
            else
                mst_fsm_state_nxt = GEN_7BIT_ADDR;
        end

        GEN_RESTART_7BIT: begin
            if (restart_done)
                mst_fsm_state_nxt = GEN_7BIT_ADDR;
            else
                mst_fsm_state_nxt = GEN_RESTART_7BIT;
        end

        BUS_HOLD: begin
            if (~txfifo_empty)
                mst_fsm_state_nxt = POP_TX_FIFO;
            else
                mst_fsm_state_nxt = BUS_HOLD;
        end

        GEN_STOP: begin
            if (stop_done & ~txfifo_empty_nodly)        // no delay version to avoid race condition between sw polling on core_status bit 
                mst_fsm_state_nxt = PRE_START;          // right after it write to txfifo vs core_status bit update
            else if (stop_done & txfifo_empty_nodly)
                mst_fsm_state_nxt = PRE_IDLE;
            else
                mst_fsm_state_nxt = GEN_STOP;
        end
        
        PRE_IDLE: begin
            if (~txfifo_empty_nodly & ~flush_txfifo)
                mst_fsm_state_nxt = PRE_START;
            else if (~ctrl_en) 
                mst_fsm_state_nxt = IDLE;
            else
                mst_fsm_state_nxt = PRE_IDLE;
        end

        default: begin
            mst_fsm_state_nxt = 4'bxxxx;
        end

    endcase
end


// Control signal based on FSM state
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mst_tx_en               <= 1'b0;
        mst_rx_en               <= 1'b0;
        start_en                <= 1'b0;
        stop_en                 <= 1'b0;
        restart_en              <= 1'b0;
        gen_7bit_addr_state     <= 1'b0;
        pop_tx_fifo_state       <= 1'b0;
        tx_byte_state           <= 1'b0;
        rx_byte_state           <= 1'b0;
        //gen_start_state         <= 1'b0;
        idle_state              <= 1'b1;
        //hold_state              <= 1'b0;
        gen_stop_state          <= 1'b0;
        pre_idle_state          <= 1'b0;
    end
    else begin
        mst_tx_en               <= mst_tx_en_nxt;
        mst_rx_en               <= mst_rx_en_nxt;
        start_en                <= start_en_nxt;
        stop_en                 <= stop_en_nxt;
        restart_en              <= restart_en_nxt;
        gen_7bit_addr_state     <= gen_7bit_addr_state_nxt;
        pop_tx_fifo_state       <= pop_tx_fifo_state_nxt;
        tx_byte_state           <= tx_byte_state_nxt;
        rx_byte_state           <= rx_byte_state_nxt;
        //gen_start_state         <= gen_start_state_nxt;
        idle_state              <= idle_state_nxt;
        //hold_state              <= hold_state_nxt;
        gen_stop_state          <= gen_stop_state_nxt;
        pre_idle_state          <= pre_idle_state_nxt;
    end
end


always @* begin
    mst_tx_en_nxt               = 1'b0;
    mst_rx_en_nxt               = 1'b0;
    start_en_nxt                = 1'b0;
    stop_en_nxt                 = 1'b0;
    restart_en_nxt              = 1'b0;
    gen_7bit_addr_state_nxt     = 1'b0;
    pop_tx_fifo_state_nxt       = 1'b0;
    tx_byte_state_nxt           = 1'b0;
    rx_byte_state_nxt           = 1'b0;
    //gen_start_state_nxt         = 1'b0;
    idle_state_nxt              = 1'b0;
    hold_state_nxt              = 1'b0;
    gen_stop_state_nxt          = 1'b0;
    pre_idle_state_nxt          = 1'b0;

    case (mst_fsm_state_nxt)
        IDLE: begin
             idle_state_nxt = 1'b1;
        end
        
        PRE_START: begin
            // Not used
        end

        GEN_START: begin
            start_en_nxt        = 1'b1;    
            //gen_start_state_nxt = 1'b1;
        end

        POP_TX_FIFO: begin
            pop_tx_fifo_state_nxt = 1'b1;
        end

        TX_BYTE: begin
            mst_tx_en_nxt       = 1'b1;
            tx_byte_state_nxt   = 1'b1;
        end

        RX_BYTE: begin
            mst_rx_en_nxt       = 1'b1;    
            rx_byte_state_nxt   = 1'b1;
        end
            
        GEN_7BIT_ADDR: begin
            mst_tx_en_nxt           = 1'b1;
            gen_7bit_addr_state_nxt = 1'b1;
        end
            
        GEN_RESTART_7BIT: begin
            restart_en_nxt  = 1'b1;
        end

        BUS_HOLD: begin
            hold_state_nxt  = 1'b1;
            
            if (set_rx_hold_flag | rx_hold_flag) begin  // case:406120 This branch to handle scenario where BUS_HOLD is transitioned from RX_BYTE
                mst_tx_en_nxt   = 1'b0;
                mst_rx_en_nxt   = 1'b1;
            end
            else begin                                  // case:406120 This branch to handle scenario where BUS_HOLD is transitioned from TX_BYTE or GEN_7BIT_ADDR
                mst_tx_en_nxt   = 1'b1;
                mst_rx_en_nxt   = 1'b0;
            end
        end

        GEN_STOP: begin
            stop_en_nxt         = 1'b1;
            gen_stop_state_nxt  = 1'b1;
        end
        
        PRE_IDLE: begin
            pre_idle_state_nxt  = 1'b1;
        end
            
        default: begin
            mst_tx_en_nxt               = 1'bx;    
            mst_rx_en_nxt               = 1'bx;
            start_en_nxt                = 1'bx;
            restart_en_nxt              = 1'bx;
            stop_en_nxt                 = 1'bx;
            gen_7bit_addr_state_nxt     = 1'bx;
            pop_tx_fifo_state_nxt       = 1'bx;
            tx_byte_state_nxt           = 1'bx;
            rx_byte_state_nxt           = 1'bx;
            //gen_start_state_nxt         = 1'bx;
            idle_state_nxt              = 1'bx;
            hold_state_nxt              = 1'bx;
            gen_stop_state_nxt          = 1'bx;
            pre_idle_state_nxt          = 1'bx;
        end

    endcase
end


assign clear_sent_7bit_addr =   idle_state |
                                gen_stop_state |
                                pre_idle_state |
                                (pop_tx_fifo_state & gen_restart_7bit_state_nxt) |
                                (rx_byte_state & gen_restart_7bit_state_nxt);


// stored read or write request bit during address phase.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rw_cmd <= 1'b0;
    else
        rw_cmd <= rw_cmd_mux;
end

// case:405219 unregistered version (tfr_cmd[0] instead of rw_cmd) is needed in mst_tx_en_nxt and mst_rx_en_nxt logic generation (during GEN_7BIT_ADDR to BUS_HOLD scenario)
assign rw_cmd_mux = set_7bit_addr ? tfr_cmd[0] : rw_cmd;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        sent_7bit_addr <= 1'b0;
    else if (set_7bit_addr)
        sent_7bit_addr <= 1'b1;
    else if (clear_sent_7bit_addr)
        sent_7bit_addr <= 1'b0;
    else
        sent_7bit_addr <= sent_7bit_addr;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        pop_tx_fifo_state_dly <= 1'b0;
    else
        pop_tx_fifo_state_dly <= pop_tx_fifo_state;
end


assign set_rx_hold_flag     = rx_byte_state & hold_state_nxt; 
assign clear_rx_hold_flag   = mst_rx_shift_done; 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rx_hold_flag <= 1'b0;
    else if (set_rx_hold_flag)
        rx_hold_flag <= 1'b1;
    else if (clear_rx_hold_flag)
        rx_hold_flag <= 1'b0;
    else
        rx_hold_flag <= rx_hold_flag;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mstfsm_b2b_rxshift <= 1'b0;
    end
    else begin
        mstfsm_b2b_rxshift <= mstfsm_b2b_rxshift_pre_flp;
    end
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        ctrl_en_dly <= 1'b0;
    else
        ctrl_en_dly <= ctrl_en;
end

assign ctrl_en_pulse = ctrl_en & ~ctrl_en_dly; 

endmodule
