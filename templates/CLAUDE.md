# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product Vision

<!-- TODO: Describe your product — what it does, who it's for, core features -->

## Main Session Rules

<!-- The .claude/agent-stack.md file defines the standard main session rules.
     Add any project-specific overrides or additions below. -->

All agents must read `.claude/agent-stack.md` before starting work. Agent role definitions are in `agents/*.md` — each agent file contains the role's identity, tool restrictions, and operational procedures.

## Agent Team

<!-- TODO: Map generic agent roles to your project's tech stacks and directories.
     Define as many developer roles as your project needs.
     The Agent File column shows the agent definition used for each role.
     All developer roles share agents/developer.md — the SA's spawn prompt sets the role tag. -->

| Role | Agent File | Model | Tech Stack | Assigned Directories | Role Tag |
|------|-----------|-------|------------|---------------------|----------|
| **Requirements Analyst (RA)** | `agents/ra.md` | Sonnet 4.6 | — | `docs/requirements/` | `[ra]` |
| **System Architect (SA)** | `agents/sa.md` | Opus 4.6 | — | `CLAUDE.md`, `docs/tasks/`, `docs/architecture/`, `docs/decisions/` | `[sa]` |
| **TODO: Developer 1** | `agents/developer.md` | Sonnet 4.6 | <!-- e.g. ASP.NET, Python, Go --> | <!-- e.g. apps/api/ --> | `[TODO-tag]` |
| **TODO: Developer 2** | `agents/developer.md` | Sonnet 4.6 | <!-- e.g. Next.js, React --> | <!-- e.g. apps/web/ --> | `[TODO-tag]` |
| **SDET / Validator** | `agents/sdet.md` | Sonnet 4.6 | — | — | `[sdet]` |
| **Overwatch** | `agents/overwatch.md` | Sonnet 4.6 | — | Read-only | `[overwatch]` |

### Submission Gate Commands

<!-- TODO: Define the specific commands for your project's submission gate.
     These are referenced by agent-stack.md's generic gate structure. -->

Before marking any task as `review`, the developer agent **must** pass:

1. **Lint + type-check**: `TODO: your lint command` and `TODO: your type-check command` — zero errors
2. **Relevant tests**: `TODO: your test command(s)` for the changed code
3. **Targeted e2e** (only when `E2e-required: yes`): `TODO: your e2e command`

<!-- Add any project-specific additional gates below -->

### Epic Completion Gates

- **RA gate (e2e)**: `TODO: full e2e suite command`
- **CI gate**: `TODO: full CI command` (lint → type-check → build → all test suites)

## Local Development Setup

<!-- TODO: Document how to get the project running locally -->

```bash
# TODO: setup commands
```

### Port Assignments

<!-- TODO: List services and their ports -->

| Service | Port | Notes |
|---------|------|-------|
| TODO | TODO | TODO |

## Commands

<!-- TODO: List common development, build, lint, and test commands -->

## Key Documentation

<!-- TODO: List important docs that agents should reference -->

- `.claude/agent-stack.md` — multi-agent workflow engine
- `agents/*.md` — agent role definitions (RA, SA, Developer, SDET, Overwatch)
- `docs/architecture/C4.md` — C4 architecture model (SA updates after each epic)
- `docs/architecture/TENETS.md` — architectural tenets
- `docs/requirements/SRS.md` — Software Requirements Specification
- `docs/decisions/` — architecture decision records
