---
allowed-tools: Bash, Read, Grep, Glob
argument-hint: [service or component name]
description: Systematic debug investigation — root cause, not symptom
model: claude-opus-4-7
---
Debug service/component: $ARGUMENTS

## Iron Law
**No fixes without root cause.** A "fix" that suppresses the symptom is a future bug with rocket boosters.

## Phases

### 1. Investigate (gather facts, no theories yet)
- Read the relevant code (the service entry point + recent changes)
- Check recent commits: `git log --oneline -20 -- <path>`
- Check error logs / monitoring if available
- Check open issues mentioning this service
- Ask: when did it start failing? What changed?

### 2. Analyze (organize facts)
- What's the observable symptom (exact error, stack trace, behavior)?
- What's the minimal reproduction?
- What's the data flow leading to the failure point?
- What changed near the time the issue appeared?

### 3. Hypothesize (theories that explain ALL the facts)
- List 2-3 hypotheses
- For each: what evidence supports it, what evidence would disprove it
- Cheapest disproof first

### 4. Test hypotheses
- Read code, add temporary logging, query DB — whatever falsifies fastest
- A hypothesis that can't be falsified is not a hypothesis

### 5. Identify root cause
- State it as a complete sentence: "X happens because Y, which causes Z"
- Verify by predicting what fixing Y would do, then confirming

### 6. Propose fix (don't implement yet — present to user)
- Minimum change that addresses root cause
- Test that fails before the fix and passes after
- Side effects: who else depends on the buggy behavior?

## Output Format
```
## Debug Report: $ARGUMENTS

### Symptom
<exact observable behavior + repro>

### Root Cause
<one-sentence cause + chain to symptom>

### Evidence
- file:line — what this shows
- file:line — what this shows

### Proposed Fix
- File change: <pointer>
- Test that catches this: <pointer>
- Risk: <none / low / medium / high — why>

### Awaiting your approval to implement.
```
