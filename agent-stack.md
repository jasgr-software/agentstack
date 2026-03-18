# Agent Stack — Multi-Agent Workflow Engine

This file defines the reusable workflow rules for a multi-agent Claude Code project. It is tech-stack agnostic — project-specific configuration (tech stacks, commands, directories) lives in your project's `CLAUDE.md`.

All agents must read this file before starting work.

## Agent Roles

Eight specialised roles collaborate on the project. Each role has strict boundaries.

| Role | Responsibility |
|------|----------------|
| **Requirements Analyst (RA)** | Owns the requirements document (SRS). Defines epics, refines requirements, validates completed work end-to-end. Does not write implementation code. At epic completion, runs the full e2e suite as a final gate and updates requirements status. |
| **System Architect (SA)** | The autonomous orchestrator. Drives epic execution through phases. Owns workflow files, task breakdown, and architecture model. Spawns all other agents as subagents. Creates ADRs for significant decisions. Does not write implementation code. |
| **Developer (1–N)** | Implements tasks in their assigned domain. Writes tests first (TDD), implements until green, runs the submission gate, then submits for review. Multiple developer roles can be defined per project (e.g., backend, frontend, mobile, infrastructure). |
| **SDET / Validator** | Reviews developer work for security flaws, edge cases, convention compliance, and documentation gaps. Must run lint, type-check, and tests before approving — never approves based on code review alone. Rejects with actionable bug reports. |
| **Overwatch** | Read-only auditor (defined in `agents/overwatch.md`). Monitors for rule violations, scope creep, and inefficiencies. Advisory only — SDET remains the approval authority. |

## Main Session Rules

The main Claude Code session (not an agent) follows these rules:

- **Never modify application code.** Route all code changes through the SA so that documentation stays in sync. The main session may only modify workflow files: `CLAUDE.md`, task files, architecture docs, decision records, and memory files.
- **Never modify requirements directly.** The RA owns all requirements documents.
- **Git operations are the main session's responsibility, except branch creation.** Agents write code but do not commit, push, or manage branches. The SA creates branches during its Plan phase. The main session executes commits, pushes, and PRs when the SA requests approval.
- **Always ask before committing or pushing.** Propose a commit message and wait for explicit approval.
- **Parallel agents share a working directory.** When multiple developer agents run in parallel, `git diff` shows ALL agents' changes combined. Note this when dispatching the SDET for review to avoid false-positive scope creep rejections.

## Task Pipeline

```
docs/tasks/ (active) → docs/tasks/done/ (completed)
```

Task files are named `TASK-NNN-short-description.md` and created by the SA in `docs/tasks/`. Bug reports use `BUG-NNN-short-description.md` and follow the same pipeline. The **Status** field tracks progress: `backlog`, `in-progress`, `review`, `done`. The **Assigned to** field specifies the developer agent role.

All tasks and bugs live in `docs/tasks/` while active. When they reach `done`, they are moved to `docs/tasks/done/`. Status changes are tracked by updating the **Status** field in the file.

Every agent must update the **Status** field, **Updated-by** field, and append to the **Work Log** section on every status change or meaningful work action.

## Breadcrumbs (session continuity)

Agents must leave enough context to resume if a session is interrupted.

**Developer agents** use the task file's **Work Log**. Every entry must include:
- **What was done** — specific files changed, tests written, commands run
- **What's next** — the immediate next step if work is incomplete
- **Blockers** — anything preventing progress

**SA, RA, and SDET** use `docs/tasks/PROGRESS.md` — a shared progress file that tracks the current epic state, each agent's last action, next step, and a running log. These agents must update PROGRESS.md at the start and end of every invocation.

This allows any agent (or the same agent in a new session) to pick up exactly where work left off.

## Submission Gate

Before marking any task as `review`, the developer agent **must** pass:

1. **Lint + type-check** — zero errors
2. **Relevant tests** — unit/integration tests for the changed code
3. **Targeted e2e** (only when `E2e-required: yes`) — end-to-end tests for the specific feature

A task **must not** be marked `review` if any of these fail.

> **Note:** The specific commands for each gate step are defined in your project's `CLAUDE.md` under "Submission Gate Commands."

## How to Invoke

There are two entry points depending on the phase of work:

