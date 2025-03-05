`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;
parameter OP_R_ALL32 = 7'b0110011;
parameter OP_R_ALL64 = 7'b0111011;
parameter OP_I_MAT32 = 7'b0010011;
parameter OP_I_MAT64 = 7'b0011011;

parameter F3_ADD = 3'b000;
parameter F3_XOR = 3'b100;
parameter F3_OR  = 3'b110;
parameter F3_AND = 3'b111;


    
/* Define pipeline structures here */

typedef enum logic [5:0] { 
	UNKNOWN, ADDI, XORI, ORI, ANDI,
	ADD, SUB, AND, OR, XOR,
	ADDIW, ADDW, SUBW
} decode_op_t; 

typedef enum logic [4:0] {
	ALU_ADD, ALU_XOR, ALU_OR, ALU_AND, ALU_SUB
} alufunc_t;

typedef struct packed {
	decode_op_t op;
	alufunc_t alufunc;
	u1 regwrite, alusrc, aluext, memwrite, memread;
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
	word_t writedata;
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

