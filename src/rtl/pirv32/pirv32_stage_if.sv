// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_stage_if
    import pirv32_pkg::*;
    import tilelink_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    // Stage control
    output logic ns_valid_o,
    input  logic ns_ready_i,

    output tl_h2d_t ibus_o,
    input  tl_d2h_t ibus_i
);

endmodule
