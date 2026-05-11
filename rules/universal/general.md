# General Coding Standards

## Code Quality
- Run lint after every change — MUST pass before commit
- Run relevant tests after changes (not the full suite if it's slow — narrow first)
- Prefer small, focused commits with descriptive messages
- Functions focused — under 50 lines as a guideline, hard cap by stack-specific rules

## Git Workflow
- Branch naming: `<type>/<short-description>` or `<type>/<ticket-id>-<short-description>`
  - Types: `feature`, `fix`, `chore`, `refactor`, `docs`, `test`
- Commit messages: Conventional Commits (`type: subject`)
  - Subject ≤50 chars, imperative mood, no trailing period
  - Body explains WHY, not WHAT (code already shows what)
- Always rebase on target branch before opening a PR
- Never force-push to shared branches (`main`, `dev`, `staging`)

## Security (universal)
- NEVER log PII (emails, names, IDs, tokens, passwords, payment data)
- NEVER hardcode secrets, API keys, credentials — use env vars or secret manager
- ALL user input MUST be validated before processing
- ALL database queries MUST be parameterized
- Money: integer base units (cents/satoshi/pence) — never floating point

## Error Handling
- Validate at boundaries (HTTP, queue, file, external API)
- Trust internal calls — don't double-validate
- Error messages safe for users (no stack traces, no internal paths, no SQL)
- Log full context internally; surface short message externally

## Documentation
- Code is the source of truth; docs explain WHY
- README has: what + setup + run + test (minimum)
- Public functions: brief docstring on purpose + non-obvious args
- No multi-paragraph docstrings unless framework requires it

## Anti-patterns
- Designing for hypothetical future requirements
- Premature abstraction (3 similar lines is fine, generalize at 5+)
- Half-finished implementations
- Backwards-compatibility shims when you can change the code
- Adding features the user didn't ask for
