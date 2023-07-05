`include "head.v"
`timescale 1ns / 1ps
module mips_pipeline(
    input wire clk,
    input wire rst

);
wire [31:0] 
            // pcF, ALU_out,
            // Read_reg_data1, Read_reg_data2, imm_extend, 
            // SrcA, SrcB, instructionD,
            Write_reg_Data, Write_memory_Data, next_pc,
            Read_memory_data;

wire stallD, stallF, flush;

wire [31:0] pcF, pc_4F, instructionF;

wire [31:0] instructionD, pc_4D,
            Read_reg_data_1D,
            Read_reg_data_2D,
            imm_extD;

wire ALUsrc_muxD, Write_reg_muxD, RegDstD;
wire RegWriteD, MemwriteD, MemreadD;
wire extend_opD;
wire [`ALU_OP_LENGTH-1:0] alu_opD;
wire [4:0] rtD, rdD, rsD;

assign rtD = instructionD[20:16],
       rdD = instructionD[15:11],
       rsD = instructionD[25:21];

wire [31:0] SrcAE, SrcBE, ALU_outE,
            imm_extE,
            Read_reg_data_1E,
            Read_reg_data_2E;
wire [5:0] funcE;
wire [4:0] Write_Reg_AddressE,
           rtE, rdE, rsE;
wire [`ALU_OP_LENGTH-1:0] alu_opE;
wire ALUsrc_muxE, Write_reg_muxE, RegDstE;
wire RegWriteE, MemwriteE, MemreadE;
wire zeroE;

assign funcE = imm_extE[5:0];

wire [31:0] Write_memory_DataM, Read_memory_dataM,
            ALU_outM;
wire [4:0] Write_Reg_AddressM;
//TODO Write_memory_address
wire RegWriteM, MemwriteM, zeroM, Write_reg_muxM;

wire [31:0] ALU_outW, Read_memory_dataW;
wire [4:0] Write_Reg_AddressW;
wire RegWriteW, Write_reg_muxW;

assign pc_4F = pcF+32'h00000004;
// assign SrcAE = Read_reg_data_1E;
wire ALUsrc_mux, Write_reg_mux, RegDst;
wire RegWrite, Memwrite, MemRead;
wire extend_op;
wire [`ALU_OP_LENGTH-1:0]       alu_op;
wire [`ALU_CONTROL_LENGTH-1:0]  alu_cont;

wire [4:0] rs, rt, rd;
wire [4:0] r1D, r2D, r3D;
assign rs = instructionD[25:21],
       rt = instructionD[20:16],
       rd = instructionD[15:11];
assign r1D = rs,
       r2D = rt;
wire [15:0] imm16, imm16F;
wire [25:0] imm26;
assign imm16 = instructionD[15:0],
       imm16F = instructionF[15:0],
       imm26 = instructionD[25:0];

wire [5:0] op, func, opF;

assign op = instructionD[31:26],
       func = instructionD[5:0],
       opF = instructionF[31:26];
assign imm16F = instructionF[15:0];
wire BranchD, Jmp, zero, predict;

controller_uint U_CU(
    .op(op),
    .stall(~stallD),
    .RegDst(RegDstD),
    .Branch(BranchD),
    .Jmp(Jmp),
    .Write_reg_mux(Write_reg_muxD),
    .ALUOp(alu_opD),
    .Memwrite(MemwriteD),
    .Memread(MemreadD),
    .ALUsrc(ALUsrc_muxD),
    .RegWrite(RegWriteD),
    .extend_op(extend_opD)
);

