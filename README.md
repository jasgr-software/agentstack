# Agent Stack

A structured multi-agent execution engine for Claude Code. It takes well-defined requirements and drives them to production-quality code by splitting work across specialised AI agents — architect, developers, reviewer, auditor — each with strict role boundaries, mandatory quality gates, and file-based memory that survives session interruptions. The workflow enforces TDD, submission gates, independent code review, and escalation protocols so that Claude Code operates with the same discipline as a well-run engineering team. Technology-agnostic: define your stack, commands, and directory structure in `CLAUDE.md` and the workflow adapts.

## When to use this (and when not to)

This stack is **not for every project.** Before adopting it, consider whether it fits your situation:

1. **Don't use it for MVPs or rapid prototyping.** The full ceremony — RA, SA, developers, SDET, Overwatch, task files, PROGRESS.md, ADRs — adds real overhead. If you're hammering out a proof of concept or validating an idea quickly, this process will slow you down. Use it when you need production-quality output, not when you need speed.

2. **Budget for tuning.** The agent stack is a framework, not a turnkey solution. The generic workflow rules in `agent-stack.md` won't get you far without a well-configured `CLAUDE.md` that defines your tech stack, submission gate commands, directory structure, and agent team mapping. Expect to invest time configuring and iterating on your project setup.

3. **Be aware of context costs.** Every agent reads `agent-stack.md` + its own role file + `CLAUDE.md` + `PROGRESS.md` + task files + tenets + architecture docs before doing any work. That's a significant chunk of context consumed by instructions rather than actual code. For large, complex codebases, keep your `CLAUDE.md` concise — every unnecessary line costs you reasoning capacity.

**Best fit:** Projects that genuinely need production quality — regulated domains, team handoffs, complex multi-service systems, or any codebase where untested code, skipped reviews, and lost context between sessions would be costly.

**Not a fit:** Quick scripts, prototypes, exploratory work, or small projects where the process overhead exceeds the value of the guardrails.

## Design philosophy

This workflow is opinionated about **process** but agnostic about **technology**. It doesn't care if you're building with Python, .NET, Go, or JavaScript. It cares that:

1. Requirements are defined before code is written
2. Tests are written before implementation
3. Quality gates are passed before review
4. Review happens before shipping
5. Decisions are documented for future sessions
6. Work can resume after interruptions

**What this stack is:** An execution engine. It takes well-defined requirements and drives them to production-quality code through a disciplined, repeatable process.

**What this stack is not:** A product discovery tool. It doesn't help you figure out what to build, validate market fit, or refine vague ideas into concrete features. The quality of its output is directly proportional to the quality of the requirements you feed it. Garbage in, garbage out — but with excellent test coverage.

The value isn't in the agent orchestration mechanics — it's in the discipline the workflow enforces. These are patterns that Anthropic won't ship as defaults because they're opinionated workflow choices, not model capabilities.

## What's in the box

| File | Purpose |
|------|---------|
| `agent-stack.md` | The workflow engine — roles, task pipeline, SA phases, escalation protocol, git rules. Copied to `.claude/agent-stack.md` in your project. |
| `agents/ra.md` | Requirements Analyst agent — owns the SRS, defines epics, validates completed work |
| `agents/sa.md` | System Architect agent — autonomous orchestrator, drives epic execution |
| `agents/developer.md` | Developer agent template — generic, spawned by SA with a specific role tag and task |
| `agents/sdet.md` | SDET / Validator agent — reviews code, runs tests independently, approves or rejects |
| `agents/overwatch.md` | Read-only auditor agent that monitors for rule violations and scope creep |
| `templates/CLAUDE.md` | Skeleton project CLAUDE.md with TODO placeholders for your stack |
| `templates/TASK-TEMPLATE.md` | Task file template used by the SA when breaking down epics |
| `templates/BUG-TEMPLATE.md` | Bug report template used by the SDET when rejecting tasks |
| `templates/PROGRESS.md` | Shared progress tracker for SA, RA, and SDET |
| `templates/C4.md` | C4 architecture model index — links to the four level files |
| `templates/C4-L1-context.md` | System context — actors, external systems |
| `templates/C4-L2-containers.md` | Containers — deployable units, technologies, relationships |
| `templates/C4-L3-components.md` | Components — internal structure of each container |
| `templates/C4-L4-code.md` | Code conventions — patterns, project structure (developer reference) |
| `templates/TENETS.md` | Architectural tenets template |
| `templates/SRS.md` | Software Requirements Specification template |
| `templates/ADR-TEMPLATE.md` | Architecture Decision Record template |
| `examples/CLAUDE.md` | A filled-in example showing what a configured project looks like |
| `ADOPTING.md` | Guide for adding the agent stack to an existing project |

