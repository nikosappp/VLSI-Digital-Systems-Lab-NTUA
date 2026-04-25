# VLSI Digital Systems Laboratory - NTUA

This repository contains the design, simulation, and implementation of digital systems developed as part of the **VLSI Digital Systems** course at the National Technical University of Athens (ECE NTUA). The project series follows a progression from basic arithmetic unit design to complex hardware-accelerated systems integrated into a Zynq-7000 SoC (Zybo).

## Tools & Technologies
* **Design & Synthesis:** Xilinx Vivado 
* **Software Development:** Xilinx Vitis 
* **Hardware Description Language:** VHDL (Dataflow, Structural, and Behavioral modeling)
* **Software Programming:** C 
* **Communication Protocols:** AXI4-Lite & AXI4-Stream
* **Hardware Platform:** Zynq-7000 SoC (Digilent Zybo board)

## Lab Assignments Overview

### Lab 1: Hierarchical Design of Arithmetic Units
Implementation of fundamental arithmetic circuits (Half Adder, Full Adder, 4-bit Parallel Adder) using Dataflow and Structural VHDL modeling. The project demonstrates hierarchical design principles by scaling basic components into complex systems, such as a BCD Full Adder and a 4-digit Parallel BCD Adder.

### Lab 2: Hardware Unit Design using Pipelining Techniques
Design and implementation of synchronous arithmetic units utilizing pipelining to increase throughput. This lab includes the development of a Synchronous Full Adder, an N-bit Pipelined Parallel Adder, and a 4-bit Systolic (Pipelined) Multiplier, focusing on performance analysis and critical path optimization.

### Lab 3: FIR Filter Design and Simulation
Design of a Finite Impulse Response (FIR) filter using a MAC architecture and FSM-driven control for memory orchestration. This phase focuses on VHDL development and functional verification through simulation to ensure correct arithmetic behavior before SoC integration.

### Lab 4: SoC Integration and On-Board FIR Verification
Integration of the Lab 3 FIR logic into a Zynq-7000 SoC using the AXI-Lite protocol. The verified RTL design was wrapped in a custom IP core and tested on the ZYBO board, with software-driven control and data exchange managed through C drivers.

### Lab 5: Debayering Filter Design and RTL Simulation
RTL implementation of a Debayering (demosaicing) filter utilizing bilinear interpolation and line buffers for 3x3 window processing. This stage focuses on algorithmic validation through simulation, ensuring precise RGB reconstruction from Bayer-patterned inputs prior to hardware deployment.

### Lab 6: SoC Integration and AXI-Stream Board Verification
Deployment of the Lab 5 Debayering logic onto the Zynq SoC using the AXI-Stream protocol for high-throughput image data transfer. The system reuses the simulated hardware accelerator and is verified on-board via Vitis, demonstrating a complete hardware-accelerated image processing pipeline.
