// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_core
    import pirv32_pkg::*;
#(
    parameter logic [31:0] BOOT_ADDR = 32'h00000080
) (
    input  logic clk_i,
    input  logic rst_ni,

    input  logic [31:0] interrupts_i,
    output logic [31:0] rs1_o
);

    // IF stage

    logic [31:0] pc;
    logic [31:0] pc_seq;
    logic [31:0] pc_jump;
    logic [31:0] pc_trap;
    logic [31:0] pc_d_arch; // Architectural next PC
    logic [31:0] pc_d;
    logic [31:0] instr;
    logic        is_first_cycle;
    logic        stall;

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
    alu_op_e     alu_op;
    shift_op_e   shift_op;
    branch_e     branch_type;
    multdiv_op_e multdiv_op;
    logic        is_jump;
    logic        is_branch;
    logic        is_ecall;
    logic        is_ebreak;
    logic        is_mret;
    logic        is_multdiv;

    assign rs1_o = rs1;
    assign csr_operand = csr_op_src ? {27'h0, ra1} : rs1;

    // CSR readouts
    mstatus_t    mstatus;
    logic [31:0] mie;
    logic [31:0] mip;
    mtvec_t      mtvec;
    logic [31:0] mepc;

    // ALU + ex stage
    logic [31:0] alu_a;
    logic [31:0] alu_b;
    alu_src1_e   alu_src1;
    alu_src2_e   alu_src2;
    logic        branch_decision;
    logic        div_stall;

    assign stall = is_first_cycle | div_stall;

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
    logic [31:0] multdiv_res;
    logic        csr_write_en;
    logic        commit;

    // Traps
    logic        trap;
    mcause_t     trap_cause;
    logic [31:0] trap_val;
    logic [31:0] trap_epc;
    logic        exception;
    assign exception = trap && !trap_cause.interrupt;

    assign commit = ~exception & ~stall;

    // -> WB pipeline stage

    logic [31:0] alu_res_q;
    logic [31:0] shiftout_q;
    // load_data is already buffered
    logic [31:0] pc_seq_q;
    logic [31:0] csr_rdata_q;
    logic [31:0] multdiv_res_q;
    logic        wb_we_q;
    logic [ 4:0] rd_q;
    wb_src_e     wb_src_q;
    
    // Forwarding logic
    logic        fw_rs1_from_wb;
    logic        fw_rs2_from_wb;
    logic [31:0] rs1_fw;
    logic [31:0] rs2_fw;

    assign fw_rs1_from_wb = ra1 == rd_q && wb_we_q && ra1 != '0;
    assign fw_rs2_from_wb = ra2 == rd_q && wb_we_q && ra2 != '0;

    always_comb begin
        priority case (1'b1)
            fw_rs1_from_wb: rs1_fw = wb_data;
            default       : rs1_fw = rs1;
        endcase

        priority case (1'b1)
            fw_rs2_from_wb: rs2_fw = wb_data;
            default       : rs2_fw = rs2;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            alu_res_q     <= '0;
            shiftout_q    <= '0;
            pc_seq_q      <= '0;
            csr_rdata_q   <= '0;
            multdiv_res_q <= '0;
            wb_we_q       <= '0;
            rd_q          <= '0;
            wb_src_q      <= ALU;
        end else begin
            alu_res_q     <= alu_res;
            shiftout_q    <= shiftout;
            pc_seq_q      <= pc_seq;
            csr_rdata_q   <= csr_rdata;
            multdiv_res_q <= multdiv_res;
            wb_we_q       <= wb_we & commit;
            rd_q          <= rd;
            wb_src_q      <= wb_src;
        end
    end

    always_comb begin
        unique case (wb_src_q)
            SHIFTER: wb_data = shiftout_q;
            DTIM   : wb_data = load_data; // buffering in DTIM
            SEQ_PC : wb_data = pc_seq_q;
            CSR    : wb_data = csr_rdata_q;
            MULTDIV: wb_data = multdiv_res_q;
            default: wb_data = alu_res_q;
        endcase

        unique case (alu_src1)
            RS1 : alu_a = rs1_fw;
            PC  : alu_a = pc;
            ZERO: alu_a = '0;
        endcase

        unique case (alu_src2)
            RS2: alu_b = rs2_fw;
            IMM: alu_b = imm;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            pc <= BOOT_ADDR;
            is_first_cycle <= '1;
        end else begin
            pc <= pc_d;
            is_first_cycle <= '0;
        end
    end

    assign pc_jump = {alu_res[31:1], 1'b0};

    always_comb begin
        unique case (1'b1)
            is_jump: pc_d_arch = pc_jump;
            is_branch && branch_decision: pc_d_arch = pc + imm;
            is_mret: pc_d_arch = mepc;
            default: pc_d_arch = pc_seq;
        endcase

        if (stall) pc_d_arch = pc;
    end

    assign pc_d = trap ? pc_trap : pc_d_arch;

    pirv32_itim #(
        .LOG_SIZE(15)
    ) itim_i (
        .clk_i,
        .rst_ni,
        .address_i(pc_d),
        .instr_o  (instr)
    );

    pirv32_decoder decoder_i (
        .instr_i     (instr),

        .rs1_adr_o   (ra1),
        .rs2_adr_o   (ra2),
        .rd_adr_o    (rd),
        .reg_we_o    (wb_we),

        .alu_op_o    (alu_op),
        .shift_op_o  (shift_op),
        .mem_op_o    (dtim_op),
        .branch_o    (branch_type),
        .multdiv_op_o(multdiv_op),

        .csr_sel_o   (csr_sel),
        .csr_op_o    (csr_op),
        .csr_we_o    (csr_write_en),
        .csr_re_o    (csr_read_en),
        .csr_opsrc_o (csr_op_src),

        .is_jump_o   (is_jump),
        .is_branch_o (is_branch),
        .is_ecall_o  (is_ecall),
        .is_ebreak_o (is_ebreak),
        .is_mret_o   (is_mret),
        .is_multdiv_o(is_multdiv),

        .imm_o       (imm),
        .alu_src1_o  (alu_src1),
        .alu_src2_o  (alu_src2),
        .wb_src_o    (wb_src)
    );

    pirv32_trap trap_i (
        .ext_ints_i       (interrupts_i),
        .pc_i             (pc),
        .next_arch_pc_i   (pc_d_arch),
        .stall_i          (stall),
        .mstatus_i        (mstatus),
        .mie_i            (mie),
        .mip_i            (mip),
        .mtvec_i          (mtvec),
        .ecall_i          (is_ecall),
        .ebreak_i         (is_ebreak),
        .dtim_misaligned_i(dtim_misaligned),
        .dtim_op_i        (dtim_op),
        .dtim_addr_i      (alu_res),
        .trap_o           (trap),
        .cause_o          (trap_cause),
        .trap_pc_o        (pc_trap),
        .trap_val_o       (trap_val),
        .epc_o            (trap_epc)
    );

    pirv32_regfile regfile_i (
        .clk_i,
        .raddr1_i(ra1),
        .rdata1_o(rs1),
        .raddr2_i(ra2),
        .rdata2_o(rs2),
        .waddr_i (rd_q),
        .wen_i   (wb_we_q),
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

        .ext_ints_i    (interrupts_i),
        .trap_i        (trap),
        .trap_cause_i  (trap_cause),
        .trap_val_i    (trap_val),
        .epc_i         (trap_epc),
        .mret_i        (is_mret),

        .mstatus_o     (mstatus),
        .mie_o         (mie),
        .mip_o         (mip),
        .mtvec_o       (mtvec),
        .mepc_o        (mepc),

        .commit_i      (commit)
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

    pirv32_dtim #(
        .LOG_SIZE(15) // 32 KiB
    ) dtim_i (
        .clk_i,
        .rst_ni,
        .data_i      (rs2_fw),
        .address_i   (alu_res),
        .op_i        (dtim_op),
        .data_o      (load_data),
        .misaligned_o(dtim_misaligned)
    );

    pirv32_multdiv multdiv_i (
        .clk_i,
        .rst_ni,
        .rs1_i       (rs1_fw),
        .rs2_i       (rs2_fw),
        .result_o    (multdiv_res),
        .op_i        (multdiv_op),
        .is_multdiv_i(is_multdiv),
        .div_stall_o (div_stall)
    );

endmodule
