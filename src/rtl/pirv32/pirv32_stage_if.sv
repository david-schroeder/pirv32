// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_stage_if
    import pirv32_pkg::*;
    import tilelink_pkg::*;
#(
    parameter logic [31:0] BOOT_ADDR      = 32'h00000080,
    parameter logic [31:0] DEBUG_ADDR     = 32'h10000000,
    parameter logic [31:0] DEBUG_EXC_ADDR = 32'h10001000
) (
    input  logic clk_i,
    input  logic rst_ni,

    // Stage control
    output logic ns_valid_o,
    input  logic ns_ready_i,

    output logic [31:0] pc_o,
    output logic [31:0] instr_o,

    output tl_h2d_t ibus_o,
    input  tl_d2h_t ibus_i
);

    logic [31:0] pc_d, pc_q;
    assign pc_d = pc_q + 4;
    assign pc_o = pc_q;

    reg [31:0] instr_mem [8191:0];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            pc_q <= BOOT_ADDR - 4;
            instr_o <= '0;
            ns_valid_o <= '0;
        end else begin
            if (ns_ready_i) begin
                pc_q <= pc_d;
                instr_o <= instr_mem[pc_d];
                ns_valid_o <= '1;
            end
        end
    end

    `define STRINGIFY(x) `"x`"
    initial begin
        $readmemh(`STRINGIFY(`INIT_MEM_FILE), instr_mem);
    end

endmodule
