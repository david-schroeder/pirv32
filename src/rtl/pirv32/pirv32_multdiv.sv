// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_multdiv
    import pirv32_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    input  logic [31:0] rs1_i,
    input  logic [31:0] rs2_i,
    output logic [31:0] result_o,

    input  multdiv_op_e op_i,
    input  logic        is_multdiv_i,
    output logic        div_stall_o
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

    /* Divider */

    logic        div_active;
    logic        div_start;
    logic        div_finish;
    logic        fast_div;
    logic        div_signed;
    logic        quot_sign, rem_sign;
    logic [ 4:0] div_shifts_remaining;
    logic [31:0] numerator;
    logic [31:0] denominator;
    logic [31:0] quotient, quotient_d;
    logic [31:0] remainder, remainder_d;
    logic [31:0] signed_quot, signed_rem;
    logic [31:0] rem_shifted;
    logic        skip_subtraction;

    always_comb begin
        unique case (op_i)
            DIV,
            DIVU,
            REM,
            REMU: div_start = is_multdiv_i;
            default: div_start = '0;
        endcase
    end

    assign div_signed = op_i == DIV || op_i == REM;
    assign numerator = div_signed && rs1_i[31] ? -rs1_i : rs1_i;
    assign denominator = div_signed && rs2_i[31] ? -rs2_i : rs2_i;
    assign rem_shifted = {remainder[30:0], numerator[div_shifts_remaining]};
    assign skip_subtraction = rem_shifted < denominator;
    assign fast_div = numerator[31:16] == '0;
    assign remainder_d = skip_subtraction ? rem_shifted : rem_shifted - denominator;
    assign quotient_d = {quotient[30:0], ~skip_subtraction};
    assign quot_sign = rs1_i[31] ^ rs2_i[31];
    assign rem_sign = rs1_i[31];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            div_active <= '0;
            div_shifts_remaining <= '1; // 31
            quotient <= '0;
            remainder <= '0;
        end else begin
            if (div_start | div_active) begin
                remainder <= remainder_d;
                quotient <= quotient_d;
                div_shifts_remaining <= div_shifts_remaining - 1;
                div_active <= ~div_finish;

                if (fast_div && div_start && !div_active) begin
                    div_shifts_remaining <= 5'd15;
                end
            end
            if (div_finish) begin
                remainder <= '0;
                quotient <= '0;
            end
        end
    end

    assign div_finish = div_shifts_remaining == '0;
    assign div_stall_o = (div_start | div_active) & ~div_finish;
    assign signed_quot = quot_sign ? -quotient_d : quotient_d;
    assign signed_rem = rem_sign ? -remainder_d : remainder_d;

    /* Result mux */
    always_comb begin
        unique case (op_i)
            MUL: result_o = mult_result_full[31:0];
            MULH,
            MULHSU,
            MULHU: result_o = mult_result_full[63:32];
            DIV: result_o = signed_quot;
            DIVU: result_o = quotient_d;
            REM: result_o = signed_rem;
            REMU: result_o = remainder_d;
            default: result_o = '0;
        endcase
    end

endmodule
