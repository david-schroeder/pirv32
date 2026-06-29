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
    logic [31:0] rs1_id;
    logic [31:0] rs2_id;
    logic [31:0] imm_id;
    alu_src1_e   alu_src1_id;
    alu_src2_e   alu_src2_id;
    alu_op_e     alu_op_id;
    shift_op_e   shift_op_id;
    branch_e     branch_type_id;
    multdiv_op_e multdiv_op_id;
    logic        is_multdiv_id;

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
    
        .reg_rs1_o   (rs1_id),
        .reg_rs2_o   (rs2_id),
        .imm_o       (imm_id),
        .pc_o        (pc_id),
        .alu_src1_o  (alu_src1_id),
        .alu_src2_o  (alu_src2_id),
        .alu_op_o    (alu_op_id),
        .shift_op_o  (shift_op_id),
        .branch_o    (branch_type_id),
        .multdiv_op_o(multdiv_op_id),
        .is_multdiv_o(is_multdiv_id),

        .mem_op_o    (),
        .is_mem_op_o (),

        .rd_o        (),
        .reg_we_o    (),
        .wb_src_o    (),

        .rd_i        ('0),
        .reg_wdata_i ('0),
        .reg_we_i    ('0)
    );

    pirv32_stage_ex ex_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(id_stage_valid),
        .ps_ready_o(ex_stage_ready),
        .ns_valid_o(ex_stage_valid),
        .ns_ready_i(mem_stage_ready),

        .pc_i        (pc_id),
        .rs1_i       (rs1_id),
        .rs2_i       (rs2_id),
        .imm_i       (imm_id),
        .alu_src1_i  (alu_src1_id),
        .alu_src2_i  (alu_src2_id),
        .alu_op_i    (alu_op_id),
        .shift_op_i  (shift_op_id),
        .branch_i    (branch_type_id),
        .multdiv_op_i(multdiv_op_id),
        .is_multdiv_i(is_multdiv_id)
    );

    pirv32_stage_mem mem_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(ex_stage_valid),
        .ps_ready_o(mem_stage_ready),
        .ns_valid_o(mem_stage_valid),
        .ns_ready_i(wb_stage_ready),

        .dbus_o
    );

    pirv32_stage_wb wb_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(mem_stage_valid),
        .ps_ready_o(wb_stage_ready),

        .dbus_i
    );

endmodule
