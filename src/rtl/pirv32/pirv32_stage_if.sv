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

    input  logic [31:0] jump_tgt_i,
    input  logic        do_jump_i,

    output logic [31:0] pc_o,
    output logic [31:0] pc_seq_o,
    output logic [31:0] instr_o,

    output tl_h2d_t ibus_o,
    input  tl_d2h_t ibus_i
);

    /////////////
    //         //
    // Signals //
    //         //
    /////////////

    logic [31:0] pc_d, pc_if;
    logic [31:0] pc_seq;
    logic        is_first_cycle;

    reg   [31:0] instr_mem [8191:0];
    logic [31:0] instr_if;

    /////////////
    //         //
    // IF Regs //
    //         //
    /////////////

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            pc_if          <= BOOT_ADDR;
            instr_if       <= '0;
            is_first_cycle <= '1;
        end else begin
            if (ns_ready_i) begin
                pc_if          <= pc_d;
                instr_if       <= instr_mem[pc_d[31:2]];
                is_first_cycle <= '0;
            end
        end
    end

    /////////////////
    //             //
    // Stage Logic //
    //             //
    /////////////////

    assign ns_valid_o = ~is_first_cycle & ~invalidate_i;

    assign pc_seq   = pc_if + 4;
    assign pc_seq_o = pc_seq;
    assign pc_o     = pc_if;
    assign instr_o  = instr_if;

    always_comb begin
        unique case (1'b1)
            is_first_cycle : pc_d = BOOT_ADDR; // First cycle after boot
            do_jump_i      : pc_d = jump_tgt_i;
            default        : pc_d = pc_seq;
        endcase
    end

    // TODO: replace with bus-based instruction fetch system
    assign ibus_o = '{
        a_opcode: Get,
        default : '0
    };

    `define STRINGIFY(x) `"x`"
    initial begin
        $readmemh(`STRINGIFY(`INIT_MEM_FILE), instr_mem);
    end

endmodule
