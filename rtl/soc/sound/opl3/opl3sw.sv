`timescale 1ns / 1ps
/*
* Copyright (c) 2021, Christopher Hubmann
* All rights reserved.
* 
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
* 
* * Redistributions of source code must retain the above copyright notice, this
*   list of conditions and the following disclaimer.
* 
* * Redistributions in binary form must reproduce the above copyright notice,
*   this list of conditions and the following disclaimer in the documentation
*   and/or other materials provided with the distribution.
* 
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
* DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
* FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
* DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
* SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
* CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
* OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
* OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

module opl3sw
(
	input             reset,
	input             clk,

	// write reg interface
	input       [1:0] addr,
	input       [7:0] din,
	input             wr,
	
	// read reg interface
	input       [7:0] mgmt_address,
	input             mgmt_read,
	output reg [15:0] mgmt_readdata
);

wire  [9:0] qdata;
wire        qempty;
wire  [7:0] qusedw;
reg         rdreq;

always @(negedge clk) begin
	if(qempty) rdreq <= 0;
	else begin
		case(mgmt_address)
		      0: rdreq <= 0;
		default: rdreq <= mgmt_read;
		endcase
	end
end

always @(posedge clk) begin
	if(qempty) mgmt_readdata <= 16'b0;
	else begin
		case(mgmt_address)
		      0: mgmt_readdata <= {8'b0, qusedw};
		default: mgmt_readdata <= {6'b0, qdata};
		endcase
	end
end

opl3_fifo reg_queue
(
	.aclr   (reset),
	.clk    (clk),
	.rdreq  (rdreq),
	.wrreq  (wr),
	.data   ({addr, din}),
	.q      (qdata),
	.empty  (qempty),
	.usedw  (qusedw)
);

endmodule

module opl3_fifo
(
	input        aclr,
	input        clk,
	input        rdreq,
	input        wrreq,
	input  [9:0] data,
	output [9:0] q,
	output       empty,
	output [7:0] usedw
);
scfifo scfifo_component (
	.aclr   (aclr),
	.clock  (clk),
	.rdreq  (rdreq),
	.wrreq  (wrreq),
	.data   (data),
	.q      (q),
	.empty  (empty),
	.usedw  (usedw));
defparam
	scfifo_component.intended_device_family = "Cyclone V",
	scfifo_component.lpm_showahead = "ON",
	scfifo_component.lpm_type = "scfifo",
	scfifo_component.lpm_width = 10, // width = 10-bit
	scfifo_component.lpm_widthu = 8, // len = 2^8 = 256
	scfifo_component.lpm_numwords = 256,
	scfifo_component.overflow_checking = "ON",
	scfifo_component.underflow_checking = "ON",
	scfifo_component.use_eab = "ON";

endmodule
