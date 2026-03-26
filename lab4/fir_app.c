#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"

#define FIR_BASE_ADDR 0x43C00000 // Base address from Vivado Address Editor

// Register offsets
#define REG_A_OFFSET 0x00  // slv_reg0: [9]=rst, [8]=valid_in, [7:0]=x
#define REG_B_OFFSET 0x04  // slv_reg1: [19]=valid_out, [18:0]=y

int main()
{
    init_platform();
    xil_printf("\r\n--- FIR Filter Test with Custom Input Sequence ---\r\n");

    // Hardware Reset
    Xil_Out32(FIR_BASE_ADDR + REG_A_OFFSET, 0x00000200); // Pulse rst high
    Xil_Out32(FIR_BASE_ADDR + REG_A_OFFSET, 0x00000000); // Set rst low

    // custom input sequence (x)
    uint32_t test_samples[] = {
        208, 231, 32, 233, 161, 247, 1, 140, 245, 247,
        40, 248, 245, 124, 204, 36, 107, 234, 202, 245,
        0, 0, 0, 0, 0, 0, 0, 0
    };

    int num_samples = sizeof(test_samples) / sizeof(test_samples[0]);

    for (int i = 0; i < num_samples; i++) {
        uint32_t x_val = test_samples[i];

        // Send Data: Set valid_in='1' (bit 8) and input x (bits 7:0)
        Xil_Out32(FIR_BASE_ADDR + REG_A_OFFSET, 0x00000100 | (x_val & 0xFF));

        // Pulse valid_in low so the FIR only sees one clock edge for this sample
        Xil_Out32(FIR_BASE_ADDR + REG_A_OFFSET, (x_val & 0xFF));

        // Polling for valid_out (bit 19 of REG_B)
        uint32_t read_data = 0;
        while (1) {
            read_data = Xil_In32(FIR_BASE_ADDR + REG_B_OFFSET);
            if ((read_data >> 19) & 0x01) { // Check valid_out bit
                break;
            }
        }

        // Extract result y (19 bits: 18 down to 0)
        uint32_t y_val = read_data & 0x7FFFF;

        xil_printf("Sample [%2d] | Input x: %3lu -> FIR Output y: %6lu\r\n", i, x_val, y_val);
    }

    xil_printf("--- Testing Complete ---\r\n");
    cleanup_platform();
    return 0;
}
