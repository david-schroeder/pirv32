// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

// This is your project toplevel.

module nanosoc_core (
    input  logic clk_i, // 100MHz clock
    input  logic rst_ni,
    input  top_pkg::board2fpga_t io_i,
    output top_pkg::fpga2board_t io_o
);

    logic [31:0] data;

    pirv32_core core_i (
        .clk_i,
        .rst_ni,
        .rs1_o(data)
    );

    always_comb begin
        io_o = '{default: '0};
        unique case (io_i.switch[1:0])
            2'b00: io_o.led = data[ 7: 0];
            2'b01: io_o.led = data[15: 8];
            2'b10: io_o.led = data[23:16];
            2'b11: io_o.led = data[31:24];
        endcase
    end

endmodule
