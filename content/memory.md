---
description: Notes on virtual memory in the Linux x86-64 kernel, covering address translation, paging, and the memory hierarchy.
---

# Virtual Memory

Note: all is assuming a linux kernel with x86-64 architecture.

## Basic

Each process has its own virtual memory as if it is the only process in the entire system, while the kernel manages the actual translation.

48 bits of 64 in the pointer space can be used as memory, that is 256 TB.

but the upper half is used by the kernel. So a user program process could have at max 128 TB.
Even when we have only a machine memory of 16GB, the process still sees as if it has so much more memory.

The remaining 16 bits are:
1. all zero for user space
2. all one for kernel space address.
Invalid ones are, obviously, invalid.
Note that newer architectures might support more, like 57 bits address space.

## Basic Layout

The virtual address space is organized in separate segments:
(note that the actual order is reverse, i.e. the text segments starts at the lowest address.)
1. Text(code) segment: the compiled instructions, no write permission, it is read-only and executable.
2. Data segment: global and static variables that are initialized.
3. BSS segment: global and static variables that are zero- uninitialized.
4. Heap: for dynamic memory allocation, it can grow upwards until the program break (BRK). Many allocator uses `mmap` directly instead of growing the heap.
5. Memory mapped region: A large flexible region in the middle of the address space. The libraries like the `.so`s are mapped here.
6. Unmapped regions.
7. Stack: holds the program call frames. Start at the top of the memory address.

## Translation: Virtual -> Physical

Byte-level translation is, obviously, not practical. Instead:
1. we divide virtual address space by fixed-sized chunks, called pages.
2. we devide physical address space into same-sized chunks, called frames.

The size is usually 4KB. It is of practical concern: it should be large enough so that related data is within, but small enough that we do not waste.

The page table converts virtual address to the physical ones.

The page table is a tree, hierarchical data structure. This page table only covers the parts that the virtual memory actually uses, not the entirety (128TB). In a textbook Linux we have
1. (top) PGD: page global directory.
2. PUD: page upper directory.
3. PMD: page middle directory.
4. (bottom) PTE: page table entry.

while in x86 architecture we have corresponding names:
1. (top) PML4: page map level 4.
2. PDPT: page directory pointer table.
3. PD: page directory.
4. (bottom) PT: page table.

the page table is a data structure, the MMU (memory management unit) actually do the table lookup (a full page table walk) and conversion.

The MMU has a thing called TLB (translation lookaside buffer) so that it caches things so that MMU does not have to do real lookup (page table walk) each time (as that means 4 lookups for PGD, PUD, PMD and PTE, each have 9 bits 4*9 = 36 bit plus the actual offset 12 bits).

## On demand paging: Virtual Memory Area

Memory in the page table entires are not always supported with a real physical frame, it is only so when the user actually use it.

One such page is marked in the Virtual Memory Area, if a user tries to access it for real, MMU will return page fault and let the kernel to handle it (really make it linked to a physical frame), the kernel will:
1. First check, if the requested memory is not within VMA, this means it is invalid, segfault here.
2. find a free physical frame.
3. zero-initialize it.
4. create a new page table entry to this frame, and mark the page table entry as present=1.
5. return to the CPU, the CPU will retry the execution.

Note that this procedure does not involve disk, so it is called a minor page fault.

### Demand paging for stack

The stack grows by this mechanism as well, but with more mechanisms:
1. the limit: kernel enforces a max limit (`ulimit -s`) default to 8MB.
2. an additional guard page below the stack max limit, deliberately unmapped. if the stack pointer enters here, this is SIGSEGV

## When there is no free frames.

When the kernel runs out of the free frames, it panics and invoke the `OOM killer` (Out-of-memory killer). It is a linux subsystem that scores each process and its memory consumption, by some heuristics and kill the highest-score ones to reclaim free frames.

The old frames are now written to disk in what is called a `swap space`.

