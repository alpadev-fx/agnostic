---
paths:
  - "**/*.c"
  - "**/*.h"
---
# C — Conventions

## Standard & Toolchain
- C17 baseline (`-std=c17`); C11 minimum for new code
- Compile with `-Wall -Wextra -Wpedantic -Werror` — zero warnings policy
- Debug builds: `-g -fsanitize=address,undefined` (ASan + UBSan)
- Release: `-O2` (or `-Os` for embedded targets)
- Static analysis: `clang-tidy` + `cppcheck` in CI

## Project Layout
```
project/
  include/project/   # public headers (installed API)
  src/               # .c files + private headers
  tests/             # unit tests (Unity/CMocka/Criterion)
  Makefile | CMakeLists.txt
```

## Headers
- Include guards or `#pragma once` (guards are more portable)
- Every header self-contained: compiles alone, includes what it uses
- Forward-declare structs in headers; define in .c for opaque types (encapsulation)
- Public API: `project_module_verb()` naming; opaque handle pattern:
```c
typedef struct buffer buffer_t;          /* header — opaque */
buffer_t *buffer_create(size_t cap);
void buffer_destroy(buffer_t *b);
```

## Memory
- Every `malloc` has one owner and one clearly-documented `free` path
- Check every allocation: `if (!p) return ERR_NOMEM;`
- `goto cleanup` pattern for multi-resource error paths (idiomatic, not evil):
```c
int f(void) {
    int rc = -1;
    char *a = malloc(N);
    if (!a) goto out;
    FILE *fp = fopen(path, "r");
    if (!fp) goto free_a;
    /* work */
    rc = 0;
    fclose(fp);
free_a:
    free(a);
out:
    return rc;
}
```
- `calloc` over `malloc`+`memset`; watch for `n * size` overflow — `calloc` checks, `malloc(n * size)` does not
- Set pointers to NULL after free in long-lived structs (defends against double-free)

## Strings & Buffers
- `snprintf` always — never `sprintf`, `strcpy`, `strcat`, `gets`
- `strncpy` does NOT null-terminate on truncation — prefer `snprintf(dst, sz, "%s", src)`
- Track length explicitly; C strings are a liability at boundaries

## Errors
- Return codes (0 success, negative errno-style failure) or result-out-parameter
- Consistent per project — pick one convention, document it
- `errno` is per-thread but clobbered easily: save immediately after the failing call

## Undefined Behavior (top killers)
- Signed integer overflow — use `unsigned` for wraparound math or check before op
- Out-of-bounds access — sanitizers catch in test, not prod
- Strict aliasing violations — use `memcpy` for type punning, not pointer casts
- Uninitialized reads — `-Wuninitialized`, MSan for the deep cases
- NULL deref, use-after-free, data races (see C11 `<stdatomic.h>` / pthreads discipline)

## Concurrency
- pthreads: every shared mutable object names its lock in a comment
- Lock ordering documented to prevent deadlock
- C11 atomics for flags/counters; `memory_order_seq_cst` until profiling says otherwise

## Testing
- Unity or CMocka for unit tests; test the public header API
- Fuzz parsers/decoders with libFuzzer or AFL++
- Valgrind (`--leak-check=full`) or ASan run in CI — leaks are failures

## Anti-patterns
- Casting `malloc` return (hides missing `<stdlib.h>` in C)
- `#define` for typed constants — use `enum` or `static const`
- Function-like macros with side-effect args (`MAX(i++, j)`)
- Global mutable state without accessor + lock
- Ignoring return values of `read`/`write`/`fwrite`
