# Knowledge Map (Obsidian + graphify)

The map is durable, CLI-agnostic memory. Any brain reads it and executes.

## What it is
- **The map** — an Obsidian vault of real, linked notes. `graphify` turns any pile of documents (docs, tickets, transcripts, research, code notes) into it: one idea per note, wikilinks between related notes.
- **The brains** — agentic CLIs that read the map and act: Claude Code, Codex CLI, Antigravity CLI. The directives file (`CLAUDE.md`, mirrored to `AGENTS.md`) points every brain at the same map, so the harness is brain-agnostic.
- Flow: `documents → graphify → Obsidian vault (the map) → brain reads relevant notes → executes → writes findings back as new linked notes`.

## Build / refresh
- `/map [source]` — run graphify over a source (folder, file, URL, or the repo docs) to build or update the vault. Skill: `~/.claude/skills/graphify`.
- Vault path: `.claude/agnostic.toml [map] vault` (default `vault`). Open it in Obsidian to navigate the graph by hand.

## Working rules
- Treat the map like `.claude/memory/`: durable state, not chat history.
- Before acting on a documented domain, read the relevant notes (follow links) — do not re-derive what the map already holds.
- Selective load — pull the few notes you need, never dump the whole vault into context.
- After a decision, gotcha, or discovery, write it back as a note and link it. A `[[note]]` that does not exist yet is a valid stub — it marks a note worth writing.
- Notes hold "why"; code holds "what". Keep notes atomic (one idea) and linked — many small linked notes beat one long doc.

## Brain-agnostic contract
- `CLAUDE.md` is the single directives source. `AGENTS.md` mirrors it (symlink) so Codex / Antigravity / any AGENTS.md brain gets identical rules.
- Route on structured signals, keep the map + `.claude/memory/` current, and any brain can pick up the work mid-stream.
