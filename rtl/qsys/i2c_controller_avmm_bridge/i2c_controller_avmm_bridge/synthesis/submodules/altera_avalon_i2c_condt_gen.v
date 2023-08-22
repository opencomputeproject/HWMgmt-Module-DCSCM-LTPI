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

module altera_avalon_i2c_condt_gen (
    input       clk,
    input       rst_n,
    input       start_hold_cnt_complete,
    input       start_en,
    
    input	scl_int,
    input       restart_scl_low_cnt_complete,
    input       restart_setup_cnt_complete,
    input       restart_hold_cnt_complete,
    input	restart_en,
    
    input       stop_scl_low_cnt_complete,
    input       stop_setup_cnt_complete,
    input       stop_en,

    output  reg    load_start_hold_cnt,
    output  reg    start_hold_cnt_en,
    output  reg    start_done,
    output  reg    start_sda_out,
    
    output  reg    load_restart_scl_low_cnt,
    output  reg    restart_scl_low_cnt_en,
    output  reg    load_restart_setup_cnt,
    output  reg    restart_setup_cnt_en,
    output  reg    load_restart_hold_cnt,
    output  reg    restart_hold_cnt_en,
    output  reg    restart_done,
    output  reg    restart_sda_out,
    output  reg    restart_scl_out,
    
    output  reg    load_stop_scl_low_cnt,
    output  reg    stop_scl_low_cnt_en,
    output  reg    load_stop_setup_cnt,
    output  reg    stop_setup_cnt_en,
    output  reg    stop_done,
    output  reg    stop_sda_out,
    output  reg    stop_scl_out
);


parameter   START_IDLE  = 2'b00,
            START_LOAD  = 2'b01,
            START_HOLD  = 2'b10,
            START_DONE  = 2'b11,

            RESTART_IDLE = 3'b000, 
            RESTART_LOAD = 3'b001,
            RESTART_SCL_LOW = 3'b010,
            RESTART_SETUP = 3'b011,
            RESTART_HOLD = 3'b100,
            RESTART_DONE = 3'b101,

            STOP_IDLE = 3'b000,
            STOP_LOAD = 3'b001,
            STOP_SCL_LOW = 3'b010,
            STOP_SETUP = 3'b011,
            STOP_DONE = 3'b100;



// wires & registers declaration
reg [1:0]   start_state, start_nx_state;
reg [2:0]   restart_state, restart_nx_state;
reg [2:0]   stop_state, stop_nx_state;



// START Condition generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        start_state <= START_IDLE;
    else
        start_state <= start_nx_state;
end


always @* begin
    case(start_state)
        START_IDLE: begin
            if (start_en)
                start_nx_state = START_LOAD; 
	    else
                start_nx_state = START_IDLE;
        end

        START_LOAD: begin
            if (~start_en)
                start_nx_state = START_IDLE;
	    else
                start_nx_state = START_HOLD;
        end

        START_HOLD: begin
            if (~start_en)
                start_nx_state = START_IDLE;
	    else if (start_hold_cnt_complete | ~scl_int)
                start_nx_state = START_DONE;
	    else
                start_nx_state = START_HOLD;
        end

        START_DONE: begin
            if (~start_en )
                start_nx_state = START_IDLE;        
	    else
                start_nx_state = START_DONE;
        end

        default: start_nx_state = 2'bx;

    endcase
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        load_start_hold_cnt     <= 1'b0;
        start_hold_cnt_en       <= 1'b0;
        start_done              <= 1'b0;
        start_sda_out           <= 1'b1;
    end
    else begin
        case(start_nx_state) 
	    START_IDLE : begin
	        load_start_hold_cnt <= 1'b0;
	        start_hold_cnt_en   <= 1'b0;
	        start_done          <= 1'b0;
	        start_sda_out       <= 1'b1;
   	    end
            START_LOAD : begin
                load_start_hold_cnt <= 1'b1;
                start_hold_cnt_en   <= 1'b0;
                start_done          <= 1'b0;
                start_sda_out       <= 1'b0;
	    end
	    START_HOLD : begin
                load_start_hold_cnt <= 1'b0;
                start_hold_cnt_en   <= 1'b1;
                start_done          <= 1'b0;
                start_sda_out       <= 1'b0;
	    end
	    START_DONE : begin
                load_start_hold_cnt <= 1'b0;
                start_hold_cnt_en   <= 1'b0;
                start_done          <= 1'b1;
                start_sda_out       <= 1'b0;
	    end
 	    default : begin
		load_start_hold_cnt <= 1'bx;
                start_hold_cnt_en   <= 1'bx;
                start_done          <= 1'bx;
                start_sda_out       <= 1'bx;
            end
    	endcase
    end
