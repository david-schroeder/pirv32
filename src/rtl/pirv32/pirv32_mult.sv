// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_mult
    import pirv32_pkg::*;
(
    input  logic [31:0] rs1_i,
    input  logic [31:0] rs2_i,
    output logic [63:0] result_o,

    input  mult_op_e    op_i,
    input  logic        is_mult_i
);

    /* Multiplier */

    logic signed [65:0] mult_result_full;
    logic signed [32:0] mult_a, mult_b;

    always_comb begin
        unique case (op_i)
            MULHU: mult_a = {1'b0, rs1_i};
            default: mult_a = {rs1_i[31], rs1_i};
        endcase

        unique case (op_i)
            MULHSU,
            MULHU: mult_b = {1'b0, rs2_i};
            default: mult_b = {rs2_i[31], rs2_i};
        endcase
    end

    assign mult_result_full = mult_a * mult_b;
    assign result_o = mult_result_full[63:0];

endmodule
