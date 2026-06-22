// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_core
    import pirv32_pkg::*;
#(
    parameter logic [31:0] BOOT_ADDR = 32'h00000080
) (
    input  logic clk_i,
    input  logic rst_ni,

    output logic [31:0] rs1_o
);

    logic [31:0] pc;
    logic [31:0] pc_seq;
    logic [31:0] pc_jump;
    logic [31:0] pc_d;
    logic [31:0] instr;

    assign pc_seq = pc + 4;

    logic [ 4:0] ra1;
    logic [ 4:0] ra2;
    logic [ 4:0] rd;
    logic [31:0] rs1;
    logic [31:0] rs2;
    logic [31:0] imm;

    assign rs1_o = rs1;

    logic [31:0] alu_a;
    logic [31:0] alu_b;
    logic        alu_src1;
    logic        alu_src2;
    alu_op_e     alu_op;
    shift_op_e   shift_op;
    logic        is_jump;
    logic        is_branch;
    branch_e     branch_type;
    logic        branch_decision;
    assign alu_a = alu_src1 ? pc : rs1;
    assign alu_b = alu_src2 ? imm : rs2;

    // DTIM
    mem_op_e dtim_op;
    logic    dtim_misaligned;

    // Writeback
    logic [31:0] wb_data;
    logic        wb_we;
    wb_src_e     wb_src;
    logic [31:0] alu_res;
    logic [31:0] shiftout;
    logic [31:0] load_data;

    always_comb begin
        unique case (wb_src)
            SHIFTER: wb_data = shiftout;
            DTIM   : wb_data = load_data;
            SEQ_PC : wb_data = pc_seq;
            default: wb_data = alu_res;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            pc <= BOOT_ADDR;
        end else begin
            pc <= pc_d;
        end
    end

    assign pc_jump = {alu_res[31:1], 1'b0};

    always_comb begin
        pc_d = pc_seq;
        if (is_jump || is_branch && branch_decision) begin
            pc_d = pc_jump;
        end
    end

    pirv32_itim #(
        .LOG_SIZE(12)
    ) itim_i (
        .address_i(pc),
        .instr_o  (instr)
    );

    pirv32_decoder decoder_i (
        .instr_i    (instr),
        .rs1_adr_o  (ra1),
        .rs2_adr_o  (ra2),
        .rd_adr_o   (rd),
        .reg_we_o   (wb_we),
        .alu_op_o   (alu_op),
        .shift_op_o (shift_op),
        .mem_op_o   (dtim_op),
        .branch_o   (branch_type),
        .is_jump_o  (is_jump),
        .is_branch_o(is_branch),
        .imm_o      (imm),
        .alu_src1_o (alu_src1),
        .alu_src2_o (alu_src2),
        .wb_src_o   (wb_src)
    );

    pirv32_regfile regfile_i (
        .clk_i,
        .raddr1_i(ra1),
        .rdata1_o(rs1),
        .raddr2_i(ra2),
        .rdata2_o(rs2),
        .waddr_i (rd),
        .wen_i   (wb_we),
        .wdata_i (wb_data)
    );

    pirv32_alu alu_i (
        .a_i          (alu_a),
        .b_i          (alu_b),
        .op_i         (alu_op),
        .res_o        (alu_res),
        .branch_i     (branch_type),
        .take_branch_o(branch_decision)
    );

    pirv32_shifter shifter_i (
        .data_i (alu_a),
        .shamt_i(alu_b),
        .op_i   (shift_op),
        .data_o (shiftout)
    );

    pirv32_dtim dtim_i (
        .clk_i,
        .data_i      (rs2),
        .address_i   (alu_res),
        .op_i        (dtim_op),
        .data_o      (load_data),
        .misaligned_o(dtim_misaligned)
    );

endmodule
