---
description: Notes on how to code and my lessons
---

# How to code

- Properly name things. It is of utmost importance, naming it right means thinking is right.
    As confucius famously noted on the most important things of all things, "It must be to rectify names" (“必也正名乎”, 《论语·子路第十三》).
- Use goto, it is not bad. Use it when you see fit.
- The program can and should panic at certain points. Panic is not bad. Panic when you see fit.
    "More panics (at proper points)" -> ultimately make the program healthier and live longer.
- OOP is trash.
- Write straightforward code. Do not abstract, let alone over-abstract. Whenever you feel like abstracting, pause and refrain, it is an illusion and not a good idea.
- Write straightforward code. Do not over-think about performance.
- Straightforward code would make abstraction decisions and performance optimization easy.
- Think about code by modelling the primary resource that the task needs.
    When say, CPU is the primary resource, model your code around CPU usage.
- Event-driven code is hard to analyze. Use while loops and model the CPU instead.

## reference

- A Possible Future of Software Development, Sean Parent, Adobe Systems, Google Tech Talks 2007
https://www.youtube.com/watch?v=4moyKUHApq4
- How To Avoid Needy Software, Jonathan Marler, Tuple, Software You Can Love Vancouver 2026
