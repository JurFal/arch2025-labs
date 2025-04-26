`ifndef __REGFILE_SV
`define __REGFILE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif

module regfile 
	import common::*;
	import pipes::*;(
	input logic clk, reset,
    input creg_addr_t ra1, ra2,
    output word_t rd1, rd2,
    input logic wen,
    input creg_addr_t wa,
    input word_t wd,
	output u64 REG[31:0]
);

u64 next_reg[31:0];
//u64 REG[31:0]; // 主寄存器
assign rd1 = REG[ra1]; // 读取依然从主寄存器中读取
assign rd2 = REG[ra2];

always_comb begin
	for (int i = 0; i < 32; i++) begin
		if (wen && (i[4:0] == wa)) begin
			next_reg[i[4:0]] = wd; // 用组合逻辑向next_reg写入
		end else begin
			next_reg[i[4:0]] = REG[i[4:0]]; // 复制其他没有写入的寄存器
		end
	end
end

always_ff @(posedge clk or posedge reset) begin
	if (reset) begin
		for (int i = 0; i < 32; i++) begin
			REG[i[4:0]] <= 64'b0;
		end
	end else begin
		for (int i = 0; i < 32; i++) begin
			REG[i[4:0]] <= next_reg[i[4:0]]; // 用next_reg在下一个周期更新主寄存器
		end
	end
end


endmodule

`endif
