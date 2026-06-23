// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_controller
    import pirv32_pkg::*;
(
    // Exception handling
    input  logic        ecall_i,
    input  logic        ebreak_i,
    input  logic        dtim_misaligned_i,
    input  mem_op_e     dtim_op_i,
    input  mtvec_t      mtvec_i,
    output logic [31:0] pc_exc_o,
    output logic        is_exception_o,
    output exc_cause_e  csr_cause_o
);

    logic        dtim_store;
    logic        is_interrupt;
    logic [31:0] vectored_exc_pc;

    assign is_interrupt = '0;

    assign is_exception_o = ecall_i | ebreak_i | dtim_misaligned_i;
    assign dtim_store = dtim_op_i == SB || dtim_op_i == SH || dtim_op_i == SW;
    assign vectored_exc_pc = {mtvec_i.base, 2'b00} + {csr_cause_o, 2'b00};
    assign pc_exc_o = mtvec_i.mode & is_interrupt
                      ? vectored_exc_pc : {mtvec_i.base, 2'b00};

    always_comb begin
        priority case (1'b1)
            ecall_i: csr_cause_o = ECALL_MMODE;
            ebreak_i: csr_cause_o = BREAKPOINT;
            dtim_misaligned_i && dtim_store: begin
                csr_cause_o = STORE_ADDR_MISALIGNED;
            end
            dtim_misaligned_i && ~dtim_store: begin
                csr_cause_o = LOAD_ADDR_MISALIGNED;
            end
            default: ;
        endcase
    end

endmodule
