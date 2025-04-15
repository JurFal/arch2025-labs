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
    input u12 csr_addr,
    output word_t csr_out,
    input logic wen,
    input creg_addr_t wa,
    input word_t wd,
	output csr_t CSR
);

csr_t next_csr;

always_comb begin
	case(csr_addr)
		CSR_MHARTID: csr_out = next_csr.mhartid;
		CSR_MIE: csr_out = next_csr.mie;
		CSR_MIP: csr_out = next_csr.mip;
		CSR_MTVEC: csr_out = next_csr.mtvec;
		CSR_MSTATUS: csr_out = next_csr.mstatus;
		CSR_MSCRATCH: csr_out = next_csr.mscratch;
		CSR_MEPC: csr_out = next_csr.mepc;
		CSR_SATP: csr_out = next_csr.satp;
		CSR_MCAUSE: csr_out = next_csr.mcause;
		CSR_MCYCLE: csr_out = next_csr.mcycle;
		CSR_MTVAL: csr_out = next_csr.mtval;
		CSR_PMPADDR0: csr_out = next_csr.pmpaddr;
		CSR_PMPCFG0: csr_out = next_csr.pmpcfg;
		CSR_MEDELEG: csr_out = next_csr.medeleg;
		CSR_MIDELEG: csr_out = next_csr.mideleg;
		CSR_STVEC: csr_out = next_csr.stvec;
		CSR_SSTATUS: csr_out = next_csr.sstatus;
		CSR_SSCRATCH: csr_out = next_csr.sscratch;
		CSR_SEPC: csr_out = next_csr.sepc;
		CSR_SCAUSE: csr_out = next_csr.scause;
		CSR_STVAL: csr_out = next_csr.stval;
		CSR_SIE: csr_out = next_csr.sie;
		CSR_SIP: csr_out = next_csr.sip;
		default: csr_out = '0;
	endcase
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
