// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_decoder
    import pirv32_pkg::*;
(
    input  logic [31:0] instr_i,

    output logic [ 4:0] rs1_adr_o,
    output logic [ 4:0] rs2_adr_o,
    output logic [ 4:0] rd_adr_o,
    output logic        reg_we_o,

    output alu_op_e     alu_op_o,
    output shift_op_e   shift_op_o,
    output mem_op_e     mem_op_o,
    output branch_e     branch_o,

    output logic        is_jump_o,
    output logic        is_branch_o,

    output logic [31:0] imm_o,
    output logic        alu_src1_o,
    output logic        alu_src2_o,

    output wb_src_e     wb_src_o
);

    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    instr_type_e instr_type;

    assign opcode = instr_i[ 6: 0];
    assign funct3 = instr_i[14:12];
    assign funct7 = instr_i[31:25];

    assign rs1_adr_o = instr_i[19:15];
    assign rs2_adr_o = instr_i[24:20];
    assign rd_adr_o  = instr_i[11:7];

    assign is_jump_o = opcode == 7'b1101111 || opcode == 7'b1100111;
    assign is_branch_o = opcode == 7'b1100011;

    always_comb begin
        unique casez ({opcode, funct3})
            {7'b0000011, 3'b000}: mem_op_o = LB;
            {7'b0000011, 3'b001}: mem_op_o = LH;
            {7'b0000011, 3'b010}: mem_op_o = LW;
            {7'b0000011, 3'b100}: mem_op_o = LBU;
            {7'b0000011, 3'b101}: mem_op_o = LHU;
            {7'b0100011, 3'b000}: mem_op_o = SB;
            {7'b0100011, 3'b001}: mem_op_o = SH;
            {7'b0100011, 3'b010}: mem_op_o = SW;
            default: mem_op_o = LB; // No side effects + no misaligned access
        endcase

        unique casez ({instr_i[30], funct3})
            {1'b?, 3'b001}: shift_op_o = SLL;
            {1'b0, 3'b101}: shift_op_o = SRL;
            default: shift_op_o = SRA;
        endcase

        unique casez ({opcode, funct3})
            {7'b0110011, 3'b000}: alu_op_o = instr_i[30] ? SUB : ADD;
            {7'b0?10011, 3'b010}: alu_op_o = SLT;
            {7'b0?10011, 3'b011}: alu_op_o = SLTU;
            {7'b0?10011, 3'b100}: alu_op_o = XOR;
            {7'b0?10011, 3'b110}: alu_op_o = OR;
            {7'b0?10011, 3'b111}: alu_op_o = AND;
            {7'b1100011, 3'b???}: alu_op_o = SUB;
            default: alu_op_o = ADD;
        endcase

        unique casez (opcode)
            7'b0000011: reg_we_o = '1; // Loads
            7'b0?10?11: reg_we_o = '1; // Arithmetic operations, U-type instrs
            7'b110?111: reg_we_o = '1; // JAL, JALR
            default: reg_we_o = '0;
        endcase

        unique casez (opcode)
            7'b0?10111: instr_type = U_TYPE;
            7'b1101111: instr_type = J_TYPE;
            7'b1100011: instr_type = B_TYPE;
            7'b0100011: instr_type = S_TYPE;
            7'b1100111, // JALR
            7'b00?0011: instr_type = I_TYPE;
            default: instr_type = R_TYPE;
        endcase

        unique case (opcode)
            7'b0010111: alu_src1_o = '1;
            7'b1101111: alu_src1_o = '1;
            default: alu_src1_o = '0;
        endcase

        unique case (instr_type)
            I_TYPE,
            S_TYPE,
            U_TYPE,
            J_TYPE: alu_src2_o = '1;
            default: alu_src2_o = '0;
        endcase

        unique case (instr_type)
            S_TYPE: imm_o = {{21{instr_i[31]}}, instr_i[30:25], instr_i[11:7]};
            U_TYPE: imm_o = {instr_i[31:12], 12'h0};
            J_TYPE: imm_o = {{12{instr_i[31]}}, instr_i[19:12], instr_i[20],
                            instr_i[30:21], 1'b0};
            B_TYPE: imm_o = {{20{instr_i[31]}}, instr_i[7], instr_i[30:25],
                            instr_i[11:8], 1'b0};
            default: imm_o = {{21{instr_i[31]}}, instr_i[30:20]};
        endcase

        unique casez ({opcode, funct3})
            {7'b0?00011, 3'b???}: wb_src_o = DTIM;
            {7'b0?10011, 3'b?01}: wb_src_o = SHIFTER;
            {7'b1101111, 3'b???},
            {7'b1100111, 3'b000}: wb_src_o = SEQ_PC;
            default: wb_src_o = ALU;
        endcase

        unique case (funct3)
            3'b001: branch_o = BNE;
            3'b100: branch_o = BLT;
            3'b101: branch_o = BGE;
            3'b110: branch_o = BLTU;
            3'b111: branch_o = BGEU;
            default: branch_o = BEQ;
        endcase

    end

endmodule
