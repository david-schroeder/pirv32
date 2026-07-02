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
    input  logic invalidate_i,

    input  logic [31:0] jump_target_i,
    input  logic [31:0] branch_target_i,
    input  logic        is_jump_i,
    input  logic        is_branch_i,
    input  logic        take_branch_i,

    output logic [31:0] pc_o,
    output logic [31:0] instr_o,

    output tl_h2d_t ibus_o,
    input  tl_d2h_t ibus_i
);

    logic [31:0] pc_d, pc_q;
    logic is_taken_branch;
    logic is_first_cycle;


    assign pc_o = pc_q;
    assign is_taken_branch = is_branch_i && take_branch_i;

    always_comb begin
        unique case (1'b1)
            is_first_cycle : pc_d = BOOT_ADDR; // First cycle after boot
            is_jump_i      : pc_d = jump_target_i;
            is_taken_branch: pc_d = branch_target_i;
            default        : pc_d = pc_q + 4;
        endcase
    end

    assign ibus_o = '{
        a_opcode: Get,
        default : '0
    };

    reg [31:0] instr_mem [8191:0];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            pc_q <= BOOT_ADDR;
            instr_o <= '0;
            is_first_cycle <= '1;
        end else begin
            if (ns_ready_i) begin
                pc_q <= pc_d;
                instr_o <= instr_mem[pc_d[31:2]];
                is_first_cycle <= '0;
            end
        end
    end

    assign ns_valid_o = ~is_first_cycle & ~invalidate_i;

    `define STRINGIFY(x) `"x`"
    initial begin
        $readmemh(`STRINGIFY(`INIT_MEM_FILE), instr_mem);
    end

endmodule
