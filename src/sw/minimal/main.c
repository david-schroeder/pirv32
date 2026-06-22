/* SPDX-License-Identifier: Apache-2.0
 * SPDX-FileCopyrightText: David Schröder 2026
 */

#include <stdio.h>

int main(void) {
    volatile int i = 0;
    for (int k = 0; k < 10; k++) {
        i += k;
    }
    return 0;
}
