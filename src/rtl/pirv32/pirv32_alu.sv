// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_alu
    import pirv32_pkg::*;
(
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  alu_op_e     op_i,
    output logic [31:0] res_o,
    output logic        lt_o,
    output logic        ltu_o,
    output logic        zero_o
);

    assign lt_o  = $signed(a_i) < $signed(b_i);
    assign ltu_o = a_i < b_i;

    always_comb begin
        unique case (op_i)
            ADD : res_o = a_i + b_i;
            SUB : res_o = a_i - b_i;
            XOR : res_o = a_i ^ b_i;
            OR  : res_o = a_i | b_i;
            AND : res_o = a_i & b_i;
            SLT : res_o = {31'h0, lt_o};
            SLTU: res_o = {31'h0, ltu_o};
        endcase
    end

    assign zero_o = res_o == '0;

endmodule
