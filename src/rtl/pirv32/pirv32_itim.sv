// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

// Unpipelined (asynchronous) Instruction Tightly Integrated Memory.

module pirv32_itim
    import pirv32_pkg::*;
#(
    parameter int LOG_SIZE = 10 // 1KiB
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  logic [LOG_SIZE-1:0] address_i,
    output logic [31:0] instr_o
);

    reg [31:0] mem [2**(LOG_SIZE-2)-1:0];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) instr_o <= '0;
        else instr_o <= mem[address_i[LOG_SIZE-1:2]];
    end

    `define STRINGIFY(x) `"x`"
    initial begin
        $readmemh(`STRINGIFY(`INIT_MEM_FILE), mem);
    end

endmodule
