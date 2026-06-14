// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

// This is your project toplevel.

module project_core (
    input  logic clk_i,
    input  logic rst_ni,
    input  top_pkg::board2fpga_t io_i,
    output top_pkg::fpga2board_t io_o
);

    logic [7:0] switch_q;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            switch_q <= '0;
        end else begin
            switch_q <= io_i.switch;
        end
    end

    always_comb begin
        io_o = '{default: '0};
        io_o.led = switch_q;
    end

endmodule
