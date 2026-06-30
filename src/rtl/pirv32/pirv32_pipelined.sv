// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_pipelined
    import pirv32_pkg::*;
    import tilelink_pkg::*;
#(
    parameter logic [31:0] BOOT_ADDR      = 32'h00000080,
    parameter logic [31:0] DEBUG_ADDR     = 32'h10000000,
    parameter logic [31:0] DEBUG_EXC_ADDR = 32'h10001000
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  logic [31:0] interrupts_i,

    output tl_h2d_t     ibus_o,
    input  tl_d2h_t     ibus_i,
    output tl_h2d_t     dbus_o,
    input  tl_d2h_t     dbus_i
);

    // Stage control signals
    logic if_stage_valid;
    logic id_stage_valid;
    logic ex_stage_valid;
    logic mem_stage_valid;

    logic id_stage_ready;
    logic ex_stage_ready;
    logic mem_stage_ready;
    logic wb_stage_ready;

    // IF stage signals
    logic [31:0] pc_if;
    logic [31:0] instr_if;

    // ID stage signals
    logic [31:0] pc_id;
    logic [ 4:0] ra1_id;
    logic [ 4:0] ra2_id;
    logic [31:0] rs1_id;
    logic [31:0] rs2_id;
    logic [31:0] imm_id;
    alu_src1_e   alu_src1_id;
    alu_src2_e   alu_src2_id;
    alu_op_e     alu_op_id;
    shift_op_e   shift_op_id;
    branch_e     branch_type_id;
    logic        is_branch_id;
    logic        is_jump_id;
    multdiv_op_e multdiv_op_id;
    logic        is_multdiv_id;
    logic [ 4:0] rd_id;
    logic        reg_we_id;
    wb_src_e     wb_src_id;

    // EX stage signals
    logic [31:0] pc_target_ex;
    logic        is_branch_ex;
    logic        is_jump_ex;
    logic        take_branch_ex;
    logic [ 4:0] rd_ex;
    logic        reg_we_ex;
    wb_src_e     wb_src_ex;
    logic [31:0] result_ex;

    // MEM stage signals
    logic [ 4:0] rd_mem;
    logic        reg_we_mem;
    wb_src_e     wb_src_mem;
    logic [31:0] reg_wdata_mem;
    logic        fw_valid_mem;
    logic [ 4:0] fw_rd_mem;
    logic [31:0] fw_data_mem;

    // WB stage signals
    logic [ 4:0] rd_wb;
    logic        reg_we_wb;
    logic [31:0] reg_wdata_wb;
    logic        fw_valid_wb;
    logic [ 4:0] fw_rd_wb;
    logic [31:0] fw_data_wb;

    /////////////////////////
    //                     //
    // Stage Instantiation //
    //                     //
    /////////////////////////

    pirv32_stage_if #(
        .BOOT_ADDR     (BOOT_ADDR),
        .DEBUG_ADDR    (DEBUG_ADDR),
        .DEBUG_EXC_ADDR(DEBUG_EXC_ADDR)
    ) if_stage_i (
        .clk_i,
        .rst_ni,

        .ns_ready_i(id_stage_ready),
        .ns_valid_o(if_stage_valid),

        .pc_target_i  (pc_target_ex),
        .is_jump_i    (is_jump_ex),
        .is_branch_i  (is_branch_ex),
        .take_branch_i(take_branch_ex),

        .pc_o   (pc_if),
        .instr_o(instr_if),

        .ibus_o,
        .ibus_i
    );

    pirv32_stage_id id_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(if_stage_valid),
        .ps_ready_o(id_stage_ready),
        .ns_valid_o(id_stage_valid),
        .ns_ready_i(ex_stage_ready),

        .interrupts_i,
        .pc_i        (pc_if),
        .instr_i     (instr_if),
    
        .reg_ra1_o   (ra1_id),
        .reg_ra2_o   (ra2_id),
        .reg_rs1_o   (rs1_id),
        .reg_rs2_o   (rs2_id),
        .imm_o       (imm_id),
        .pc_o        (pc_id),
        .alu_src1_o  (alu_src1_id),
        .alu_src2_o  (alu_src2_id),
        .alu_op_o    (alu_op_id),
        .shift_op_o  (shift_op_id),
        .branch_o    (branch_type_id),
        .is_branch_o (is_branch_id),
        .is_jump_o   (is_jump_id),
        .multdiv_op_o(multdiv_op_id),
        .is_multdiv_o(is_multdiv_id),

        .mem_op_o    (),
        .is_mem_op_o (),

        .rd_o        (rd_id),
        .reg_we_o    (reg_we_id),
        .wb_src_o    (wb_src_id),

        .rd_i        (rd_wb),
        .reg_wdata_i (reg_wdata_wb),
        .reg_we_i    (reg_we_wb)
    );

    pirv32_stage_ex ex_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(id_stage_valid),
        .ps_ready_o(ex_stage_ready),
        .ns_valid_o(ex_stage_valid),
        .ns_ready_i(mem_stage_ready),

        .pc_i        (pc_id),
        .ra1_i       (ra1_id),
        .ra2_i       (ra2_id),
        .rs1_i       (rs1_id),
        .rs2_i       (rs2_id),
        .imm_i       (imm_id),
        .alu_src1_i  (alu_src1_id),
        .alu_src2_i  (alu_src2_id),
        .alu_op_i    (alu_op_id),
        .shift_op_i  (shift_op_id),
        .branch_i    (branch_type_id),
        .is_branch_i (is_branch_id),
        .is_jump_i   (is_jump_id),
        .multdiv_op_i(multdiv_op_id),
        .is_multdiv_i(is_multdiv_id),
        .rd_i        (rd_id),
        .reg_we_i    (reg_we_id),
        .wb_src_i    (wb_src_id),

        .pc_target_o  (pc_target_ex),
        .is_branch_o  (is_branch_ex),
        .is_jump_o    (is_jump_ex),
        .take_branch_o(take_branch_ex),

        .fw_valid_mem_i(fw_valid_mem),
        .fw_rd_mem_i   (fw_rd_mem),
        .fw_data_mem_i (fw_data_mem),
        .fw_valid_wb_i (fw_valid_wb),
        .fw_rd_wb_i    (fw_rd_wb),
        .fw_data_wb_i  (fw_data_wb),

        .rd_o    (rd_ex),
        .reg_we_o(reg_we_ex),
        .wb_src_o(wb_src_ex),
        .result_o(result_ex)
    );

    pirv32_stage_mem mem_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(ex_stage_valid),
        .ps_ready_o(mem_stage_ready),
        .ns_valid_o(mem_stage_valid),
        .ns_ready_i(wb_stage_ready),

        .rd_i       (rd_ex),
        .reg_we_i   (reg_we_ex),
        .wb_src_i   (wb_src_ex),
        .ex_result_i(result_ex),

        .rd_o       (rd_mem),
        .reg_we_o   (reg_we_mem),
        .wb_src_o   (wb_src_mem),
        .reg_wdata_o(reg_wdata_mem),

        .fw_valid_o(fw_valid_mem),
        .fw_rd_o   (fw_rd_mem),
        .fw_data_o (fw_data_mem),

        .dbus_o,
        .dbus_i
    );

    pirv32_stage_wb wb_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(mem_stage_valid),
        .ps_ready_o(wb_stage_ready),

        .rd_i       (rd_mem),
        .reg_we_i   (reg_we_mem),
        .wb_src_i   (wb_src_mem),
        .ex_result_i(reg_wdata_mem),

        .reg_rd_o   (rd_wb),
        .reg_we_o   (reg_we_wb),
        .reg_wdata_o(reg_wdata_wb),

        .fw_valid_o (fw_valid_wb),
        .fw_rd_o    (fw_rd_wb),
        .fw_data_o  (fw_data_wb),

        .dbus_i
    );

endmodule
