`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;

// opcode
parameter OP_R_OPS = 7'b0110011; // R-Type, normal operators
parameter OP_R_OPW = 7'b0111011; // R-Type, operators, sign-externed 32-bit results
parameter OP_I_OPS = 7'b0010011; // I-Type, normal operators
parameter OP_I_OPW = 7'b0011011; // I-Type, operators, sign-externed 32-bit results
parameter OP_I_LIM = 7'b0000011; // I-Type, load immediate
parameter OP_S_SIM = 7'b0100011; // S-Type, store immediate
parameter OP_U_LUI = 7'b0110111; // U-Type, load upper immediate

// operation F3
parameter F3_OP_ADD = 3'b000; // add and sub
parameter F3_OP_XOR = 3'b100; // xor
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


    
/* Define pipeline structures here */

typedef enum logic [5:0] { 
	UNKNOWN, ADDI, XORI, ORI, ANDI,
	ADD, SUB, AND, OR, XOR,
	ADDIW, ADDW, SUBW,
	LB, LBU, LH, LHU, LW, LWU, LD,
	SB, SH, SW, SD,
	LUI
} opcode_t; 

typedef enum logic [4:0] {
	ALU_ADD, ALU_XOR, ALU_OR, ALU_AND, ALU_SUB
} alufunc_t;

typedef struct packed {
	opcode_t op;
	alufunc_t alufunc;
	u1 regwrite, immsrc, aluext, memwrite, memread, zeroextwb;
	msize_t memsize;
} control_t;


typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
} fetch_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t srca, srcb, imm;
	control_t ctl;
	creg_addr_t dst;
} decode_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t aluout, pcbranch, memwd;
	control_t ctl;
	creg_addr_t dst;
} execute_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t aluout, readdata;
	control_t ctl;
	creg_addr_t dst;
} memory_data_t;

typedef struct packed {
	u1 valid;
	u32 raw_instr;
	u64 pc;
	word_t writedata;
	control_t ctl;
	creg_addr_t dst;
} writeback_data_t;

endpackage

`endif

