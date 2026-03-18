# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Product Vision

**TaskFlow** is a task management platform for small engineering teams. It provides kanban boards, sprint planning, and lightweight reporting — designed to be simpler than Jira but more structured than a spreadsheet.

### Core Features
- **Boards**: Kanban boards with customisable columns and WIP limits
- **Sprints**: Time-boxed sprint planning with velocity tracking
- **Reports**: Burndown charts, cycle time, and throughput metrics
- **Integrations**: GitHub PR linking, Slack notifications

### Users
- **Primary**: Engineering teams (5–20 people) — developers, managers, PMs
- **Future (not in scope now)**: External stakeholders with read-only dashboards

### Platforms
- Web browser (desktop-first, responsive)
- REST API for integrations

## Main Session Rules

All agents must read `.claude/agent-stack.md` before starting work. The SA must include this instruction in every subagent spawn prompt: *"Read `.claude/agent-stack.md` first for workflow rules."*

## Agent Team

| Role | Model | Tech Stack | Assigned Directories | Role Tag |
|------|-------|------------|---------------------|----------|
| **Requirements Analyst (RA)** | Sonnet 4.6 | — | `docs/requirements/` | `[ra]` |
| **System Architect (SA)** | Opus 4.6 | — | `CLAUDE.md`, `docs/tasks/`, `docs/architecture/`, `docs/decisions/` | `[sa]` |
| **Backend Developer** | Sonnet 4.6 | Go, PostgreSQL, sqlc, Chi | `apps/api/`, `db/` | `[backend]` |
| **Frontend Developer** | Sonnet 4.6 | Next.js 15, React, Tailwind, Zustand | `apps/web/` | `[frontend]` |
| **DevOps Engineer** | Sonnet 4.6 | Terraform, GitHub Actions, Docker | `infra/`, `.github/workflows/`, `Dockerfile*` | `[devops]` |
| **SDET / Validator** | Sonnet 4.6 | — | — | `[sdet]` |
| **Overwatch** | Sonnet 4.6 | — | Read-only | `[overwatch]` |

### Submission Gate Commands

Before marking any task as `review`, the developer agent **must** pass:

1. **Lint + type-check**: `make lint` and `pnpm type-check` — zero errors
2. **Relevant tests**:
   - Backend: `go test ./apps/api/...`
   - Frontend: `pnpm --filter web test`
3. **Targeted e2e** (only when `E2e-required: yes`): `pnpm --filter web e2e -- --grep '<feature>'`

### Epic Completion Gates

- **RA gate (e2e)**: `pnpm --filter web e2e`
- **CI gate**: `make ci` (lint → type-check → build → all test suites)

## Local Development Setup

```bash
cp .env.example .env
docker compose up -d          # PostgreSQL + migrations
make dev-api                  # Go API server (port 8080)
pnpm dev                      # Next.js dev server (port 3000)
```

### Port Assignments

| Service | Port | Notes |
|---------|------|-------|
| Web app | 3000 | Next.js |
| API server | 8080 | Go / Chi |
| PostgreSQL | 5432 | Docker |

## Commands

### Development
```bash
make dev-api                   # Run API with hot reload (air)
pnpm dev                       # Next.js dev server
docker compose up -d db        # Start PostgreSQL only
```

### Build / Lint / Type Check
```bash
make build                     # Build Go binary
make lint                      # golangci-lint + ESLint
pnpm type-check                # TypeScript check
make ci                        # Full CI pipeline
```

### Testing
```bash
go test ./apps/api/...         # Backend tests
pnpm --filter web test         # Frontend unit tests
pnpm --filter web e2e          # E2E tests (Playwright)
```

### Database
```bash
make migrate-up                # Run pending migrations
make migrate-create NAME=xxx   # Create new migration
```

## Key Documentation

- `docs/architecture/C4.md` — C4 architecture model (SA updates after each epic)
- `docs/architecture/TENETS.md` — architectural tenets
- `docs/requirements/SRS.md` — Software Requirements Specification
- `docs/requirements/ep-NNN-name.md` — epic requirements with acceptance criteria
- `docs/decisions/` — architecture decision records
