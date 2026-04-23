#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xaxidma.h"
#include "xtime_l.h"
#include "xil_cache.h" // Required for proper Cache functions

#define TX_DMA_ID                 XPAR_PS2PL_DMA_DEVICE_ID
#define RX_DMA_ID                 XPAR_PL2PS_DMA_DEVICE_ID

#define TX_BUFFER (XPAR_DDR_MEM_BASEADDR + 0x08000000) // 0 + 128MByte
#define RX_BUFFER (XPAR_DDR_MEM_BASEADDR + 0x10000000) // 0 + 256MByte

/* User application global variables & defines */
// Set to 32 for testing. Remember to change to 1024 for the final lab exam!
#define IMG_WIDTH  32
#define IMG_HEIGHT 32
#define NUM_PIXELS (IMG_WIDTH * IMG_HEIGHT)

// Define buffer pointers
u8  *tx_buffer = (u8 *) TX_BUFFER;                     // Raw Bayer input
u32 *rx_buffer = (u32 *) RX_BUFFER;                    // Hardware RGB output
u32 *sw_buffer = (u32 *)(RX_BUFFER + 0x01000000);      // Software RGB output (offset to avoid overlap)

int main()
{

    XTime preExecCyclesFPGA = 0;     // for fpga timing
    XTime postExecCyclesFPGA = 0;
    XTime preExecCyclesSW = 0;       // for software timing
    XTime postExecCyclesSW = 0;

    init_platform();

    print("HELLO 1\r\n");
    print("Initializing test data...\r\n");

    // Initialize the TX buffer with a dummy image (a simple gradient)
    for (int i = 0; i < NUM_PIXELS; i++) {
        tx_buffer[i] = (u8)(i % 256);
    }

    // User application local variables
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

    print("Starting FPGA Processing...\r\n");

    // --- CACHE MANAGEMENT ---
    // Flush the TX buffer so the DMA can see the dummy data we just wrote to the cache.
    Xil_DCacheFlushRange((UINTPTR)tx_buffer, NUM_PIXELS * sizeof(u8));

    // Invalidate the RX buffer so the CPU is forced to read the fresh DMA results from DDR later.
    Xil_DCacheInvalidateRange((UINTPTR)rx_buffer, NUM_PIXELS * sizeof(u32));

    XTime_GetTime(&preExecCyclesFPGA);

    // Step 3 : Perform FPGA processing
    //      3a: Setup RX-DMA transaction FIRST (Receiving 32-bit RGB pixels)
    XAxiDma_SimpleTransfer(&rx_dma, (UINTPTR)rx_buffer, NUM_PIXELS * sizeof(u32), XAXIDMA_DEVICE_TO_DMA);

    //      3b: Setup TX-DMA transaction SECOND (Sending 8-bit Bayer pixels)
    XAxiDma_SimpleTransfer(&tx_dma, (UINTPTR)tx_buffer, NUM_PIXELS * sizeof(u8), XAXIDMA_DMA_TO_DEVICE);

    //      3c: Wait for TX-DMA & RX-DMA to finish
    while (XAxiDma_Busy(&tx_dma, XAXIDMA_DMA_TO_DEVICE)) {}
    while (XAxiDma_Busy(&rx_dma, XAXIDMA_DEVICE_TO_DMA)) {}

    XTime_GetTime(&postExecCyclesFPGA);
    print("FPGA Processing Done.\r\n");


    print("Starting Software Processing...\r\n");
    XTime_GetTime(&preExecCyclesSW);

    // Step 5: Perform SW processing (Reference Model)
    for(int r = 0; r < IMG_HEIGHT; r++) {
        for(int c = 0; c < IMG_WIDTH; c++) {
            // Apply zero padding for edge cases, exactly matching the VHDL 'edge' logic
            int p11 = (r > 0 && c > 0)                 ? tx_buffer[(r-1)*IMG_WIDTH + (c-1)] : 0;
            int p12 = (r > 0)                          ? tx_buffer[(r-1)*IMG_WIDTH + c]     : 0;
            int p13 = (r > 0 && c < IMG_WIDTH-1)       ? tx_buffer[(r-1)*IMG_WIDTH + (c+1)] : 0;
            int p21 = (c > 0)                          ? tx_buffer[r*IMG_WIDTH + (c-1)]     : 0;
            int p22 = tx_buffer[r*IMG_WIDTH + c];
            int p23 = (c < IMG_WIDTH-1)                ? tx_buffer[r*IMG_WIDTH + (c+1)]     : 0;
            int p31 = (r < IMG_HEIGHT-1 && c > 0)      ? tx_buffer[(r+1)*IMG_WIDTH + (c-1)] : 0;
            int p32 = (r < IMG_HEIGHT-1)               ? tx_buffer[(r+1)*IMG_WIDTH + c]     : 0;
            int p33 = (r < IMG_HEIGHT-1 && c < IMG_WIDTH-1) ? tx_buffer[(r+1)*IMG_WIDTH + (c+1)] : 0;

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

            // Pack to 32-bit: "00000000" & R & G & B
            sw_buffer[r * IMG_WIDTH + c] = (R << 16) | (G << 8) | B;
        }
    }

    XTime_GetTime(&postExecCyclesSW);
    print("Software Processing Done.\r\n");


    // Step 6: Compare FPGA and SW results
    int errors = 0;
    for (int i = 0; i < NUM_PIXELS; i++) {
        if (rx_buffer[i] != sw_buffer[i]) {
            errors++;
        }
    }

    //     6a: Report total percentage error
    float err_pct = ((float)errors / (float)NUM_PIXELS) * 100.0f;
    printf("\nComparison Errors: %d out of %d (%.4f %%)\r\n", errors, NUM_PIXELS, err_pct);

    //     6b: Report FPGA execution time in cycles
    u64 fpga_cycles = 2 * (postExecCyclesFPGA - preExecCyclesFPGA);
    printf("FPGA execution time: %llu cycles\r\n", fpga_cycles);

    //     6c: Report SW execution time in cycles
    u64 sw_cycles = 2 * (postExecCyclesSW - preExecCyclesSW);
    printf("SW execution time: %llu cycles\r\n", sw_cycles);

    //     6d: Report speedup (SW_execution_time / FPGA_exection_time)
    float speedup = (float)sw_cycles / (float)fpga_cycles;
    printf("FPGA Speedup over SW: %.2fx\r\n", speedup);

    cleanup_platform();
    return 0;
}