end

 // End of START condition generation




// RESTART Condition generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        restart_state <= RESTART_IDLE;
    else
        restart_state <= restart_nx_state;
end


always @* begin
    case(restart_state)
        RESTART_IDLE: begin
            if (restart_en)
                restart_nx_state = RESTART_LOAD;
            else
                restart_nx_state = RESTART_IDLE;
        end

        RESTART_LOAD: begin
            if (~restart_en)
                restart_nx_state = RESTART_IDLE;
	    else if (restart_scl_low_cnt_complete)
                restart_nx_state = RESTART_SETUP;
	    else if (restart_setup_cnt_complete)
                restart_nx_state = RESTART_HOLD;
	    else
                restart_nx_state = RESTART_SCL_LOW;
        end

        RESTART_SCL_LOW: begin
            if (~restart_en)
                restart_nx_state = RESTART_IDLE;
	    else if (restart_scl_low_cnt_complete)
                restart_nx_state = RESTART_LOAD;
	    else
                restart_nx_state = RESTART_SCL_LOW;
        end

        RESTART_SETUP: begin
            if (~restart_en)
                restart_nx_state = RESTART_IDLE;
	    else if (restart_setup_cnt_complete)
                restart_nx_state = RESTART_LOAD;
            else
                restart_nx_state = RESTART_SETUP;
        end

        RESTART_HOLD: begin
            if (~restart_en)
                restart_nx_state = RESTART_IDLE;
	    else if (restart_hold_cnt_complete | ~scl_int)
                restart_nx_state = RESTART_DONE;
	    else
                restart_nx_state = RESTART_HOLD;
        end

        RESTART_DONE: begin
            if (~restart_en)
                restart_nx_state = RESTART_IDLE;
	    else
                restart_nx_state = RESTART_DONE;
        end

	default: restart_nx_state = 3'bx;
    endcase
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        load_restart_scl_low_cnt    <= 1'b0;
        restart_scl_low_cnt_en      <= 1'b0;
        load_restart_setup_cnt      <= 1'b0;
        restart_setup_cnt_en        <= 1'b0;
        load_restart_hold_cnt       <= 1'b0;
        restart_hold_cnt_en         <= 1'b0;
        restart_done                <= 1'b0;
        restart_sda_out             <= 1'b1;
        restart_scl_out             <= 1'b1;
    end
    else begin
        case(restart_nx_state)
            RESTART_IDLE : begin
  	        load_restart_scl_low_cnt    <= 1'b0;
            	restart_scl_low_cnt_en      <= 1'b0;
                load_restart_setup_cnt      <= 1'b0;
                restart_setup_cnt_en        <= 1'b0;
                load_restart_hold_cnt       <= 1'b0;
        	restart_hold_cnt_en         <= 1'b0;
          	restart_done                <= 1'b0;
                restart_sda_out             <= 1'b1;
                restart_scl_out             <= 1'b1;
	     end
	    RESTART_LOAD : begin
	        restart_scl_low_cnt_en  <= 1'b0;
		restart_setup_cnt_en    <= 1'b0;
		restart_hold_cnt_en     <= 1'b0;
                restart_done            <= 1'b0;
                if (restart_scl_low_cnt_complete) begin
		    load_restart_scl_low_cnt    <= 1'b0;
		    load_restart_setup_cnt      <= 1'b1;
                    load_restart_hold_cnt       <= 1'b0;
                    restart_scl_out             <= 1'b1;
		    restart_sda_out             <= 1'b1;
		end 
		else if (restart_setup_cnt_complete) begin
		    load_restart_scl_low_cnt    <= 1'b0;
                    load_restart_setup_cnt      <= 1'b0;
		    load_restart_hold_cnt       <= 1'b1;
                    restart_scl_out             <= 1'b1;
		    restart_sda_out             <= 1'b0;
		end
		else begin
                    load_restart_scl_low_cnt    <= 1'b1;
                    load_restart_setup_cnt      <= 1'b0;
                    load_restart_hold_cnt       <= 1'b0;
                    restart_scl_out             <= 1'b0;
		    restart_sda_out             <= 1'b1;
		end
            end
            RESTART_SCL_LOW : begin
                load_restart_scl_low_cnt    <= 1'b0;
                restart_scl_low_cnt_en      <= 1'b1;
                load_restart_setup_cnt      <= 1'b0;
                restart_setup_cnt_en        <= 1'b0;
                load_restart_hold_cnt       <= 1'b0;
                restart_hold_cnt_en         <= 1'b0;
                restart_done                <= 1'b0;
                restart_sda_out             <= 1'b1;
                restart_scl_out             <= 1'b0;
            end
	    RESTART_SETUP : begin
                load_restart_scl_low_cnt    <= 1'b0;
                restart_scl_low_cnt_en      <= 1'b0;
                load_restart_setup_cnt      <= 1'b0;
                load_restart_hold_cnt       <= 1'b0;
                restart_hold_cnt_en         <= 1'b0;
                restart_done                <= 1'b0;
                restart_sda_out             <= 1'b1;
                restart_scl_out             <= 1'b1;

		if (scl_int)
                    restart_setup_cnt_en <= 1'b1;
		else
                    restart_setup_cnt_en <= 1'b0;	
	    end
	    RESTART_HOLD : begin
                load_restart_scl_low_cnt    <= 1'b0;
                restart_scl_low_cnt_en      <= 1'b0;
                load_restart_setup_cnt      <= 1'b0;
                restart_setup_cnt_en        <= 1'b0;
                load_restart_hold_cnt       <= 1'b0;
                restart_hold_cnt_en         <= 1'b1;
                restart_done                <= 1'b0;
                restart_sda_out             <= 1'b0;
                restart_scl_out             <= 1'b1;
            end
	    RESTART_DONE : begin
                load_restart_scl_low_cnt    <= 1'b0;
                restart_scl_low_cnt_en      <= 1'b0;
                load_restart_setup_cnt      <= 1'b0;
                restart_setup_cnt_en        <= 1'b0;
                load_restart_hold_cnt       <= 1'b0;
                restart_hold_cnt_en         <= 1'b0;
                restart_done                <= 1'b1;
                restart_sda_out             <= 1'b0;
                restart_scl_out             <= 1'b1;
            end
	    default : begin
		load_restart_scl_low_cnt    <= 1'bx;
                restart_scl_low_cnt_en      <= 1'bx;
                load_restart_setup_cnt      <= 1'bx;
                restart_setup_cnt_en        <= 1'bx;
                load_restart_hold_cnt       <= 1'bx;
                restart_hold_cnt_en         <= 1'bx;
                restart_done                <= 1'bx;
                restart_sda_out             <= 1'bx;
                restart_scl_out             <= 1'bx; 
	    end
        endcase
    end
