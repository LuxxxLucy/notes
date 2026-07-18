---
description: Notes on TCP, the basics of the transport protocol.
---

# TCP

notes on TCP

## Main performance lession: GRO and instruction miss

From my personal experience,
The TCP entire stack is rather very complicated and CPU-heavy, and in some way it suffers from the issue of the instruction cache miss, in this way from the perspective of the system, the only way to improve this is to **reduce the number of times of calling into this entire TCP stack**.

From this perspective it is easier  to see why GRO, even it is a software done GRO, would bring huge improvement to the relief of the CPU.

Also I recommend enable `TCP_NODELAY`, which disables the Nagle's algorithm which keeps buffering small payload, and only send a packet that is long enough.

## Basics

- `iss`: Initial Send Sequence number
- `irs` — Initial Receive Sequence number
- `snd_una`: sending unacknowledged

**Sending side**:
```
snd_una        snd_nxt        snd_una + snd_wnd
          |              |                 |
   <------+--------------+-----------------+------>
   acked  | in flight    | usable window   | can't send yet
          |  (unacked)   | (not yet sent)  |
```

**Receive side**:
```

        rcv_nxt                         rcv_nxt + rcv_wnd
          |                                   |
   <------+-----------------+-----------------+------>
   rcv'd  |         acceptable window         | beyond window
   & acked|   ┌─────┐                         | (drop / trim)
          |   │ OOO │  ← buffered in          |
          |   └─────┘    reassembly queue     |
          ↑   ↑     ↑                         ↑
       left  hole  out-of-order data      right edge
       edge        (above the hole)
```

## Fast path

Comes from an Jacobson's **header prediction** optimization (circa 1990).
Fast path: when in a particular state (established state, as determined by a header-prediction function as below), the actual operation is minimal, and we can do this with a separate fast path that is faster and go through less code.

The prediction function is
```c
if (tp->t_state == TCPS_ESTABLISHED &&
    (tiflags & (TH_SYN|TH_FIN|TH_RST|TH_URG|TH_ACK)) == TH_ACK &&
    (no timestamp, or timestamp not older than ts_recent) &&
    ti->ti_seq == tp->rcv_nxt &&          /* exactly the next byte expected */
    tiwin && tiwin == tp->snd_wnd &&      /* peer's window unchanged, nonzero */
    tp->snd_nxt == tp->snd_max)           /* we're not retransmitting */
```

when the TCP is in established state, the most likely case is that it is either
1. in recv side, an in-order data packet: advance `rcv_nxt`, append to socket buffer, schedule a (delayed) ack.
2. in sending side, a pure valid ack packet: advance the `snd_una`, send more (advance `snd_nxt` towards `snd_una+snd_wnd` (usable window))
in this two case, we need only simple operations, a lot of things are not done (as in the full state machine, the rest of `tcp_input`):

- connection setup/teardown: SYN, FIN, RST, and the full state-machine transitions
- out-of-order data → insert into the reassembly queue, trim overlaps
- duplicate ACKs → trigger fast retransmit / fast recovery and the congestion-control logic
- window updates, zero/persist windows, urgent data
- timestamp validation, ACKs for unsent data, and other edge cases

## Duplicate ACKs → fast retransmit → fast recovery

### Fast Retransmission
Typically after 3 or 4 duplicate ACKs, the sender will need to start retransmitting again the packet at the recv' sides' `rcv_nxt`

Note that window-updating ACK is not counted as duplicate ACK.

## Congestion Control

- Loss-based: Reno, CUBIC
- Delay-based: Vegas, FAST
- Model-based

### Loss-based:

**Reno**: additive increase, and multiplicative decrease (halve cwnd on loss). This is the default textbook example. A tiny loss could make it quite bad.

**CUBIC**: Linux default since 2006 (RFC 9438). It grows the window as a cubic function of time since the last loss, independent of RTT. It reduces by 30%, so it is more aggressive than Reno.

### model based

**BBR**: It uses measurements of delivery rate, round-trip time, and loss to build an explicit model.

It might get high goodput at the cost of a lot of resending.

### Datacenter CC

see more in [datacenter.md](./datacenter.md)
