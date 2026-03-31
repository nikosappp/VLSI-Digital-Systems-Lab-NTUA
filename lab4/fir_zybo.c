#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"

// Hardware Addresses and Offsets
#define FIR_BASE_ADDR 0x43C00000

#define REG_A_OFFSET        0x00
#define REG_B_OFFSET        0x04

// Bitmasks
#define MASK_VALID_IN       0x00000100  // Bit 8
#define MASK_RST            0x00000200  // Bit 9
#define MASK_OUT_READY      0x00080000  // Bit 19
#define MASK_Y_DATA         0x0007FFFF  // Bits 18:0 (19 bits of data)

// Filter Coefficients
const int h_coeff[8] = {1, 2, 3, 4, 5, 6, 7,  8};

// SW Input delay line
uint8_t x_hist[8] = {0};

// Helper Functions
// Reset FIR Filter
void fir_reset() {
    // write 1 to the reset bit (Bit 9)
    Xil_Out32(FIR_BASE_ADDR + REG_A_OFFSET, MASK_RST);

    // write 0 to clear the reset
    Xil_Out32(FIR_BASE_ADDR + REG_A_OFFSET, 0x00000000);
    xil_printf("FIR Filter Reset Complete.\r\n");
}

// Send data and wait for result
uint32_t fir_process_sample(uint8_t input_x) {
    uint32_t reg_b_val;
    uint32_t output_y;

    // Write data and trigger valid_in
    uint32_t reg_a_val = (uint32_t)input_x | MASK_VALID_IN;
    Xil_Out32(FIR_BASE_ADDR + REG_A_OFFSET, reg_a_val);

    // Poll register B until the hardware sets out_ready (Bit 19) high.
    do {
        reg_b_val = Xil_In32(FIR_BASE_ADDR + REG_B_OFFSET);
    } while ((reg_b_val & MASK_OUT_READY) == 0);

    // Extract the 19-bit y data from Register B
    output_y = reg_b_val & MASK_Y_DATA;

    return output_y;
}

// Calculate expected outputs
// Reset SW delay line
void sw_fir_reset() {
	for (int i = 0; i < 8; i++) {
		x_hist[i] = 0;
	}
}

// Calculate SW result
uint32_t sw_fir_process_sample(uint8_t x_n) {
	uint32_t y = 0;

	// Shift delay line
	for (int i = 7; i > 0; i--) {
		x_hist[i] = x_hist[i-1];
	}

	// Insert new sample
	x_hist[0] = x_n;

	// Multiply and accumulate
	for (int i = 0; i < 8; i++) {
		y += x_hist[i] * h_coeff[i];
	}

	// Mask to 19 bits
	return y & MASK_Y_DATA;
}

int main() {
    // Test input array
    uint8_t test_data[28] = {208, 231, 32, 233, 161, 24, 71, 140, 245, 247, 40, 248, 245, 124, 204, 36, 107, 234, 202, 245, 0, 0, 0, 0, 0, 0, 0, 0};
    uint32_t filtered_data[28];
    int error_cnt = 0;
    uint32_t sw_res;

    xil_printf("Starting FIR Filter Test...\r\n");

    // Initialize hardware
    fir_reset();

    // Initialize software
    sw_fir_reset();

    // Process the array
    for (int i = 0; i < 28; i++) {
        filtered_data[i] = fir_process_sample(test_data[i]);
        xil_printf("Input: %3d -> FIR Output: %lu\r\n", test_data[i], filtered_data[i]);

        // Compare HW result to SW result
        sw_res = sw_fir_process_sample(test_data[i]);
        if (filtered_data[i] != sw_res) {
        	xil_printf("Error! Expected: %lu, Got: %lu\r\n", sw_res, filtered_data[i]);
        	error_cnt++;
        }
    }

    xil_printf("Test Complete\r\n");
    if (error_cnt == 0) {
    	xil_printf("Success! No errors detected.\r\n");
    } else {
    	xil_printf("Failure: Got %d errors\r\n", error_cnt);
    }

    return 0;
}
