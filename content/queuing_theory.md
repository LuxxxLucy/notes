---
description: Notes on queuing theory, Kendall notation and the basic results used in system performance analysis.
---

# Queuing Theory

General Theory on queuing theory, the Kendall notation and how it can be used to analyze the system.



## Notation

| Symbol | Meaning | Unit |
| ------ | ------- | ---- |
| $\lambda$ | request arrival rate | req/s |
| $\mu$ | service rate of one server, $1/\tau$ | req/s |
| $\tau$ | mean service time of one request, $1/\mu$ | s |
| $c$ | number of servers | |
| $a$ | offered load, $\lambda/\mu$; mean number of busy servers | |
| $\rho$ | utilization rate $\lambda/(c\mu) = a/c$; fraction of time server capacity is occupied | |
| $L$ | mean number of requests in the system (waiting + in service) | |
| $W$ | mean time in the system (response time = waiting + service) | s |
| $W_q$ | mean time waiting in the queue before service starts, $W - \tau$ | s |
| $P(\text{wait})$ | probability an arriving request finds all $c$ servers busy | |
| $c_a$ | coefficient of variation (std / mean) of inter-arrival times | |
| $c_s$ | coefficient of variation of service times | |

### Kendall Denotation

Kendall denotation is a well-established way to define the queuing models in the form of `A/S/C`

|Symbol| Meaning|
| ---- | ------ |
|A| Inter-arrival distribution (e.g., M = Poisson/exponential) |
|S| Service-time distribution (e.g., M = exponential, D = deterministic, G = general) |
|C| Number of servers/service-providers (concurrent) |

Examples:
- M/M/1: Poisson arrivals, exponential service, 1 server.
- M/M/c: same, but `c` parallel servers.
- G/G/1: “anything goes General” arrivals and service times.

## Little's Law

$$L = \lambda W$$

Say you run a service with arrival rate $\lambda = 1000$ req/s and
average end-to-end latency $W = 0.050$ s, then the average number of requests inside the system (queued + running) is:

$L = \lambda W = 1000 \times 0.050 = 50$

That's often directly useful:

- If your service uses one connection per request, you will need 50 connections.
- If your service has a max in-flight limit of 30 ongoing, you will need to low down to ~600 req/s.

## Utilization rate $\rho$ and the stability condition

For $c$ identical servers with service rate $\mu$, then the utilization rate $\rho$ is

$$\rho = \frac{\lambda}{c\mu}$$

$\rho$ shall be no greater than 1. Otherwise it would indicate degeneration, we say $\rho \gt 1$ as unstable.

Say a single-threaded worker (number of servers $c = 1$) processes requests with mean service time $\tau = 10$ ms, so service rate $\mu = 1/\tau = 100$ req/s.

- If arrival rate $\lambda = 80$ req/s, then utilization $\rho = 0.8$ (stable)
- If arrival rate $\lambda$ rises to $110$ req/s, then utilization $\rho = 1.1$ (unstable)

## M/M/1: the simplest model

For M/M/1, the response time $W$ is:

$$W = \frac{1}{\mu - \lambda}$$

and the queue wait time $W_q$ is:

$$W_q = W - \frac{1}{\mu} = W - \tau$$

Say an API server with one worker thread has mean service time $\tau = 10$ ms, service rate $\mu = 100$ req/s, and arrival rate $\lambda = 80$ req/s:

- response time $W = 1/(100-80) = 1/20 = 0.05$ s = 50 ms
- queue wait time $W_q = W - \tau = 50 - 10 = 40$ ms
- by Little's Law, requests in system $L = \lambda W = 80 \times 0.05 = 4$

Even at utilization $\rho = 0.8$, response time $W = 5\tau$, because queue wait time $W_q = 4\tau$, this means a lot of time is not the actual service time, but the queuing wait.

## M/M/c (Erlang-C):


With more servers, we can reduce waiting.
For an M/M/c queue, the wait probability $P(\text{wait})$ is given by the Erlang-C formula.

