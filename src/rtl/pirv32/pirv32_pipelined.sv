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

    /////////////////////////
    //                     //
    // Stage Instantiation //
    //                     //
    /////////////////////////

    pirv32_stage_if if_stage_i (
        .clk_i,
        .rst_ni,

        .ns_ready_i(id_stage_ready),
        .ns_valid_o(if_stage_valid),

        .ibus_o,
        .ibus_i
    );

    pirv32_stage_id id_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(if_stage_valid),
        .ps_ready_o(id_stage_ready),
        .ns_valid_o(id_stage_valid),
        .ns_ready_i(ex_stage_ready)
    );

    pirv32_stage_ex ex_stage_i (
        .clk_i,
        .rst_ni,

        .ps_valid_i(id_stage_valid),
        .ps_ready_o(ex_stage_ready),
        .ns_valid_o(ex_stage_valid),
        .ns_ready_i(mem_stage_ready)
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
