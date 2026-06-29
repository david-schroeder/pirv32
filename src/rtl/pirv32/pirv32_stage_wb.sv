// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_stage_wb
    import pirv32_pkg::*;
    import tilelink_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    // Stage control
    input  logic ps_valid_i,
    output logic ps_ready_o,

    input  tl_d2h_t dbus_i
);

    assign ps_ready_o = '1;

endmodule
