# Verilog_divider_by_7_interview_question
A complete answer for an interview question of implementing a divider by 7 using long division method.

## Divider by 7 – Verilog Implementation

### TL;DR

A fully synthesizable, sequential Verilog divider by constant 7, based on a binary long-division algorithm and a simple 3-state FSM, designed with FPGA-friendly timing and resource efficiency in mind.
Produces both quotient and remainder from a 16-bit unsigned input using a clean start / busy / valid handshake.

### Overview

As part of my preparation for FPGA development roles and technical interviews, I implemented a divider by 7 in Verilog.
Although dividing by a constant may seem trivial at first glance, this exercise touches on several fundamental FPGA design topics, including architectural trade-offs,
finite state machines (FSMs), sequential vs. combinational logic, and binary arithmetic.

The goal of the project was to divide a 16-bit unsigned input value by the constant 7 and produce
both the quotient and the remainder, using a resource-efficient and synthesizable RTL design.

### Design Requirements
#### Input

* Input width: 16-bit unsigned (data[15:0]).
* Maximum input value: 65,535 (for a 16-bit unsigned number).
* Divisor: constant value 7.

#### Outputs

* q[13:0] – Quotient.
* remainder[3:0] – Remainder (0–6).

Control / Interface:
* clk – system clock
* rst – active-high synchronous reset
* start – start pulse to begin a division operation
* busy – asserted while calculation is in progress
* valid – asserted when outputs become valid

### Why widths?

* Max quotient: 65535 / 7 = 9362 (fits in 14 bits)
* Remainder: 0–6 (fits in 4 bits)

### Architectural Choice: Sequential vs. Combinational

A purely combinational divider for a 16-bit input typically creates:
- High LUT usage
- Long combinational paths
- Timing closure challenges

Instead, a sequential long-division approach was chosen:
- Lower resource usage
- Shorter critical paths
- Better scalability
- Easier timing closure

This is a practical FPGA-oriented design choice, since division results are rarely required in a single cycle.

### Interface & Handshake Behavior (Important RTL Details)

This module uses a simple start / busy / valid handshake:

  - start is sampled only in IDLE.
    When start = 1 in IDLE:
      * The input data is captured into an internal register
      * Internal remainder / quotient are cleared
      * The FSM moves into RUN and asserts busy
  - busy = 1 means “engine is working”
      * Any start pulses while busy = 1 are ignored (simple, deterministic behavior)
  - valid is a one-clock pulse indicating the outputs are now ready
      * The quotient / remainder are stored in registers and remain stable after completion
      * 'valid' pulses to mark the completion moment

This is a common FPGA design pattern:
busy indicates progress, valid indicates completion, and outputs remain available until the next operation overwrites them.

### Finite State Machine (FSM)

The divider is controlled by a 3-state FSM:

  * IDLE:
    
      - 'busy' = 0, 'valid' = 0.
      - Waits for 'start'.
      - Captures input and initializes computation.

  * RUN:

      - Performs one long-division iteration per clock (16 cycles total).
      - 'busy' = 1.
      - Updates remainder and shifts quotient each cycle.

  * DONE:

      - Immediately returns to IDLE
      - Outputs remain stored in registers
      - 'valid' was already pulsed on the RUN → DONE transition

This keeps the control logic readable and synthesizable.

### Division Algorithm: Binary Long Division

The implementation follows standard binary long division, processing one input bit per clock, starting from MSB.

  Per cycle:
      Shift remainder left by 1
      Bring down next dividend bit into the remainder LSB
      Compare remainder with 7
      
      If remainder ≥ 7:
            remainder = remainder − 7
            shift in quotient bit ‘1’
      Otherwise:
            keep remainder
            shift in quotient bit ‘0’

After 16 iterations, the quotient and remainder are final.

### Example: Dividing 25 by 7

The decimal number 25 is represented in binary as:
  #### 25 = 11001₂

Applying the binary long-division algorithm:
Initial bits produce remainders smaller than 7, yielding quotient bits of 0
When the partial remainder reaches or exceeds 7, subtraction occurs and a 1 is appended to the quotient
The process continues until all bits are consumed

#### Final result:
    Quotient = 3
    Remainder = 4

Which matches the expected arithmetic result:
      25 ÷ 7 = 3 remainder 4

### Latency, Throughput, and Timing (Often Asked in Interviews)

**Latency:** fixed 16 clock cycles from start acceptance to valid pulse.

**Throughput:** one result every 16 cycles (single engine, non-pipelined).

**Critical path:** compare / subtract of a small value (7) and shifts → typically easy timing closure.


### Verification

The design was verified using a self-written Verilog testbench that exercises both functional correctness and interface behavior.
Verification focused on the following aspects:

* Basic functionality
  * Correct quotient and remainder for representative values
  * Comparison against expected mathematical results
* Corner cases
  * Input value 0
  * Maximum input value (65,535)
  * Values just below and just above multiples of 7
* Handshake behavior
  * start is accepted only in IDLE
  * busy remains asserted throughout the full computation
  * valid pulses for exactly one clock cycle at completion
  * Output values remain stable after completion until the next operation
* Timing behavior
  * Fixed latency of 16 clock cycles from start acceptance to valid
  * Deterministic behavior with no race conditions or combinational feedback paths
* Simulation waveforms were inspected to confirm:
  * Proper FSM state transitions
  * Correct bit-by-bit evolution of the remainder and quotient
  * Clean separation between control logic and datapath

This verification approach ensured the design is functionally correct, deterministic, and suitable for synthesis and integration in larger FPGA systems.

### RTL Implementation Notes

* All state and registers are implemented in a single always @(posedge clk) (fully synchronous RTL)
* No use of / or % operators (for synthesis)
* No IP cores / vendor primitives
* Uses an internal 5-bit remainder path during the “shift + bring bit” step to avoid overflow

### Learning Outcomes

The project that came out from this question strengthened:
* FSM design and debugging.
* Sequential RTL architecture and control.
* Implementing arithmetic algorithms in hardware.
* Writing timing-friendly, synthesizable Verilog.

### About Me

I am currently seeking my next role in FPGA and digital / logic design.
I have approximately 1.5 years of experience as a System Engineer, with a strong focus on FPGA-based systems.
My work included close collaboration with development teams and hands-on involvement in hardware, firmware, and software development, integration, and system-level bring-up
