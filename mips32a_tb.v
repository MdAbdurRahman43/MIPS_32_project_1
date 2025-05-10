`timescale 1ns/1ns
module mips32a_tb;
reg clk1,clk2;
integer k;
mips32a mips32a_t(clk1,clk2);
   initial begin
        clk1 = 0; 
        clk2 = 0; 
   
    repeat(20) begin
        #5 clk1 <= 1; #5 clk1 <= 0;
        #5 clk2 <= 0; #5 clk2 <= 1;
    end
end


initial begin 
    for (k = 0; k < 31; k=k+1) 
        mips32a_t.regg[k] = k; 
    
    mips32a_t.mem[0] = 32'h2801000a;  // ADDI  R1,R0,10 
    mips32a_t.mem[1] = 32'h28020014;  // ADDI  R2,R0,20 
    mips32a_t.mem[2] = 32'h28030019;  // ADDI  R3,R0,25 
    mips32a_t.mem[3] = 32'h0ce77800;  // OR    R7,R7,R7 -- dummy instr. 
    mips32a_t.mem[4] = 32'h0ce77800;  // OR    R7,R7,R7 -- dummy instr. 
    mips32a_t.mem[5] = 32'h00222000;  // ADD   R4,R1,R2 
    mips32a_t.mem[6] = 32'h0ce77800;  // OR    R7,R7,R7 -- dummy instr. 
    mips32a_t.mem[7] = 32'h00832800;  // ADD   R5,R4,R3 
    mips32a_t.mem[8] = 32'hfc000000;  // HLT 
    
    mips32a_t.halted = 0; 
    mips32a_t.pc = 0; 
    mips32a_t.taken_branch = 0; 
    
    #280   
    
    for (k = 0; k < 6; k=k+1) 
        $display ("R%1d - %2d", k, mips32a_t.regg[k]); 
end
endmodule
