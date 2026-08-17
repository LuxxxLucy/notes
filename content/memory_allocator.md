---
description: Notes on memory allocators
---

# Memory Allocators

Memory allocators is often a thing that people bring about when thinking of
performance optimization.

I would suggest the following
1. try refactor first. Allocate less is alwasy better than "allocate faster"
2. If it really is a complicated system, measure first
3. Some heuristics for selecting allocators. (And then do some tuning)

## "Allocate less" is always better than "allocate faster."

Sometimes if we know the problem is from a particular part, or a particular routine.
We can consider refactor instead.

1. Use a linear allocator (or called Arena, Bump allocator) youself in the program. This often solves the issue in the simplest way
2. inline small allocations on stack.
3. Reserve upfront the capacity (say in C++, reserve)
4. Structure of arrays. Solves also the cache issue.

## Measuring first

It is better to categorize and understand real workload memory usage patterns

1. Make sure it is bug-free in the beginning: so that we know it is leak or just issues from fragmentation.
2. Allocation rate. How many malloc/free per second
3. Size Distribution: mostly small? A few huge ones?
4. Lifetime Distribution: Mostly dies shortly? Or can they stay alive for long?
5. Thread Behaviour: Is it freed in the same thread? Or more are malloc in one thread and transfer to another thread that frees it?

? do we have a eBPF for this? (say we do use system std malloc)
that would be nice.

One way to do this measurement is to:
1. get the current program and set up of real workload
2. Run and measure (mainly 3 aspects). Note that we need to run often many times to reduce variance.
    1. throughput
    2. tail latency (p90, p99)
    3. RSS
3. (Optional) swap allocator and test. And also we can tune the allocators.

## Candidates and how to select them

Thread topology still dominates the choice between jemalloc / tcmalloc / mimalloc / snmalloc.

Three axes: throughput, tail latency, RSS

### glibc malloc
Or that whatever is your default.

### mimalloc
Fastest with many small and short lived objects

Throughput-heavy multithreaded, same-thread free

Also good with cross-thread freeing.

Small and light-weighted and an often quite good choice.

### jemalloc
Used for long-running server and when RSS matters.

It handles fragmentation better.

More options for tuning, but also heavy

### tcmalloc

Fast thread local cache.
Great for multi-thread (but same-thread free) programs and high throughput

### snmalloc
cross-thread allocate/transfer/free

### harden_malloc
security first.

## References

- [tcmalloc, Characterizing a Memory Allocator at Warehouse Scale](https://people.csail.mit.edu/delimitrou/papers/2024.asplos.memory.pdf)
- [jemalloc, scalable memory allocation using jemalloc](https://engineering.fb.com/2011/01/03/core-infra/scalable-memory-allocation-using-jemalloc/)
-[snmalloc — a message passing allocator](https://www.microsoft.com/en-us/research/wp-content/uploads/2020/04/snmalloc.pdf)
