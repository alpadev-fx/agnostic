---
allowed-tools: Bash, Read, Write, Edit, Glob, Skill
argument-hint: [source: folder | file | URL | "repo" (default: project docs)]
description: Build/refresh the Obsidian knowledge map from documents via graphify. Any brain reads the map and executes.
model: claude-sonnet-4-6
---
Build / refresh the knowledge map: $ARGUMENTS

The map is a CLI-agnostic Obsidian vault of linked notes. graphify turns any pile of documents into it; the brain (Claude Code / Codex / Antigravity) reads the relevant notes and executes.

## Steps

1. **Resolve source** from `$ARGUMENTS` (default: the project's docs — `README.md`, `docs/`, `.claude/memory/`, plus any `*.md` the user names). A folder, file, or URL are all valid.
2. **Resolve vault path** from `.claude/agnostic.toml [map] vault` (default `vault`). Create it if missing; add it to `.gitignore` unless the user wants the map committed.
3. **Run graphify** over the source into the vault: invoke the `graphify` skill (`~/.claude/skills/graphify`) with the source and vault path. graphify writes atomic, wikilinked notes — the map.
4. **Report** — note count, new links, vault path. Tell the user to open it in Obsidian to navigate the graph.
5. **Wire the brains (once)** — ensure `AGENTS.md` mirrors `CLAUDE.md` so Codex / Antigravity read the same directives + map. `agnostic init` does this; recreate if missing: `ln -sf CLAUDE.md AGENTS.md`.

## Rules
- Treat the map as durable memory, like `.claude/memory/`. Read relevant notes before acting on a documented domain; do not re-derive.
- Selective load — pull the notes you need, never the whole vault.
- After decisions / gotchas / discoveries, write them back as linked notes.
