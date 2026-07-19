---
paths:
  - "**/*.s"
  - "**/*.S"
  - "**/*.asm"
---
# Assembly — Conventions

## Targets & Syntax
- **x86-64**: AT&T syntax with GAS (`.s`), Intel syntax with NASM (`.asm`) — never mix; state which at file top
- **ARM64 (AArch64)**: GAS syntax — the dialect for Raspberry Pi 3/4/5 (64-bit OS)
- **ARM32 (A32/T32)**: legacy Pi models, many Orange Pi images
- `.S` (capital) = run through C preprocessor — use for shared constants via `#include`

## File Discipline
```asm
// func.S — what this file provides, ABI notes, clobbers
    .text
    .global my_func
    .type   my_func, %function   // ELF: mark symbol type
my_func:
    // prologue
    ...
    ret
    .size   my_func, . - my_func
```
- One logical routine per section; document register usage contract in header comment
- Constants in `.rodata`, zeroed buffers in `.bss`, initialized data in `.data`

## Calling Conventions (memorize per target)
| | args | return | callee-saved |
|---|---|---|---|
| x86-64 SysV | rdi rsi rdx rcx r8 r9 | rax | rbx rbp r12–r15 |
| AArch64 | x0–x7 | x0 | x19–x28, sp |
| ARM32 AAPCS | r0–r3 | r0 | r4–r11 |

- Stack alignment: 16 bytes at call sites (x86-64 SysV and AArch64) — misalignment = SIGSEGV in libc calls
- Preserve callee-saved registers you touch; document clobbers for inline asm

## Interop with C
- Prefer standalone `.S` files over inline asm — testable, readable, no constraint syntax
- Inline asm (GCC/Clang extended): every input/output/clobber listed; `"memory"` clobber when touching memory the compiler tracks
- Match C prototypes exactly; test asm routines from C unit tests

## Correctness Workflow
1. Write the routine in C first; compile with `-O2 -S` and study the compiler's output
2. Hand-write only after the C version is correct and profiled as hot
3. Single-step in GDB (`layout asm`, `si`, `info registers`) for first bring-up
4. Diff behavior against the C reference on randomized inputs

## Reading Disassembly (core expert skill)
- `objdump -d --no-show-raw-insn`, `gdb disassemble`, Compiler Explorer (godbolt.org)
- Learn what `-O2` does to your C: inlining, vectorization, branch layout — this teaches more asm than writing it

## Performance
- Profile first (`perf stat`, `perf record`) — modern compilers beat hand asm on most scalar code
- Hand asm earns its keep in: SIMD kernels (NEON on Pi, SSE/AVX on x86), crypto, tight interrupt paths
- Know your microarch: instruction latency/throughput tables, branch predictor behavior, cache line = 64B

## Anti-patterns
- Rewriting whole functions in asm when intrinsics (`<arm_neon.h>`, `<immintrin.h>`) get 95% there portably
- Untested asm — every routine gets a C-driven test harness
- Ignoring the ABI "because it's my code" — signal handlers and callbacks will find you
- Magic numbers without `.equ`/`#define` names
- Assuming ARM32 idioms on AArch64 (no ldm/stm, different shifter, w/x register views)
