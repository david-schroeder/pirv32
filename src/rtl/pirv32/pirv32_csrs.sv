// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

// RISC-V Control and Status Registers.

module pirv32_csrs
    import pirv32_pkg::*;
(
    input  logic clk_i,
    input  logic rst_ni,

    // Software interface
    input  logic        read_en_i,
    input  logic        write_en_i,
    input  csr_e        csr_sel_i,
    input  csr_op_e     op_i,
    input  logic [31:0] operand_i,
    output logic [31:0] rdata_o,

    input  logic        exc_save_i,
    input  exc_cause_e  exc_cause_i,
    input  logic [31:0] pc_i,
    input  logic [31:0] next_pc_i,
    input  logic [31:0] dtim_addr_i,
    input  logic        interrupt_i,
    input  logic [ 4:0] interrupt_id_i,
    output mtvec_t      mtvec_o,
    output logic [31:0] mepc_o
);

    mstatus_t    mstatus_d,  mstatus_q;
    mtvec_t      mtvec_d,    mtvec_q;
    logic [31:0] mie_d,      mie_q;
    logic [31:0] mip_d,      mip_q;
    logic [31:0] mscratch_d, mscratch_q;
    logic [31:1] mepc_d,     mepc_q;
    mcause_t     mcause_d,   mcause_q;
    logic [31:0] mtval_d,    mtval_q;

    assign mtvec_o = mtvec_q;
    assign mepc_o = {mepc_q, 1'b0};

    logic [31:0] csr_wdata;
    always_comb begin
        unique case (op_i)
            CSRRW: csr_wdata = operand_i;
            CSRRS: csr_wdata = rdata_o | operand_i;
            CSRRC: csr_wdata = rdata_o & (~operand_i);
        endcase
    end

    always_comb begin
        mstatus_d  = mstatus_q;
        mtvec_d    = mtvec_q;
        mie_d      = mie_q;
        mip_d      = mip_q;
        mscratch_d = mscratch_q;
        mepc_d     = mepc_q;
        mcause_d   = mcause_q;
        mtval_d    = mtval_q;

        if (write_en_i) begin
            unique case (csr_sel_i)
                MSTATUS: mstatus_d = '{
                    mpp: M_MODE,
                    mie: csr_wdata[3],
                    mpie: csr_wdata[7]
                };
                MIE: mie_d = csr_wdata;
                MIP: mip_d = csr_wdata;
                MTVEC: mtvec_d = '{base: csr_wdata[31:2], mode: csr_wdata[0]};
                MSCRATCH: mscratch_d = csr_wdata;
                MEPC: mepc_d = csr_wdata[31:1];
                MCAUSE: mcause_d = '{
                    interrupt: csr_wdata[31],
                    cause: exc_cause_e'(csr_wdata[4:0])
                };
                MTVAL: mtval_d = csr_wdata;
            endcase
        end

        if (exc_save_i) begin
            mepc_d = pc_i[31:1];
            mcause_d = '{interrupt: '0, cause: exc_cause_i};
            unique case (exc_cause_i)
                LOAD_ADDR_MISALIGNED: mtval_d = dtim_addr_i;
                STORE_ADDR_MISALIGNED: mtval_d = dtim_addr_i;
                default: mtval_d = '0;
            endcase
            mstatus_d = '{
                mpp: M_MODE,
                mpie: mstatus_q.mie,
                mie: '0
            };
        end else if (interrupt_i) begin
            mepc_d = next_pc_i[31:1];
            mcause_d = '{interrupt: '1, cause: exc_cause_e'(interrupt_id_i)};
            mtval_d = '0;
            mstatus_d = '{
                mpp: M_MODE,
                mpie: mstatus_q.mie,
                mie: '0
            };
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            mstatus_q  <= '{mpp: M_MODE, default: '0};
            mtvec_q    <= '{default: '0};
            mie_q      <= '0;
            mip_q      <= '0;
            mscratch_q <= '0;
            mepc_q     <= '0;
            mcause_q   <= INSN_ADDR_MISALIGNED;
            mtval_q    <= '0;
        end else begin
            mstatus_q  <= mstatus_d;
            mtvec_q    <= mtvec_d;
            mie_q      <= mie_d;
            mip_q      <= mip_d;
            mscratch_q <= mscratch_d;
            mepc_q     <= mepc_d;
            mcause_q   <= mcause_d;
            mtval_q    <= mtval_d;
        end
    end

    /* Read logic */
    always_comb begin
        rdata_o = '0;
        if (read_en_i) begin
            unique case (csr_sel_i)
                MSTATUS: rdata_o = {
                    19'h0,
                    mstatus_q.mpp,
                    3'h0,
                    mstatus_q.mpie,
                    3'h0,
                    mstatus_q.mie,
                    3'h0
                };
                MIE: rdata_o = mie_q;
                MIP: rdata_o = mip_q;
                MTVEC: rdata_o = {mtvec_q.base, 1'b0, mtvec_q.mode};
                MSCRATCH: rdata_o = mscratch_q;
                MEPC: rdata_o = {mepc_q[31:1], 1'b0};
                MCAUSE: rdata_o = {mcause_q.interrupt, 26'h0, mcause_q.cause};
                MTVAL: rdata_o = mtval_q;
            endcase
        end
    end

endmodule
