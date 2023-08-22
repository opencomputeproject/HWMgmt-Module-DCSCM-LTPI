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


//////////////////////////////////////////////////////////////////////////////////
/*!
    \brief      <b>8-bit CRC</b> 
    \details    Polynomial = x^8 + x^2 + x^1 + x^0\n
	
    \file       crc8.v
    \author     Matthew Deckard
    \date       December 2016
*/

module crc8(
	input			    iClk,      			//% Clock
	input               iRst,
	input			    iClr,				//% Clear CRC-8
    
	input			    iEn,				//% Clock enable
	input		[7:0]   ivByte,				//% Inbound byte
	
	output	reg	[7:0]   ovCrc8				//% Outbound CRC-8 byte
);

// Initial
//initial
//    ovCrc8 =    8'h00;

// Polynomial = x^8 + x^2 + x^1 + x^0
always @ ( posedge iClk or posedge iRst )
begin
	if (iRst)
		ovCrc8      <= 8'h00;
	else if ( iClr ) begin
		ovCrc8      <= 8'h00;
	end
	else begin
		if ( iEn ) begin   
				ovCrc8[0]       <= ivByte[7] ^ ivByte[6] ^ ivByte[0]
										^ ovCrc8[7] ^ ovCrc8[6] ^ ovCrc8[0];
				ovCrc8[1]       <= ivByte[6] ^ ivByte[1] ^ ivByte[0]
										^ ovCrc8[6] ^ ovCrc8[1] ^ ovCrc8[0];
				ovCrc8[2]       <= ivByte[6] ^ ivByte[2] ^ ivByte[1] ^ ivByte[0]
										^ ovCrc8[6] ^ ovCrc8[2] ^ ovCrc8[1] ^ ovCrc8[0];
				ovCrc8[3]       <= ivByte[7] ^ ivByte[3] ^ ivByte[2] ^ ivByte[1]
										^ ovCrc8[7] ^ ovCrc8[3] ^ ovCrc8[2] ^ ovCrc8[1];
				ovCrc8[4]       <= ivByte[4] ^ ivByte[3] ^ ivByte[2]
										^ ovCrc8[4] ^ ovCrc8[3] ^ ovCrc8[2];
				ovCrc8[5]       <= ivByte[5] ^ ivByte[4] ^ ivByte[3]
										^ ovCrc8[5] ^ ovCrc8[4] ^ ovCrc8[3];
				ovCrc8[6]       <= ivByte[6] ^ ivByte[5] ^ ivByte[4]
										^ ovCrc8[6] ^ ovCrc8[5] ^ ovCrc8[4];
				ovCrc8[7]       <= ivByte[7] ^ ivByte[6] ^ ivByte[5]
										^ ovCrc8[7] ^ ovCrc8[6] ^ ovCrc8[5];
		end
	end
end

endmodule
