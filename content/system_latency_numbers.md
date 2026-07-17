---
description: System latency numbers every programmer should know, inspired from Jeff Dean and Brendan Gregg
---

# Time scale of system latencies: numbers that a programmer should know.

This is a table that summarizes the main latency numbers. These are the numbers that one shall know in mind when making mental analysis.

To make it intuitive, the Scaled column stretches each latency so that one CPU cycle equals one second.

Credit:
- Latency Numbers Every Programmer Should Know, Jeff Dean
- Table 2.2 of *Systems Performance* (2nd edition), assuming a 3.5 GHz CPU, Brendan Gregg. (This is where the scaling idea comes from).

Notes:
- I added more GPU-related stats, assuming an H100 (1.75 GHz).
- The memory and disk access is updated to 2020s data (as a lot of improvement has been done since 2012).

| Event | Latency | Scaled |
| --- | --- | --- |
| 1 CPU cycle | 0.3 ns | 1 s |
| Level 1 cache access | 0.9 ns | 3 s |
| Level 2 cache access | 3 ns | 10 s |
| Branch mispredict | 5 ns | 17 s |
| Level 3 cache access | 10 ns | 33 s |
| GPU shared memory access | 17 ns | 57 s |
| GPU L1 cache access | 23 ns | 1.3 min |
| Mutex lock/unlock | 25 ns | 1.4 min |
| Main memory access (DRAM, from CPU) | 100 ns | 6 min |
| GPU L2 cache access | 150 ns | 8 min |
| GPU global memory (HBM) | 273 ns | 15 min |
| PCIe DMA doorbell | 1 µs | 0.9 hours |
| NVLink peer-GPU access | 1.5 µs | 1.4 hours |
| GPUDirect RDMA (InfiniBand, small msg) | 3 µs | 2.8 hours |
| CUDA kernel launch | 5 µs | 4.6 hours |
| PCIe small host-to-device transfer | 8 µs | 7.4 hours |
| Read 1 MB sequentially from memory | 30 µs | 1.2 days |
| Solid-state disk I/O (flash memory) | 10–100 µs | 9–90 hours |
| Read 1 MB sequentially from SSD | 200 µs | 7.7 days |
| Round trip within same datacenter | 500 µs | 19 days |
| Rotational disk I/O | 1–10 ms | 1–12 months |
| Read 1 MB sequentially from disk | 5 ms | 6.3 months |
| Internet: San Francisco to New York | 40 ms | 4 years |
| Internet: San Francisco to United Kingdom | 81 ms | 8 years |
| Lightweight hardware virtualization boot | 100 ms | 11 years |
| Internet: San Francisco to Australia | 183 ms | 19 years |
| OS virtualization system boot | < 1 s | 105 years |
| TCP timer-based retransmit | 1–3 s | 105–317 years |
| SCSI command time-out | 30 s | 3 millennia |
| Hardware (HW) virtualization system boot | 40 s | 4 millennia |
| Physical system reboot | 5 m | 32 millennia |