end




// STOP Condition generation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        stop_state <= STOP_IDLE;
    else
        stop_state <= stop_nx_state;
end

always @* begin
    case(stop_state)
        STOP_IDLE: begin
            if (stop_en)
                stop_nx_state = STOP_LOAD;
            else
                stop_nx_state = STOP_IDLE;
        end

        STOP_LOAD: begin
            if (~stop_en)
                stop_nx_state = STOP_IDLE;
	    else if (stop_scl_low_cnt_complete)
                stop_nx_state = STOP_SETUP;
	    else
                stop_nx_state = STOP_SCL_LOW;
        end

        STOP_SCL_LOW: begin
            if (~stop_en)
                stop_nx_state = STOP_IDLE;
	    else if (stop_scl_low_cnt_complete)
                stop_nx_state = STOP_LOAD;
	    else
                stop_nx_state = STOP_SCL_LOW;
        end

        STOP_SETUP: begin
            if (~stop_en)
                stop_nx_state = STOP_IDLE;
	    else if (stop_setup_cnt_complete)
                stop_nx_state = STOP_DONE;
	    else
                stop_nx_state = STOP_SETUP;
        end

        STOP_DONE: begin
            if (~stop_en)
                stop_nx_state = STOP_IDLE;
            else
                stop_nx_state = STOP_DONE;
        end

        default: stop_nx_state = 3'bx;

    endcase
