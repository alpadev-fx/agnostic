---
allowed-tools: Bash, Read
argument-hint: <message or context>
description: Draft a Slack message to team channel for review before sending
model: claude-sonnet-4-6
---
Draft Slack notification: $ARGUMENTS

## Workflow

1. **Understand context.** What's the message about? Recent PR? Incident? Deploy? Feature ship? Ask user briefly if unclear.

2. **Pick channel.** Read `agnostic.toml [integrations]` for default channels:
   - `standup_channel` — daily standups
   - `engineering_channel` — eng-wide updates
   - `incidents_channel` — incidents
   - `releases_channel` — ship announcements

   If no default applies, ask user which channel.

3. **Draft message.** Slack-friendly format:
   - Lead with the action/announcement (no preamble)
   - Bullet key context (max 4 bullets)
   - Link PR/issue/commit if relevant
   - End with explicit ask if action needed ("👀 review?", "deploy at 3pm — any concerns?")

4. **Open draft.** Use `mcp__claude_ai_Slack__send_message_draft` — NEVER `send_message`. User reviews + sends.

## Templates

### Ship announcement
```
Shipped <feature> → <PR url>

• <key change 1>
• <key change 2>

Live in <env>. Dashboard: <url>
```

### Incident
```
🚨 Investigating <symptom> in <service>

• Started: <time>
• Impact: <scope>
• On it: <people>

Updates in thread.
```

### Decision needed
```
Need decision on <topic>

Context: <2-3 lines>

Options:
1. <option> — <tradeoff>
2. <option> — <tradeoff>

Picking <recommendation> unless objections by EOD.
```

## Anti-patterns

- Never use `send_message` (direct send) — always `send_message_draft` so user reviews
- No `@channel` / `@here` without user explicitly asking
- No more than 1 emoji per message unless template requires
- Keep under 200 words; long content goes in a thread reply

## Output

Confirm to user: draft opened in #<channel>. Ask if they want to refine before sending.
