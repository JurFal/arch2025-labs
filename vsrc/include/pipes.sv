`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif

package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;
parameter F7_R_ALL32 = 7'b0110011;
parameter F7_R_ALL64 = 7'b0111011;
parameter F7_I_MAT32 = 7'b0010011;
parameter F7_I_MAT64 = 7'b0011011;

parameter F3_ADD = 3'b000;
    
/* Define pipeline structures here */

typedef struct packed {
	u32 raw_instr;
} fetch_data_t;

typedef struct packed {
	u32 rd;
} reg_data_t;

typedef enum logic [5:0] { 
	UNKNOWN, ADDI
} decode_op_t; 

typedef enum logic [4:0] {
	ALU_ADD
} alufunc_t;

typedef struct packed {
	decode_op_t op;
	alufunc_t alufunc;
	u1 regwrite;
	
} control_t;

typedef struct packed {
	word_t srca, srcb;
	control_t ctl;
	creg_addr_t dst; 
} decode_data_t;

endpackage

`endif

