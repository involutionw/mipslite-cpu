`include "head.v"

module forwarding_uint(
    input wire          exe_mem_RegWrite,//
    input wire          mem_wb_RegWrite,//
    input wire  [4:0]   exe_mem_rd,//
    input wire  [4:0]   mem_wb_rd,//
    input wire  [4:0]   id_exe_rs,//
    input wire  [4:0]   id_exe_rt,
    input wire  [4:0]   rsD,//
    input wire  [4:0]   rtD,

    output wire [1:0]   forward_A,
    output wire [1:0]   forward_B,
    output wire         forward_AD,
    output wire         froward_BD
);

assign forward_A = ((exe_mem_RegWrite)&&(exe_mem_rd!=0)&&(exe_mem_rd==id_exe_rs))?2'b10:
        (((mem_wb_RegWrite)&&(mem_wb_rd!=0)
        // &&  ~ ((exe_mem_RegWrite) && (exe_mem_rd != 0) && (exe_mem_rd != id_exe_rs))
        // &&(mem_wb_rd == id_exe_rs))
        &&(exe_mem_rd != id_exe_rs) &&(mem_wb_rd == id_exe_rs))
        ?2'b01:2'b00);

assign forward_B = ((exe_mem_RegWrite)&&(exe_mem_rd!=0)&&(exe_mem_rd==id_exe_rt))?2'b10:
        (((mem_wb_RegWrite)&&(mem_wb_rd!=0)
        // && ~ ((exe_mem_RegWrite) && (exe_mem_rd != 0) && (exe_mem_rd == id_exe_rt))
        // &&(mem_wb_rd == id_exe_rt))
        &&(exe_mem_rd != id_exe_rt) &&(mem_wb_rd == id_exe_rt))
        ?2'b01:2'b00);

assign froward_AD = ((rsD)&&(rsD == mem_wb_rd)&&(mem_wb_RegWrite))?1:0;
assign froward_BD = ((rtD)&&(rtD == mem_wb_rd)&&(mem_wb_RegWrite))?1:0;
endmodule 