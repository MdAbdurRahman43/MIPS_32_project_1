`timescale 1ns/1ns
module mips32a(clk1,clk2);
input clk1,clk2;
reg[31:0] if_id_ir,if_id_npc,pc;
reg[31:0] id_ex_ir,id_ex_npc,id_ex_a,id_ex_b,id_ex_imm;
reg[2:0] id_ex_type,ex_mem_type,mem_wb_type;
reg[31:0] ex_mem_ir,ex_mem_alout,ex_mem_b;
reg ex_mem_cond;
reg[31:0] mem_wb_ir,mem_wb_alout,mem_wb_lmd;
reg[31:0] regg[0:31];
reg [31:0] mem [0:1023];
parameter add=6'b000000,sub='b000001,andd=6'b000010,orr='b000011,
          slt=6'b000100,mul=6'b000101,hlt=6'b111111,lw='b001000,
          sw=6'b001001,addi='b001010,subi=6'b001011,slti='b001100,
          beqz=6'b001101,bneqz=6'b001110;
parameter rr_alu=3'b000,rm_alu=3'b001,load=3'b010,store=3'b011,branch=3'b100,halt=3'b101;
reg halted;
reg taken_branch;

/*****************************
**********if-stage*************
*****************************/
always @(posedge clk1) begin
if (halted==0) begin 
if (((ex_mem_ir[31:26] == beqz) && (ex_mem_cond == 1)) || 
    ((ex_mem_ir[31:26] == bneqz) && (ex_mem_cond == 0)))
 begin 
if_id_ir<=#2 mem[ex_mem_alout];
taken_branch<=#2 1'b1;
if_id_npc<=#2 ex_mem_alout+1;
pc<=#2 ex_mem_alout+1;end
else begin 
if_id_ir<=#2 mem[pc];
if_id_npc<=#2 pc+1;
pc<=#2 pc+1;
end
end
end
/*****************************
**********id-stage*************
*****************************/
always @(posedge clk2) begin
if (halted==0) begin 
if (if_id_ir[25:21]==5'b00000) begin
 id_ex_a<=0;
 end
else begin 
id_ex_a<=#2 regg[if_id_ir[25:21]]; 
end
if (if_id_ir[20:16]==5'b00000) begin
 id_ex_b<=0; 
end
else begin 
id_ex_b<=#2 regg[if_id_ir[20:16]]; 
end

id_ex_npc<= #2 if_id_npc;
id_ex_ir<=#2 if_id_ir;
id_ex_imm <= #2 { {16{if_id_ir[15]}}, if_id_ir[15:0] };

 case (if_id_ir[31:26]) 
        add,sub,andd,orr,slt,mul: id_ex_type <= #2 rr_alu; 
        addi,subi,slti:id_ex_type <= #2 rm_alu; 
        lw:id_ex_type<=#2 load;                     
        sw:    id_ex_type<=#2 store;                   
        bneqz,beqz:id_ex_type<=#2 branch;               
        hlt:id_ex_type<=#2 halt;                    
        default:    id_ex_type<=#2 halt;
endcase
end
end
/*****************************
**********ex-stage*************
*****************************/
always @(posedge clk1) begin
    if (halted == 0) begin
        ex_mem_type <= #2 id_ex_type;
        ex_mem_ir <= #2 id_ex_ir;
        taken_branch <= #2 0;

        case (id_ex_type) 
            rr_alu: begin
                case (id_ex_ir[31:26])
                    add: ex_mem_alout <= #2 id_ex_a + id_ex_b;
                    sub: ex_mem_alout <= #2 id_ex_a - id_ex_b;
                    andd: ex_mem_alout <= #2 id_ex_a & id_ex_b;
                    orr: ex_mem_alout <= #2 id_ex_a | id_ex_b;
                    slt: ex_mem_alout <= #2 id_ex_a < id_ex_b;
                    mul: ex_mem_alout <= #2 id_ex_a * id_ex_b;
                    default: ex_mem_alout <= #2 32'hxxxxxxxx;
                endcase
            end
            rm_alu: begin
                case (id_ex_ir[31:26])
                    addi: ex_mem_alout <= #2 id_ex_a + id_ex_imm;
                    subi: ex_mem_alout <= #2 id_ex_a - id_ex_imm;
                    slti: ex_mem_alout <= #2 id_ex_a < id_ex_imm;
                    default: ex_mem_alout <= #2 32'hxxxxxxxx;
                endcase
            end
            load, store: begin
                ex_mem_alout <= #2 id_ex_a + id_ex_imm;
                ex_mem_b <= #2 id_ex_b;
            end
            branch: begin
                ex_mem_alout <= #2 id_ex_npc + id_ex_imm;
                ex_mem_cond <= #2 (id_ex_a == 0);
            end
        endcase
    end
end

/*****************************
**********mem-stage*************
*****************************/
always @(posedge clk2) begin
    if (halted == 0) begin
        mem_wb_type <= ex_mem_type;
        mem_wb_ir <= #2 ex_mem_ir;

        case (ex_mem_type)
            rr_alu, rm_alu: mem_wb_alout <= #2 ex_mem_alout;
            load: mem_wb_lmd <= #2 mem[ex_mem_alout];
            store: begin 
                if (taken_branch == 0) begin 
                    mem[ex_mem_alout] <= #2 ex_mem_b;
                end
            end
        endcase
    end
end
/*****************************
**********wb-stage*************
*****************************/
always @(posedge clk1) begin
    if (taken_branch == 0) begin
        case (mem_wb_type)
            rr_alu: begin
                regg[mem_wb_ir[15:11]] <= #2 mem_wb_alout;
            end
            
            rm_alu: begin
                regg[mem_wb_ir[20:16]] <= #2 mem_wb_alout;
            end
            
            load: begin
                regg[mem_wb_ir[20:16]] <= #2 mem_wb_lmd;
            end
            
            halt: begin
                halted <= #2 1'b1;
            end
        endcase
    end
end



endmodule



