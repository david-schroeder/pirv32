// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

// Unpipelined (asynchronous) Data Tightly Integrated Memory.

module pirv32_dtim
    import pirv32_pkg::*;
#(
    parameter int LOG_SIZE = 10 // 1KiB
) (
    input  logic clk_i,

    input  logic [        31:0] data_i,
    input  logic [LOG_SIZE-1:0] address_i,
    input  mem_op_e             op_i,

    output logic [31:0] data_o,
    output logic        misaligned_o
);

    reg [31:0] mem [2**(LOG_SIZE-2)-1:0];

    /* Store logic */

    logic [LOG_SIZE-3:0] waddr;
    logic [        31:0] wdata;
    logic [         3:0] wmask;

    assign waddr = address_i[LOG_SIZE-1:2];

    always_comb begin
        unique case (op_i)
            SB: wdata = {data_i[7:0], data_i[7:0], data_i[7:0], data_i[7:0]};
            SH: wdata = {data_i[15:0], data_i[15:0]};
            default: wdata = data_i;
        endcase

        unique case ({op_i, address_i[1:0]})
            {SB, 2'b00}: wmask = 4'b0001;
            {SB, 2'b01}: wmask = 4'b0010;
            {SB, 2'b10}: wmask = 4'b0100;
            {SB, 2'b11}: wmask = 4'b1000;
            {SH, 2'b00}: wmask = 4'b0011;
            {SH, 2'b10}: wmask = 4'b1100;
            {SW, 2'b00}: wmask = 4'b1111;
            // Misaligned cases don't write to memory
            default: wmask = 4'b0000;
        endcase
    end

    always_ff @(posedge clk_i) begin
        for (int i = 0; i < 4; i++) begin
            if (wmask[i]) mem[waddr][8*i+:8] <= wdata[8*i+:8];
        end
    end

    /* Load logic */

    logic [31:0] rdata;
    assign rdata = mem[address_i[LOG_SIZE-1:2]];

    logic [15:0] sel_halfword;
    logic [ 7:0] sel_byte;
    assign sel_halfword = address_i[1] ? rdata[31:16] : rdata[15:0];
    assign sel_byte = address_i[0] ? sel_halfword[15:8] : sel_halfword[7:0];

    always_comb begin
        unique case (op_i)
            LB : data_o = {{24{sel_byte[7]}}, sel_byte};
            LBU: data_o = {24'h0, sel_byte};
            LH : data_o = {{16{sel_halfword[15]}}, sel_halfword};
            LHU: data_o = {16'h0, sel_halfword};
            default: data_o = rdata;
        endcase
    end

    /* Misalignment logic */

    always_comb begin
        unique case ({op_i, address_i[1:0]})
            {LH , 2'b01},
            {LHU, 2'b01},
            {LH , 2'b11},
            {LHU, 2'b11},
            {LW , 2'b01},
            {LW , 2'b10},
            {LW , 2'b11},
            {SH , 2'b01},
            {SH , 2'b11},
            {SW , 2'b01},
            {SW , 2'b10},
            {SW , 2'b11}: misaligned_o = '1;
            default: misaligned_o = '0;
        endcase
    end

endmodule
