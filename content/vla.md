---
description: Notes on vision-language-action models, the pi-series: π0, π0-FAST, π0.5, π0.6:
---

# VLA

## π0

The basis of Vision Embedding + Language prefix backbone + action expert, as the integrated system of V + L + A.
- V+L is from PaliGemma, 3B
- action expert is new, 300M.

For each decision step, it receive the vision (images from cameras), robot state and instruction, and output an action trajectory (of some fixed size).
This then becomes a smooth action that the robot would then execute.

The action are not binned/discretized as it is not done by autoregressive next-token prediction based methods.

RT-2 and OpenVLA are based on autoregressive methods.

## π0-FAST

π0 had strong action quality, but flow-matching training was expensive.

π0-FAST tries to use an autoregressive action export, but without the naive action binning, which is too coarse grained for precise action control.

FAST: Frequency-space Action Sequence Tokenization
it solves:
- training efficiency,
- action discretization quality.

## π0.5

Introduce staged-training, and the task decomposition.

Essentially it tries to model the semantic part and the motor part separately.
Predict a task, and then the action expert generate the low level actions.

It uses a two-stage training,
stage 1: autoregressive pretraining.
stage 2: continuous posttraining.

## π0.6 and π0.6*

Further scaling:
- larger VLM: change to a larger 4B VLM base (Gemma 3)
- larger action expert. (to 860M)
- more data
- Knowledge Insulation: meaning the action export loss does not effect the VLM representation learning.
- RL with roll-out.
    - RECAP: Reinforcement Learning with Experience and Corrections via Advantage-conditioned Policies.