This involves the disk, so it becomes a major page fault.

The old page table that points to the swap space will have its present bit = 0, and the other bits as offset to the swap space (swap-device plus swap offsets)

## Pinned memory

Pinned memory (or page-locked memory) are ones that the kernel cannot do swap.

`mlock` would tell the kernel that this frame cannot be moved or reclaimed.

In things like modern GPU data transfer like the DMA (Direct Memory Access), this can be helpful. We can do this in PyTorch with `pin_memory=True` so that the data transfer between RAM and GPU VRAM can be done with DMA with no CPU involved, and this requires the memory to be pinned (when it is locked).

## Fork and Copy-on-Write

Fork would make a process that shares the same virtual address space.

When fork is done, all the memories are not copied physically, instead the PTE is marked as read-only, only when an actual write happens, the kernel would actually do a copy of the page and start writing. Before that the PTE is pointing to the old frame from the parent process.

Note that the read-only applies to both parent and child. Only after some write, the parent or the child would own a new (fully-copied) writable frame.

## Memory-mapped files

which is using `mmap`

which is also lazy, as in the beginning the kernel just records the file into the VMA.

When loaded, the file data is in the page cache, which is a special collection of physical frames for data on the disk. And then the page table entries points directly to the page cache.

> note that since page cache points data to disk, it can be reclaimed instantly as the disk has the backup. And also the page cache can be special as we can use DMA that transfer data from disk to it, so that CPU is not burned with this. (of course dirty pages need to be written back on disk before reclaiming)

Without `mmap`, the data will be loaded first in the page cache, and then copied into a user space buffer with an `read()`. But when using mmap, the read can be avoided, and so `mmap` would save a copy.

> there is also ways to bypass the page cache using direct I/O, which bypass the entire page cache things, but comes with more constraints, usually that the size needs to be in certain numbers, like 512 bytes or 4KB (page size). It gives more control, but then we need to more things like the caching, alignment, etc.

## Page Reclaim

Page reclaim is about some heuristics on how to evict frames to swap space and get free ones to use.

It can be done with a LRU of recently used frames. The oldest used frames can be evicted.

The bits for that is done by hardware with an access bit on the page table entry.

This means that the LRU list would require to have reverse pointer, of the physical frame pointing to the page table entry.

| kswapd: linux runs a background thread called kswapd that watches free-memory watermarks. When free memory drops below a threshold, kswapd wakes up and starts reclaiming pages before the situation becomes urgent.

Note that how the LRU is done is a sophisticate matter. We can have Multi-generational LRU (MGLRU)

## TLB

The CPU has a limited TLB hierarchy, with small L1 TLBs backed by larger second-level TLBs. Together, they cover a limited number of translations, typically a few hundred to a few thousand, depending on the CPU and page size

Why dense array is faster than hash table in terms of accessing it:
1. for pages, we have less TLB missing rate, with fewer TLB missing rate, it would not be slowed down.
2. for inside the page, the cache line prefetch also make it faster.

### Another way is to use large pages.

x86-64 supports pages with 2 MB sizes, and on many systems 1 GB pages as well.

### Issues with `munmap` on multi-core systems: TLB shootdown

When you want to return the page, on multi-core system you need to notify the other cores.
This is because each core has its own TLB entries. In this case an interupt (inter-processor interupt) to let each core's TLB caches to invalid that specific TLB entry. This is called TLB shootdown.

> Modern CPUs have a hardware mechanism called the APIC (Advanced Programmable Interrupt Controller) that lets one CPU core send an interrupt directly to another. This is an inter-processor interrupt, or IPI. Unlike a regular device interrupt, which is triggered by external hardware (a disk, a network card), an IPI is sent by software running on one core to deliberately interrupt a different core. This makes a cross-core coordination and is costly.

## Cycle for memory access

