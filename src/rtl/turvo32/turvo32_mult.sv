// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module turvo32_mult
    import turvo32_pkg::*;
(
    input  logic        clk_i,
    input  logic        rst_ni,

    input  logic [31:0] rs1_i,
    input  logic [31:0] rs2_i,
    input  logic        ce_mem_i,
    input  logic        ce_wb_i,
    input  mult_op_e    op_i,
    output logic [31:0] result_o
);

    /* Multiplier */

    logic signed [65:0] mult_result_full;
    logic signed [32:0] mult_a, mult_b;
    logic signed [32:0] a_mux, b_mux;

    mult_op_e op_mem;

    always_comb begin
        unique case (op_i)
            MULHU: a_mux = $signed({1'b0, rs1_i});
            default: a_mux = $signed({rs1_i[31], rs1_i});
        endcase

        unique case (op_i)
            MULHSU,
            MULHU: b_mux = $signed({1'b0, rs2_i});
            default: b_mux = $signed({rs2_i[31], rs2_i});
        endcase
    end

    assign mult_result_full = mult_a * mult_b;

    always_ff @(posedge clk_i) begin
        if (~rst_ni) begin
            mult_a <= '0;
            mult_b <= '0;
            op_mem <= MUL;
            result_o <= '0;
        end else begin
            if (ce_mem_i) begin
                mult_a <= a_mux;
                mult_b <= b_mux;
                op_mem <= op_i;
            end
            if (ce_wb_i) begin
                unique case (op_mem)
                    MUL: result_o <= mult_result_full[31:0];
                    MULH,
                    MULHSU,
                    MULHU: result_o <= mult_result_full[63:32];
                    default: result_o <= '0;
                endcase
            end
        end
    end

endmodule
