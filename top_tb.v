`timescale 1ns / 1ps

module tb();
 

reg clk = 0,sys_rst = 0;
reg [18:0] din = 16'h0000F;
wire [18:0] dout;
 
 
top dut(clk, sys_rst, din, dout);
 
always #5 clk = ~clk;
 
initial begin
sys_rst = 1'b1;
repeat(5) @(posedge clk);
sys_rst = 1'b0;
#10000;
$stop;
end
 
endmodule
