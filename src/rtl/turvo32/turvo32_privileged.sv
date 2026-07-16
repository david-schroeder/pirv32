// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module turvo32_privileged
    import turvo32_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    input  logic [31:0] interrupts_i,
    input  logic [31:0] pc_i,
    input  logic [31:0] next_arch_pc_i,
    input  logic        stall_i,

    input  logic        mem_misaligned_i,
    input  mem_op_e     mem_op_i,
    input  logic [31:0] mem_addr_i,

    input  logic        instr_valid_i,
    input  logic [31:0] instr_i,
    input  logic [31:0] rs1_i,
    output logic [31:0] csr_rdata_o,
    output logic        mret_o,

    output logic        trap_o,
    output mcause_t     mcause_o,
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

    csr_e        csr_sel;
    csr_op_e     csr_op;
    logic [31:0] csr_operand;
    logic        csr_re;
    logic        csr_we;
    logic        ecall;
    logic        ebreak;
    logic        mret;

    assign mret_o = mret;

    turvo32_trap trap_i (
        .clk_i,
        .rst_ni,

        .ext_ints_i      (interrupts_i),
        .pc_i            (pc_i),
        .next_arch_pc_i  (next_arch_pc_i),
        .instr_valid_i   (instr_valid_i),
        .stall_i         (stall_i),
        .mstatus_i       (mstatus),
        .mie_i           (mie),
        .mip_i           (mip),
        .mtvec_i         (mtvec),
        .ecall_i         (ecall),
        .ebreak_i        (ebreak),
        .mem_misaligned_i(mem_misaligned_i && instr_valid_i),
        .mem_op_i        (mem_op_i),
        .mem_addr_i      (mem_addr_i),
        .trap_o          (trap_o),
        .cause_o         (mcause_o),
        .trap_pc_o       (trap_pc_o),
        .trap_val_o      (trap_val),
        .epc_o           (trap_epc)
    );

    turvo32_csrs csrfile_i (
        .clk_i,
        .rst_ni,

        .read_en_i     (csr_re),
        .write_en_i    (csr_we),
        .csr_sel_i     (csr_sel),
        .op_i          (csr_op),
        .operand_i     (csr_operand),
        .rdata_o       (csr_rdata_o),

        .ext_ints_i    (interrupts_i),
        .trap_i        (trap_o),
        .trap_cause_i  (mcause_o),
        .trap_val_i    (trap_val),
        .epc_i         (trap_epc),
        .mret_i        (mret),

        .mstatus_o     (mstatus),
        .mie_o         (mie),
        .mip_o         (mip),
        .mtvec_o       (mtvec),
        .mepc_o        (mepc_o),

        .commit_i      (commit_i)
    );

    turvo32_privdec privdec_i (
        .instr_valid_i,
        .instr_i,
        .rs1_i,
        .csr_sel_o    (csr_sel),
        .csr_op_o     (csr_op),
        .csr_operand_o(csr_operand),
        .csr_re_o     (csr_re),
        .csr_we_o     (csr_we),
        .ecall_o      (ecall),
        .ebreak_o     (ebreak),
        .mret_o       (mret)
    );

endmodule