## Quick setup

### Option A: Run the setup script

**Bash (macOS/Linux/WSL):**
```bash
./setup.sh /path/to/your/project
```

**PowerShell (Windows):**
```powershell
.\setup.ps1 C:\path\to\your\project
```

This copies files into the right locations, creates the full `docs/` directory structure, and skips project-managed files if they already exist.

### Option B: Manual copy

```bash
TARGET=/path/to/your/project

# Core workflow engine
mkdir -p "$TARGET/.claude"
cp agent-stack.md "$TARGET/.claude/agent-stack.md"

# Agent files
mkdir -p "$TARGET/agents"
cp agents/ra.md "$TARGET/agents/ra.md"
cp agents/sa.md "$TARGET/agents/sa.md"
cp agents/developer.md "$TARGET/agents/developer.md"
cp agents/sdet.md "$TARGET/agents/sdet.md"
cp agents/overwatch.md "$TARGET/agents/overwatch.md"

# Task and bug templates
mkdir -p "$TARGET/docs/tasks/done"
cp templates/TASK-TEMPLATE.md "$TARGET/docs/tasks/TASK-TEMPLATE.md"
cp templates/BUG-TEMPLATE.md "$TARGET/docs/tasks/BUG-TEMPLATE.md"

# Architecture templates
mkdir -p "$TARGET/docs/architecture"
cp templates/C4.md "$TARGET/docs/architecture/C4.md"
cp templates/C4-L1-context.md "$TARGET/docs/architecture/C4-L1-context.md"
cp templates/C4-L2-containers.md "$TARGET/docs/architecture/C4-L2-containers.md"
cp templates/C4-L3-components.md "$TARGET/docs/architecture/C4-L3-components.md"
cp templates/C4-L4-code.md "$TARGET/docs/architecture/C4-L4-code.md"
cp templates/TENETS.md "$TARGET/docs/architecture/TENETS.md"

# Requirements
mkdir -p "$TARGET/docs/requirements/implemented"
cp templates/SRS.md "$TARGET/docs/requirements/SRS.md"

# ADR template
mkdir -p "$TARGET/docs/decisions"
cp templates/ADR-TEMPLATE.md "$TARGET/docs/decisions/ADR-TEMPLATE.md"

# Progress tracker
cp templates/PROGRESS.md "$TARGET/docs/tasks/PROGRESS.md"

# Project CLAUDE.md (only if you don't have one yet)
cp templates/CLAUDE.md "$TARGET/CLAUDE.md"
```

## Upgrading

When you improve the agent stack and want to propagate changes to existing projects:

**Preview what changed:**
```bash
./setup.sh --diff /path/to/your/project       # Bash
.\setup.ps1 -Diff C:\path\to\your\project     # PowerShell
```

**Apply the upgrade:**
```bash
./setup.sh /path/to/your/project               # Bash
.\setup.ps1 C:\path\to\your\project            # PowerShell
```

The scripts distinguish between two categories of files:

| Category | Files | On upgrade |
|----------|-------|-----------|
| **Upstream-managed** | `.claude/agent-stack.md`, `agents/*.md` (all agent files), `docs/tasks/TASK-TEMPLATE.md`, `docs/tasks/BUG-TEMPLATE.md` | Always updated to latest |
| **Project-managed** | `CLAUDE.md`, `docs/tasks/PROGRESS.md`, `docs/architecture/C4.md`, `docs/architecture/C4-L1-context.md`, `docs/architecture/C4-L2-containers.md`, `docs/architecture/C4-L3-components.md`, `docs/architecture/C4-L4-code.md`, `docs/architecture/TENETS.md`, `docs/requirements/SRS.md`, `docs/decisions/ADR-TEMPLATE.md` | Never overwritten (your project config) |

