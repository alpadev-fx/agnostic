---
paths:
  - "**/*.py"
---
# Python — Conventions

## Project Layout (typical FastAPI/Flask)
```
src/app/
  api/              # routes / endpoints
  schemas/          # Pydantic models (request/response)
  services/         # business logic
  repositories/     # data access (SQLAlchemy)
  models/           # ORM entities
  middleware/       # auth, error handling
  core/             # config, db pool, settings
  utils/            # pure helpers
```

## Style
- PEP 8 + ruff/black formatting
- Type hints on EVERY function signature (`-> None` if no return)
- `mypy --strict` in CI
- f-strings (not `.format()` or `%`)
- pathlib over os.path

## Pydantic / Validation
- Pydantic v2 models for request/response
- Validate at boundary; trust internal calls
- Use `model_dump()` not `.dict()` (v1 API)

## ORM
- SQLAlchemy 2.x with `async` if endpoints are async
- Declarative base, type-annotated columns
- Parameterized queries always (default with ORM)
- Migrations via Alembic

## Async
- FastAPI: prefer `async def` for IO-bound endpoints
- Use `httpx.AsyncClient` not `requests`
- Use `asyncpg` or `psycopg` (3.x) async drivers
- `asyncio.gather()` for parallel awaits

## Errors
- Custom exception classes per domain
- Global exception handler in FastAPI (`@app.exception_handler`)
- Never leak stack traces externally

## Logging
- `structlog` for structured JSON logs
- `logging` module config in `core/logging.py`
- No `print()` in production code

## Money
- `Decimal` from `decimal` module (with context precision set)
- NEVER `float` for money

## Testing
- pytest + pytest-asyncio
- Fixtures over class-based setup
- Auto-mock I/O in unit tests; integration tests use real DB (testcontainers)

## Anti-patterns
- `print()` for debugging committed
- Mutable default args (`def f(x=[])`)
- Catching `Exception` broadly (catch specific)
- Threading + asyncio mixed without `loop.run_in_executor`
