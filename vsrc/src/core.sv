`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/writeback/writeback.sv"
`include "pipeline/fwdmux.sv"

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
	input logic trint, swint, exint,
	output u2 priviledgeMode,
	output satp_t satp
);
	/* TODO: Add your pipeline here. */	
	word_t pc, pc_nxt, branch_target, branch_target_d;

	word_t REG[31:0];
	csr_t CSR;

	u1 stallpc;
	u1 stalllu;
	u1 stallmem, stallmem_d;
	u1 branch_enable, branch_enable_d;
	u1 forceflush;
	u3 interrupts, interrupts_d;
	u1 receive_interrupt, receive_interrupt_d, receive_interrupt_can_recover;

	assign satp = CSR.satp;
	assign interrupts = {trint, swint, exint};

	assign stallpc = ireq.valid & ~iresp.data_ok;
	assign stalllu = (dataD.ctl.memread | dataD.ctl.csrsrc) & (dataF.ra1 == dataD.dst | dataF.ra2 == dataD.dst) & (!branch_enable_d);


	u1 interrupted;
	word_t interrupt_mcause;
	word_t extra_mip;
	u1 new_interrupt;
	u1 interrupt_csr_eval;
	always_comb begin
		interrupted = '0;
		interrupt_mcause = '0;
		extra_mip = '0;
		new_interrupt = interrupts > interrupts_d || interrupt_csr_eval || dataE_nxt.ctl.mret;
		if(trint) extra_mip[7] = 1'b1;
		if(swint) extra_mip[3] = 1'b1;
		if(exint) extra_mip[11] = 1'b1;
		if(CSR.mstatus.mie == 1 || priviledgeMode != 2'b11) begin
			if((new_interrupt || receive_interrupt) && iresp.data_ok) begin
				if(trint && CSR.mie[7]) begin
					interrupted = 1'b1;
					interrupt_mcause = {1'b1, 63'd7};
				end 
				else if(swint && CSR.mie[3]) begin
					interrupted = 1'b1;
					interrupt_mcause = {1'b1, 63'd3};
				end
				else if(exint && CSR.mie[11]) begin
					interrupted = 1'b1;
					interrupt_mcause = {1'b1, 63'd11};
				end
			end
		end
	end

	always_ff @(posedge clk) begin
		if(reset) begin
			interrupts_d <= '0;
		end else begin
			interrupts_d <= interrupts;
		end
	end
	always_ff @(posedge clk) begin
		if(reset) begin
			stallmem_d <= '0;
		end else begin
			stallmem_d <= stallmem;
		end
	end
	always_ff @(posedge clk) begin
		if(reset) begin
			branch_target_d <= '0;
		end else begin
			branch_target_d <= branch_target;
		end
	end
	always_ff @(posedge clk) begin
		if(reset) begin
			branch_enable_d <= '0;
		end else begin
			branch_enable_d <= branch_enable;
		end
	end
	assign forceflush = !stallmem & stallmem_d;

	always_ff @(posedge clk) begin
		if(reset) begin
			pc <= 64'h8000_0000;
		end else if((forceflush & branch_enable_d) | !(stallpc | stallmem | stalllu)) begin
			pc <= pc_nxt;
		end else begin
			pc <= pc;
		end
	end
	
	always_ff @(posedge clk) begin
		if(reset) begin
			receive_interrupt <= '0;
		end else if(dataF_nxt.excep.mcause[63]) begin
			receive_interrupt <= '0;
		end else if(new_interrupt || (stalllu && receive_interrupt_can_recover)) begin 
			receive_interrupt <= 1'b1;
			receive_interrupt_can_recover <= '0;
		end
	end
	always_ff @(posedge clk) begin
		if(reset) begin
			receive_interrupt_can_recover <= '0;
		end else if(dataF_nxt.excep.mcause[63]) begin
			receive_interrupt_can_recover <= 1'b1;
		end else if(dataD_nxt.excep.mcause[63]) begin
			receive_interrupt_can_recover <= '0;
		end
	end

	u1 pc_misaligned, mem_misaligned;
	word_t mem_mcause;
	assign pc_misaligned = (pc[1:0] != 2'b00);

	fetch_data_t dataF, dataF_nxt;
	decode_data_t dataD, dataD_nxt;
	execute_data_t dataE, dataE_nxt;
	memory_data_t dataM, dataM_nxt;
	writeback_data_t dataW, dataW_nxt;

	u32 raw_instr;

	assign raw_instr = iresp.data;
	assign ireq.valid = !pc_misaligned;
	assign ireq.addr = pc;

	u1 flushF;

	assign flushF = (iresp.data_ok & !stallmem & !stallpc & !stalllu) | (!stalllu & forceflush) | pc_misaligned;

	always_ff @(posedge clk) begin
		if (reset) dataF <= '0;
		else if(flushF) dataF <= dataF_nxt;
	end

	fetch fetch (
		.dataF(dataF_nxt),
		.raw_instr,
		.pc,
		.stall(branch_enable_d),
		.pc_misaligned,
		.mem_misaligned,
		.mem_mcause,
		.priviledgeMode,
		.interrupted,
		.interrupt_mcause,
		.data_ok(iresp.data_ok)
	);
	
	muxword pcselect (
		.choose(branch_enable_d),
		.muxin0(pc + 4),
		.muxin1(branch_target_d),
		.muxout(pc_nxt)
	);

	u1 flushD;

	assign flushD = (dataF.valid & !stallmem & !stallpc) | forceflush;

	always_ff @(posedge clk) begin
		if (reset) dataD <= '0;
		else if (flushD) dataD <= dataD_nxt;
	end

	creg_addr_t ra1, ra2, wa;
	word_t rd1, rd2, wd;
	logic wen;

	decode decode (
		.clk, .reset,
		.dataF,
		.dataD(dataD_nxt),
		.wa(dataW_nxt.dst),
		.wen(dataW_nxt.ctl.regwrite),
		.wd(dataW_nxt.writedata),
		.csr_wa(dataM_nxt.csraddr),
		.csr_wen(dataM_nxt.ctl.csrsrc && !(dataM_nxt.ctl.exception | dataM_nxt.ctl.mret)),
		.csr_wd(dataM_nxt.csrdata),
		.REG,
		.CSR,
		.stall(stalllu | branch_enable_d | mem_misaligned),
		.excep_wdata(dataW_nxt.excep),
		.extra_mip,
		.interrupt_csr_eval
	);

	u1 flushE;

	assign flushE = (dataD.valid & !stallmem & !stallpc) | forceflush;

	always_ff @(posedge clk) begin
		if (reset) begin dataE <= '0; priviledgeMode <= 2'b11; end
		else if (flushE) begin 
			dataE <= dataE_nxt; 
			if(dataE_nxt.raw_instr != '0) priviledgeMode <= dataE_nxt.priviledgeMode_new; 
		end
	end

	fwd_data_t fwd_srca, fwd_srcb;
	fwdmux fwdmux (
		.dataD,
		.dataE,
		.dataM,
		.dataW,
		.fwd_srca,
		.fwd_srcb
	);

	execute execute (
		.dataD,
		.fwda(fwd_srca),
		.fwdb(fwd_srcb),
		.dataE(dataE_nxt),
		.branch_enable,
		.branch_target,
		.priviledgeMode,
		.mem_misaligned,
		.mem_mcause
	);

	u1 flushM;

	assign flushM = (dataE.valid & !stallmem & !stallpc) | forceflush;

	always_ff @(posedge clk) begin
		if (reset) dataM <= '0;
		else if(flushM) dataM <= dataM_nxt;
	end

	memory memory(
		.clk, .reset,
		.dataE,
		.dataM(dataM_nxt),
		.dreq,
		.dresp,
		.stallmem
	);

	u1 flushW;

	assign flushW = dataM.valid & !stallpc;

	u1 wdata_valid;

	always_ff @(posedge clk) begin
		if (reset) dataW <= '0;
		else if (flushW) dataW <= dataW_nxt;
		else dataW.valid <= '0;
	end

	writeback writeback(
		.dataM,
		.dataW(dataW_nxt)
	);

/* TODO: Add your CPU-Core here. */

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (CSR.mhartid[7:0]),
		.index              (0),
		.valid              (dataW.valid),
		.pc                 (dataW.pc),
		.instr              (dataW.raw_instr),
		.skip    			(((dataW.ctl.memwrite | dataW.ctl.memread) & dataW.memaddr[31] == 0)),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataW.ctl.regwrite),
		.wdest              ({3'b000, dataW.dst}),
		.wdata              (dataW.writedata)
	);

	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (CSR.mhartid[7:0]),
		.gpr_0              (REG[0]),
		.gpr_1              (REG[1]),
		.gpr_2              (REG[2]),
		.gpr_3              (REG[3]),
		.gpr_4              (REG[4]),
		.gpr_5              (REG[5]),
		.gpr_6              (REG[6]),
		.gpr_7              (REG[7]),
		.gpr_8              (REG[8]),
		.gpr_9              (REG[9]),
		.gpr_10             (REG[10]),
		.gpr_11             (REG[11]),
		.gpr_12             (REG[12]),
		.gpr_13             (REG[13]),
		.gpr_14             (REG[14]),
		.gpr_15             (REG[15]),
		.gpr_16             (REG[16]),
		.gpr_17             (REG[17]),
		.gpr_18             (REG[18]),
		.gpr_19             (REG[19]),
		.gpr_20             (REG[20]),
		.gpr_21             (REG[21]),
		.gpr_22             (REG[22]),
		.gpr_23             (REG[23]),
		.gpr_24             (REG[24]),
		.gpr_25             (REG[25]),
		.gpr_26             (REG[26]),
		.gpr_27             (REG[27]),
		.gpr_28             (REG[28]),
		.gpr_29             (REG[29]),
		.gpr_30             (REG[30]),
		.gpr_31             (REG[31])
	);

    DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (CSR.mhartid[7:0]),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);

	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (CSR.mhartid[7:0]),
		.priviledgeMode     (dataW.priviledgeMode),
		.mstatus            (CSR.mstatus & MSTATUS_MASK),
		.sstatus            (CSR.mstatus & SSTATUS_MASK),
		.mepc               (CSR.mepc),
		.sepc               (CSR.sepc),
		.mtval              (CSR.mtval),
		.stval              (CSR.stval),
		.mtvec              (CSR.mtvec & MTVEC_MASK),
		.stvec              (CSR.stvec),
		.mcause             (CSR.mcause),
		.scause             (CSR.scause),
		.satp               (CSR.satp),
		.mip                (CSR.mip & MIP_MASK),
		.mie                (CSR.mie),
		.mscratch           (CSR.mscratch),
		.sscratch           (CSR.sscratch),
		.mideleg            (CSR.mideleg & MIDELEG_MASK),
		.medeleg            (CSR.medeleg & MEDELEG_MASK)
	);
`endif


endmodule

`endif
