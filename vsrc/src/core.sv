`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/writeback/writeback.sv"
`include "pipeline/regfile/regfile.sv"

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

	u64 next_reg[31:0];

	u1 stallpc;

	assign stallpc = ireq.valid & ~iresp.data_ok;

	always_ff @(posedge clk) begin
		if(reset) begin
			pc <= 64'h8000_0000;
		end else if(stallpc) begin
			pc <= pc;
		end else begin
			pc <= pc_nxt;
		end
	end


	fetch_data_t dataF, dataF_nxt;
	decode_data_t dataD, dataD_nxt;
	execute_data_t dataE, dataE_nxt;
	memory_data_t dataM, dataM_nxt;
	writeback_data_t dataW, dataW_nxt;

	u32 raw_instr;

	assign raw_instr = iresp.data;
	assign ireq.valid = '1;
	assign ireq.addr = pc;
	assign dreq = '0;

	u1 flushF;

	assign flushF = ireq.valid & ~iresp.data_ok;

	always_ff @(posedge clk) begin
		if (reset | flushF) begin
			dataF <= '0;
		end else if(iresp.data_ok) begin
			dataF <= dataF_nxt;
		end else begin
			dataF <= dataF;
		end
	end

	fetch fetch (
		.dataF(dataF_nxt),
		.raw_instr,
		.pc
	);
	
	pcselect pcselect (
		.pcp4(pc + 4),
		.pc_out(pc_nxt)
	);

	u1 flushD;

	assign flushD = ~dataF.valid;

	always_ff @(posedge clk) begin
		if (reset | flushD) begin
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
		.wd(dataW.writedata),
		.next_reg
	);

	u1 flushE;

	assign flushE = ~dataD.valid;

	always_ff @(posedge clk) begin
		if (reset | flushE) begin
			dataE <= '0;
		end else begin
			dataE <= dataE_nxt;
		end
	end

	execute execute (
		.dataD,
		.dataE(dataE_nxt)
	);

	u1 flushM;

	assign flushM = ~dataE.valid;

	always_ff @(posedge clk) begin
		if (reset | flushM) begin
			dataM <= '0;
		end else begin
			dataM <= dataM_nxt;
		end
	end

	memory memory(
		.dataE,
		.dataM(dataM_nxt)
	);

	u1 flushW;

	assign flushW = ~dataM.valid;

	always_ff @(posedge clk) begin
		if (reset | flushW) begin
			dataW <= '0;
		end else begin
			dataW <= dataW_nxt;
		end
	end

	writeback writeback(
		.dataM,
		.dataW(dataW_nxt)
	);

/* TODO: Add your CPU-Core here. */

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (dataW.valid),
		.pc                 (dataW.pc),
		.instr              (dataW.raw_instr),
		.skip               (0),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataW.ctl.regwrite),
		.wdest              ({3'b000, dataW.dst}),
		.wdata              (dataW.writedata)
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (next_reg[0]),
		.gpr_1              (next_reg[1]),
		.gpr_2              (next_reg[2]),
		.gpr_3              (next_reg[3]),
		.gpr_4              (next_reg[4]),
		.gpr_5              (next_reg[5]),
		.gpr_6              (next_reg[6]),
		.gpr_7              (next_reg[7]),
		.gpr_8              (next_reg[8]),
		.gpr_9              (next_reg[9]),
		.gpr_10             (next_reg[10]),
		.gpr_11             (next_reg[11]),
		.gpr_12             (next_reg[12]),
		.gpr_13             (next_reg[13]),
		.gpr_14             (next_reg[14]),
		.gpr_15             (next_reg[15]),
		.gpr_16             (next_reg[16]),
		.gpr_17             (next_reg[17]),
		.gpr_18             (next_reg[18]),
		.gpr_19             (next_reg[19]),
		.gpr_20             (next_reg[20]),
		.gpr_21             (next_reg[21]),
		.gpr_22             (next_reg[22]),
		.gpr_23             (next_reg[23]),
		.gpr_24             (next_reg[24]),
		.gpr_25             (next_reg[25]),
		.gpr_26             (next_reg[26]),
		.gpr_27             (next_reg[27]),
		.gpr_28             (next_reg[28]),
		.gpr_29             (next_reg[29]),
		.gpr_30             (next_reg[30]),
		.gpr_31             (next_reg[31])
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
