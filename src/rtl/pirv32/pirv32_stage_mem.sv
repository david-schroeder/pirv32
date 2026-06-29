// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_stage_mem
    import pirv32_pkg::*;
    import tilelink_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    // Stage control
    input  logic ps_valid_i,
    output logic ps_ready_o,
    output logic ns_valid_o,
    input  logic ns_ready_i,

    // EX stage inputs
    input  logic [ 4:0] rd_i,
    input  logic        reg_we_i,
    input  wb_src_e     wb_src_i,
    input  logic [31:0] ex_result_i,

    // WB stage outputs
    output logic [ 4:0] rd_o,
    output logic        reg_we_o,
    output wb_src_e     wb_src_o,
    output logic [31:0] reg_wdata_o,

    // Forwarding outputs
    output logic        fw_valid_o,
    output logic [ 4:0] fw_rd_o,
    output logic [31:0] fw_data_o,

    // Data bus
    output tl_h2d_t dbus_o,
    input  tl_d2h_t dbus_i
);

    logic stage_ready;
    assign stage_ready = '1;
    assign ps_ready_o = ns_ready_i & stage_ready;

    /////////////
    //         //
    // Signals //
    //         //
    /////////////

    /////////////////////
    //                 //
    // EX <-> MEM Regs //
    //                 //
    /////////////////////

    logic        valid_mem;
    logic [ 4:0] rd_mem;
    logic        reg_we_mem;
    wb_src_e     wb_src_mem;
    logic [31:0] ex_result_mem;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            valid_mem     <= '0;
            rd_mem        <= '0;
            reg_we_mem    <= '0;
            wb_src_mem    <= ALU;
            ex_result_mem <= '0;
        end else begin
            if (ns_ready_i) begin
                valid_mem     <= ps_valid_i;
                rd_mem        <= rd_i;
                reg_we_mem    <= reg_we_i;
                wb_src_mem    <= wb_src_i;
                ex_result_mem <= ex_result_i;
            end
        end
    end

    assign ns_valid_o = valid_mem;

    /////////////////
    //             //
    // Stage Logic //
    //             //
    /////////////////

    assign rd_o        = rd_mem;
    assign reg_we_o    = reg_we_mem;
    assign wb_src_o    = wb_src_mem;
    assign reg_wdata_o = ex_result_mem;
    assign dbus_o      = '{
        a_opcode: Get,
        a_address: reg_wdata_o,
        default: '0
    };

    assign fw_valid_o  = rd_mem != '0 && reg_we_mem && valid_mem;
    assign fw_rd_o     = rd_mem;
    assign fw_data_o   = ex_result_mem;

endmodule
