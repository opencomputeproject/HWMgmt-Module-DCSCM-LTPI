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

`ifndef UART_DRIVER_TARGET_SVH
`define UART_DRIVER_TARGET_SVH
`timescale 1 ns / 1 ps
/* Class: uart_driver_target
 *
 * Uart Target interface driver.
 *
 */

class uart_driver_target;
    typedef virtual uart_if .cb_slave_modport vif_t;

     typedef logic [7:0] data_t;

    /* Interface */
    local vif_t             m_vif;

    local int               clk_per_bit;
    
    /* Function: new
     * Constructor. Assigns the uart tagret interface to object.
     */
    extern function         new(vif_t vif);

    /* Task: reset
     * Initializes Uart tagret interface that is connected to the object into reset state.
     */
    extern task             reset                   ();
    
    /* Task: Write byte
     * Receives byte data
     * Input: 
     */
    extern task             write                   (ref data_t data_wr);

    /* Task: Set baud rate for UART transmision
     * Input: 
     */
    extern function         void set_baudrate      (int baudrate);


endclass

/* Function: new
 * Constructor. Assigns the AXI4-MM slave interface to object.
 */
function uart_driver_target::new(vif_t vif);
    m_vif       = vif;
endfunction

/* Task: aclk_posedge
 * Wait for rising edge of clock. (Clock period delay).
 * Input: count - number of clock cycles to wait.
 */
// task logic_avalon_mm_driver_slave::aclk_posedge(int count = 1);
//     repeat (count) @(m_vif.cb_slave);  
// endtask

/* Task: reset
 * Initializes Avalon-MM slave interface that is connected to the object into reset state.
 */
task uart_driver_target::reset();
    m_vif.cb_slave.data               <= 1'b1;  
    clk_per_bit = 8680;
endtask

/* Task: write
 * Initializes Uart tagret interface that is connected to the object into reset state.
 */
task uart_driver_target::write(ref data_t data_wr);

    m_vif.cb_slave.data <= 0; //start
    repeat (clk_per_bit) @ (m_vif.cb_slave);

    //$display("data_wr: %h",data_wr);
    for(int i = 0 ; i < 8 ; i++) begin
        m_vif.cb_slave.data           <= data_wr[i];
        repeat (clk_per_bit) @ (m_vif.cb_slave);
    end

    m_vif.cb_slave.data <= 1; //stop
    repeat (clk_per_bit) @ (m_vif.cb_slave);

endtask

/* Function: Set baud rate for UART transmision
 * Set the value of cloks per 1 bit
 */
function void uart_driver_target::set_baudrate(int baudrate);
    case (baudrate)
        9600    : clk_per_bit = 104166;
        115200  : clk_per_bit = 8680;
        576000  : clk_per_bit = 1736;
        921600  : clk_per_bit = 1085;
    default:
        clk_per_bit = 8680;
    endcase
endfunction

`endif /* UART_DRIVER_TARGET_SVH */
