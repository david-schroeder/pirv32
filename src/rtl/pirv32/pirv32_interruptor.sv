// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_interruptor
    import pirv32_pkg::*;
(
    input  logic [31:0] ext_interrupts_i,
    input  mstatus_t    mstatus_i,
    input  logic [31:0] mie_i,
    input  logic [31:0] mip_i,
    output logic        is_interrupt_o,
    output logic [ 4:0] interrupt_id_o
);

endmodule
