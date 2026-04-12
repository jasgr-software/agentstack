# CLAUDE.md

This file provides project-specific guidance to Claude Code. For the reusable multi-agent workflow engine, see `.claude/agent-stack.md`. For individual agent instructions, see `agents/*.md`.

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

<!-- Add any domain-specific additional gates below. Examples:
     - Data import tasks must run a real import against the local database before review
     - Infrastructure tasks must update operational docs (inventory, runbooks) as part of the task
     - API tasks must verify OpenAPI spec is consistent with implementation
     Domain-specific gates catch integration issues that unit tests and lint cannot. -->

### Container Smoke Test

<!-- The SDET runs this after Review phase. Must use Docker containers — local dev is not valid.
     Define the commands or script here. If you have a smoke-test.sh, reference it.
     Otherwise, define the manual steps: docker compose build, up, health checks, basic UI validation. -->

```bash
# TODO: Define your container smoke test
# scripts/smoke-test.sh     # Or define manual steps:
# docker compose down -v && docker compose build && docker compose up -d
# docker compose ps          # All services healthy
# curl -sf http://localhost:PORT/health   # Per-service health checks
```

### Infrastructure Documentation Consistency

<!-- If your project has infrastructure-as-code (Terraform, Bicep, CloudFormation, etc.),
     uncomment and configure the rules below. -->

<!-- When a task changes infrastructure resources, secrets, or configuration, the developer
     **must update operational documentation** (inventory, runbooks, deployment guides) as part
     of the task. The SDET **must verify** that operational docs are consistent with infrastructure
     code changes — reject if stale. -->

### Required CI Checks (branch protection)

<!-- TODO: If your repo uses branch protection with required status checks, document them here.
     This helps agents understand which CI jobs must pass before a PR can merge. -->

<!-- Example: The `build` and `test` jobs in `.github/workflows/ci.yml` are **required status checks**
     for PR merge. They must pass before any PR can be merged to `main`. -->

### Epic Completion Gates

- **RA gate (e2e)**: `TODO: full e2e suite command`
- **CI gate**: `TODO: full CI command` (lint → type-check → build → all test suites)

## Agent Status Line (optional)

<!-- Uncomment this section if you've installed the statusline.sh script and want
     the SA to update .claude/agent-status.json when dispatching subagents.
     See the Agent Stack README § "Agent status line" for setup instructions. -->

<!-- ### agent-status.json contract

The file `.claude/agent-status.json` tracks active subagent sessions for the status bar.
It is gitignored (runtime state, not source). The main session and SA must follow this protocol:

**Before dispatching a subagent:**
```python
# Read-modify-write — never overwrite the whole file
import json, os, subprocess
from datetime import datetime, timezone

status_file = ".claude/agent-status.json"
sessions = {}
if os.path.exists(status_file):
    with open(status_file) as f:
        sessions = json.load(f)

session_id = "UNIQUE_ID"  # Use the subagent session ID or PID
sessions[session_id] = {
    "pid": int(subprocess.check_output(["echo", "$PPID"]).strip()),
    "agent": "backend-developer",       # Role tag from Agent Team table
    "model": "sonnet-4.6",              # Model used for this agent
    "goal": "TASK-001-003: user auth",  # Current task description
    "dispatched_by": "sa",              # Who spawned this agent
    "status": "active",
    "started": datetime.now(timezone.utc).isoformat()
}

with open(status_file, "w") as f:
    json.dump(sessions, f, indent=2)
```

**After subagent returns:** Set `"status": "idle"` or remove the entry.

**Rules:**
- Always read-modify-write to preserve concurrent sessions
- Never write a flat object — top-level must be a dict keyed by session ID
- Status writes must never block workflow — if rejected/fails, skip and continue
- Add `.claude/agent-status.json` to your `.gitignore`
-->

## Role-Specific Rules

<!-- Add project-specific constraints for individual agent roles here.
     These survive agent stack upgrades (unlike changes to agents/*.md files).
     Each agent reads CLAUDE.md on startup, so rules here are authoritative.
     Only add sections for roles that need project-specific rules. -->

<!-- ### Developer Rules -->
<!-- Examples: -->
<!-- - Use `pnpm --filter` for all package commands -->
<!-- - Never use `cd` in shell commands — use the Bash tool's `cwd` parameter -->
<!-- - Never use `sudo` — escalate to the SA instead -->
<!-- - Use the Write tool to create files, not `cat` heredocs or `echo` redirection -->

<!-- ### SDET Rules -->
<!-- Examples: -->
<!-- - Verify operations docs consistency when infrastructure code changes -->
<!-- - Never use `cd` in shell commands — use the Bash tool's `cwd` parameter -->

<!-- ### RA Rules -->
<!-- Examples: -->
<!-- - Read docs/requirements/observations.md for live product observations before starting any epic -->

<!-- ### SA Rules -->
<!-- Examples: -->
<!-- - Check docs/architecture/staging-inventory.md before planning infrastructure tasks -->

<!-- ### Overwatch Rules -->
<!-- Examples: -->
<!-- - Verify that infrastructure changes include updated staging-inventory.md and staging-runbook.md -->

## Local Development Setup

<!-- TODO: Document how to get the project running locally -->

### Prerequisites

<!-- The agent stack requires Docker for e2e testing workflows. Tasks marked with
     E2e-required: yes will fail pre-flight checks if Docker is not available.
     Agents will STOP and ask you to start Docker rather than approving gates without it. -->

- **Docker** — required for e2e tests. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and ensure it's running before invoking the SA on epics with e2e tasks.
- Run `docker compose up -d` to start the local stack before e2e test runs.

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

- `.claude/agent-stack.md` — multi-agent workflow engine (7 phases: Plan → Dispatch → Audit → Review → Smoke → Validate → Close)
- `agents/*.md` — agent role definitions (RA, SA, Developer, SDET, Overwatch)
- `docs/architecture/C4.md` — C4 architecture model index (SA updates level files after each epic)
- `docs/architecture/C4-L1-context.md` — system context, actors, external systems
- `docs/architecture/C4-L2-containers.md` — containers, technologies, relationships
- `docs/architecture/C4-L3-components.md` — component diagrams per container
- `docs/architecture/C4-L4-code.md` — code conventions, patterns, project structure
- `docs/architecture/TENETS.md` — architectural tenets
- `docs/requirements/SRS.md` — Software Requirements Specification
- `docs/requirements/implemented/` — archived epic files for completed requirements
- `docs/decisions/` — architecture decision records (SA creates per § ADR Lifecycle)
- `docs/tasks/PROGRESS.md` — current epic state (archived to `docs/tasks/done/PROGRESS-ARCHIVE.md` at Close)
- `docs/tasks/done/RETRO-EEE.md` — Overwatch retrospective reports per epic
