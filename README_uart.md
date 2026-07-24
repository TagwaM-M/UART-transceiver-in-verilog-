# UART Transceiver in Verilog (TX + RX)

A UART transmitter and receiver written from scratch in Verilog, verified in simulation, and taken through synthesis and timing closure on a Xilinx Zynq UltraScale+ device. Both blocks are combined into a top-level transceiver and verified with a serial loopback testbench.

**Target device:** `xczu9eg-ffvb1156-1` (Trenz TEB0911 module)
**Tools:** Vivado 2020.2, XSim
**Configuration:** 8N1 (1 start bit, 8 data bits LSB-first, 1 stop bit), 9600 baud from a 100 MHz clock

---

## Why this project

UART is small enough to finish solo but forces the full flow: FSM design, a baud-rate generator, a shift register, clock-domain synchronization of an asynchronous input, simulation, synthesis, and timing closure. The receiver is the more interesting half — it has to *recover* bit timing from the wire with no shared clock.

---

## Design

### Transmitter (`uart_tx.v`)

A linear four-state FSM driven by a baud tick.

- **Baud generator** — a counter parameterized by `CK_PER_BIT` (10417 = 100 MHz / 9600 baud) that pulses `baud_tick` once per bit period. The counter is gated by `tx_active`, so it only runs while transmitting and every bit gets a full, aligned period.
- **FSM** — `IDLE → START → DATA → STOP`. Each state holds its level on the line and advances only on `baud_tick`.
- **Shift register** — the byte is loaded on `start`, and `shift_bits[0]` drives the line while the register shifts right each tick, producing LSB-first output for free.
- **Outputs** — `tx_serial_out` (the line, idle high), `tx_active`, and a one-cycle `done` pulse.

### Receiver (`uart_rx.v`)

Same FSM shape, but the timing must be recovered from the incoming line.

- **Two-flop synchronizer** — `rx_serial` is asynchronous to the system clock, so it is passed through two flip-flops before use. Sampling an async signal directly risks metastability; only the second-stage output is used by any logic.
- **Edge detection** — a one-cycle `start_edge` pulse is generated from the synchronized line (`rx_prev & ~sync2`) to catch the falling edge that begins a frame.
- **Mid-bit sampling** — the counter is started by the start edge, and `mid_sample` fires when `counter == CK_PER_BIT/2`. Because the counter free-runs from that point, every subsequent `mid_sample` lands at the centre of the next bit. Sampling at bit centres rather than edges gives margin against clock mismatch between the two ends and against transition noise.
- **FSM** — `IDLE` waits for `start_edge`; `START` validates the start bit at its centre (a high level here means a false start, and the receiver returns to idle); `DATA` samples eight bits, shifting them in LSB-first with `rx_out <= {sync2, rx_out[7:1]}`; `STOP` pulses `rx_done`.

### Top level (`uart_top.v`)

Instantiates both blocks on a shared clock and reset, exposing the TX and RX interfaces plus the two serial pins.

---

## Verification

Two testbenches:

- **`tb_uart_tx.v`** — pulses `start` with `0x41` and checks the serial output frame: idle high → start bit low → `1 0 0 0 0 0 1 0` (0x41, LSB-first) → stop bit high.
- **`tb_uart_rx.v`** — acts as a transmitter, driving `rx_serial` bit by bit with a full frame (each bit held for one 104.17 µs bit period) and checking that `rx_out` reconstructs `0x41`.
- **`tb_uart_top.v`** — **serial loopback**: the transmitter's output is wired directly to the receiver's input, a byte is sent, and the received byte is compared against what was transmitted. This exercises both blocks together and confirms the frame format is self-consistent.

One byte at 9600 baud occupies roughly 1.04 ms of simulated time (10 bits × 104.17 µs), so the simulation must be run to completion (`run -all`) rather than the default 1 µs.

---

## Results — transmitter

Post-implementation, 100 MHz clock constraint (`create_clock -period 10.000`):

| Metric | Value |
|---|---|
| Setup WNS | +8.543 ns (met) |
| Hold WHS | +0.052 ns (met) |
| Pulse width WPWS | +4.725 ns (met) |
| Failing endpoints | 0 |
| Estimated Fmax | ≈ 686 MHz |

Utilization:

| Resource | Count |
|---|---|
| CLB LUTs | 29 |
| CLB Registers | 31 |
| BRAM / DSP | 0 / 0 |
| Global clock buffers | 1 |

The 31 registers account exactly for the design: 14 for the baud counter (`$clog2(10417)`), 8 for the shift register, 3 for the bit index, 2 for the state, and the registered outputs. The design is counter-dominated — unlike a FIFO, where the memory array dominates — which is the expected signature for a UART.

*Synthesis and timing results for the receiver and the combined top level have not been run yet; only the transmitter has been through implementation so far.*

---

## Repository structure

```
.
├── uart_tx.v          # transmitter
├── uart_rx.v          # receiver
├── uart_top.v         # transceiver top level
├── tb_uart_tx.v       # transmitter testbench
├── tb_uart_rx.v       # receiver testbench
├── tb_uart_top.v      # loopback testbench
├── tx_uart.xdc        # 100 MHz clock constraint
└── README.md
```

---

## Notes

- The baud counter in each block is gated by the busy/active flag so that bit periods start aligned with the frame rather than at an arbitrary point in a free-running count.
- `CK_PER_BIT` is a parameter, so the baud rate can be changed by recalculating `clock frequency / baud rate` — no other edits required.
