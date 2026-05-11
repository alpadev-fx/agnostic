# Security Checklist — Universal

Before merging code, verify:

## Authentication & Authorization
- [ ] Auth required on every protected endpoint
- [ ] Role/permission checked on every protected action (not just route)
- [ ] Ownership checks on every fetch by ID (prevent IDOR)
- [ ] Admin checks server-side (never trust client `isAdmin`)
- [ ] Tokens: short-lived, refresh flow, revocation possible
- [ ] Passwords: argon2 / bcrypt only (never MD5/SHA1/plaintext)
- [ ] MFA path cannot be bypassed by API quirks

## Input Validation
- [ ] Every external input validated (HTTP body, query, headers, queue message, file upload)
- [ ] SQL queries parameterized
- [ ] HTML output encoded (or framework auto-escapes)
- [ ] No shell command interpolation with user data
- [ ] Path traversal blocked in file inputs (`../`, absolute paths)
- [ ] SSRF blocked in URL inputs (private IP ranges, file://, etc.)

## Secrets
- [ ] No hardcoded credentials, keys, tokens
- [ ] `.env*` files in `.gitignore`
- [ ] No secrets in logs, error messages, stack traces
- [ ] No secrets in URL query strings
- [ ] Production secrets from secret manager (not env in container image)

## Data Protection
- [ ] PII never logged
- [ ] TLS in transit; encryption at rest for sensitive data
- [ ] Sensitive responses not cached (Cache-Control: no-store)
- [ ] CSRF protection on state-changing endpoints
- [ ] CORS narrowly scoped (no `*` for credentialed requests)

## Rate Limiting & Abuse
- [ ] Login + signup endpoints rate-limited
- [ ] Expensive endpoints rate-limited (search, exports)
- [ ] Captcha/proof-of-work on signup if public

## Dependencies
- [ ] No known-vulnerable versions (CI runs `audit`/`safety`/`gosec`)
- [ ] No unmaintained packages on critical paths

## Logging & Monitoring
- [ ] Auth failures logged
- [ ] Sensitive operations audited (admin actions, financial transactions)
- [ ] Logs don't contain PII or secrets
- [ ] Alerts on auth failure spikes, 5xx spikes
