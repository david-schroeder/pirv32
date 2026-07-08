// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

// Privileged instruction decoder

module pirv32_privdec
    import pirv32_pkg::*;
(
    input  logic        instr_valid_i,
    input  logic [31:0] instr_i,
    input  logic [31:0] rs1_i,
    output csr_e        csr_sel_o,
    output csr_op_e     csr_op_o,
    output logic [31:0] csr_operand_o,
    output logic        csr_re_o,
    output logic        csr_we_o,
    output logic        ecall_o,
    output logic        ebreak_o,
    output logic        mret_o
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    logic [4:0] ra1;
    logic [4:0] rd;
    logic       is_system;
    logic       is_csr_op;

    // Instruction fields
    assign opcode = instr_i[ 6: 0];
    assign rd     = instr_i[11: 7];
    assign funct3 = instr_i[14:12];
    assign ra1    = instr_i[19:15];
    assign funct7 = instr_i[31:25];

    // Instruction decoding
    assign is_system = opcode == 7'h73;
    assign ecall_o  = instr_valid_i && instr_i == 32'h00000073;
    assign ebreak_o = instr_valid_i && instr_i == 32'h00100073;
    assign mret_o   = instr_valid_i && instr_i == 32'h30200073;

    // CSR control signals
    assign is_csr_op     = is_system && funct3 != 3'b000 && instr_valid_i;
    assign csr_sel_o     = csr_e'(instr_i[31:20]);
    assign csr_re_o      = is_csr_op && (csr_op_o != CSRRW || rd != '0);
    assign csr_we_o      = is_csr_op && (csr_op_o == CSRRW || ra1 != '0);
    assign csr_operand_o = instr_i[14] ? {27'h0, ra1} : rs1_i;

    always_comb begin
        unique case (funct3[1:0])
            2'b10: csr_op_o = CSRRS;
            2'b11: csr_op_o = CSRRC;
            default: csr_op_o = CSRRW;
        endcase
    end

endmodule
