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

`ifndef UART_DRIVER_CONTROLLER_SVH
`define UART_DRIVER_CONTROLLER_SVH

/* Class: uart_driver_controller
 *
 * Uart Controller interface driver.
 *
 */

class uart_driver_controller;
    typedef virtual uart_if .cb_master_modport vif_t;

    typedef logic [7:0] data_t;

    /* Interface */
    local vif_t             m_vif;

    local int               clk_per_bit;

    /* Function: new
     * Constructor. Assigns the uart controller interface to object.
     */
    extern function         new(vif_t vif);

    /* Task: reset
     * Initializes Uart controller interface that is connected to the object into reset state.
     */
    extern task             reset                       ();

    /* Task: Read byte
     * Receives byte data
     * Input: request type, address, data, byteenable 
     */
    extern task             read                        (ref data_t data_rd);

    /* Task: Set baud rate for UART transmision
     * Input: 
     */
    extern function         void set_baudrate           (int baudrate);


endclass

/* Function: new
 * Constructor. Assigns the Uart controller interface to object.
 */
function uart_driver_controller::new(vif_t vif);
    m_vif       = vif;
endfunction

/* Task: reset
 * Initializes Uart controller interface that is connected to the object into reset state.
 */
task uart_driver_controller::reset();
    clk_per_bit = 8680;
endtask

/* Task: write
 * Initializes Uart controller interface that is connected to the object into reset state.
 */
task uart_driver_controller::read(ref data_t data_rd);

    while(m_vif.cb_master.data) begin  
        @ (m_vif.cb_master); 
    end
    //$display("clk_per_bit: %d",clk_per_bit);
    repeat (clk_per_bit + clk_per_bit/2) @ (m_vif.cb_master);
   
    for(int i = 0; i<8 ; i++) begin
        data_rd [i] = m_vif.cb_master.data;
        //$display("data_rd[%h]: %d",i,m_vif.cb_master.data);
        repeat (clk_per_bit) @ (m_vif.cb_master);
    end

    repeat (clk_per_bit) @ (m_vif.cb_master);
endtask

/* Function: Set baud rate for UART transmision
 * Set the value of cloks per 1 bit
 */
function void uart_driver_controller::set_baudrate(int baudrate);
    case (baudrate)
        9600    : clk_per_bit = 104166;
        115200  : clk_per_bit = 8680;
        576000  : clk_per_bit = 1736;
        921600  : clk_per_bit = 1085;
    default:
        clk_per_bit = 8680;
    endcase
endfunction


`endif /* UART_DRIVER_CONTROLLER_SVH */
