// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_trap
    import pirv32_pkg::*;
(
    // External interrupt source
    input  logic [31:0] ext_ints_i,

    input  logic [31:0] pc_i,
    input  logic [31:0] next_arch_pc_i,
    input  logic        stall_i,

    // CSR sources
    input  mstatus_t    mstatus_i,
    input  logic [31:0] mie_i,
    input  logic [31:0] mip_i,
    input  mtvec_t      mtvec_i,

    // Exception causes
    input  logic        ecall_i,
    input  logic        ebreak_i,
    input  logic        mem_misaligned_i,
    input  mem_op_e     mem_op_i,
    input  logic [31:0] mem_addr_i,

    // Output
    output logic        trap_o,
    output mcause_t     cause_o,
    output logic [31:0] trap_pc_o,
    output logic [31:0] trap_val_o,
    output logic [31:0] epc_o
);

    logic [31:0] pending_ints;
    logic [31:0] valid_ints;
    logic        interrupt;
    assign pending_ints = mip_i | ext_ints_i;
    assign valid_ints   = mie_i & pending_ints & {32{mstatus_i.mie}};
    assign interrupt    = ~stall_i & |valid_ints;

    logic exception;
    assign exception = ecall_i | ebreak_i | mem_misaligned_i;

    assign trap_o = interrupt | exception;

    always_comb begin
        cause_o = '{interrupt: interrupt & ~exception, cause: exc_cause_e'('0)};
        trap_val_o = '0;
        epc_o = next_arch_pc_i;

        if (interrupt) begin
            for (int i = 0; i < 32; i++) begin
                if (valid_ints[i]) cause_o.cause = exc_cause_e'(i);
            end
        end

        trap_pc_o = mtvec_i.mode && !exception
                    ? {mtvec_i.base + 5'(cause_o.cause), 2'b00}
                    : {mtvec_i.base, 2'b00};

        if (exception) begin
            priority case (1'b1)
                ecall_i: cause_o.cause = ECALL_MMODE;
                ebreak_i: cause_o.cause = BREAKPOINT;
                mem_misaligned_i: begin
                    unique case (mem_op_i)
                        SB,
                        SH,
                        SW: cause_o.cause = STORE_ADDR_MISALIGNED;
                        default: cause_o.cause = LOAD_ADDR_MISALIGNED;
                    endcase

                    trap_val_o = mem_addr_i;
                end
            endcase

            epc_o = pc_i;
        end

    end

endmodule
