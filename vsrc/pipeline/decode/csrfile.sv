`ifndef __CSRFILE_SV
`define __CSRFILE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module csrfile 
	import common::*;
	import pipes::*;(
	input logic clk, reset,
    input u12 csr_ra,
    output word_t csr_out,
    input logic csr_wen,
    input u12 csr_wa,
    input word_t csr_wd,
	input excep_data_t excep_wdata,
	input u1 excep_readstatus,
	output mstatus_t excep_mstatus,
	output csr_t CSR
);

csr_t next_csr;

always_comb begin
	case(csr_ra)
		//CSR_MHARTID: begin csr_out = CSR.mhartid; end
		CSR_MIE: begin csr_out = CSR.mie; end
		CSR_MIP: begin csr_out = CSR.mip; end
		CSR_MTVEC: begin csr_out = CSR.mtvec; end
		CSR_MSTATUS: begin csr_out = CSR.mstatus; end
		CSR_MSCRATCH: begin csr_out = CSR.mscratch; end
		CSR_MEPC: begin csr_out = CSR.mepc; end
		CSR_SATP: begin csr_out = CSR.satp; end
		CSR_MCAUSE: begin csr_out = CSR.mcause; end
		CSR_MCYCLE: begin csr_out = CSR.mcycle; end
		CSR_MTVAL: begin csr_out = CSR.mtval; end
		//CSR_PMPADDR0: begin csr_out = CSR.pmpaddr; end
		//CSR_PMPCFG0: begin csr_out = CSR.pmpcfg; end
		//CSR_MEDELEG: begin csr_out = CSR.medeleg; end
		//CSR_MIDELEG: begin csr_out = CSR.mideleg; end
		//CSR_STVEC: begin csr_out = CSR.stvec; end
		CSR_SSTATUS: begin csr_out = CSR.mstatus & SSTATUS_MASK; end
		//CSR_SSCRATCH: begin csr_out = CSR.sscratch; end
		//CSR_SEPC: begin csr_out = CSR.sepc; end
		//CSR_SCAUSE: begin csr_out = CSR.scause; end
		//CSR_STVAL: begin csr_out = CSR.stval; end
		//CSR_SIE: begin csr_out = CSR.sie; end
		//CSR_SIP: begin csr_out = CSR.sip; end
		default: csr_out = '0;
	endcase
end

always_comb begin
	next_csr = CSR;
	next_csr.mcycle = CSR.mcycle + 1;
	excep_mstatus = excep_readstatus ? CSR.mstatus : '0;
	if(excep_wdata.enable) begin
		next_csr.mstatus = excep_wdata.mstatus;
		if(!excep_wdata.mret) begin
			next_csr.mcause = excep_wdata.mcause;
			next_csr.mepc = excep_wdata.mepc;
		end
	end
	if(csr_wen) begin
		case(csr_wa)
			//CSR_MHARTID: next_csr.mhartid = csr_wd;
			CSR_MIE: next_csr.mie = csr_wd;
			CSR_MIP: next_csr.mip = csr_wd & MIP_MASK;
			CSR_MTVEC: next_csr.mtvec = csr_wd & MTVEC_MASK;
			CSR_MSTATUS: next_csr.mstatus = csr_wd & MSTATUS_MASK;
			CSR_MSCRATCH: next_csr.mscratch = csr_wd;
			CSR_MEPC: next_csr.mepc = csr_wd;
			CSR_SATP: next_csr.satp = csr_wd;
			CSR_MCAUSE: next_csr.mcause = csr_wd;
			CSR_MCYCLE: next_csr.mcycle = csr_wd;
			CSR_MTVAL: next_csr.mtval = csr_wd;
			//CSR_PMPADDR0: next_csr.pmpaddr = csr_wd;
			//CSR_PMPCFG0: next_csr.pmpcfg = csr_wd;
			//CSR_MEDELEG: next_csr.medeleg = csr_wd & MEDELEG_MASK;
			//CSR_MIDELEG: next_csr.mideleg = csr_wd & MIDELEG_MASK;
			//CSR_STVEC: next_csr.stvec = csr_wd;
			CSR_SSTATUS: next_csr.mstatus = csr_wd & SSTATUS_MASK;
			//CSR_SSCRATCH: next_csr.sscratch = csr_wd;
			//CSR_SEPC: next_csr.sepc = csr_wd;
			//CSR_SCAUSE: next_csr.scause = csr_wd;
			//CSR_STVAL: next_csr.stval = csr_wd;
			//CSR_SIE: next_csr.sie = csr_wd;
			//CSR_SIP: next_csr.sip = csr_wd;
			default: ;
		endcase
	end
end

always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		CSR <= '0;
	end else begin
		CSR <= next_csr;
	end
end


endmodule

`endif
