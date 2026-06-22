// SPDX-License-Identifier: SHL-2.1
// SPDX-FileCopyrightText: David Schröder 2026

module pirv32_core_tb ();

    logic clk;
    logic rst_n;

    always begin
        clk <= '1;
        #5000;
        clk <= '0;
        #5000;
    end

    pirv32_core DUT (
        .clk_i (clk),
        .rst_ni(rst_n),
        .rs1_o ()
    );

    initial begin
        rst_n <= '0;
        @(posedge clk);
        @(posedge clk);
        rst_n <= '1;
        @(posedge clk);

        for (int i = 0; i < 100; i++) @(posedge clk);

        $finish;
    end

endmodule
