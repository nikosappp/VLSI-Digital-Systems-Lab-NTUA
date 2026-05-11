#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xaxidma.h"
#include "xtime_l.h"
#include "xil_cache.h" // Required for proper Cache functions
#include "sleep.h"     // required for usleep()

#define TX_DMA_ID                 XPAR_PS2PL_DMA_DEVICE_ID
#define RX_DMA_ID                 XPAR_PL2PS_DMA_DEVICE_ID

#define TX_BUFFER (XPAR_DDR_MEM_BASEADDR + 0x08000000) // 0 + 128MByte
#define RX_BUFFER (XPAR_DDR_MEM_BASEADDR + 0x10000000) // 0 + 256MByte

#define DEBAYER_IP_BASEADDR       0x43C00000

// Define buffer pointers
u8  *tx_buffer = (u8 *) TX_BUFFER;                     // Raw Bayer input
u32 *rx_buffer = (u32 *) RX_BUFFER;                    // Hardware RGB output
u32 *sw_buffer = (u32 *)(RX_BUFFER + 0x01000000);      // Software RGB output (offset to avoid overlap)

int main()
{
    XTime preExecCyclesFPGA = 0, postExecCyclesFPGA = 0;
    XTime preExecCyclesSW = 0, postExecCyclesSW = 0;

    init_platform();
    // Disable cache
    Xil_DCacheDisable();
    Xil_ICacheDisable();

    print("\r\n--- Runtime Reconfigurable Debayering Test (CACHE OFF) ---\r\n");
//    print("\r\n--- Runtime Reconfigurable Debayering Test ---\r\n");

    // Initialize DMA Engines
    XAxiDma tx_dma;
    XAxiDma rx_dma;
    XAxiDma_Config *tx_cfg;
    XAxiDma_Config *rx_cfg;
    int status;

    // Step 1: Initialize TX-DMA Device (PS->PL)
    tx_cfg = XAxiDma_LookupConfig(TX_DMA_ID);
    status = XAxiDma_CfgInitialize(&tx_dma, tx_cfg);
    if (status != XST_SUCCESS) {
        print("Error initializing TX DMA\r\n");
        return XST_FAILURE;
    }

    // Step 2: Initialize RX-DMA Device (PL->PS)
    rx_cfg = XAxiDma_LookupConfig(RX_DMA_ID);
    status = XAxiDma_CfgInitialize(&rx_dma, rx_cfg);
    if (status != XST_SUCCESS) {
        print("Error initializing RX DMA\r\n");
        return XST_FAILURE;
    }

    // test image dimensions
    int test_sizes[] = {64, 128, 256, 512, 1024};
    int num_tests = sizeof(test_sizes) / sizeof(test_sizes[0]);

    // loop on dimensions
    for (int t = 0; t < num_tests; t++) {
        int current_dim = test_sizes[t];
        int num_pixels = current_dim * current_dim;

        printf("\r\n===================================================\r\n");
        printf("Testing Image Size: %d x %d\r\n", current_dim, current_dim);
        printf("===================================================\r\n");

        // set dimension
        *(volatile u32 *)DEBAYER_IP_BASEADDR = current_dim;

        // delay for HW dimension reset
        usleep(1000);

        // Readback
        u32 readback_dim = *(volatile u32 *)DEBAYER_IP_BASEADDR;
        printf("FPGA Hardware Configured. Readback Dimension: %lu\r\n", readback_dim);

        if (readback_dim != current_dim) {
            printf("ERROR: AXI-Lite write failed! Expected %d, got %lu\r\n", current_dim, readback_dim);
            continue;
        }

        // --- Generate data ---
        for (int i = 0; i < num_pixels; i++) {
            tx_buffer[i] = (u8)(i % 256);
        }

        // Cache Management
        Xil_DCacheFlushRange((UINTPTR)tx_buffer, num_pixels * sizeof(u8));
        Xil_DCacheInvalidateRange((UINTPTR)rx_buffer, num_pixels * sizeof(u32));

        // --- FPGA (DMA Transfers) ---
        XTime_GetTime(&preExecCyclesFPGA);

        XAxiDma_SimpleTransfer(&rx_dma, (UINTPTR)rx_buffer, num_pixels * sizeof(u32), XAXIDMA_DEVICE_TO_DMA);
        XAxiDma_SimpleTransfer(&tx_dma, (UINTPTR)tx_buffer, num_pixels * sizeof(u8), XAXIDMA_DMA_TO_DEVICE);

        while (XAxiDma_Busy(&tx_dma, XAXIDMA_DMA_TO_DEVICE)) {}
        while (XAxiDma_Busy(&rx_dma, XAXIDMA_DEVICE_TO_DMA)) {}

        XTime_GetTime(&postExecCyclesFPGA);

        // --- CPU (Software Reference Model) ---
        XTime_GetTime(&preExecCyclesSW);

        for(int r = 0; r < current_dim; r++) {
            for(int c = 0; c < current_dim; c++) {
                int p11 = (r > 0 && c > 0)                         ? tx_buffer[(r-1)*current_dim + (c-1)] : 0;
                int p12 = (r > 0)                                  ? tx_buffer[(r-1)*current_dim + c]     : 0;
                int p13 = (r > 0 && c < current_dim-1)             ? tx_buffer[(r-1)*current_dim + (c+1)] : 0;
                int p21 = (c > 0)                                  ? tx_buffer[r*current_dim + (c-1)]     : 0;
                int p22 = tx_buffer[r*current_dim + c];
                int p23 = (c < current_dim-1)                      ? tx_buffer[r*current_dim + (c+1)]     : 0;
                int p31 = (r < current_dim-1 && c > 0)             ? tx_buffer[(r+1)*current_dim + (c-1)] : 0;
                int p32 = (r < current_dim-1)                      ? tx_buffer[(r+1)*current_dim + c]     : 0;
                int p33 = (r < current_dim-1 && c < current_dim-1) ? tx_buffer[(r+1)*current_dim + (c+1)] : 0;

                u32 R = 0, G = 0, B = 0;
                int row_lsb = r % 2;
                int col_lsb = c % 2;

                if (row_lsb == 1 && col_lsb == 1) {        // ctrl "00"
                    R = (p21 + p23) / 2;
                    G = p22;
                    B = (p12 + p32) / 2;
                } else if (row_lsb == 0 && col_lsb == 0) { // ctrl "01"
                    R = (p12 + p32) / 2;
                    G = p22;
                    B = (p21 + p23) / 2;
                } else if (row_lsb == 1 && col_lsb == 0) { // ctrl "10"
                    R = p22;
                    G = (p12 + p21 + p23 + p32) / 4;
                    B = (p11 + p13 + p31 + p33) / 4;
                } else if (row_lsb == 0 && col_lsb == 1) { // ctrl "11"
                    R = (p11 + p13 + p31 + p33) / 4;
                    G = (p12 + p21 + p23 + p32) / 4;
                    B = p22;
                }

                sw_buffer[r * current_dim + c] = (R << 16) | (G << 8) | B;
            }
        }

        XTime_GetTime(&postExecCyclesSW);

        // --- Comparison and Metrics ---
        int errors = 0;
        for (int i = 0; i < num_pixels; i++) {
            if (rx_buffer[i] != sw_buffer[i]) {
                errors++;
            }
        }

        float err_pct = ((float)errors / (float)num_pixels) * 100.0f;
        u64 fpga_cycles = 2 * (postExecCyclesFPGA - preExecCyclesFPGA);
        u64 sw_cycles = 2 * (postExecCyclesSW - preExecCyclesSW);
        float speedup = (float)sw_cycles / (float)fpga_cycles;

        printf("Comparison Errors: %d out of %d (%.4f %%)\r\n", errors, num_pixels, err_pct);
        printf("FPGA execution time: %llu cycles\r\n", fpga_cycles);
        printf("SW execution time  : %llu cycles\r\n", sw_cycles);
        printf("FPGA Speedup over SW: %.2fx\r\n", speedup);
    }

    print("\r\nAll tests completed successfully.\r\n");
    cleanup_platform();
    return 0;
}
