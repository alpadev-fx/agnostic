---
allowed-tools: Bash, Read, Edit, Write, Grep, Glob
argument-hint: [METHOD /path description]
description: Add a new HTTP/API endpoint with handler, business logic, and tests
model: claude-sonnet-4-6
---
Add API endpoint: $ARGUMENTS

1. **Determine placement:**
   - Read `.claude/rules/` for stack-specific conventions
   - Find where existing endpoints live (handlers / routes / controllers)
   - Match the pattern of similar endpoints

2. **Define request/response contract:**
   - Request struct/type with validation rules
   - Response struct/type
   - Error responses (status codes + bodies)

3. **Implement layers** (in this order — TDD friendly):
   a. **Repository / data access** — schema, query, test
   b. **Business logic / use case** — orchestrate, test
   c. **Transport / handler** — parse, validate, delegate, return — test

4. **Wire route:** register in the routes file appropriate for this stack

5. **Document:**
   - OpenAPI/Swagger annotations if used (Go: Swag, Node: tsoa/zod-to-openapi, Python: FastAPI auto-docs)
   - Update API docs if separately maintained

6. **Verify:**
   - Unit tests pass
   - Integration test for handler (httptest / supertest / TestClient)
   - Lint + typecheck

7. **Security check:**
   - Auth required? Apply auth middleware
   - Admin required? Apply admin guard
   - Validation on every field
   - No SQL injection vectors
   - Rate limit if exposed publicly

Output the diff summary + endpoint URL + how to test it.