The output tells you what happened to each file:
- `+` new file created
- `~` existing file updated
- `=` unchanged (already up to date)
- `-` skipped (project-managed, already exists)

**If you've customized an upstream file** in a specific project (e.g., tweaked `agent-stack.md`), use `--diff` first to see what you'd lose, then decide whether to accept the update or keep your version.

**Project-specific agent rules** belong in `CLAUDE.md`, not in the agent files. Since `agents/*.md` are upstream-managed and overwritten on upgrade, any project-specific constraints (e.g., "use `pnpm --filter` for all commands", "never use `cd` in shell commands") should go in `CLAUDE.md` under role-specific headings like "Developer Rules" or "SDET Rules". Each agent reads `CLAUDE.md` on startup, so rules there are authoritative. The agent files contain a `## Project-Specific Rules` placeholder pointing to this convention.

## Getting started

### Greenfield vs. brownfield

This stack was developed and tested on **greenfield projects** — new repos where it shapes the workflow from day one. That's the recommended path.

If you're adding the agent stack to an **existing project** with an established CLAUDE.md and conventions, see **[ADOPTING.md](ADOPTING.md)** for a step-by-step guide. That path is untested — try it on a separate branch first.

### New project setup

After running the setup script, here's how to go from empty project to first epic.

### Prerequisites: bring good requirements

**The agent stack is an execution engine, not a requirements discovery tool.** It decomposes well-defined requirements into tasks, enforces quality gates, and drives work to completion. It does not figure out what you should build.

