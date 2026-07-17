---
description: My notes on system optimization, reducing latency and compute cost across the software stack through workload and resource analysis, observability, and profiling.
---

# Optimization

General tricks of optimization

## branch misprediction

Modern CPUs use branch prediction to guess the outcome of conditional branches, before the condition is fully resolved, as it can do pipeline to optimize instruction sequence. This allows the CPU to keep fetching and executing instructions instead of waiting.

A branch misprediction typically costs about 10–20 CPU cycles.
| Situation                               |         Approximate added latency |
| --------------------------------------- | --------------------------------: |
| Correctly predicted branch              | ~0–1 cycles of effective overhead |
| Mispredicted branch, modern desktop CPU |                     ~10–20 cycles |
| Especially deep pipeline                |                     ~20–30 cycles |
| Small/simple embedded CPU               |                      ~3–10 cycles |

One of the most effective ways to reduce mispredictions is to simply avoid branches in programming

## Memory and Data Accessing

Now this is a memory access related issue so might consult [memory.md](./memory.md).

