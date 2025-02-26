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

	assign stallpc = ireq.valid & ~iresp.data_ok;

	always_ff @( posedge clk ) begin
		if(reset) begin
			pc <= 64'h8000_0000;
		end else if(stallpc) begin
			pc <= pc;
		end else begin
			pc <= pc_nxt;
		end
		
	end

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
	u1 valid;

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

	
	assign ireq.valid = 1'b0;
	assign ireq.addr = pc;

/* TODO: Add your CPU-Core here. */

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (1'b1),
		.pc                 (pc),
		.instr              (raw_instr),
		.skip               (0),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataW_nxt.ctl.regwrite),
		.wdest              ({3'b000, dataW_nxt.dst}),
		.wdata              (dataW_nxt.writedata)
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (0),
		.gpr_1              (0),
		.gpr_2              (0),
		.gpr_3              (0),
		.gpr_4              (0),
		.gpr_5              (0),
		.gpr_6              (0),
		.gpr_7              (0),
		.gpr_8              (0),
		.gpr_9              (0),
		.gpr_10             (0),
		.gpr_11             (0),
		.gpr_12             (0),
		.gpr_13             (0),
		.gpr_14             (0),
		.gpr_15             (0),
		.gpr_16             (0),
		.gpr_17             (0),
		.gpr_18             (0),
		.gpr_19             (0),
		.gpr_20             (0),
		.gpr_21             (0),
		.gpr_22             (0),
		.gpr_23             (0),
		.gpr_24             (0),
		.gpr_25             (0),
		.gpr_26             (0),
		.gpr_27             (0),
		.gpr_28             (0),
		.gpr_29             (0),
		.gpr_30             (0),
		.gpr_31             (0)
	);

    DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (3),
		.mstatus            (0),
		.sstatus            (0 /* mstatus & 64'h800000030001e000 */),
		.mepc               (0),
		.sepc               (0),
		.mtval              (0),
		.stval              (0),
		.mtvec              (0),
		.stvec              (0),
		.mcause             (0),
		.scause             (0),
		.satp               (0),
		.mip                (0),
		.mie                (0),
		.mscratch           (0),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	);
`endif


endmodule

`endif