The better your requirements are when they enter the stack, the more successful it will be. Ideally, you arrive with:
- A clear product vision (what it does, who it's for)
- Defined features with acceptance criteria
- Known platforms and constraints

If your requirements are vague, refine them first — through user research, design sprints, prototyping, or tools like [Ouroboros](https://github.com/Q00/ouroboros). The RA structures and tracks requirements in the SRS format, and can help with a basic interview to fill gaps, but it's not a substitute for thoughtful product thinking upfront.

### Step 1: Write your product vision

Open `CLAUDE.md` and fill in the **Product Vision** section. This is what every agent reads first to understand what they're building. Include core features, target users, and platforms.

### Step 2: Bootstrap your tech stack with the SA

If you already know your tech stack, fill in the Agent Team table in `CLAUDE.md` directly (see `examples/CLAUDE.md` for reference). If you're unsure, use the SA to help:

> *"You are the System Architect. Begin every response with `[sa]`. Read `.claude/agent-stack.md` for workflow rules. I need help bootstrapping this project. Here's the product vision: [paste from CLAUDE.md]. Recommend a tech stack, agent team mapping, directory structure, and submission gate commands."*

The SA will recommend:
- **Tech stack** based on your product's needs (platforms, scale, complexity)
- **Developer roles** — one per technology boundary (e.g., backend, frontend, mobile, infra)
- **Directory assignments** — which directories each role owns
- **Submission gate commands** — your project's lint, type-check, test, and e2e commands

Review the SA's recommendations, adjust as needed, and fill in CLAUDE.md. The SA can also help with the initial C4 model and tenets in the following steps.

### Step 3: Define your architectural tenets

Edit `docs/architecture/TENETS.md`. Tenets are the principles agents use to break ties between valid approaches. Start with 3–5 tenets that reflect your strongest opinions about how the project should be built. You can always add more later.

### Step 4: Sketch your initial architecture

Edit the C4 level files in `docs/architecture/`. You don't need a complete model — just enough to get started:

- **L1** (`C4-L1-context.md`): What is the system? Who uses it? What external systems does it talk to?
- **L2** (`C4-L2-containers.md`): What are the deployable units? (API, web app, database, etc.)
- **L3** (`C4-L3-components.md`): Leave mostly empty — the SA will fill this in as epics are implemented.
- **L4** (`C4-L4-code.md`): Leave empty initially — the SA populates this as code conventions emerge.

The SA updates the relevant C4 level files after each epic, so the model grows organically. Each level is a separate file so agents read only what they need.

### Step 5: Define requirements

Invoke the **RA** (Requirements Analyst) to structure your requirements into the SRS format:

> *"You are the Requirements Analyst. Begin every response with `[ra]`. Read `.claude/agent-stack.md` for workflow rules. Here are the requirements for [your product]: [paste or describe your requirements]. Structure these into the SRS and create the first epic."*

The RA structures your requirements into `docs/requirements/SRS.md` and creates epic files (`docs/requirements/ep-001-name.md`) with acceptance criteria. The more complete the requirements you provide, the less the RA needs to infer.

### Step 6: Build

Invoke the **SA** (System Architect) in Claude Code:

> *"You are the System Architect. Begin every response with `[sa]`. Read `.claude/agent-stack.md` for workflow rules. Execute epic ep-001."*

The SA reads the epic requirements, creates a branch, breaks the work into tasks, spawns developers, runs review, and drives to completion. You re-invoke between phases if the session ends.

## How it works

### The problem

Claude Code is powerful, but without structure it tends to:
- Lose track of what it was doing across sessions
- Skip tests or quality checks when moving fast
- Make architectural decisions without consulting the broader design
- Repeat failed approaches instead of escalating

The agent stack solves this by splitting work across specialised roles with strict boundaries, mandatory quality gates, and a file-based memory system that survives session interruptions.

### Roles

The stack defines five role types. You map these to your project's specific tech stacks in `CLAUDE.md`.

| Role | What it does | What it can't do |
|------|-------------|-----------------|
| **Requirements Analyst (RA)** | Owns the SRS and epic definitions. Validates completed features end-to-end. | Write implementation code |
| **System Architect (SA)** | Orchestrates everything. Breaks epics into tasks, spawns agents, drives phases. | Write implementation code |
| **Developer (1–N)** | Implements tasks using TDD. You define as many developer roles as your project needs (backend, frontend, mobile, infra, etc.) | Commit, push, or manage git branches |
| **SDET / Validator** | Reviews code for security, correctness, and convention compliance. Must run tests before approving. | Approve based on code review alone |
| **Overwatch** | Read-only auditor. Scans for rule violations, scope creep, and inefficiencies. | Modify any files |

The **main Claude Code session** (you, talking to Claude) never writes application code directly. It manages git operations and invokes the RA or SA to drive work.

### Two entry points

```
Requirements phase:  You → RA  (define what to build)
Execution phase:     You → SA  (build it)
```

The SA is always invoked directly by you. The RA has two modes: invoked directly by you for requirements definition, or spawned as a subagent of the SA during the Validate phase to run the e2e completion gate.

### The SA phase lifecycle

Once you invoke the SA with a defined epic, it drives autonomously through seven phases:

```
Plan → Dispatch → Audit → Review → Smoke → Validate → Close
```

| Phase | What happens |
|-------|-------------|
| **Plan** | SA reads the epic requirements, architecture docs, and tenets. Creates a feature branch. Breaks the epic into task files in `docs/tasks/`. Runs a design coherence gate against the C4 model and tenets. Marks each task with `Impl: sa` (simple, self-implemented) or `Impl: developer` (delegated). |
| **Dispatch** | SA spawns developer agents for backlog tasks sequentially (one at a time). Simple tasks marked `Impl: sa` are self-implemented by the SA directly. Developers write tests first, implement until green, then run the submission gate before marking tasks as `review`. |
| **Audit** | SA spawns Overwatch to scan all `review` tasks for rule violations, scope creep, and inefficiencies. Findings are addressed before moving to Review. (The SA may also run mid-dispatch audits for larger epics when risk signals appear.) |
| **Review** | SA spawns the SDET for each `review` task. The SDET must run lint, type-check, and tests before approving. Rejections go back to `backlog` with notes. After all tasks pass, the SA runs an architecture scan against the C4 model. |
| **Smoke** | SDET runs a container smoke test against Docker — validates image builds, container startup, migrations, inter-service networking, health endpoints, and basic UI. No local dev processes — Docker containers only. |
| **Validate** | Two completion gates: the RA validates the epic satisfies requirements end-to-end (runs the full e2e suite), and the SDET runs the full CI pipeline plus a quality parity audit. Both must pass. |
| **Close** | SA updates the architecture model, creates ADRs, archives task/bug/epic files to `done/` and `implemented/`, spawns Overwatch for a retrospective, and requests your approval to commit, push, and create a PR. |

If a session ends mid-epic, you just re-invoke the SA. It reads `PROGRESS.md` to determine where it left off and resumes from there.

### Quality enforcement

The stack enforces quality through several mechanisms:

- **TDD**: Developers write tests before implementation. Tests define the contract; code makes them pass.
- **Submission gates**: Before any task can be marked for review, the developer must pass lint, type-check, and relevant tests. The specific commands are defined in your project's `CLAUDE.md`.
- **SDET review**: An independent reviewer runs the same checks and inspects for security flaws, edge cases, and documentation gaps. Nothing ships without SDET sign-off.
- **Overwatch audits**: A read-only agent scans for process violations — missing work logs, skipped gates, scope creep, repeated failed approaches.
- **Container smoke test**: After Review, the SDET validates that all services build and run correctly as Docker containers before the epic proceeds to Validate.
- **Epic completion gates**: The RA validates the full user workflow works end-to-end. The SDET validates the full CI pipeline passes and audits quality parity across all UI apps. Both gates must clear before an epic is complete.

### Session continuity

Claude Code sessions end. Context windows fill up. The agent stack handles this with file-based breadcrumbs:

- **Developers** log what they did, what's next, and any blockers in the task file's **Work Log** section
- **SA, RA, and SDET** update `docs/tasks/PROGRESS.md` — a shared file tracking the current phase, each agent's last action, and next steps
- **Task files** track status (`backlog` → `in-progress` → `review` → `done`) and move to `docs/tasks/done/` when complete

This means any agent — or the same agent in a new session — can pick up exactly where work left off by reading these files.

### Live progress tracking

All four agent roles (developer, SDET, SA, RA) use `TaskCreate` and `TaskUpdate` to show real-time progress in the Claude Code UI. When an agent is dispatched, it breaks its work into 3–6 visible steps with spinners:

```
✓ Read source code and existing tests
✓ Write failure mode test script
● Running lint and type-check
○ Update work log
```

This gives you a live indicator of what the agent is doing instead of staring at a blank screen for 5–8 minutes. These are ephemeral UI tasks — separate from the persistent task files in `docs/tasks/` which serve as the cross-session audit trail.

### Escalation protocol

When an agent gets stuck, it escalates to the SA rather than spinning:

- After **2 failed attempts**: agent must log what was tried and why it failed before retrying
- After **4 failed attempts**: hard stop. The SA decides if it's a requirements problem or an implementation problem
- Agents can escalate at any time for architectural questions or cross-service issues

### Git discipline

- The `main` branch is off-limits — all changes go through feature branches and PRs
- One branch per epic, squash-merged to main
- Only the main Claude session (not agents) performs git operations
- Commits require explicit user approval

## Project structure in your repo

After setup, your project will have this structure:

```
your-project/
├── CLAUDE.md                          # Your project config (product, team, commands)
├── .claude/
│   └── agent-stack.md                 # Workflow engine (upstream-managed)
├── agents/
│   ├── ra.md                          # Requirements Analyst (upstream-managed)
│   ├── sa.md                          # System Architect (upstream-managed)
│   ├── developer.md                   # Developer template (upstream-managed)
│   ├── sdet.md                        # SDET / Validator (upstream-managed)
│   └── overwatch.md                   # Auditor agent (upstream-managed)
└── docs/
    ├── architecture/
    │   ├── C4.md                      # C4 model index
    │   ├── C4-L1-context.md           # System context — actors, external systems
    │   ├── C4-L2-containers.md        # Containers — deployable units, relationships
    │   ├── C4-L3-components.md        # Components — internal structure per container
    │   ├── C4-L4-code.md              # Code conventions — patterns, project structure
    │   └── TENETS.md                  # Architectural tenets
    ├── decisions/
    │   └── ADR-TEMPLATE.md            # Template for new ADRs
    ├── requirements/
    │   ├── SRS.md                     # Software Requirements Specification
    │   ├── ep-001-first-epic.md       # (created by RA)
    │   └── implemented/                # Completed epics move here
    └── tasks/
        ├── TASK-TEMPLATE.md           # Template for new tasks
        ├── BUG-TEMPLATE.md            # Template for bug reports
        ├── PROGRESS.md                # SA/RA/SDET progress tracker
        ├── TASK-001-001-some-task.md   # (created by SA during Plan)
        └── done/                      # Completed tasks move here
```

## Permission configuration (semi-yolo mode)

The agent stack spawns multiple subagents that run shell commands, read/write files, and execute tests. By default, Claude Code prompts for permission on each action, which interrupts autonomous execution constantly — especially during the SA's Dispatch and Review phases.

**Semi-yolo mode** is a curated permission configuration that pre-allows safe, routine operations while explicitly denying destructive ones. This lets agents work autonomously without your constant approval, while still protecting against dangerous commands.

### How to configure

Create or edit `.claude/settings.json` in your project:

```json
{
  "permissions": {
    "allow": [
      "Read",
      "Glob",
      "Grep",
      "Agent",
      "TaskCreate",
      "TaskUpdate",
      "TaskGet",
      "TaskList",
      "TaskOutput",
      "TaskStop",
      "Skill",
      "EnterPlanMode",
      "ExitPlanMode",
      "WebSearch",
      "WebFetch",
      "Write(docs/**)",
      "Write(agents/**)",
      "Write(CLAUDE.md)",
      "Edit(docs/**)",
      "Edit(agents/**)",
      "Edit(CLAUDE.md)",
      "Bash(git:*)",
      "Bash(ls:*)",
      "Bash(find:*)",
      "Bash(wc:*)",
      "Bash(echo:*)",
      "Bash(mkdir:*)",
      "Bash(cat:*)",
      "Bash(head:*)",
      "Bash(tail:*)",
      "Bash(grep:*)",
      "Bash(diff:*)",
      "Bash(which:*)",
      "Bash(cp:*)",
      "Bash(mv:*)"
    ],
    "deny": [
      "Bash(git push --force*)",
      "Bash(git push -f*)",
      "Bash(git reset --hard*)",
      "Bash(git clean -fd*)",
      "Bash(rm -rf /home*)",
      "Bash(rm -rf /*)"
    ]
  }
}
```

### What to customize

The example above covers workflow operations (docs, agents, task tracking) and common shell tools. You'll want to add entries for your project's tech stack:

**Source code write access** — add `Write` and `Edit` patterns for your application directories:
```json
"Write(src/**)",
"Write(apps/**)",
"Edit(src/**)",
"Edit(apps/**)"
```

**Build tools** — add your project's package manager, compiler, and test runner:
```json
"Bash(npm:*)",
"Bash(pnpm:*)",
"Bash(dotnet:*)",
"Bash(cargo:*)",
"Bash(go:*)",
"Bash(python3:*)",
"Bash(docker:*)",
"Bash(npx:*)",
"Bash(node:*)"
```

### The deny list

The deny list is just as important as the allow list. The defaults above prevent force-pushes, hard resets, and recursive deletes. Consider adding project-specific denials:

```json
"deny": [
  "Bash(git push --force*)",
  "Bash(git push -f*)",
  "Bash(git reset --hard*)",
  "Bash(git clean -fd*)",
  "Bash(rm -rf /home*)",
  "Bash(rm -rf /*)",
  "Bash(sudo:*)"
]
```

### Project vs local settings

- `.claude/settings.json` — checked into the repo, shared with the team. Put permissions here that every developer should have.
- `.claude/settings.local.json` — gitignored, per-developer overrides. Put environment-specific tokens (`GH_TOKEN`), absolute paths, and personal tool preferences here.

Anything in `settings.local.json` merges on top of `settings.json`. If a permission appears in both allow lists, it's allowed. Deny takes precedence over allow.

### Why not full yolo?

Full `acceptEdits` or `dangerouslyDisableSandbox` modes remove all guardrails. Semi-yolo is a middle ground: agents run without interruption for routine work, but you still get prompted for anything unusual — new file locations, unfamiliar commands, or operations not in your allowlist. The deny list acts as a safety net even if an agent tries something destructive.

## Origin

Extracted from a real project where this workflow was developed and battle-tested across multiple epics.
