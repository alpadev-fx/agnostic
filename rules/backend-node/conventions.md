---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# Node.js / TypeScript — Conventions

## Project Layout (typical Express/Fastify/Nest backend)
```
src/
  routes/            # HTTP route handlers
  controllers/       # Or merge with routes
  services/          # Business logic
  repositories/      # Data access (Prisma/TypeORM/Drizzle)
  middleware/        # auth, CORS, error handling, rate limit
  schemas/           # Zod / TypeBox / class-validator schemas
  config/            # env config (load once at startup)
  utils/             # pure helpers
```

## TypeScript
- `strict: true` always
- No `any` — use `unknown` if shape is truly unknown
- Use `type` for unions/intersections, `interface` for extensible objects
- Don't fight the inference — let TS infer where it can

## Validation
- Zod or TypeBox for runtime validation at boundaries
- Schema is the source of truth: derive types from schema (`z.infer<typeof X>`)
- Validate at: HTTP body/query/params, queue message, file upload, external API response

## ORM
- Prisma: schema-first, type-safe by default
- Drizzle: type-first, closer to SQL
- TypeORM: only if you need legacy patterns
- All queries parameterized (default behavior — never use raw `$queryRaw` with interpolation)

## Async
- `async/await` always — never callback style
- Don't mix `.then()` and `await`
- Always handle rejection on top-level async (process.on('unhandledRejection'))

## Errors
- Custom error classes extending `Error` with `name` and `code` fields
- Central error handler middleware (Express) or hook (Fastify)
- Never leak stack traces to clients

## Logging
- Pino for structured logs (fast)
- Log level per env (info in prod, debug in dev)
- No PII or secrets in logs

## Money
- Use BigInt for cents, or `decimal.js` for arbitrary precision
- NEVER `Number` for money (floating point imprecision)

## Anti-patterns
- `any` to silence TS errors
- Mutable global state
- `JSON.parse` on user input without try/catch
- Synchronous file IO in request path
