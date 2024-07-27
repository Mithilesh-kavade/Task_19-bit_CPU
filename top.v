`timescale 1ns/1ps
////////////////fields of Instruction Register
`define op_type       IR[18:15]
`define dest_reg      IR[14:10]
`define src_reg_1     IR[9:5]
`define src_reg_2     IR[4:0]
 
//////////////// Operations

`define add             4'b0000
`define sub             4'b0001

`define and             4'b0010
`define or              4'b0011
`define xor             4'b0100
`define not             4'b0101
 
`define jmp             4'b0110
`define beq             4'b0111
`define bne             4'b1000
`define ld              4'b1001
`define st              4'b1010
`define ld_dout         4'b1011
`define st_din          4'b1100


`define encrypt         4'b1101
`define decrypt         4'b1110
`define hlt             4'b1111
 
module top(
input clk, sys_rst,
input [18:0]din,
output reg [18:0] dout
);

reg [18:0] inst_mem [31:0]; ////program memory to store instructions
reg [18:0] data_mem [31:0]; ////data memory to store data
 
reg [18:0] IR;                                              
 
reg [18:0] GPR [31:0] ;   /////// 32 General purpose registers to perform arithmetic and logical operations

////// Flags to signify exection of jmp, beq and bne instructions
reg jmp_flag = 0;
reg beq_flag = 0;
reg bne_flag = 0;
reg stop = 0;

///// initial data stored in data memory to be later used for calculation
initial begin
    data_mem[0]  <= 19'h00001;
    data_mem[1]  <= 19'h00002;
    data_mem[2]  <= 19'h00003;
    data_mem[3]  <= 19'h00004;
    data_mem[4]  <= 19'h00005;
    data_mem[5]  <= 19'h0000F;
end

////// Decoding and executing instructions
task decode_inst();
begin
 
case(`op_type)

`add :
begin
GPR[`dest_reg] = GPR[`src_reg_1] + GPR[`src_reg_2];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`sub:
begin
GPR[`dest_reg] = GPR[`src_reg_1] - GPR[`src_reg_2];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`and:
begin
GPR[`dest_reg] = GPR[`src_reg_1] & GPR[`src_reg_2];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`or:
begin
GPR[`dest_reg] = GPR[`src_reg_1] | GPR[`src_reg_2];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`xor:
begin
GPR[`dest_reg] = GPR[`src_reg_1] ^ GPR[`src_reg_2];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`not:
begin
GPR[`dest_reg] = ~GPR[`src_reg_1];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`jmp:
begin
jmp_flag = 1'b1;
end

`beq:
begin
if(GPR[`src_reg_1] == GPR[`src_reg_2])
begin
beq_flag = 1'b1;
end
else
begin
beq_flag = 1'b0;
end
end

`bne:
begin
if(GPR[`src_reg_1] !== GPR[`src_reg_2])
begin
bne_flag = 1'b1;
end
else
begin
bne_flag = 1'b0;
end
end

`ld:
begin
GPR[`dest_reg] = data_mem[`src_reg_1];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`st:
begin
data_mem[`dest_reg] = GPR[`src_reg_1];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`ld_dout:
begin
dout = data_mem[`dest_reg];
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`st_din:
begin
data_mem[`dest_reg] = din;
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`encrypt:
begin
GPR[`dest_reg] = (GPR[`src_reg_1]**7) % 33;
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`decrypt:
begin
GPR[`dest_reg] = (GPR[`src_reg_1]**3) % 33;
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

`hlt:
begin
stop = 1'b1;
jmp_flag = 1'b0;
beq_flag = 1'b0;
bne_flag = 1'b0;
end

endcase
end
endtask

    

////////////////////////////////////////////////// reading program from given path
initial begin 
$readmemb("C:/Verilog_Practice/Vicharak_task_new/prog.mem",inst_mem);
end

reg [2:0] count = 0;
integer PC = 0;

////////////////////////////////// FSM states
parameter idle = 0, fetch_inst = 1, dec_exec_inst = 2, next_inst = 3, sense_halt = 4, delay_next_inst = 5;
//////idle : check reset state
///// fetch_inst : load instrcution from Program memory into instruction register
///// dec_exec_inst : execute instruction / execution of decode_inst()
///// next_inst : next instruction to be fetched
reg [2:0] state = idle;
reg [2:0] next_state = idle;
 
///////////////////RESET
always@(posedge clk)
begin
if(sys_rst)
state <= idle;
else
state <= next_state; 
end
 

always@(*)
begin
case(state)

idle: begin
IR = 19'b0;
PC = 0;
next_state = fetch_inst;
end

fetch_inst: begin
IR = inst_mem[PC];   
next_state  = dec_exec_inst;
end

dec_exec_inst: begin
decode_inst();
next_state = delay_next_inst;
end

delay_next_inst:begin
if(count < 4)
next_state = delay_next_inst;       
else
next_state = next_inst;
end

next_inst:begin
next_state = sense_halt;
if(jmp_flag == 1'b1)
PC = `dest_reg;
else if(beq_flag == 1'b1)
PC = `dest_reg;
else if(bne_flag == 1'b1)
PC = `dest_reg;
else
PC = PC + 1;
end

sense_halt: begin
if(stop == 1'b0)
next_state = fetch_inst;
else if(sys_rst == 1'b1)
next_state = idle;
else
next_state = sense_halt;
end
  
default: next_state = idle;
  
endcase
end
 
////////////////////////////////// Count 
 
always@(posedge clk)
begin
case(state)
 
idle: begin
count <= 0;
end
 
fetch_inst: begin
count <= 0;
end
 
dec_exec_inst: begin
count <= 0;    
end  
 
delay_next_inst: begin
count  <= count + 1;
end

next_inst : begin
count <= 0;
end
 
sense_halt : begin
count <= 0;
end
 
default : count <= 0;

endcase
end

endmodule