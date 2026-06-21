// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_regfile
    import pirv32_pkg::*;
(
    input  logic clk_i,

    // read port 1
    input  logic [ 4:0] raddr1_i,
    output logic [31:0] rdata1_o,
    // read port 2
    input  logic [ 4:0] raddr2_i,
    output logic [31:0] rdata2_o,
    // write port
    input  logic [ 4:0] waddr_i,
    input  logic        wen_i,
    input  logic [31:0] wdata_i
);

    reg [31:0] mem [31:0];

    always_ff @(posedge clk_i) begin
        if (wen_i) begin
            mem[waddr_i] <= wdata_i;
        end
    end

    assign rdata1_o = raddr1_i == '0 ? '0 : mem[raddr1_i];
    assign rdata2_o = raddr2_i == '0 ? '0 : mem[raddr2_i];

endmodule
