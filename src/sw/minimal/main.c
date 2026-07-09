/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: David Schröder 2026
 */

#include <stdio.h>
#include <stdint.h>

#define read_csr(reg) ({ unsigned long __tmp; \
    asm volatile ("csrr %0, " reg : "=r"(__tmp)); \
    __tmp; })

#define write_csr(reg, val) ({ \
    asm volatile ("csrw " reg ", %0" :: "rK"(val)); })

int main(void) {
    printf("Hello World %d!\n", 567);

    uint32_t mcycle = read_csr("mcycle");
    uint32_t minstret = read_csr("minstret");

    uint32_t cpi_x1k = (mcycle * 1000) / minstret;

    printf("CPI: %d.%03d\n", cpi_x1k/1000, cpi_x1k%1000);

    return 0;
}
