---
description: Notes on E-graph and Equality Saturation
---

# E-graph and Equality Saturation.

## e-graph

An e-graph is a data structure that stores a set of terms together with an equivalence relation over them.

It is a set of e-classes; each e-class is a set of e-nodes that are known to be equal, representing equivalence.

An e-node is an operator plus a list of child e-classes, so one e-node compactly stands for many terms.

For example we can define 4 = 2 * 2 = 2 * (1 + 1), even though they are represented as different AST, we can define them over the same e-class.

The main data structure it uses is a union-find structure.

By doing this, we can use a compact data structure to represent combinatorially exploded space of AST.

## equality saturation (EqSat)

Equality saturation is the optimization method built on the e-graph.

Normal optimization applies a sequential chain of steps (`rewrite` steps), but
this makes an ordering issue as we can have a list of steps that might not lead us
to the optimal state, which is called the `phase-ordering` problem.

Instead of applying rewrite rules destructively in sequential order,
e-graph provides a way to represent all these possibilities.

Two step algorithm of equality saturation:
1. grow the e-graph until it is exhausted (saturation) or until some computation budget. And then,
2. perform search (`extraction`) on the e-graph, extract one that is optimal.

Reference:
[*Equality Saturation: A New Approach to Optimization*](https://arxiv.org/abs/1012.1802), POPL 2009.

## egg

egg is an e-graph and equality saturation library in Rust, and is highly efficient.

Its main contribution is the introduction of delayed merge: invariant maintenance is deferred and batched, which the paper calls rebuilding.
It is a way to cleverly solve an implementation issue so that now EqSat is made more scalable and efficient.

The delayed merge also enables *e-matching* over a stable snapshot: rules are matched against the e-graph as it was at the start of the iteration, and all their results applied at the end, which makes an iteration deterministic and parallelizable.

Reference:

[*egg: Fast and Extensible Equality Saturation*](https://arxiv.org/abs/2004.03082), POPL 2021.

## good application.

- floating-point (Herbie)
- tensor graph optimization (TASO / Tensat)

TODO: I should elaborate them and add more applications, there are many interesting works
