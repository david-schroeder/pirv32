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

    // IF stage

    logic [31:0] pc;
    logic [31:0] pc_seq;
    logic [31:0] pc_jump;
    logic [31:0] pc_exc;
    logic [31:0] pc_d;
    logic [31:0] instr;

    assign pc_seq = pc + 4;

    // ID stage

    logic [ 4:0] ra1;
    logic [ 4:0] ra2;
    logic [ 4:0] rd;
    logic [31:0] rs1;
    logic [31:0] rs2;
    logic [31:0] imm;
    logic        csr_read_en;
    csr_e        csr_sel;
    csr_op_e     csr_op;
    logic        csr_op_src;
    logic [31:0] csr_operand;
    logic [31:0] csr_rdata;
    mtvec_t      mtvec;
    logic [31:0] mepc;
    alu_op_e     alu_op;
    shift_op_e   shift_op;
    logic        is_jump;
    logic        is_branch;
    logic        is_ecall;
    logic        is_ebreak;
    logic        is_mret;
    branch_e     branch_type;

    assign rs1_o = rs1;
    assign csr_operand = csr_op_src ? {27'h0, ra1} : rs1;

    // ALU + ex stage
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    alu_src1_e   alu_src1;
    alu_src2_e   alu_src2;
    logic        branch_decision;

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
    logic        csr_write_en;

    // Exceptions
    logic        is_exception;
    exc_cause_e  exc_cause;

    always_comb begin
        unique case (wb_src)
            SHIFTER: wb_data = shiftout;
            DTIM   : wb_data = load_data;
            SEQ_PC : wb_data = pc_seq;
            CSR    : wb_data = csr_rdata;
            default: wb_data = alu_res;
        endcase

        unique case (alu_src1)
            RS1 : alu_a = rs1;
            PC  : alu_a = pc;
            ZERO: alu_a = '0;
        endcase

        unique case (alu_src2)
            RS2: alu_b = rs2;
            IMM: alu_b = imm;
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
        if (is_jump) begin
            pc_d = pc_jump;
        end
        if (is_branch && branch_decision) begin
            pc_d = pc + imm;
        end
        if (is_mret) begin
            pc_d = mepc;
        end
        if (is_exception) begin
            pc_d = pc_exc;
        end
    end

    pirv32_itim #(
        .LOG_SIZE(14)
    ) itim_i (
        .clk_i,
        .rst_ni,
        .address_i(pc_d),
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
        .csr_sel_o  (csr_sel),
        .csr_op_o   (csr_op),
        .csr_we_o   (csr_write_en),
        .csr_re_o   (csr_read_en),
        .csr_opsrc_o(csr_op_src),
        .is_jump_o  (is_jump),
        .is_branch_o(is_branch),
        .is_ecall_o (is_ecall),
        .is_ebreak_o(is_ebreak),
        .is_mret_o  (is_mret),
        .imm_o      (imm),
        .alu_src1_o (alu_src1),
        .alu_src2_o (alu_src2),
        .wb_src_o   (wb_src)
    );

    pirv32_controller controller_i (
        .ecall_i          (is_ecall),
        .ebreak_i         (is_ebreak),
        .dtim_misaligned_i(dtim_misaligned),
        .dtim_op_i        (dtim_op),
        .mtvec_i          (mtvec),
        .pc_exc_o         (pc_exc),
        .is_exception_o   (is_exception),
        .csr_cause_o      (exc_cause)
    );

    pirv32_regfile regfile_i (
        .clk_i,
        .raddr1_i(ra1),
        .rdata1_o(rs1),
        .raddr2_i(ra2),
        .rdata2_o(rs2),
        .waddr_i (rd),
        .wen_i   (wb_we & !is_exception),
        .wdata_i (wb_data)
    );

    pirv32_csrs csrfile_i (
        .clk_i,
        .rst_ni,
        .read_en_i     (csr_read_en),
        .write_en_i    (csr_write_en),
        .csr_sel_i     (csr_sel),
        .op_i          (csr_op),
        .operand_i     (csr_operand),
        .rdata_o       (csr_rdata),

        .exc_save_i    (is_exception),
        .exc_cause_i   (exc_cause),
        .pc_i          (pc),
        .next_pc_i     (pc_d),
        .dtim_addr_i   (alu_res),
        .interrupt_i   ('0),
        .interrupt_id_i('0),
        .mret_i        (is_mret),
        .mtvec_o       (mtvec),
        .mepc_o        (mepc)
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