| Scenario                                                 | What happens                                   |                    Approximate cost |
| -------------------------------------------------------- | ---------------------------------------------- | ----------------------------------: |
| **L1 TLB hit**                                           | Translation found in the L1 TLB                |                      **0–1 cycles** |
| **L1 TLB miss, L2/STLB hit**                             | Translation found in the second-level TLB      |                     **5–10 cycles** |
| **All TLB levels miss; page-table walk hits CPU caches** | Page-table entries are found in CPU caches     |                   **10–100 cycles** |
| **Page-table walk reaches DRAM**                         | Page-table entries must be fetched from memory |                 **100–500+ cycles** |
| **Minor page fault**                                     | Kernel resolves the fault without storage I/O  |             **1,000–30,000 cycles** |
| **Major page fault**                                     | Page must be loaded from SSD or disk           | **3,000,000–3,000,000,000+ cycles** |


## NUMA (Non-Uniform Memory Access)

Physical memory is divided into NUMA nodes, each directly attached to one CPU socket. A CPU can access memory on any node, but local access is noticeably faster than remote access, which must traverse the inter-socket interconnect.

Problems happen you have multiple CPU sockets, each with its own local RAM, but sometimes you will need to access the memory from another socket's RAM, with inter-socket interconnect,
this would be 2 or 3 times longer.

We in virtual memory has no way of controlling easily, and it follows a first-touch policy, the part that is first used will be load to that core's local RAM.

Other than that we have the `mbind` can control which part loads on which.

NUMA-sensitive workloads typically pin threads to specific CPUs using `taskset` or `pthread_setaffinity_np`

## Is system under memory pressure?

`/proc/<pid>/maps` list the VMA.
`pmap -x <pid>` is similar.

`smaps` is maps extended with a full accounting breakdown for every VMA:
- Rss (Resident Set Size): how many kilobytes of that VMA are currently in physical RAM

For the system-wide picture, `/proc/meminfo`, check:
- MemAvailable: the kernel’s estimate of how much can be freed without touching swap,
- Cached: page cache, most of which is reclaimable,
- Dirty and Writeback: pages queued for or actively being written back,
- AnonPages: anonymous pages currently in RAM
- SwapTotal, SwapFree: the swap related fields

For Page faults:
- Minor Page Fault: page fault without any real disk I/O.
- Major Page Fault: actual disk I/O.

`perf stat -e page-faults,major-faults ./your-program`

`vmstat 1` samples every second. The columns to watch are si and so (swap-in and swap-out in KiB per second).

Pressure Stall Information (PSI) at `/proc/pressure/memory`: it reports the fraction of time tasks spent stalled waiting for memory.

For the TLB:
`perf stat -e dTLB-load-misses,dTLB-store-misses,iTLB-load-misses ./your-program`

`dTLB-load-misses` and `dTLB-store-misses` count data TLB misses on loads and stores respectively. `iTLB-load-misses` tracks instruction TLB misses, which matters when the code is large.

NUMA related:
- `numactl --hardware`: shows NUMA topology.
- `numastat -p <pid>` shows where a process’s pages actually live

## Optimization for memory access in programming

Tips for software side: Design user program with these in mind:

1. less access of memory.
2. less pages involved.
3. less actual translation of page table walk.
4. less TLB entries needed.

sometimes we need to think about the algorithm (for the logical things we need to do),
Sometimes we need to think about the data structure,
sometimes we need think about the struct (padding).

In fact there is an interesting blog [slowest add: Data Access Patterns That Makes Your CPU Really Angry](https://blog.weineng.me/posts/slowest_add/), which it does not seek to optimize the task of summing over an array, rather it exploits the memory access mechanism to find a deliberately slowest way to do this task, it is an interesting read.

## Reference

[Virtual Memory From First Principles, Abhinav Upadhyay](https://blog.codingconfessions.com/p/virtual-memory?utm_source=bonobopress&utm_medium=newsletter&utm_campaign=2319)