alu_control U_ALU_CONT(
    .aluop(alu_opE),
    .func(funcE),
    .alu_control(alu_cont)
);
wire is_equal, fix_cont;
// assign fix_cont = (BranchD)
wire [`LENGTH-1:0] next_pc_predict, next_pc_fix;

MuxKey #(3, 2, `LENGTH) U_pc_src_mux(next_pc, ({{opF==`OP_JAL}, {BranchD&is_equal}}), {
    2'b00, pc_4F,
    2'b01, pc_4D + {{14{imm16[15]}}, imm16, 2'b00},
    2'b10, {pc_4F[31:28], {instructionF[25:0], 2'b00}}
});

pc U_PC(.clk(clk),
        .rst(rst),
        .wen(~stallF),
        .npc(next_pc),
        .pc(pcF)
);

// npc U_NPC(.pc(pc),
//           .imm16(imm16),
//           .imm26(imm26),
//           .branch((Branch&zero)),
//           .jmp(Jmp),
//           .npc(next_pc)
// );

grp U_RF(.clk(clk),
         .wen(RegWriteW),
         .r1(r1D),
         .r2(r2D),
         .r3(Write_Reg_AddressW),
         .WD(Write_reg_Data),
         .RD1(Read_reg_data_1D),
         .RD2(Read_reg_data_2D)
);

extend U_EXT(.imm16(imm16),
             .ext_op(extend_opD),
             .ext_out(imm_extD)
);

wire [`LENGTH-1:0] w_hi, w_lo, hi, lo, r_hi, r_lo, w_hiE, w_loE; 
wire wen_hilo;
reg_hilo_r U_HILO_R(.clk(clk),
                    .rst(rst),
                    .hi_in(lo),
                    .lo_in(hi),
                    .hi_out(r_hi),
                    .lo_out(r_lo)
);
hilo_reg U_HILO(.clk(clk),
                .rst(rst),
                .wen(wen_hiloE),
                .w_hi(w_hiE),
                .w_lo(w_loE),
                .lo(lo),
                .hi(hi)
);
reg_hilo_w U_HILO_W(.clk(clk),
                    .rst(rst),
                    .hi_in(w_hi),
                    .lo_in(w_lo),
                    .wen_in(wen_hilo),
                    .hi_out(w_hiE),
                    .lo_out(w_loE),
                    .wen_out(wen_hiloE)
);
alu U_ALU(.SrcA(SrcAE),
          .SrcB(SrcBE),
          .alu_cont(alu_cont),
          .zero(zeroE),
          .ALUout(ALU_outE),
          .LO(r_lo),
          .HI(r_hi),
          .W_HILO(wen_hilo),
          .Write_HI(w_hi),
          .Write_LO(w_lo)
);

wire [31:0] wrie_IM_to_IR;
instruction_memory U_IM(.instruction_address(pcF[`INST_MEM_ADDRESS+1:2]),
                        // .instruction(wrie_IM_to_IR));
                        .instruction(instructionF));
// instruction_reg U_IR(.clk(clk),
//                      .rst(rst),
//                      .ni(wrie_IM_to_IR),
//                      .i(instruction)
// );

data_memory U_DM(.clk(clk),
                 .wen(MemwriteM),
                 .address(ALU_outM[`DATA_MEM_ADDRESS+1:2]),
                 .write_data(Write_memory_DataM),
                 .read_data(Read_memory_dataM)
);

wire [`LENGTH-1:0] SrcB_tmp;

//AULsrc MUX
MuxKey #(2, 1, 32) U_ALUsrc_MUX(SrcBE, ALUsrc_muxE, {
    1'b0, SrcB_tmp,
    1'b1, imm_extE
});
//Write_reg_MemorALU
MuxKey #(2, 1, 32) U_Write_reg_data_MUX(Write_reg_Data, Write_reg_muxW, {
    1'b0, ALU_outW,
    1'b1, Read_memory_dataW
});

//Write_Reg_Address Mux
MuxKey #(2, 1, 5) U_Write_reg_address_MUX(Write_Reg_AddressE, RegDstE, {
    1'b0, rtE,
    1'b1, rdE
});
wire flushF = (BranchD&is_equal);
reg_if_id U_IF_ID(
    .clk(clk),
    .rst(rst),
    .wen(~stallD),
    .flush(flushF),
    .instruction_in(instructionF),
    .pc_4_in(pc_4F),
    .instruction_out(instructionD),
    .pc_4_out(pc_4D)
);

reg_id_exe U_ID_EXE(
    .clk(clk),
    .rst(rst),
    // .wen(~stallD),
    .flush(flush),
    .RegDst_in(RegDstD),
    .ALUOp_in(alu_opD),
    .Write_reg_mux_in(Write_reg_muxD),
    .Memwrite_in(MemwriteD),
    .Memread_in(MemreadD),
    .ALUsrc_in(ALUsrc_muxD),
    .RegWrite_in(RegWriteD),
    .Read_data_1_in(Read_reg_data_1D),
    .Read_data_2_in(Read_reg_data_2D),
    .imm_ext_in(imm_extD),
    .rt_in(rtD),
    .rd_in(rdD),
    .rs_in(rsD),
    .RegDst_out(RegDstE),
    .ALUOp_out(alu_opE),
    .Write_reg_mux_out(Write_reg_muxE),
    .Memwrite_out(MemwriteE),
    .Memread_out(MemreadE),
    .ALUsrc_out(ALUsrc_muxE),
    .RegWrite_out(RegWriteE),
    .Read_data_1_out(Read_reg_data_1E),
    .Read_data_2_out(Read_reg_data_2E),
    .imm_ext_out(imm_extE),
    .rt_out(rtE),
    .rd_out(rdE),
    .rs_out(rsE)
);

reg_exe_mem U_EXE_MEM(
    .clk(clk),
    .rst(rst),
    .Memwrite_in(MemwriteE),
    .RegWrite_in(RegWriteE),
    .ALU_out_in(ALU_outE),
    .Write_memory_Data_in(Read_reg_data_2E),
    .zero_in(zeroE),
    .Write_Reg_Address_in(Write_Reg_AddressE),
    .Write_reg_mux_in(Write_reg_muxE),
    .Memwrite_out(MemwriteM),
    .RegWrite_out(RegWriteM),
    .ALU_out_out(ALU_outM),
    .Write_memory_Data_out(Write_memory_DataM),
    .zero_out(zeroM),
    .Write_Reg_Address_out(Write_Reg_AddressM),
    .Write_reg_mux_out(Write_reg_muxM)
);

reg_mem_wb U_MEM_WB(
    .clk(clk),
    .rst(rst),
    .RegWrite_in(RegWriteM),
    .Read_memory_data_in(Read_memory_dataM),
    .Write_Reg_Address_in(Write_Reg_AddressM),
    .ALU_out_in(ALU_outM),
    .Write_reg_mux_in(Write_reg_muxM),
    .RegWrite_out(RegWriteW),
    .Read_memory_data_out(Read_memory_dataW),
    .Write_Reg_Address_out(Write_Reg_AddressW),
    .ALU_out_out(ALU_outW),
    .Write_reg_mux_out(Write_reg_muxW)
);

wire [1:0] forward_a, forward_b;
wire forward_AD, forward_BD;
forwarding_uint U_FORWARD(
    .exe_mem_RegWrite(RegWriteM),
    .mem_wb_RegWrite(RegWriteW),
    .exe_mem_rd(Write_Reg_AddressM),
    .mem_wb_rd(Write_Reg_AddressW),
    .id_exe_rs(rsE),
    .id_exe_rt(rtE),
    .rsD(rsD),
    .rtD(rtD),

    .forward_A(forward_a),
    .forward_B(forward_b),
    .forward_AD(forward_AD),
    .forward_BD(forward_BD)
);

MuxKey #(3, 2, `LENGTH) U_FORWARD_MUX1(SrcAE, forward_a, {
    2'b01, Write_reg_Data,
    2'b10, ALU_outM,
    2'b00, Read_reg_data_1E
});

MuxKey #(3, 2, `LENGTH) U_FORWARD_MUX2(SrcB_tmp, forward_b, {
    2'b01, Write_reg_Data,
    2'b10, ALU_outM,
    2'b00, Read_reg_data_2E
});

hazard_detection_uint U_HAZARD_DETE(
    .rtE(rtE),
    .rsE(rsE),
    .rsD(rsD),
    .rtD(rtD),
    .id_exe_mem_read(MemreadE),
    .branchD(BranchD),
    .RegWriteE(RegWriteE),
    .Write_Reg_AddressE(Write_Reg_AddressE),
    .Write_Reg_AddressM(Write_Reg_AddressM),
    .Write_reg_muxM(Write_reg_muxM),
    .stallD(stallD),
    .stallF(stallF),
    .flush(flush)
);
wire [`LENGTH-1:0] read_data_1tmp, read_data_2tmp;
MuxKey #(2, 1, `LENGTH) U_branch_r1_mux(read_data_1tmp, forward_AD, {
    1'b0, Read_reg_data_1D,
    1'b1, ALU_outM
});
MuxKey #(2, 1, `LENGTH) U_branch_r2_mux(read_data_2tmp, forward_BD, {
    1'b0, Read_reg_data_2D,
    1'b1, ALU_outM
});

is_equal U_IS_EQUAL(
    .read_data_1(read_data_1tmp),
    .read_data_2(read_data_2tmp),
    .equal(is_equal)
);

endmodule