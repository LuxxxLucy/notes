---
description: My notes on system optimization, reducing latency and compute cost across the software stack through workload and resource analysis, observability, and profiling.
---

# Optimization

About optimization

## Goal

The general goals of system optimization is to improve end-user experience.

It is in fact pretty loose and would have included the product feature.

But in narrow sense, we often care about the two basic aspects:
1. reduce latency.
2. reducing computation cost.

The object of optimization is, of course, the entire software stack,
from the application on the top, and all the way down to the bare metal (including system software, OS kernel, and the hardware).

## Analysis

We can often start analysis from two complementary views:
1. the analysis of the workload.
2. the analysis of the resources.

## Observability

TODO: what are the observability tools? read more

1. counters, statistics, metrics.
2. profiling.
3. tracing.

I would often opt to a customized instrumentation (mostly static) for the code (after that I got the main overview of the program working), and then make it a customized tracing tool which would provide me data so that analysis and reasoning of my hypothesis can be performed.

## Experimentation

TODO: elaborate more on this direction.

apply experiment: applying a synthetic workload to the system and measure its performance.

1. macro experimentation (end to end)
2. micro experimentation: focused on a particular component.

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

## Profile

## De-redundancy

## Fast Path

## Wholesale rewrite
