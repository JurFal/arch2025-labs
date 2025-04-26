`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

package pipes;
	import common::*;

// csr names
  parameter u12 CSR_MHARTID = 12'hf14;
  parameter u12 CSR_MIE = 12'h304;
  parameter u12 CSR_MIP = 12'h344;
  parameter u12 CSR_MTVEC = 12'h305;
  parameter u12 CSR_MSTATUS = 12'h300;
  parameter u12 CSR_MSCRATCH = 12'h340;
  parameter u12 CSR_MEPC = 12'h341;
  parameter u12 CSR_SATP = 12'h180;
  parameter u12 CSR_MCAUSE = 12'h342;
  parameter u12 CSR_MCYCLE = 12'hb00;
  parameter u12 CSR_MTVAL = 12'h343;
  parameter u12 CSR_PMPADDR0 = 12'h3b0;
  parameter u12 CSR_PMPCFG0 = 12'h3a0;
  parameter u12 CSR_MEDELEG = 12'h302;
  parameter u12 CSR_MIDELEG = 12'h303;
  parameter u12 CSR_STVEC = 12'h105;
  parameter u12 CSR_SSTATUS = 12'h100;
  parameter u12 CSR_SSCRATCH = 12'h140;
  parameter u12 CSR_SEPC = 12'h141;
  parameter u12 CSR_SCAUSE = 12'h142;
  parameter u12 CSR_STVAL = 12'h143;
  parameter u12 CSR_SIE = 12'h104;
  parameter u12 CSR_SIP = 12'h144;

  parameter u64 MSTATUS_MASK = 64'h7e79bb;
  parameter u64 SSTATUS_MASK = 64'h800000030001e000;
  parameter u64 MIP_MASK = 64'h333;
  parameter u64 MTVEC_MASK = ~(64'h2);
  parameter u64 MEDELEG_MASK = 64'h0;
  parameter u64 MIDELEG_MASK = 64'h0;


// opcode
parameter OP_R_OPS = 7'b0110011; // R-Type, normal operators
parameter OP_R_OPW = 7'b0111011; // R-Type, operators, sign-externed 32-bit results
parameter OP_I_OPS = 7'b0010011; // I-Type, normal operators
parameter OP_I_OPW = 7'b0011011; // I-Type, operators, sign-externed 32-bit results
parameter OP_I_LIM = 7'b0000011; // I-Type, load immediate
parameter OP_I_JLR = 7'b1100111; // I-Type, jump and link register
parameter OP_I_CSR = 7'b1110011; // I-Type, operate csrs
parameter OP_B_BRH = 7'b1100011; // B-Type, branch
parameter OP_J_JAL = 7'b1101111; // J-Type, jump and link
parameter OP_S_SIM = 7'b0100011; // S-Type, store immediate
parameter OP_U_LUI = 7'b0110111; // U-Type, load upper immediate
parameter OP_U_APC = 7'b0010111; // U-Type, add upper immediate to pc

// operation F3
parameter F3_OP_ADD = 3'b000; // add and sub
parameter F3_OP_SLE = 3'b001; // shift left
parameter F3_OP_SLT = 3'b010; // set if less than
parameter F3_OP_SLU = 3'b011; // set if less than unsigned
parameter F3_OP_XOR = 3'b100; // xor
parameter F3_OP_SRG = 3'b101; // shift right
parameter F3_OP_ORR = 3'b110; // or
parameter F3_OP_AND = 3'b111; // and

// memory F3
parameter F3_MM_QWS = 3'b000; // signed byte (quarter word)
parameter F3_MM_HWS = 3'b001; // signed half word
parameter F3_MM_SWS = 3'b010; // signed (single) word
parameter F3_MM_DWS = 3'b011; // signed double word
parameter F3_MM_QWU = 3'b100; // unsigned byte(quarter word)
parameter F3_MM_HWU = 3'b101; // unsigned half word
parameter F3_MM_SWU = 3'b110; // unsigned (single) word

// branch F3
parameter F3_BR_BEQ = 3'b000; // equal
parameter F3_BR_BNE = 3'b001; // not equal
parameter F3_BR_BLT = 3'b100; // less than
parameter F3_BR_BGE = 3'b101; // greater than
parameter F3_BR_BLU = 3'b110; // less than
parameter F3_BR_BGU = 3'b111; // greater than, unsigned

// csr F3
parameter F3_CS_RWR = 3'b001; // read and write
parameter F3_CS_RSR = 3'b010; // read and set
parameter F3_CS_RCR = 3'b011; // read and clear
parameter F3_CS_RWI = 3'b101; // read and write immediate
parameter F3_CS_RSI = 3'b110; // read and set immediate
parameter F3_CS_RCI = 3'b111; // read and clear immediate

// jump and link register F3
parameter F3_JL_JLR = 3'b010; // jump and link register
    
/* Define pipeline structures here */

typedef enum logic [5:0] { 
	UNKNOWN, 
	ADD, ADDW, ADDI, ADDIW,
	SUB, SUBW,
	AND, ANDI,
	OR, ORI,
	XOR, XORI,
	SLT, SLTU, SLTI, SLTIU,
	SLL, SLLW, SLLI, SLLIW,
	SRL, SRLW, SRLI, SRLIW,
	SRA, SRAW, SRAI, SRAIW,
	LB, LBU, LH, LHU, LW, LWU, LD,
	SB, SH, SW, SD,
	LUI, AUIPC,
	BEQ, BNE, BLT, BLTU, BGE, BGEU,
	JAL, JALR
} opcode_t; 

typedef enum logic [4:0] {
	ALU_SRC1, ALU_SRC2,
	ALU_ADD, ALU_SUB, ALU_XOR, ALU_OR, ALU_AND, ALU_NAND,
	ALU_SLT, ALU_SLTU,
	ALU_SLL, ALU_SLLW,
	ALU_SRL, ALU_SRLW,
	ALU_SRA, ALU_SRAW
} alufunc_t;

typedef enum logic [3:0] {
	BRH_NEV, BRH_AWS,
	BRH_EQL, BRH_NEQ,
	BRH_LST, BRH_LSTU,
	BRH_GOE, BRH_GOEU
} branchfunc_t;

typedef struct packed {
	opcode_t op;
	alufunc_t alufunc;
	branchfunc_t branchfunc;
	u1 zeroextwb, regwrite, immsrc, pcsrc, csrsrc, aluext,
	   memwrite, memread, jal, jalr;
	msize_t memsize;
} control_t;

typedef struct packed {
	u1 enable;
	word_t data;
} fwd_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t imm;
	control_t ctl;
	creg_addr_t ra1, ra2, dst;
	u12 csraddr;
} fetch_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t srca, srcb, imm, csrdata;
	control_t ctl;
	creg_addr_t ra1, ra2, dst;
	u12 csraddr;
} decode_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t aluout, csrdata, memwd;
	control_t ctl;
	creg_addr_t ra1, ra2, dst;
	u12 csraddr;
} execute_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t writedata, csrdata, memaddr;
	control_t ctl;
	creg_addr_t ra1, ra2, dst;
	u12 csraddr;
} memory_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t writedata, csrdata, memaddr;
	control_t ctl;
	creg_addr_t ra1, ra2, dst;
	u12 csraddr;
} writeback_data_t;

typedef struct packed {
    u1 sd;
    logic [MXLEN-2-36:0] wpri1;
    u2 sxl;
    u2 uxl;
    u9 wpri2;
    u1 tsr;
    u1 tw;
    u1 tvm;
    u1 mxr;
    u1 sum;
    u1 mprv;
    u2 xs;
    u2 fs;
    u2 mpp;
    u2 wpri3;
    u1 spp;
    u1 mpie;
    u1 wpri4;
    u1 spie;
    u1 upie;
    u1 mie;
    u1 wpri5;
    u1 sie;
    u1 uie;
} mstatus_t;

typedef struct packed {
    u4  mode;
    u16 asid;
    u44 ppn;
} satp_t;


typedef struct packed {
	word_t mhartid;

    word_t mtvec;
    word_t mepc;
    word_t mcause;
    word_t mie;
    word_t mip;
    word_t mtval;
    word_t mscratch;

    mstatus_t mstatus;

	word_t mcycle;

	word_t pmpaddr;
	word_t pmpcfg;

	word_t mideleg;
	word_t medeleg;

	satp_t satp;

    word_t stvec;
    word_t sepc;
    word_t scause;
    word_t sie;
    word_t sip;
    word_t stval;
    word_t sscratch;

} csr_t;

endpackage

`endif

