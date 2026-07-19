---
allowed-tools: Read, Grep, Glob, Bash, Write, Edit, Task
argument-hint: [track: python | c | cpp | asm | rpi | opi] [optional: topic]
description: Guided expertise-building session with the mentor agent. Tracks progress across sessions in memory.
model: claude-opus-4-7
---
Learning session: $ARGUMENTS (no args → resume the active track).

## Setup

1. Read `.claude/memory/learning.md`. If missing, initialize it from the template structure below and interview the user briefly (2–3 questions max): which tracks matter most, current self-assessed level, hardware on hand (which Pi/Orange Pi models, if any).
2. Determine today's track and topic:
   - Explicit args → use them
   - No args → the track marked `active` in learning.md, next item in its progression

## Run the session

**Delegate to the `mentor` agent** with this context:
- Current level + track + last-session gap from learning.md
- Today's topic
- The user's actual project files when relevant (teach on real code)

The mentor runs: warm-up recall question → main exercise → review of the attempt → one structural improvement.

## Hardware sessions (rpi / opi tracks)

Before any wiring exercise:
- Confirm exact board model (`cat /proc/device-tree/model` if session is on-device, else ask)
- State pin numbers, voltage levels, and required components explicitly
- Flag anything that can damage the board BEFORE the user wires it

## Close the session

Update `.claude/memory/learning.md`:
- Move mastered items to the log with today's date
- Record what wobbled (becomes next warm-up question)
- Set the next exercise so the next `/learn` starts instantly
- Adjust level (novice → competent → proficient → expert) only on demonstrated output

End with a 3-line summary: what was learned, what to practice before next session, what's next.

## learning.md structure (for initialization)

```markdown
# Learning Tracker

## Profile
- Hardware: <boards owned>
- Goal: expert in Python, C, C++, assembly, Raspberry Pi, Orange Pi

## Tracks
| Track | Level | Active | Next exercise |
|---|---|---|---|
| python | novice | | |
| c      | novice | ✓ | |
| cpp    | novice | | |
| asm    | novice | | |
| rpi    | novice | | |
| opi    | novice | | |

## Wobbles (next warm-ups)
- <concept that needs reinforcement — date>

## Mastered log
- <date> — <track> — <concept, evidence>
```

Do NOT write exercise solutions into the user's project files.
