`ifndef __MUL_DIV_UNIT_SV
`define __MUL_DIV_UNIT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`endif

module mul_div_unit
    import common::*;
    import pipes::*;(
    input alufunc_t alufunc,
    input word_t src1, src2,
    output word_t result
);

    // 乘法实现 - 使用移位和加法
    function automatic word_t multiply_64bit(word_t a, word_t b);
        word_t product;
        word_t multiplicand;
        word_t multiplier;
        int i;
        
        product = 64'b0;
        multiplicand = a;
        multiplier = b;
        
        for (i = 0; i < 64; i++) begin
            if (multiplier[0]) begin
                product = product + multiplicand;
            end
            multiplicand = multiplicand << 1;
            multiplier = multiplier >> 1;
        end
        
        return product;
    endfunction
    
    // 32位乘法实现
    function automatic u32 multiply_32bit(u32 a, u32 b);
        u64 product;
        u64 multiplicand;
        u64 multiplier;
        int i;
        
        product = 64'b0;
        multiplicand = {32'b0, a};
        multiplier = {32'b0, b};
        
        for (i = 0; i < 32; i++) begin
            if (multiplier[0]) begin
                product = product + multiplicand;
            end
            multiplicand = multiplicand << 1;
            multiplier = multiplier >> 1;
        end
        
        return product[31:0];
    endfunction

    // 除法实现 - 使用移位和减法
    function automatic word_t divide_64bit(word_t dividend, word_t divisor, logic is_signed, logic get_remainder);
        word_t quotient;
        word_t remainder;
        word_t abs_dividend, abs_divisor;
        logic sign_dividend, sign_divisor, sign_result;
        int i;
        
        if (divisor == 64'b0) begin
            // 除零处理
            if (get_remainder) begin
                return dividend;
            end else begin
                return 64'hFFFFFFFFFFFFFFFF;
            end
        end
        
        // 处理符号
        sign_dividend = is_signed && dividend[63];
        sign_divisor = is_signed && divisor[63];
        sign_result = sign_dividend ^ sign_divisor;
        
        abs_dividend = sign_dividend ? (~dividend + 1) : dividend;
        abs_divisor = sign_divisor ? (~divisor + 1) : divisor;
        
        quotient = 64'b0;
        remainder = 64'b0;
        
        for (i = 63; i >= 0; i--) begin
            remainder = remainder << 1;
            remainder[0] = abs_dividend[i];
            
            if (remainder >= abs_divisor) begin
                remainder = remainder - abs_divisor;
                quotient[i] = 1'b1;
            end
        end
        
        if (get_remainder) begin
            return sign_dividend ? (~remainder + 1) : remainder;
        end else begin
            return sign_result ? (~quotient + 1) : quotient;
        end
    endfunction
    
    // 32位除法实现
    function automatic u32 divide_32bit(u32 dividend, u32 divisor, logic is_signed, logic get_remainder);
        u32 quotient;
        u32 remainder;
        u32 abs_dividend, abs_divisor;
        logic sign_dividend, sign_divisor, sign_result;
        int i;
        
        if (divisor == 32'b0) begin
            // 除零处理
            if (get_remainder) begin
                return dividend;
            end else begin
                return 32'hFFFFFFFF;
            end
        end
        
        // 处理符号
        sign_dividend = is_signed && dividend[31];
        sign_divisor = is_signed && divisor[31];
        sign_result = sign_dividend ^ sign_divisor;
        
        abs_dividend = sign_dividend ? (~dividend + 1) : dividend;
        abs_divisor = sign_divisor ? (~divisor + 1) : divisor;
        
        quotient = 32'b0;
        remainder = 32'b0;
        
        for (i = 31; i >= 0; i--) begin
            remainder = remainder << 1;
            remainder[0] = abs_dividend[i];
            
            if (remainder >= abs_divisor) begin
                remainder = remainder - abs_divisor;
                quotient[i] = 1'b1;
            end
        end
        
        if (get_remainder) begin
            return sign_dividend ? (~remainder + 1) : remainder;
        end else begin
            return sign_result ? (~quotient + 1) : quotient;
        end
    endfunction

    always_comb begin
        case(alufunc)
            ALU_MUL: begin
                result = multiply_64bit(src1, src2);
            end
            
            ALU_DIV: begin
                result = divide_64bit(src1, src2, 1'b1, 1'b0);  // signed division
            end
            ALU_DIVU: begin
                result = divide_64bit(src1, src2, 1'b0, 1'b0);  // unsigned division
            end
            ALU_REM: begin
                result = divide_64bit(src1, src2, 1'b1, 1'b1);  // signed remainder
            end
            ALU_REMU: begin
                result = divide_64bit(src1, src2, 1'b0, 1'b1);  // unsigned remainder
            end
            ALU_MULW: begin
                result = {{32{multiply_32bit(src1[31:0], src2[31:0])[31]}}, multiply_32bit(src1[31:0], src2[31:0])};
            end
            ALU_DIVW: begin
                result = {{32{divide_32bit(src1[31:0], src2[31:0], 1'b1, 1'b0)[31]}}, divide_32bit(src1[31:0], src2[31:0], 1'b1, 1'b0)};
            end
            ALU_DIVUW: begin
                result = {32'b0, divide_32bit(src1[31:0], src2[31:0], 1'b0, 1'b0)};
            end
            ALU_REMW: begin
                result = {{32{divide_32bit(src1[31:0], src2[31:0], 1'b1, 1'b1)[31]}}, divide_32bit(src1[31:0], src2[31:0], 1'b1, 1'b1)};
            end
            ALU_REMUW: begin
                result = {32'b0, divide_32bit(src1[31:0], src2[31:0], 1'b0, 1'b1)};
            end
            default: begin
                result = 64'b0;
            end
        endcase
    end

endmodule

`endif