Say we start from the single process worker to a thread pool / worker pool.
Suppose:

- arrival rate $\lambda = 200$ req/s
- mean service time $\tau = 12.5$ ms per worker $\Rightarrow$ service rate $\mu = 80$ req/s per worker

In case of number of servers $c = 3$,
, utilization will be $\rho = 200/(3 \times 80) = 0.833$, offered load $a = 200/80 = 2.5$

The wait probability $P(\text{wait})$ is the steady-state probability that all $c$ servers are busy:

$$P(\text{wait}) = \frac{\dfrac{a^c}{c!}\cdot\dfrac{1}{1-\rho}}{\displaystyle\sum_{k=0}^{c-1}\frac{a^k}{k!} + \frac{a^c}{c!}\cdot\frac{1}{1-\rho}}$$

- For $n < c$ requests in system, state $n$ has unnormalized probability $a^n/n!$ (departure rate grows as $n\mu$).
- For $n \geq c$, departure rate stays at $c\mu$, so state probabilities form a geometric series with ratio $\rho$; its sum is $\frac{a^c}{c!}\cdot\frac{1}{1-\rho}$.

Then queue wait time $W_q = P(\text{wait}) / (c\mu - \lambda)$ and response time $W = W_q + 1/\mu$.

Say we have the offered load $a = 2.5$, when we have $c = 3$ servers :

- head: $\sum_{k=0}^{2} a^k/k! = 1 + 2.5 + 3.125 = 6.625$
- tail: $(2.5^3/3!) / (1 - 0.833) = 2.604 / 0.167 = 15.625$
- wait probability $P(\text{wait}) = 15.625 / (6.625 + 15.625) = 0.70$
- queue wait time $W_q = 0.70 / (240 - 200) = 17.6$ ms
- response time $W = 17.6 + 12.5 = 30.1$ ms

In case of number of servers $c = 4$:

- wait probability $P(\text{wait}) \approx 0.32$
- queue wait time $W_q \approx 2.7$ ms
- response time $W \approx 15.2$ ms

Interpretation: Adding one worker (number of servers $c$: 3 → 4) did not just increase capacity by 33%, it cut response time $W$ roughly in half.
This is a recurring theme in real services: once utilization $\rho$ is near 1, small changes in number of servers $c$ can create huge changes in response time $W$.

## Variability matters (a lot): the VUT / Kingman approximation

Real workloads are rarely "memoryless exponential everything." Variability in arrivals (bursts, high arrival variation $c_a$) and service (slow queries, GC, cache misses, high service variation $c_s$) causes tail latency.

A common, practical approximation for G/G/1 is Kingman's formula (often called the VUT equation):

$$\mathbb{E}[W_q] \approx \left(\frac{\rho}{1-\rho}\right)\left(\frac{c_a^2 + c_s^2}{2}\right)\tau$$

Example: same mean service time, different variability

Let:

- utilization $\rho = 0.8$
- mean service time $\tau = 10$ ms
- arrivals roughly Poisson $\Rightarrow$ arrival variation $c_a \approx 1$

Scenario 1: highly variable service (service variation $c_s = 1$)

- queue wait time $\mathbb{E}[W_q] \approx (0.8/0.2) \times ((1^2+1^2)/2) \times 10 \text{ ms}$
- $= 4 \times 1 \times 10 = 40$ ms

Scenario 2: more predictable service (service variation $c_s = 0.2$)

- queue wait time $\mathbb{E}[W_q] \approx 4 \times ((1 + 0.04)/2) \times 10$
- $= 4 \times 0.52 \times 10 = 20.8$ ms

Same utilization $\rho$ and mean service time $\tau$, but halving service variation $c_s$ roughly halves queue wait time $W_q$.

Interpretation: performance work that reduces service variation $c_s$ (caching, eliminating stop-the-world pauses, bounding query time, isolating noisy neighbors) often improves tail latency more than shaving a millisecond off mean service time $\tau$.

## Queues in Real Computer Systems

