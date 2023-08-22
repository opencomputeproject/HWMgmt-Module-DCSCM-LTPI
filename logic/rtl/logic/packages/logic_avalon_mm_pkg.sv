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

/* Package: logic_avalon_mm_pkg
 *
 * Logic package.
 */
package logic_avalon_mm_pkg;
    /* Enum: response_t
     *
     * Response.
     *
     * RESPONSE_OKAY        - Successful response for a transaction.
     * RESPONSE_RESERVED    - Encoding is reserved.
     * RESPONSE_SLAVEERROR  - Error from an endpoint slave. Indicates an
     *                        unsuccessful transaction.
     * RESPONSE_DECODEERROR - Indicates attempted access to an undefined
     *                        location.
     */
    typedef enum logic [1:0] {
        RESPONSE_OKAY           = 2'b00,
        RESPONSE_RESERVED       = 2'b01,
        RESPONSE_SLAVEERROR     = 2'b10,
        RESPONSE_DECODEERROR    = 2'b11
    } response_t;

    typedef enum logic {
        REQUEST_WRITE           = 1'b0,
        REQUEST_READ            = 1'b1
    } request_t;

endpackage