end


always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        load_stop_scl_low_cnt   <= 1'b0;
        stop_scl_low_cnt_en     <= 1'b0;
        load_stop_setup_cnt     <= 1'b0;
        stop_setup_cnt_en       <= 1'b0;
        stop_done               <= 1'b0;
        stop_sda_out            <= 1'b1;
        stop_scl_out            <= 1'b1;
    end
    else begin
        case(stop_nx_state)
            STOP_IDLE : begin
                load_stop_scl_low_cnt   <= 1'b0;
                stop_scl_low_cnt_en     <= 1'b0;
                load_stop_setup_cnt     <= 1'b0;
                stop_setup_cnt_en       <= 1'b0;
                stop_done               <= 1'b0;
                stop_sda_out            <= 1'b1;
                stop_scl_out            <= 1'b1;
            end
            STOP_LOAD : begin
                stop_scl_low_cnt_en     <= 1'b0;
                stop_setup_cnt_en       <= 1'b0;
                stop_done               <= 1'b0;
                stop_sda_out            <= 1'b0;	
                if (stop_scl_low_cnt_complete) begin
                    load_stop_scl_low_cnt   <= 1'b0;
                    load_stop_setup_cnt     <= 1'b1;
                    stop_scl_out            <= 1'b1;
                end
                else begin
                    load_stop_scl_low_cnt   <= 1'b1;
                    load_stop_setup_cnt     <= 1'b0;
                    stop_scl_out            <= 1'b0;
                end
            end
            STOP_SCL_LOW : begin
                load_stop_scl_low_cnt   <= 1'b0;
                stop_scl_low_cnt_en     <= 1'b1;
                load_stop_setup_cnt     <= 1'b0;
                stop_setup_cnt_en       <= 1'b0;
                stop_done               <= 1'b0;
                stop_sda_out            <= 1'b0;
                stop_scl_out            <= 1'b0;
             end
             STOP_SETUP : begin
                load_stop_scl_low_cnt   <= 1'b0;
                stop_scl_low_cnt_en     <= 1'b0;
                load_stop_setup_cnt     <= 1'b0;
                stop_done               <= 1'b0;
                stop_sda_out            <= 1'b0;
                stop_scl_out            <= 1'b1;

                if (scl_int)
                    stop_setup_cnt_en <= 1'b1;
                else
                    stop_setup_cnt_en <= 1'b0;
             end
             STOP_DONE : begin
                load_stop_scl_low_cnt   <= 1'b0;
                stop_scl_low_cnt_en     <= 1'b0;
                load_stop_setup_cnt     <= 1'b0;
                stop_setup_cnt_en       <= 1'b0;
                stop_done               <= 1'b1;
                stop_sda_out            <= 1'b1;
                stop_scl_out            <= 1'b1;
             end
             default : begin
                load_stop_scl_low_cnt   <= 1'bx;
                stop_scl_low_cnt_en     <= 1'bx;
                load_stop_setup_cnt     <= 1'bx;
                stop_setup_cnt_en       <= 1'bx;
                stop_done               <= 1'bx;
                stop_sda_out            <= 1'bx;
                stop_scl_out            <= 1'bx;
              end
            endcase
       end
  end

endmodule