### Identify the queues in the boundaries

Common "queue boundaries" include:

- Load balancer backlog (requests waiting to be accepted)
- Thread pool queue (waiting for a worker)
- DB connection pool (waiting for a connection)
- Downstream service (RPCs queued behind other callers)
- Disk / network (I/O queues)

A key practice: apply Little's Law *per boundary* to estimate requests in system $L$ at each one and identify bottlenecks.

### Bottleneck for end to end latency

If a request processing must go through multiple queues (a small queueing network), the stage with the highest utilization rate $\rho$ tends to dominate queue wait time $W_q$.

### Queue discipline changes p99 behavior

FIFO is fair-ish, but it lets one slow job delay many fast ones. Alternatives:

- Priority-based: protect latency-sensitive traffic (but risk starving background jobs).
- Shortest-job-first / SRPT: improves mean latency; may be unfair without safeguards.
- Processor sharing: approximates time-slicing, common in some network and CPU models.

## Practical Modeling Workflow

1. Pick the boundary you're modeling (wherever you introduced a queue).
2. Measure:
    - arrival rate $\lambda$ into that boundary
    - mean service time $\tau$
    - variability proxies for arrival variation $c_a$ and service variation $c_s$: p50/p95/p99 service times; burstiness of arrivals
3. Compute utilization $\rho$ and check.
4. Use a simple model first:
    - M/M/1 or M/M/c for "first-order" capacity decisions.
    - Kingman (G/G/1) when variability is clearly more important.
5. Validate against production (does predicted requests in system $L$ match observed in-flight? does predicted knee match when p99 explodes?).

## Limitations for the simple modelling

- Non-stationarity: diurnal traffic, deployments, incident conditions.
- Correlated arrivals: synchronized retries, fan-out bursts, cache stampedes.
- Heavy-tailed service times: long-tail queries or rare slow paths can dominate p99/p999.
- Finite buffers and backpressure: real queues drop, throttle, or shed load.
- Retries change arrival rate $\lambda$: a timeout often creates *more* work, not less.

Queueing theory still helps here, but you often combine it with measurement, tracing, and load testing.

## Takeaway

- Little's Law turns response time $W$ and arrival rate $\lambda$ into living requests in system $L$: $L=\lambda W$.
- Utilization rate $\rho$ indicates the potential failure part: near $\rho = 1$, latency explode.
- Variability: reducing arrival variation $c_a$ and service variation $c_s$ can be more valuable than reducing mean service time $\tau$.
- Adding servers $c$ can cut response time $W$ disproportionately (Erlang-C intuition) while utilization rate is high.

## Referenecs/Reading

- [Queuing theory notes, Hongyu](https://hongyu.nl/queuing/) Main reference, a lot is from this blog.
- [Queuing Theory, Wikipedia](https://en.wikipedia.org/wiki/Queueing_theory)
- [Little's law, Wikipedia](https://en.wikipedia.org/wiki/Little%27s_law)
- [M/M/c queue, Wikipedia](https://en.wikipedia.org/wiki/M/M/c_queue)
- [Kingman's formula, Wikipedia](https://en.wikipedia.org/wiki/Kingman%27s_formula)
- [SREcon24 Americas, System Performance and Queuing](https://www.youtube.com/watch?v=3at6ijBU2ug)
- [LISA17, Queueing Theory in Practice: Performance Modeling](https://www.youtube.com/watch?v=Hda5tMrLJqc)
- Harchol-Balter, M. (2013). *Performance Modeling and Design of Computer Systems: Queueing Theory in Action*. Cambridge University Press.
- Gross, D., & Harris, C. M. (1998). *Fundamentals of Queuing Theory*. John Wiley & Sons, Inc.
- Kleinrock, L. (1975). *Queueing Systems, Volume 1: Theory*. John Wiley & Sons, Inc.
- Sutton, C., & Jordan, M. I. (2010). [Bayesian inference for queueing networks and modeling of internet services](https://arxiv.org/abs/1001.3355).

