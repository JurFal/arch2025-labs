`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/writeback/writeback.sv"

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
	execute_data_t dataE, dataE_nxt;
	writeback_data_t dataW, dataW_nxt;

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
	logic wen;

	decode decode (
		.clk, .reset,
		.dataF,
		.dataD(dataD_nxt),
		.wa(dataW.dst),
		.wen(dataW.ctl.regwrite),
		.wd(dataW.writedata)
	);

	u1 flushE;

	assign flushE = ireq.valid & ~iresp.data_ok;

	always_ff @(posedge clk) begin
		if (flushE) begin
			dataE <= '0;
		end else begin
			dataE <= dataE_nxt;
		end
	end

	execute execute (
		.dataD,
		.dataE(dataE_nxt)
	);

	u1 flushW;

	assign flushW = ireq.valid & ~iresp.data_ok;

	always_ff @(posedge clk) begin
		if (flushW) begin
			dataW <= '0;
		end else begin
			dataW <= dataW_nxt;
		end
	end

	writeback writeback(
		.dataE,
		.dataW(dataW_nxt)
	);

endmodule

`endif
