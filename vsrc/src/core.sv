`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decode.sv"

`else

`endif

module core
	import common::*;
	import pipes::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input logic trint, swint, exint
);
	/* TODO: Add your pipeline here. */	
	u64 pc, pc_nxt;

	u1 stallpc;

	assign stallpc = ireq.valid && ~iresp.data_ok;

	always_ff @( posedge clk ) begin
		if(reset) begin
			pc <= 64'h8000_0000;
		end else if(stallpc) begin
			pc <= pc;
		end else begin
			pc <= pc_nxt;
		end
		
	end


	assign ireq.valid = 1'b1;
	assign ireq.addr = pc;

	u32 raw_instr;

	assign raw_instr = iresp.data;

	fetch_data_t dataF, dataF_nxt;
	decode_data_t dataD, dataD_nxt;

	u1 flushF;

	assign flushF = ireq.valid & ~iresp.data_ok;

	always_ff @(posedge clk) begin
		if (flushF) begin
			dataF <= '0;
		end else begin
			dataF <= dataF_nxt;
		end
	end

	fetch fetch (
		.dataF(dataF_nxt),
		.raw_instr(raw_instr)
	);
	
	pcselect pcselect (
		.pcp4(pc + 4),
		.pc_out(pc_nxt)
	);

	u1 flushD;

	assign flushD = ireq.valid & ~iresp.data_ok;

	always_ff @(posedge clk) begin
		if (flushD) begin
			dataD <= '0;
		end else begin
			dataD <= dataD_nxt;
		end
	end

	creg_addr_t ra1, ra2, wa;
	word_t rd1, rd2, wd;

	decode decode (
		.dataF,
		.dataD(dataD_nxt),

		.ra1, .ra2, .wa, .rd1, .rd2, .wd
	);

	
	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,
		.rd2,
		.wen(dataD.ctl.regwrite),
		.wa,
		.wd
	);

endmodule

`endif
