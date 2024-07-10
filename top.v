`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/10/2024 12:53:26 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

///////// Fields of Instruction Register
`define oper_type IR[31:27]
`define rdst IR[26:22]
`define rsrc1 IR[21:17]
`define imm_mode IR[16]
`define rsrc2 IR[15:11]
`define isrc IR[15:0]


////////// Arithmitic operations
`define movsgpr         5'b00000
`define mov             5'b00001
`define add             5'b00010
`define sub             5'b00011
`define mul             5'b00100

////////// Logical operations

`define ror             5'b00101
`define rand            5'b00110
`define rxor            5'b00111
`define rxnor           5'b01000
`define rnand           5'b01001
`define rnor            5'b01010
`define rnot            5'b01011

////////// Memory operations

`define storereg        5'b01101
`define storedin        5'b01110
`define senddout        5'b01111
`define sendreg         5'b10001




module top(
input clk, sys_rst,
input [15:0] din,
output reg [15:0] dout
);


//////////////// Adding Program and Data memory
reg [31:0] inst_mem [15:0];
reg [15:0] data_mem [15:0];


reg [31:0] IR; 

reg [15:0] GPR [31:0] ;


reg [15:0] SGPR ;

reg [31:0] mul_res;


task decode_inst();
begin
 
case(`oper_type)

`movsgpr: begin
    GPR[`rdst] = SGPR;
end

/////////////////////

`mov: begin
    if(`imm_mode)
        GPR[`rdst] = `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1];
 end

/////////////////////

`add: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] + `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] + GPR[`rsrc2];
 end

/////////////////////

`sub: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] - `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] - GPR[`rsrc2];
        
 end

/////////////////////

`mul: begin
    if(`imm_mode)
        mul_res = GPR[`rsrc1] * `isrc;
    else
        mul_res = GPR[`rsrc1] * GPR[`rsrc2];
    
    GPR[`rdst] = mul_res[15:0];
    SGPR       = mul_res[31:16];
 end
 
 ////////////////////
 
`ror: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] | `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] | GPR[`rsrc2];
 end
 
 ////////////////////

`rand: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] & `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] & GPR[`rsrc2];
 end

////////////////////

`rxor: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] ^ `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] ^ GPR[`rsrc2];
 end
 
 ////////////////////

`rxnor: begin
    if(`imm_mode)
        GPR[`rdst] = GPR[`rsrc1] ~^ `isrc;
    else
        GPR[`rdst] = GPR[`rsrc1] ~^ GPR[`rsrc2];
 end
 
////////////////////

`rnand: begin
    if(`imm_mode)
        GPR[`rdst] = ~(GPR[`rsrc1] & `isrc);
    else
        GPR[`rdst] = ~(GPR[`rsrc1] & GPR[`rsrc2]);
 end
 
 ////////////////////

`rnor: begin
    if(`imm_mode)
        GPR[`rdst] = ~(GPR[`rsrc1] | `isrc);
    else
        GPR[`rdst] = ~(GPR[`rsrc1] | GPR[`rsrc2]);
 end
 
 ////////////////////

`rnot: begin
    if(`imm_mode)
        GPR[`rdst] = ~(`isrc);
    else
        GPR[`rdst] = ~(GPR[`rsrc1]);
 end
 
 ////////////////////

`storedin: begin
    data_mem[`isrc] = din;
end

////////////////////

`storereg: begin
    data_mem[`isrc] = GPR[`rsrc1];
end

////////////////////

`senddout: begin
    dout = data_mem[`isrc];
end

////////////////////

`sendreg: begin
    GPR[`rdst] = data_mem[`isrc];
end

////////////////////

endcase
end
endtask


///////////////////////logic for condition flag
reg sign = 0, zero = 0, overflow = 0, carry = 0;
reg [16:0] temp_sum;
 
task decode_condflag();
begin
 
/////////////////sign bit
if(`oper_type == `mul)
  sign = SGPR[15];
else
  sign = GPR[`rdst][15];
 
////////////////carry bit
 
if(`oper_type == `add)
   begin
      if(`imm_mode)
         begin
         temp_sum = GPR[`rsrc1] + `isrc;
         carry    = temp_sum[16]; 
         end
      else
         begin
         temp_sum = GPR[`rsrc1] + GPR[`rsrc2];
         carry    = temp_sum[16]; 
         end   end
   else
    begin
        carry  = 1'b0;
    end
 
///////////////////// zero bit
if(`oper_type == `mul)
  zero =  ~((|SGPR[15:0]) | (|GPR[`rdst]));
else
  zero =  ~(|GPR[`rdst]); 
 
 
//////////////////////overflow bit
 
if(`oper_type == `add)
     begin
       if(`imm_mode)
         overflow = ( (~GPR[`rsrc1][15] & ~IR[15] & GPR[`rdst][15] ) | (GPR[`rsrc1][15] & IR[15] & ~GPR[`rdst][15]) );
       else
         overflow = ( (~GPR[`rsrc1][15] & ~GPR[`rsrc2][15] & GPR[`rdst][15]) | (GPR[`rsrc1][15] & GPR[`rsrc2][15] & ~GPR[`rdst][15]));
     end
  else if(`oper_type == `sub)
    begin
       if(`imm_mode)
         overflow = ( (~GPR[`rsrc1][15] & IR[15] & GPR[`rdst][15] ) | (GPR[`rsrc1][15] & ~IR[15] & ~GPR[`rdst][15]) );
       else
         overflow = ( (~GPR[`rsrc1][15] & GPR[`rsrc2][15] & GPR[`rdst][15]) | (GPR[`rsrc1][15] & ~GPR[`rsrc2][15] & ~GPR[`rdst][15]));
    end 
  else
     begin
     overflow = 1'b0;
     end
 
end
endtask


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


//////////////// Reading program

initial begin
$readmemb("C:/Users/nadin/Desktop/data.mem", inst_mem);
end


////////// Reading instructions one after another
reg [2:0] count = 0;
integer PC = 0;

always@(posedge clk)
begin
    if(sys_rst)
    begin
        count <= 0;
        PC    <= 0;
    end
    else
    begin
        if(count < 4)
        begin
            count <= count + 1;
        end
        else
        begin
            count <= 0;
            PC    <= PC + 1;
        end
    end
end

////////// Reading instructions 

always@(*)
begin
    if(sys_rst == 1'b1)
        IR = 0;
    else
    begin
        IR = inst_mem[PC];
        decode_inst();
        decode_condflag();
    end
end
      
      
      
///////////////////////////////////////////


endmodule      