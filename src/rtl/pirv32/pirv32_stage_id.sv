// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_stage_id
    import pirv32_pkg::*;
    import tilelink_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    // Stage control
    input  logic ps_valid_i,
    output logic ps_ready_o,
    output logic ns_valid_o,
    input  logic ns_ready_i
);

    //logic stage_ready;
    //assign stage_ready = '1;
    //assign ps_ready_o = ns_ready_i & stage_ready;

endmodule
