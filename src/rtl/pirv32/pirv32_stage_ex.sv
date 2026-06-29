// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_stage_ex
    import pirv32_pkg::*;
    import tilelink_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    // Stage control
    input  logic ps_valid_i,
    output logic ps_ready_o,
    output logic ns_valid_o,
    input  logic ns_ready_i,

    // ID stage inputs
    input  logic [31:0] pc_i,
    input  logic [31:0] rs1_i,
    input  logic [31:0] rs2_i,
    input  logic [31:0] imm_i,
    input  alu_src1_e   alu_src1_i,
    input  alu_src2_e   alu_src2_i,
    input  alu_op_e     alu_op_i,
    input  shift_op_e   shift_op_i,
    input  branch_e     branch_i,
    input  multdiv_op_e multdiv_op_i,
    input  logic        is_multdiv_i
);

    logic stage_ready;
    assign ps_ready_o = ns_ready_i & stage_ready;

    /////////////
    //         //
    // Signals //
    //         //
    /////////////

    logic [31:0] operand_a, operand_b;
    logic        div_stall;

    ////////////////////
    //                //
    // ID <-> EX Regs //
    //                //
    ////////////////////

    logic        valid_ex;
    logic [31:0] pc_ex;
    logic [31:0] rs1_ex, rs2_ex;
    logic [31:0] imm_ex;
    alu_src1_e   alu_src1_ex;
    alu_src2_e   alu_src2_ex;
    alu_op_e     alu_op_ex;
    shift_op_e   shift_op_ex;
    branch_e     branch_type_ex;
    multdiv_op_e multdiv_op_ex;
    logic        is_multdiv_ex;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            valid_ex       <= '0;
            pc_ex          <= '0;
            rs1_ex         <= '0;
            rs2_ex         <= '0;
            imm_ex         <= '0;
            alu_src1_ex    <= RS1;
            alu_src2_ex    <= RS2;
            alu_op_ex      <= ADD;
            shift_op_ex    <= SLL;
            branch_type_ex <= BEQ;
            multdiv_op_ex  <= MUL;
            is_multdiv_ex  <= '0;
        end else begin
            if (ns_ready_i) begin
                valid_ex       <= ps_valid_i;
                pc_ex          <= pc_i;
                rs1_ex         <= rs1_i;
                rs2_ex         <= rs2_i;
                imm_ex         <= imm_i;
                alu_src1_ex    <= alu_src1_i;
                alu_src2_ex    <= alu_src2_i;
                alu_op_ex      <= alu_op_i;
                shift_op_ex    <= shift_op_i;
                branch_type_ex <= branch_i;
                multdiv_op_ex  <= multdiv_op_i;
                is_multdiv_ex  <= is_multdiv_i;
            end
        end
    end

    assign ns_valid_o = valid_ex;

    /////////////////
    //             //
    // Stage Logic //
    //             //
    /////////////////

    always_comb begin
        unique case (alu_src1_ex)
            RS1 : operand_a = rs1_ex;
            PC  : operand_a = pc_ex;
            ZERO: operand_a = '0;
        endcase

        unique case (alu_src2_ex)
            RS2: operand_b = rs2_ex;
            IMM: operand_b = imm_ex;
        endcase
    end

    assign stage_ready = ~div_stall;

    ///////////////////
    //               //
    // Instantiation //
    //               //
    ///////////////////

    pirv32_alu alu_i (
        .a_i          (operand_a),
        .b_i          (operand_b),
        .op_i         (alu_op_ex),
        .res_o        (),
        .branch_i     (branch_type_ex),
        .take_branch_o()
    );

    pirv32_shifter shifter_i (
        .data_i (operand_a),
        .shamt_i(operand_b),
        .op_i   (shift_op_ex),
        .data_o ()
    );

    pirv32_multdiv multdiv_i (
        .clk_i,
        .rst_ni,

        .rs1_i       (rs1_ex),
        .rs2_i       (rs2_ex),
        .result_o    (),
        .op_i        (multdiv_op_ex),
        .is_multdiv_i(is_multdiv_ex),
        .div_stall_o (div_stall)
    );

endmodule
