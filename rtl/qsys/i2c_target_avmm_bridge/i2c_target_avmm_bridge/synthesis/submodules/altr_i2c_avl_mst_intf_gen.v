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


`timescale 1 ps / 1 ps

module altr_i2c_avl_mst_intf_gen #(
	parameter BYTE_ADDRESSING = 2,
	parameter READ_ONLY = 1,
	parameter ADDRESS_STEALING = 0
) (
	input		       i2c_clk,
	input		       i2c_rst_n, 
	input			   waitrequest,
	input		       put_rx_databuffer,
	input		       set_rd_req,		
	input		       stop_det,
	input		       start_det,
	input       [7:0]  rdata_rx_databuffer,
	input		[31:0] avl_readdata,
	input			   avl_readdatavalid,   
	input			   slv_tx_chk_ack,
	input			   ack_det,
	input			   rx_addr_match,
	input		[2:0]  lsb_rx_shifter,
	output reg		   avl_read,
	output reg 	[7:0]  readdatabyte,
	output reg 	  	   avl_readdatavalid_reg,
	output reg 		   avl_write,
	output reg  [31:0] avl_writedata,
	output reg  [ 3:0] avl_byteenable,
	output wire [31:0] avl_addr
);

localparam [3:0]		IDLE			= 4'b0000;
localparam [3:0]		WORDADDRBYTE_1	= 4'b0001;
localparam [3:0]		WORDADDRBYTE_2	= 4'b0010;
localparam [3:0]		WORDADDRBYTE_3	= 4'b0011;
localparam [3:0]		WORDADDRBYTE_4	= 4'b0100;
localparam [3:0]		ASSIGN_RDADDR	= 4'b0101;
localparam [3:0]		ASSIGN_WRADDR	= 4'b0110;
localparam [3:0]		WRDATABYTE		= 4'b0111;
localparam [3:0]     	ISSUE_WRITE     = 4'b1000;
localparam [3:0]     	NEXT_WRITE		= 4'b1001;
localparam [3:0]     	WRITE_COMPLETE	= 4'b1010;
localparam [3:0]		SPLIT_WRITE		= 4'b1011;
localparam [3:0]     	ISSUE_READ      = 4'b1100;
localparam [3:0]     	RDDATABYTE      = 4'b1101;

localparam ADDRWIDTH = 32;
localparam BYTEADDRWIDTH = (BYTE_ADDRESSING == 1) ? (8+ADDRESS_STEALING) :
							(BYTE_ADDRESSING == 2) ? (16+ADDRESS_STEALING) :
								(BYTE_ADDRESSING == 3) ? (24+ADDRESS_STEALING) :
									(BYTE_ADDRESSING == 4) ? 32 : (16+ADDRESS_STEALING);

reg [3:0]  fsm_state;
reg [3:0]  fsm_state_nxt;
reg		   avl_read_nxt;
reg	[7:0]  readdatabyte_nxt;
reg		   avl_write_nxt;
reg	[31:0] avl_writedata_nxt;
reg [3:0]  temp_wrbyteen;
reg [3:0]  temp_wrbyteen_nxt;
reg [31:0] ori_wrdata;
reg [3:0]  ori_wrbyteen;
reg [31:0] ori_wrdata_nxt;
reg [3:0]  ori_wrbyteen_nxt;
reg [3:0]  avl_byteenable_nxt;
reg		   wordwrite_complete_nxt;
reg		   illegal_byteen_nxt;
reg		   illegal_byteen;
reg		   ack_det_reg;
reg 	   wordwrite_complete;
reg [ADDRWIDTH-1:0] load_addr_value_nxt;
reg [ADDRWIDTH-1:0] load_addr_value;
reg [BYTEADDRWIDTH-1:0] addr_cnt;
wire [2:0]  extra_addrbit;

wire incr_addr;
wire load_rdaddr;
wire load_wraddr;

generate if (READ_ONLY) begin
	assign incr_addr = (fsm_state == RDDATABYTE && avl_readdatavalid);
end
else begin
	assign incr_addr = ((fsm_state == RDDATABYTE && avl_readdatavalid) || (fsm_state == WRDATABYTE && put_rx_databuffer) || (fsm_state == NEXT_WRITE && put_rx_databuffer));
end
endgenerate

assign load_rdaddr = fsm_state == ASSIGN_RDADDR;
assign load_wraddr = fsm_state_nxt == ASSIGN_WRADDR;

generate if (BYTEADDRWIDTH == 32) begin
	assign avl_addr = {addr_cnt[BYTEADDRWIDTH-1:2], 2'b00};
end
else begin
	assign avl_addr = {{ADDRWIDTH-BYTEADDRWIDTH{1'b0}}, {addr_cnt[BYTEADDRWIDTH-1:2], 2'b00}};
end
endgenerate

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        fsm_state <= IDLE;
    else
        fsm_state <= fsm_state_nxt;
end

generate if (ADDRESS_STEALING > 0) begin
reg [2:0] extra_addrbit_reg;

	always @(posedge i2c_clk or negedge i2c_rst_n) begin
		if (!i2c_rst_n)
			extra_addrbit_reg <= {3{1'b0}};
		else if (rx_addr_match)
			extra_addrbit_reg <= lsb_rx_shifter;
	end
	
	assign extra_addrbit = extra_addrbit_reg;
end
else begin
	assign extra_addrbit = {3{1'b0}};
end
endgenerate

// Address increment counter
always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n)
        addr_cnt <= {BYTEADDRWIDTH{1'b0}};
	else if (incr_addr)							// priority else if
        addr_cnt <= addr_cnt + 1'b1;
	else if (load_rdaddr)
		addr_cnt <= load_addr_value[BYTEADDRWIDTH-1:0];
	else if (load_wraddr)
		addr_cnt <= load_addr_value_nxt[BYTEADDRWIDTH-1:0];
end

generate if (READ_ONLY) begin
	always @* begin
		case (fsm_state)
			IDLE: begin
				if (put_rx_databuffer)
					fsm_state_nxt = WORDADDRBYTE_1;
				else if (set_rd_req)		// to issue read for current address read
					fsm_state_nxt = ISSUE_READ;
				else
					fsm_state_nxt = IDLE;
			end
	
			WORDADDRBYTE_1:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;	
				else if (put_rx_databuffer)
					if (BYTE_ADDRESSING > 1) begin
						fsm_state_nxt = WORDADDRBYTE_2;
					end
					else begin
						fsm_state_nxt = IDLE;
					end
				else
					fsm_state_nxt = WORDADDRBYTE_1;
			end
			
			WORDADDRBYTE_2:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;
				else if (put_rx_databuffer)
					if (BYTE_ADDRESSING > 2) begin
						fsm_state_nxt = WORDADDRBYTE_3;
					end
					else begin
						fsm_state_nxt = IDLE;
					end
				else
					fsm_state_nxt = WORDADDRBYTE_2;
			end
			
			WORDADDRBYTE_3:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;
				else if (put_rx_databuffer)
					if (BYTE_ADDRESSING > 3) begin
						fsm_state_nxt = WORDADDRBYTE_4;
					end
					else begin
						fsm_state_nxt = IDLE;
					end
				else
					fsm_state_nxt = WORDADDRBYTE_3;
			end
			
			WORDADDRBYTE_4:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;	
				else if (put_rx_databuffer)
					fsm_state_nxt = IDLE;
				else
					fsm_state_nxt = WORDADDRBYTE_4;
			end
			
			ASSIGN_RDADDR:  begin
				fsm_state_nxt = IDLE;
			end
			
			ISSUE_READ: begin
				if (stop_det || start_det)  // to detect stop or repeated start                                       
					fsm_state_nxt = IDLE;
				else if (~waitrequest)
					fsm_state_nxt = RDDATABYTE;
				else
					fsm_state_nxt = ISSUE_READ;
			end
			
			RDDATABYTE: begin
				if (stop_det || start_det)  // to detect stop or repeated start                                       
					fsm_state_nxt = IDLE;
				else if (slv_tx_chk_ack && ack_det && ~ack_det_reg)
					fsm_state_nxt = ISSUE_READ;
				else
					fsm_state_nxt = RDDATABYTE;
			end
			
			default: begin
				fsm_state_nxt = 4'bxxxx;
			end
		endcase
	end
end 
else begin
	always @* begin
		case (fsm_state)
			IDLE: begin
				if (put_rx_databuffer)
					fsm_state_nxt = WORDADDRBYTE_1;
				else if (set_rd_req)		// to issue read for current address read
					fsm_state_nxt = ISSUE_READ;
				else
					fsm_state_nxt = IDLE;
			end
	
			WORDADDRBYTE_1:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;	
				else if (put_rx_databuffer)
					if (BYTE_ADDRESSING > 1) begin
						fsm_state_nxt = WORDADDRBYTE_2;
					end
					else begin
						fsm_state_nxt = ASSIGN_WRADDR;
					end
				else
					fsm_state_nxt = WORDADDRBYTE_1;
			end
			
			WORDADDRBYTE_2:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;
				else if (put_rx_databuffer)
					if (BYTE_ADDRESSING > 2) begin
						fsm_state_nxt = WORDADDRBYTE_3;
					end
					else begin
						fsm_state_nxt = ASSIGN_WRADDR;
					end
				else
					fsm_state_nxt = WORDADDRBYTE_2;
			end
			
			WORDADDRBYTE_3:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;
				else if (put_rx_databuffer)
					if (BYTE_ADDRESSING > 3) begin
						fsm_state_nxt = WORDADDRBYTE_4;
					end
					else begin
						fsm_state_nxt = ASSIGN_WRADDR;
					end
				else
					fsm_state_nxt = WORDADDRBYTE_3;
			end
			
			WORDADDRBYTE_4:  begin
				if (stop_det || start_det)                            
					fsm_state_nxt = ASSIGN_RDADDR;	
				else if (put_rx_databuffer)
					fsm_state_nxt = ASSIGN_WRADDR;
				else
					fsm_state_nxt = WORDADDRBYTE_4;
			end
			
			ASSIGN_RDADDR:  begin
				fsm_state_nxt = IDLE;
			end
			
			ASSIGN_WRADDR:  begin
				fsm_state_nxt = WRDATABYTE;
			end
			
			WRDATABYTE: begin
				if (stop_det || start_det)  // to detect stop or repeated start                                       
					fsm_state_nxt = WRITE_COMPLETE;
				else if (wordwrite_complete)
					fsm_state_nxt = ISSUE_WRITE;
				else
					fsm_state_nxt = WRDATABYTE;
			end
	
			ISSUE_WRITE:  begin				
				if (~waitrequest)
					if (illegal_byteen)
						fsm_state_nxt = SPLIT_WRITE;
					else
						fsm_state_nxt = NEXT_WRITE;
				else begin
					fsm_state_nxt = ISSUE_WRITE;
				end
			end
			
			NEXT_WRITE: begin
				if (stop_det || start_det)  // to detect stop or repeated start     
					fsm_state_nxt = IDLE;
				else if (put_rx_databuffer)
					fsm_state_nxt = ASSIGN_WRADDR;
				else
					fsm_state_nxt = NEXT_WRITE;
			end
			
            WRITE_COMPLETE: begin
                 //if (~waitrequest) begin
                     if (illegal_byteen) begin
                         fsm_state_nxt = SPLIT_WRITE;
                     end
                     else begin
                       if (~waitrequest) begin
                             fsm_state_nxt = IDLE;
                         end     
                         else begin    
                           fsm_state_nxt = WRITE_COMPLETE;
                         end
                     end
                     
                 //end
                 //else begin
                 //    fsm_state_nxt = WRITE_COMPLETE;
                 //end
            end
			
			SPLIT_WRITE: begin
				if (~illegal_byteen)
					fsm_state_nxt = IDLE;
				else
					fsm_state_nxt = ISSUE_WRITE;
			end
			
			ISSUE_READ: begin
				if (stop_det || start_det)  // to detect stop or repeated start                                       
					fsm_state_nxt = IDLE;
				else if (~waitrequest)
					fsm_state_nxt = RDDATABYTE;
				else
					fsm_state_nxt = ISSUE_READ;
			end
			
			RDDATABYTE: begin
				if (stop_det || start_det)  // to detect stop or repeated start                                       
					fsm_state_nxt = IDLE;
				else if (slv_tx_chk_ack && ack_det && ~ack_det_reg)
					fsm_state_nxt = ISSUE_READ;
				else
					fsm_state_nxt = RDDATABYTE;
			end
			
			default: begin
				fsm_state_nxt = 4'bxxxx;
			end
		endcase
	end
end
endgenerate

always @(posedge i2c_clk or negedge i2c_rst_n) begin
    if (!i2c_rst_n) begin
		avl_read				<= 1'b0;
		load_addr_value			<= {ADDRWIDTH{1'b0}};
		readdatabyte			<= {8{1'b0}};
		avl_readdatavalid_reg	<= 1'b0;
		ack_det_reg				<= 1'b0;
		avl_write				<= 1'b0;
		avl_writedata			<= {32{1'b0}};
		avl_byteenable		<= {4{1'b0}};
		wordwrite_complete		<= 1'b0;
		illegal_byteen			<= 1'b0;
		temp_wrbyteen			<= {4{1'b0}};
		ori_wrdata	 			<= {32{1'b0}};
		ori_wrbyteen	 		<= {4{1'b0}};
    end
    else begin
		avl_read				<= avl_read_nxt;
		load_addr_value			<= load_addr_value_nxt;
		readdatabyte    		<= readdatabyte_nxt;
		avl_readdatavalid_reg	<= avl_readdatavalid;
		ack_det_reg				<= ack_det;
		avl_write				<= avl_write_nxt;
		avl_writedata			<= avl_writedata_nxt;
		avl_byteenable		<= avl_byteenable_nxt;
		wordwrite_complete		<= wordwrite_complete_nxt;
		illegal_byteen			<= illegal_byteen_nxt;
		temp_wrbyteen			<= temp_wrbyteen_nxt;
		ori_wrdata	 			<= ori_wrdata_nxt;
		ori_wrbyteen	 		<= ori_wrbyteen_nxt;
    end
end

generate if (READ_ONLY) begin
	always @* begin
		avl_read_nxt = avl_read;
		load_addr_value_nxt = load_addr_value;
		readdatabyte_nxt = readdatabyte;
		avl_write_nxt = avl_write;
		avl_writedata_nxt = avl_writedata;
		avl_byteenable_nxt = avl_byteenable;
		wordwrite_complete_nxt = wordwrite_complete;
		illegal_byteen_nxt = illegal_byteen;
		temp_wrbyteen_nxt = temp_wrbyteen;
		ori_wrdata_nxt = ori_wrdata;
		ori_wrbyteen_nxt = ori_wrbyteen;
				
		case (fsm_state_nxt)
			IDLE: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = {ADDRWIDTH{1'b0}};
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
		
			WORDADDRBYTE_1: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = {8{1'b0}};
				load_addr_value_nxt[15:8]  = {8{1'b0}};
				load_addr_value_nxt[23:16] = {8{1'b0}};
				load_addr_value_nxt[31:24] = rdata_rx_databuffer;
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end 
		
			WORDADDRBYTE_2: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = {8{1'b0}};
				load_addr_value_nxt[15:8]  = {8{1'b0}};
				load_addr_value_nxt[23:16] = rdata_rx_databuffer;
				load_addr_value_nxt[31:24] = load_addr_value[31:24];
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			WORDADDRBYTE_3: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = {8{1'b0}};
				load_addr_value_nxt[15:8]  = rdata_rx_databuffer;
				load_addr_value_nxt[23:16] = load_addr_value[23:16];
				load_addr_value_nxt[31:24] = load_addr_value[31:24];
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			WORDADDRBYTE_4: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = rdata_rx_databuffer;
				load_addr_value_nxt[15:8]  = load_addr_value[15:8];
				load_addr_value_nxt[23:16] = load_addr_value[23:16];
				load_addr_value_nxt[31:24] = load_addr_value[31:24];
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			ASSIGN_RDADDR: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = load_addr_value;
				
				if (BYTE_ADDRESSING == 1) begin
					load_addr_value_nxt = (load_addr_value >> 24 | {{21{1'b0}}, extra_addrbit, {8{1'b0}}});
				end
				else if (BYTE_ADDRESSING == 2) begin
					load_addr_value_nxt = (load_addr_value >> 16 | {{13{1'b0}}, extra_addrbit, {16{1'b0}}});
				end
				else if (BYTE_ADDRESSING == 3) begin
					load_addr_value_nxt = (load_addr_value >> 8  | {{5{1'b0}}, extra_addrbit, {24{1'b0}}});
				end
				
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			ISSUE_READ:  begin
				avl_read_nxt = 1'b1;
				load_addr_value_nxt = load_addr_value;
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b1}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			RDDATABYTE:  begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = {ADDRWIDTH{1'b0}};
				readdatabyte_nxt = readdatabyte;
				
				if (avl_readdatavalid) begin
					if (addr_cnt[1:0] == 2'b00)
						readdatabyte_nxt = avl_readdata[7:0];
					else if (addr_cnt[1:0] == 2'b01)
						readdatabyte_nxt = avl_readdata[15:8];
					else if (addr_cnt[1:0] == 2'b10)
						readdatabyte_nxt = avl_readdata[23:16];
					else if (addr_cnt[1:0] == 2'b11)
						readdatabyte_nxt = avl_readdata[31:24];
				end
				
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
	
			default: begin
				avl_read_nxt = 1'bx;
				load_addr_value_nxt = {ADDRWIDTH{1'bx}};
				readdatabyte_nxt = {8{1'bx}};
				avl_write_nxt = 1'bx;
				avl_writedata_nxt = {32{1'bx}};
				avl_byteenable_nxt = {4{1'bx}};
				wordwrite_complete_nxt = 1'bx;
				illegal_byteen_nxt = 1'bx;
				temp_wrbyteen_nxt = {4{1'bx}};
				ori_wrdata_nxt = {32{1'bx}};
				ori_wrbyteen_nxt = {4{1'bx}};
			end
		endcase
	end
end
else begin
	always @* begin
		avl_read_nxt = avl_read;
		load_addr_value_nxt = load_addr_value;
		readdatabyte_nxt = readdatabyte;
		avl_write_nxt = avl_write;
		avl_writedata_nxt = avl_writedata;
		avl_byteenable_nxt = avl_byteenable;
		wordwrite_complete_nxt = wordwrite_complete;
		illegal_byteen_nxt = illegal_byteen;
		temp_wrbyteen_nxt = temp_wrbyteen;
		ori_wrdata_nxt = ori_wrdata;
		ori_wrbyteen_nxt = ori_wrbyteen;
				
		case (fsm_state_nxt)
			IDLE: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = {ADDRWIDTH{1'b0}};
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
		
			WORDADDRBYTE_1: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = {8{1'b0}};
				load_addr_value_nxt[15:8]  = {8{1'b0}};
				load_addr_value_nxt[23:16] = {8{1'b0}};
				load_addr_value_nxt[31:24] = rdata_rx_databuffer;
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end 
		
			WORDADDRBYTE_2: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = {8{1'b0}};
				load_addr_value_nxt[15:8]  = {8{1'b0}};
				load_addr_value_nxt[23:16] = rdata_rx_databuffer;
				load_addr_value_nxt[31:24] = load_addr_value[31:24];
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			WORDADDRBYTE_3: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = {8{1'b0}};
				load_addr_value_nxt[15:8]  = rdata_rx_databuffer;
				load_addr_value_nxt[23:16] = load_addr_value[23:16];
				load_addr_value_nxt[31:24] = load_addr_value[31:24];
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			WORDADDRBYTE_4: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt[7:0]   = rdata_rx_databuffer;
				load_addr_value_nxt[15:8]  = load_addr_value[15:8];
				load_addr_value_nxt[23:16] = load_addr_value[23:16];
				load_addr_value_nxt[31:24] = load_addr_value[31:24];
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			ASSIGN_RDADDR: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = load_addr_value;
				
				if (BYTE_ADDRESSING == 1) begin
					load_addr_value_nxt = (load_addr_value >> 24 | {{21{1'b0}}, extra_addrbit, {8{1'b0}}});
				end
				else if (BYTE_ADDRESSING == 2) begin
					load_addr_value_nxt = (load_addr_value >> 16 | {{13{1'b0}}, extra_addrbit, {16{1'b0}}});
				end
				else if (BYTE_ADDRESSING == 3) begin
					load_addr_value_nxt = (load_addr_value >> 8  | {{5{1'b0}}, extra_addrbit, {24{1'b0}}});
				end
				
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			ASSIGN_WRADDR: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = load_addr_value;
				
				if (BYTE_ADDRESSING == 1) begin
					load_addr_value_nxt = (load_addr_value >> 24 | {{21{1'b0}}, extra_addrbit, {8{1'b0}}});
				end
				else if (BYTE_ADDRESSING == 2) begin
					load_addr_value_nxt = (load_addr_value >> 16 | {{13{1'b0}}, extra_addrbit, {16{1'b0}}});
				end
				else if (BYTE_ADDRESSING == 3) begin
					load_addr_value_nxt = (load_addr_value >> 8  | {{5{1'b0}}, extra_addrbit, {24{1'b0}}});
				end
				
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			WRDATABYTE: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = {ADDRWIDTH{1'b0}};
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = avl_writedata;
				avl_byteenable_nxt = avl_byteenable;
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
				
				if (addr_cnt[1:0] == 2'b00) begin
					avl_writedata_nxt[7:0] = rdata_rx_databuffer;
					avl_byteenable_nxt[0] = 1'b1;
					wordwrite_complete_nxt = 1'b0;
				end
				else if (addr_cnt[1:0] == 2'b01) begin
					avl_writedata_nxt[15:8] = rdata_rx_databuffer;
					avl_byteenable_nxt[1] = 1'b1;
					wordwrite_complete_nxt = 1'b0;
				end
				else if (addr_cnt[1:0] == 2'b10) begin
					avl_writedata_nxt[23:16] = rdata_rx_databuffer;
					avl_byteenable_nxt[2] = 1'b1;
					wordwrite_complete_nxt = 1'b0;
				end
				else if (addr_cnt[1:0] == 2'b11) begin
					avl_writedata_nxt[31:24] = rdata_rx_databuffer;
					avl_byteenable_nxt[3] = 1'b1;
					wordwrite_complete_nxt = 1'b1;
				end
				
				if (avl_byteenable_nxt == 4'b0110 || avl_byteenable_nxt == 4'b1110 || avl_byteenable_nxt == 4'b0111) begin
					illegal_byteen_nxt = 1'b1;
				end
			end
			
			ISSUE_WRITE:  begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = load_addr_value;
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b1;
				avl_writedata_nxt = avl_writedata;
				avl_byteenable_nxt = avl_byteenable;
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = illegal_byteen;
				temp_wrbyteen_nxt = temp_wrbyteen;
				ori_wrdata_nxt = ori_wrdata;
				ori_wrbyteen_nxt = ori_wrbyteen;
			end
			
			NEXT_WRITE: begin                                  
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = {ADDRWIDTH{1'b0}};
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			WRITE_COMPLETE: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = load_addr_value;
				readdatabyte_nxt = {8{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = illegal_byteen;
				temp_wrbyteen_nxt = {4{1'b0}};
					
				if (illegal_byteen) begin
					avl_write_nxt = 1'b0;
					avl_writedata_nxt = {32{1'b0}};
					avl_byteenable_nxt = {4{1'b0}};
					ori_wrdata_nxt = avl_writedata;
					ori_wrbyteen_nxt = avl_byteenable;
				end
				else begin
					avl_write_nxt = 1'b1;
					avl_writedata_nxt = avl_writedata;
					avl_byteenable_nxt = avl_byteenable;
					ori_wrdata_nxt = {32{1'b0}};
					ori_wrbyteen_nxt = {4{1'b0}};
				end
			end
			
			SPLIT_WRITE: begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = load_addr_value;
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				temp_wrbyteen_nxt = temp_wrbyteen;
				ori_wrdata_nxt = ori_wrdata;
				ori_wrbyteen_nxt = ori_wrbyteen;
				
				if (ori_wrbyteen[0] ^ temp_wrbyteen[0]) begin
					avl_writedata_nxt[7:0] = ori_wrdata[7:0];
					avl_byteenable_nxt[0] = 1'b1;
					temp_wrbyteen_nxt[0] = 1'b1;
				end
				else if (ori_wrbyteen[1] ^ temp_wrbyteen[1]) begin
					avl_writedata_nxt[15:8] = ori_wrdata[15:8];
					avl_byteenable_nxt[1] = 1'b1;
					temp_wrbyteen_nxt[1] = 1'b1;
				end
				else if (ori_wrbyteen[2] ^ temp_wrbyteen[2]) begin
					avl_writedata_nxt[23:16] = ori_wrdata[23:16];
					avl_byteenable_nxt[2] = 1'b1;
					temp_wrbyteen_nxt[2] = 1'b1;
				end	
				else if (ori_wrbyteen[3] ^ temp_wrbyteen[3]) begin
					avl_writedata_nxt[31:24] = ori_wrdata[31:24];
					avl_byteenable_nxt[3] = 1'b1;
					temp_wrbyteen_nxt[3] = 1'b1;
				end
				
				if ((ori_wrbyteen ^ temp_wrbyteen) == 4'b0000) begin
					illegal_byteen_nxt = 1'b0;
				end
				else begin
					illegal_byteen_nxt = illegal_byteen;
				end
			end
			
			ISSUE_READ:  begin
				avl_read_nxt = 1'b1;
				load_addr_value_nxt = load_addr_value;
				readdatabyte_nxt = {8{1'b0}};
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b1}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
			
			RDDATABYTE:  begin
				avl_read_nxt = 1'b0;
				load_addr_value_nxt = {ADDRWIDTH{1'b0}};
				readdatabyte_nxt = readdatabyte;
				
				if (avl_readdatavalid) begin
					if (addr_cnt[1:0] == 2'b00)
						readdatabyte_nxt = avl_readdata[7:0];
					else if (addr_cnt[1:0] == 2'b01)
						readdatabyte_nxt = avl_readdata[15:8];
					else if (addr_cnt[1:0] == 2'b10)
						readdatabyte_nxt = avl_readdata[23:16];
					else if (addr_cnt[1:0] == 2'b11)
						readdatabyte_nxt = avl_readdata[31:24];
				end
				
				avl_write_nxt = 1'b0;
				avl_writedata_nxt = {32{1'b0}};
				avl_byteenable_nxt = {4{1'b0}};
				wordwrite_complete_nxt = 1'b0;
				illegal_byteen_nxt = 1'b0;
				temp_wrbyteen_nxt = {4{1'b0}};
				ori_wrdata_nxt = {32{1'b0}};
				ori_wrbyteen_nxt = {4{1'b0}};
			end
	
			default: begin
				avl_read_nxt = 1'bx;
				load_addr_value_nxt = {ADDRWIDTH{1'bx}};
				readdatabyte_nxt = {8{1'bx}};
				avl_write_nxt = 1'bx;
				avl_writedata_nxt = {32{1'bx}};
				avl_byteenable_nxt = {4{1'bx}};
				wordwrite_complete_nxt = 1'bx;
				illegal_byteen_nxt = 1'bx;
				temp_wrbyteen_nxt = {4{1'bx}};
				ori_wrdata_nxt = {32{1'bx}};
				ori_wrbyteen_nxt = {4{1'bx}};
			end
		endcase
	end
end
endgenerate

endmodule
