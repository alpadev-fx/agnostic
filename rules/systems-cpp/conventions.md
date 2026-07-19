---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.hpp"
  - "**/*.hh"
  - "**/CMakeLists.txt"
---
# C++ — Conventions

## Standard & Toolchain
- C++20 baseline (`-std=c++20`); C++17 minimum
- `-Wall -Wextra -Wpedantic -Werror`; debug builds add ASan/UBSan
- CMake ≥ 3.20, targets-based (`target_link_libraries`, `target_include_directories`) — no global `include_directories`
- `clang-format` (checked in `.clang-format`) + `clang-tidy` in CI
- Follow the C++ Core Guidelines; cite rule IDs (e.g. `F.15`) in reviews

## Ownership & Lifetime (the core discipline)
- RAII for every resource — no naked `new`/`delete` in application code
- `std::unique_ptr` default owner; `std::shared_ptr` only for genuinely shared lifetime
- Raw pointer / reference = non-owning observer, never freed by holder
- `std::span` / `std::string_view` for non-owning ranges — mind dangling: never store a view to a temporary
- Rule of Zero: let members manage resources; if you write one of dtor/copy/move, write or delete all five

## API Style
```cpp
class Connection {
public:
    static std::expected<Connection, Error> open(const Config& cfg); // C++23, or tl::expected
    Connection(const Connection&) = delete;             // move-only resource
    Connection(Connection&&) noexcept = default;
    ~Connection();                                       // RAII close
private:
    explicit Connection(int fd);
    int fd_;
};
```
- `explicit` single-arg constructors
- Pass: cheap/sink → by value; read-only → `const&`; out → return value (RVO), not out-params
- `[[nodiscard]]` on functions whose return must be checked
- `noexcept` on move ctors/assignment and anything the compiler should optimize around

## Errors
- Exceptions for exceptional, non-local failures; `std::expected`/`std::optional` for expected failures on hot paths
- Never throw from destructors
- Catch by `const&`

## Modern Idioms
- `auto` when the type is obvious or nameable only awkwardly; spell it out at API boundaries
- Range-for + `<ranges>`/`<algorithm>` over index loops
- `constexpr`/`consteval` for compile-time work; `if constexpr` over SFINAE; concepts over `enable_if`
- `enum class` always; `std::variant` + `std::visit` over type-tag unions
- Structured bindings for pair/tuple returns

## Concurrency
- `std::jthread` (auto-join) over `std::thread`
- Data + its mutex live together in one class; lock via `std::scoped_lock`
- `std::atomic` for flags/counters; default `seq_cst` until profiled
- Prefer message passing / task queues over shared mutable state

## Performance
- Measure first (perf, VTune, Tracy) — no speculative optimization
- Reserve vectors when size known; `emplace_back` over `push_back(T(...))`
- Understand move vs copy in hot paths; watch accidental copies in lambda captures and range-for (`for (const auto& x : xs)`)
- Cache-friendly layout (SoA vs AoS) only where profiling justifies

## Testing
- GoogleTest or Catch2; test via public API
- Death tests for contract violations; fuzz parsers with libFuzzer
- Sanitizer jobs (ASan/UBSan/TSan) as separate CI matrix entries

## Anti-patterns
- `new`/`delete` outside smart-pointer factories
- `std::endl` in loops (flushes) — use `'\n'`
- Inheritance for code reuse — prefer composition; virtual only at true polymorphic boundaries
- `const_cast`, C-style casts — `static_cast`/`reinterpret_cast` explicit and rare
- Header-wide `using namespace std;`
- Premature templates — write concrete code first, generalize on second use