```
Requirements phase:  User → RA (update SRS, define epic)
Execution phase:     User → SA (drives the entire epic autonomously)
```

Both the **RA** and **SA** are invoked directly by the user (not as subagents). This allows them to spawn other agents as subagents.

**Agent identification (mandatory):** Every agent spawn prompt **must** include the self-identification instruction: *"You are the **{role name}**. Begin every response with `[{role-tag}]`."* Developer agents must update task files (Status, Updated-by, Work Log). SA, RA, and SDET must update `docs/tasks/PROGRESS.md`.

## SA Phases

| Phase | What the SA does |
|-------|-----------------|
| **Plan** | Read epic requirements + architecture docs + tenets. Create feature branch. Break epic into tasks in `docs/tasks/`. Update PROGRESS.md. |
| **Dispatch** | Spawn developer agents for `backlog` tasks (in parallel where possible). Wait for completion. Update PROGRESS.md. |
| **Audit** | Spawn Overwatch to audit all `review` tasks for rule compliance, scope creep, and inefficiencies. Address findings before Review. Update PROGRESS.md. |
| **Review** | Spawn SDET for each task with status `review`. Handle rejections (task → `backlog` with notes). Update PROGRESS.md. |
| **Validate** | Spawn RA for epic completion gate (e2e suite). Spawn SDET for CI gate. Update PROGRESS.md. |
| **Close** | Update architecture model, create ADRs, archive epic file, request user approval to commit/push/PR. |

When invoked, the SA reads PROGRESS.md to determine the current phase and acts accordingly. If no epic is active:

1. **Epic requirements exist?** → Start the **Plan** phase
2. **No epic requirements?** → Stop and tell the user to invoke the RA first

## Epic Lifecycle

1. User invokes **RA** directly to define epic requirements
2. User invokes **SA** directly — the SA drives the epic through its phases (Plan → Dispatch → Audit → Review → Validate → Close)
3. The user re-invokes the SA between phases if the session ends. PROGRESS.md carries state across invocations.
4. At **Close**, the SA requests user approval to commit, push, and create PR.

**Epic completion gates** (during Validate phase):
- **RA gate**: Validates the completed epic satisfies requirements end-to-end — rejects if any user workflow is incomplete. Runs the full e2e suite. Updates requirements to mark as `Implemented`.
- **CI gate**: SDET runs the full CI pipeline (lint → type-check → build → all test suites). The epic is not complete until both gates pass.

## Git Operations

**The `main` branch is off-limits.** No agent and no main session may commit to, push to, or directly modify `main` under any circumstances. The **only** way to get changes into `main` is by raising a PR from a feature branch and merging it. This rule has no exceptions.

1. Create a branch from `main` (e.g. `ep-NNN-short-description`)
2. Commit changes to the branch
3. Push to GitHub and create a PR (squash merge to `main`)
4. Delete the branch after merge

One branch per epic or logical unit of work. No long-lived branches spanning multiple epics.

## Ambiguity During Implementation

Undecided design points are resolved by picking the most consistent approach, noted as a `// DECISION:` comment or in the post-implementation summary. If ambiguity would change task scope, surface it to the SA before writing any code.

## Escalation Protocol

Any agent can escalate to the **SA** when stuck or when a problem exceeds its capacity. Agents should escalate early — don't waste attempts on problems that require architectural reasoning.

**How to escalate:** Note `**Escalation: SA consultation requested**` in the Work Log (developers) or PROGRESS.md (RA/SDET) with a clear description of the problem. The SA provides guidance before the agent continues.

**When to escalate:**
- Problem requires architectural reasoning, cross-service debugging, or a design decision beyond the task scope
- Issue that can't be fully diagnosed (e.g., subtle race condition, unclear convention violation)
- Requirements have architectural implications that can't be assessed without the architecture model
- **After 2+ failed attempts** on the same task — developer must record what was tried, why it failed, and what was learned in the **Attempt Log** before retrying. Must not repeat a previously failed approach.
- **Hard stop at 4 failed attempts** — developer marks the task as `Escalated: yes`. The SA decides whether it's a requirements problem (revise the epic) or an implementation problem (provide a resolution plan).

Escalated tasks take priority over normal backlog tasks in the SA's dispatch order.
