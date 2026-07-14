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

### Tips for software side: Design user program with these in mind:

1. less access of memory.
2. less pages involved.
3. less actual translation of page table walk.
3. less TLB entries needed.

sometimes we need to think about the algorithm (for the logical things we need to do),
Sometimes we need to think about the data structure,
sometimes we need think about the struct (padding).

