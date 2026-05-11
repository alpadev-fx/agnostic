---
paths:
  - "**/*.go"
---
# Go Backend — Clean Architecture

## Layer Structure (typical)
```
cmd/<binary>/main.go              # entry points (one per binary)
internal/
  adapters/
    http/handlers/                # HTTP — Echo/Fiber/chi handlers
    http/middleware/              # auth, CORS, rate limit
    http/routes/                  # route registration
    apis/                         # external HTTP clients (Stripe, Plaid, etc.)
  domain/
    entities/                     # data structs (often GORM/sqlc models)
    repository/                   # data access INTERFACES
  usecase/                        # business logic (orchestration)
  infrastructure/                 # platform: DB pool, Redis, queues
  features/<feature>/             # vertical slices (optional)
    delivery/http/
    usecase/
    repository/
    entities/
```

## Layer Rules
- **Handlers**: thin — parse/validate input, call use case, return response. NO business logic.
- **Use cases**: orchestrate. Accept interfaces, return concrete types.
- **Repositories**: data access INTERFACES live in domain; IMPLs in repository/infrastructure.
- **Entities**: data containers. No business logic. No HTTP types.
- **Dependencies flow inward**: handlers → usecases → repositories. Never the reverse.

## DI
- Manual DI in `main.go` — wire structs explicitly
- No reflection-based DI containers (Wire is OK for code-gen)
- Constructor injection: `NewX(deps...) *X`

## Errors
- Centralize error types in `internal/errors/` (or similar)
- Domain errors vs HTTP errors — different types, mapped at handler boundary
- `errors.Is`/`errors.As` for sentinel matching; wrap with `fmt.Errorf("... %w", err)`
- Never `panic()` in production code

## Money
- `int64` cents. Never `float64`.
- Decimal package only if multi-currency math gets complex.

## Validation
- Use a validator library (go-playground/validator) — custom tags for domain rules
- Validate request structs at handler entry, not deeper

## Anti-patterns
- Business logic in handlers
- SQL in handlers or use cases (must go through repository)
- Returning interface types from concrete constructors (return concrete, accept interface)
- Global state (use struct fields instead)
