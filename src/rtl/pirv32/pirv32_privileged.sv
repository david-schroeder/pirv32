// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_privileged
    import pirv32_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    input  logic [31:0] interrupts_i,
    input  logic [31:0] pc_i,
    input  logic [31:0] next_arch_pc_i,
    input  logic        stall_i,

    input  logic        ecall_i,
    input  logic        ebreak_i,
    input  logic        mret_i,
    input  logic        dtim_misaligned_i,

    input  mem_op_e     dtim_op_i,
    input  logic [31:0] dtim_addr_i,

    input  logic        csr_read_en_i,
    input  logic        csr_write_en_i,
    input  csr_e        csr_sel_i,
    input  csr_op_e     csr_op_i,
    input  logic [31:0] csr_operand_i,
    output logic [31:0] csr_rdata_o,

    output logic        trap_o,
    output mcause_t     trap_cause_o,
    output logic [31:0] trap_pc_o,
    output logic [31:0] mepc_o,

    input  logic        commit_i
);

    logic [31:0] trap_val;
    logic [31:0] trap_epc;

    mstatus_t    mstatus;
    logic [31:0] mie;
    logic [31:0] mip;
    mtvec_t      mtvec;

    pirv32_trap trap_i (
        .ext_ints_i       (interrupts_i),
        .pc_i             (pc_i),
        .next_arch_pc_i   (next_arch_pc_i),
        .stall_i          (stall_i),
        .mstatus_i        (mstatus),
        .mie_i            (mie),
        .mip_i            (mip),
        .mtvec_i          (mtvec),
        .ecall_i          (ecall_i),
        .ebreak_i         (ebreak_i),
        .dtim_misaligned_i(dtim_misaligned_i),
        .dtim_op_i        (dtim_op_i),
        .dtim_addr_i      (dtim_addr_i),
        .trap_o           (trap_o),
        .cause_o          (trap_cause_o),
        .trap_pc_o        (trap_pc_o),
        .trap_val_o       (trap_val),
        .epc_o            (trap_epc)
    );

    pirv32_csrs csrfile_i (
        .clk_i,
        .rst_ni,
        .read_en_i     (csr_read_en_i),
        .write_en_i    (csr_write_en_i),
        .csr_sel_i     (csr_sel_i),
        .op_i          (csr_op_i),
        .operand_i     (csr_operand_i),
        .rdata_o       (csr_rdata_o),

        .ext_ints_i    (interrupts_i),
        .trap_i        (trap_o),
        .trap_cause_i  (trap_cause_o),
        .trap_val_i    (trap_val),
        .epc_i         (trap_epc),
        .mret_i        (mret_i),

        .mstatus_o     (mstatus),
        .mie_o         (mie),
        .mip_o         (mip),
        .mtvec_o       (mtvec),
        .mepc_o        (mepc_o),

        .commit_i      (commit_i)
    );

endmodule
