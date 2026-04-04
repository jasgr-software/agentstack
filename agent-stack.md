# Agent Stack — Multi-Agent Workflow Engine

This file defines the reusable workflow rules for a multi-agent Claude Code project. It is tech-stack agnostic — project-specific configuration (tech stacks, commands, directories) lives in your project's `CLAUDE.md`.

All agents must read this file before starting work.

## Agent Roles

Five specialised role types collaborate on the project. Each has strict boundaries. Projects define how many Developer instances they need (e.g., backend, frontend, mobile, infrastructure) in `CLAUDE.md`.

| Role                          | Agent File            | Responsibility                                                                                                                                                                                                                                                                                                                                 |
| ----------------------------- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Requirements Analyst (RA)** | `agents/ra.md`        | Owns the requirements document (SRS). Defines epics, refines requirements, validates completed work end-to-end. Does not write implementation code. At epic completion, runs the full e2e suite as a final gate and updates requirements status.                                                                                               |
| **System Architect (SA)**     | `agents/sa.md`        | The autonomous orchestrator. Drives epic execution through phases. Owns workflow files, task breakdown, and architecture model. Spawns all other agents as subagents. Creates ADRs for significant decisions. May self-implement simple tasks (see § SA Self-Implementation) to preserve context; delegates complex tasks to developer agents. |
| **Developer (1–N)**           | `agents/developer.md` | Implements tasks in their assigned domain. Writes tests first (TDD), implements until green, runs the submission gate, then submits for review. Multiple developer roles can be defined per project (e.g., backend, frontend, mobile, infrastructure).                                                                                         |
| **SDET / Validator**          | `agents/sdet.md`      | Reviews developer work for security flaws, edge cases, convention compliance, and documentation gaps. Must run lint, type-check, and tests before approving — never approves based on code review alone. Rejects with actionable bug reports.                                                                                                  |
| **Overwatch**                 | `agents/overwatch.md` | Read-only auditor. Monitors for rule violations, scope creep, and inefficiencies. Advisory only — SDET remains the approval authority.                                                                                                                                                                                                         |

## Main Session Rules

The main Claude Code session (not an agent) follows these rules:

- **Never modify application code.** Route all code changes through the SA so that documentation stays in sync. The main session may only modify workflow files: `CLAUDE.md`, task files, architecture docs, decision records, and memory files.
- **Never modify requirements directly.** The RA owns all requirements documents.
- **Git operations are the main session's responsibility, except branch creation.** Agents write code but do not commit, push, or manage branches. The SA creates branches during its Plan phase. The main session executes commits, pushes, and PRs when the SA requests approval.
- **Always ask before committing or pushing.** Propose a commit message and wait for explicit approval.
- **No worktree-based parallelization.** Do not use git worktrees for parallel agent execution. The merge complexity, conflict resolution overhead, and two-pass SDET review outweigh the time savings. Dispatch developer agents sequentially. When the user wants parallelism, they will open separate Claude Code sessions on separate branches manually.
- **Agent workflow file changes require quad review.** Any modification to `agents/*.md` or `.claude/agent-stack.md` must be reviewed by the SA, RA, SDET, and Overwatch before the change is considered final. Each reviews from their own perspective: SA validates orchestration feasibility and developer impact (since the SA dispatches developers, it is responsible for verifying that changes don't break developer task execution), RA validates that requirements/validation workflows remain sound, SDET validates that review processes and submission gates are workable, and Overwatch audits for rule conflicts and gaps. The main session dispatches all four reviews after making changes. Changes are not committed until all four have reported findings and any critical/warning issues are resolved. **Expedited path for non-structural changes:** wording fixes, formatting, typo corrections, and clarifications that do not alter any rule's meaning require only SA + one other reviewer (main session picks whichever role is most relevant). A change is **structural** (and requires full quad review) if it: adds/removes a gate or phase, changes role boundaries or approval authority, modifies phase sequencing, or alters Submission Gate, Docker Pre-Flight, or review authority rules. The main session judges whether a change qualifies as non-structural and must note "expedited quad review" in the commit message so Overwatch can audit the decision retrospectively. If in doubt, use the full quad review.

## Task Pipeline

```
docs/tasks/ (active) → docs/tasks/done/ (completed)
```

Task files are named `TASK-EEE-NNN-short-description.md` where `EEE` is the epic number and `NNN` is the task sequence within the epic (e.g., `TASK-001-003-provider-repository.md`). Bug reports use `BUG-EEE-NNN-short-description.md` and follow the same pipeline. Bugs discovered during the Validate phase or ad-hoc testing that don't tie to a single epic use `BUG-000-NNN-description.md` (epic zero = cross-cutting). The **Status** field tracks progress: `backlog`, `in-progress`, `review`, `done`. The **Assigned to** field specifies the developer agent role.

All tasks and bugs live in `docs/tasks/` while active. When they reach `done`, they are moved to `docs/tasks/done/`. Status changes are tracked by updating the **Status** field in the file.

Every agent must update the **Status** field, **Updated-by** field, and append to the **Work Log** section on every status change or meaningful work action.

## Breadcrumbs (session continuity)

Agents must leave enough context to resume if a session is interrupted.

**Developer agents** use the task file's **Work Log**. Every entry must include:

- **What was done** — specific files changed, tests written, commands run
- **What's next** — the immediate next step if work is incomplete
- **Blockers** — anything preventing progress

**SA, RA, and SDET** use `docs/tasks/PROGRESS.md` — a shared progress file that tracks the current epic state and a running log. These agents must update PROGRESS.md at the start and end of every invocation. Each entry should follow this structure:

```
### {Role} {Phase} — {date}
**Start:** {what this invocation is doing}
**Actions:** {bulleted list of what was done}
**End:** {outcome and next step}
```

This allows any agent (or the same agent in a new session) to pick up exactly where work left off.

**Cross-referencing:** The SA should read task Work Logs when reviewing developer output (not just PROGRESS.md). Developer spawn prompts should include the current phase and relevant PROGRESS.md context so developers understand the epic state.

**PROGRESS.md archival:** PROGRESS.md tracks only the **current epic**. During the Close phase, the SA archives the completed epic's sessions to `docs/tasks/done/PROGRESS-ARCHIVE.md` (append to the top) and resets PROGRESS.md to a clean state noting "no epic in progress" and the last completed epic. This keeps PROGRESS.md small so agents don't waste context reading historical sessions.

## Docker Pre-Flight

**Any agent about to run e2e tests must first verify Docker is available.** Run `docker info` — if it fails, **STOP immediately** and report that Docker is unavailable. Do not run e2e tests, do not approve gates, do not mark tasks as passing. Ask the user to start Docker before proceeding.

For tasks with `E2e-required: yes`, also run `docker compose ps` to verify the stack is healthy before executing e2e tests. If services are not running, **STOP** and ask the user to bring up the stack (`docker compose up -d`).

**This is a hard gate — no exceptions.** An e2e pass without a running Docker stack is invalid.

## Submission Gate

Before marking any task as `review`, the developer agent **must** pass:

1. **Lint + type-check** — zero errors
2. **Relevant tests** — unit/integration tests for the changed code
3. **Docker pre-flight** (only when `E2e-required: yes`) — see § Docker Pre-Flight
4. **Targeted e2e** (only when `E2e-required: yes`)

A task **must not** be marked `review` if any of these fail. A task with `E2e-required: yes` **must not** be marked `review` if Docker is unavailable — the e2e result is invalid without a running stack.

**E2e parity rule:** Every app with a user-facing UI must have its own e2e test config and test suite. The SA must verify e2e infrastructure exists for the target app during the Plan phase. If a new app is introduced without e2e infrastructure, the first task in the epic must create it before any feature tasks are dispatched.

**E2E execution proof requirement:** For any task with `E2e-required: yes`, the developer **must** include actual e2e test execution output (pass/fail counts, test names) in the Work Log. "Tests written but not executed", "Docker not available", or curl-based API verification are **not acceptable substitutes** for e2e tests. If e2e tests are blocked (networking, browser, infrastructure issue), the developer must **stop and escalate to the SA** — do not work around the blocker. The SA escalates to the user or dispatches the devops agent to fix the underlying issue before any e2e-required task can proceed.

**Domain-specific gates:** Projects may define additional submission gates in `CLAUDE.md` for integration-heavy domains (e.g., "must run a real data import before review", "must update operational docs when changing infrastructure"). These are enforced alongside the standard gates above.

**Bash command hygiene (all agents):** Never use `$()` command substitution in Bash tool calls — it triggers a permission prompt that blocks automation. Instead, split into sequential Bash calls: capture the output of the first, then use it in the second.

> **Note:** The specific commands for each gate step are defined in your project's `CLAUDE.md` under "Submission Gate Commands."

## Testing Epics

Some epics are test- or quality-focused rather than feature-focused (e.g., scenario mapping, security testing, accessibility audits, load testing). These epics follow the same SA phase lifecycle but with adapted role assignments and submission gates.

### Role adaptations

- **SDET becomes a primary implementer.** In testing epics, the SDET writes tests, produces audit reports, creates scenario maps, and runs analysis tools — not just reviews. The SA must communicate this role change when dispatching the SDET: include "This is a testing epic — you are the primary implementer, not a reviewer. Write tests, produce reports, and create artifacts as defined in the task spec." in the dispatch prompt.
- **Developers are secondary.** Developers are only dispatched if the testing epic reveals gaps that require code changes (e.g., missing error handling, graceful degradation logic, accessibility fixes). The SA creates developer tasks as needed based on SDET findings.
- **SA is the approval authority for SDET-implemented tasks.** The SDET cannot review its own implementation. Overwatch audits SDET work during the Audit phase (advisory findings), then the SA makes the final approve/reject decision during Review. SDET retains approval authority for any developer-implemented tasks (standard flow). To make review routing explicit, the SA must set `Reviewer: sa` on SDET-implemented tasks and `Reviewer: sdet` on developer-implemented tasks during the Plan phase. The Review phase uses this field to determine who reviews each task — the SA does not spawn the SDET for tasks marked `Reviewer: sa`. **Independence limitation:** the SA both designs tasks and approves SDET work, which is not fully independent. Overwatch's Audit findings are the counterbalance — the SA must document a disposition for each Overwatch finding (accepted or rejected with rationale) before approving.

### Submission gate adaptations

Testing epic tasks may produce different artifact types. The submission gate adjusts based on task output:

| Task output type                                                        | Gate requirements                                                                                                                                                                                               |
| ----------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Test code** (e2e tests, load tests, security tests)                   | Standard gate: lint + type-check + tests must pass                                                                                                                                                              |
| **Documents** (scenario maps, audit reports, coverage analysis)         | SA reviews for completeness against the task spec's Definition of Done; verifies all required sections are present, all flows are mapped, and findings are actionable (not vague). No lint/type-check required. |
| **CI/infrastructure config** (scanning tools, browser matrix config)    | Standard gate + verification that the pipeline runs successfully                                                                                                                                                |
| **Code fixes** (error handling, degradation logic found during testing) | Full standard gate including e2e where applicable                                                                                                                                                               |

### SDET-to-SA signaling for second-wave tasks

When the SDET discovers gaps that require code changes during a testing epic, it must flag them explicitly in its Work Log using this format:

```
**Code fix needed:** [description of the gap]
- Affected files/components: [list]
- Suggested fix: [brief guidance]
- Severity: [blocking | non-blocking]
```

The SA reads these flags after SDET tasks complete and creates developer tasks for the second wave. "Blocking" means the testing epic cannot pass validation without the fix. "Non-blocking" means the fix improves quality but the epic can close without it (SA may defer to a future epic).

### SA phase adjustments

These adjustments **override** the corresponding entries in the standard SA Phases table above when the current epic is a testing epic.

- **Plan:** SA identifies which tasks go to SDET vs. developers. SDET tasks are dispatched first — their findings may generate developer tasks. SA marks each task with `Artifact-type:` (test-code, document, ci-config, or code-fix) to determine which submission gate applies.
- **Dispatch:** SDET tasks are dispatched before developer tasks. If SDET findings produce new developer tasks (via the signaling format above), the SA creates and dispatches them in a second wave.
- **Review:** SA reviews and approves/rejects SDET-implemented tasks (informed by Overwatch's Audit findings). SDET reviews any developer-implemented tasks (standard flow).
- **Smoke:** SA may skip the Smoke phase if the epic produced no container or infrastructure changes (e.g., document-only epics). If the epic added or modified test code that runs against the Docker stack, Smoke applies as normal.
- **Validate:** The RA's e2e gate applies only if the epic produced new e2e tests or code changes. For document-only epics, the RA validates acceptance criteria against the delivered artifacts instead of running e2e. The SDET CI gate applies if any code or config was changed.
- **Close:** No changes — standard flow applies.

## SA Self-Implementation

The SA may implement simple tasks directly instead of spawning a developer agent. This preserves context (no agent spawn overhead, no redundant file reads) and is appropriate when the implementation is straightforward enough that a developer agent would just be translating the task spec into code.

### When to self-implement

During the Plan phase, the SA marks tasks with `Impl: sa` or `Impl: developer`. Use `Impl: sa` when:

- The change is **localized** — touches 1-2 files with a clear, mechanical modification
- The implementation is **obvious from the task spec** — no design judgment needed, no ambiguity
- **No significant debugging expected** — wiring up a field, adding a route, renaming, configuration changes
- The task does **not** have `E2e-required: yes` — e2e tasks involve iteration cycles that consume SA context

Use `Impl: developer` when:

- The change spans **multiple files or services** requiring coordination
- **TDD iteration** is expected — writing tests, debugging failures, multiple attempts
- The implementation requires **domain-specific judgment** beyond what the task spec provides
- The task has `E2e-required: yes`
- The SA's context window is under pressure (late in a large epic)

When in doubt, delegate. A wasted developer spawn is cheaper than an SA running out of context mid-epic.

**Bail-out rule:** If the SA hits unexpected behavior during self-implementation (test failures that aren't obvious, debugging cycles, scope expanding beyond 1-2 files), stop immediately. Create a task file with what was attempted and what went wrong, mark it `Impl: developer`, and delegate. Do not burn SA context on iteration.

### Rules for SA-implemented tasks

- The SA must still follow the **submission gate** — lint, type-check, and relevant tests must pass before marking `review`
- The SA must update the task file's **Work Log** with what was done, including any non-obvious design constraints or choices that downstream tasks need to respect
- SA-implemented tasks are still reviewed by the **SDET** during the Review phase — the SA cannot approve its own code
- Task specs for `Impl: sa` tasks should be **thinner** — define _what_ and _why_, not _how_. The SA already has the context; detailed implementation instructions are redundant
- **Cross-referencing for downstream tasks:** If a later `Impl: developer` task builds on an SA-implemented change, the SA must note the dependency in the developer task spec (e.g., "Extends SA-implemented TASK-NNN-NNN — see its Work Log for design constraints")

## How to Invoke

There are two entry points depending on the phase of work:

```
Requirements phase:  User → RA (update SRS, define epic)
Execution phase:     User → SA (drives the entire epic autonomously)
```

The **RA** and **SA** have different invocation modes:

- **SA** — always invoked directly by the user. Spawns all other agents as subagents.
- **RA** — has two invocation modes:
  - **Requirements definition** (Epic Lifecycle steps 1-2): invoked directly by the user to define/refine epics and the SRS.
  - **Validation gate** (Validate phase): spawned as a subagent of the SA to run the e2e completion gate. In this mode the RA executes its validation procedure and reports results back to the SA.

**Agent identification (mandatory):** Every agent spawn prompt **must** include: (1) the instruction to read `.claude/agent-stack.md` for workflow rules, (2) the instruction to read their agent file (`agents/{role}.md`) for role instructions, and (3) the self-identification instruction: _"You are the **{role name}**. Begin every response with `[{role-tag}]`."_ Developer agents must update task files (Status, Updated-by, Work Log). SA, RA, and SDET must update `docs/tasks/PROGRESS.md`.

## SA Phases

| Phase        | What the SA does                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Plan**     | **Context pre-flight: if starting a new epic, ask the user to run `/compact` to maximize context for the orchestration cycle.** Read epic requirements + architecture docs + tenets. Docker pre-flight (§ Docker Pre-Flight). Create feature branch. Break epic into tasks in `docs/tasks/`. **Design coherence gate:** review the task breakdown against the C4 model and tenets — verify tasks don't conflict with architectural decisions, cross-service contracts are consistent, and related tasks share a common approach. Update PROGRESS.md.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| **Dispatch** | Docker pre-flight (§ Docker Pre-Flight) before dispatching any wave with `E2e-required: yes` tasks. For each `backlog` task: if marked `Impl: sa` (see § SA Self-Implementation), the SA implements it directly; otherwise spawn a developer agent. Process tasks sequentially (one at a time). **Mid-dispatch audit (SA-discretionary):** for larger epics, the SA may spawn Overwatch mid-dispatch to check for rule violations and scope creep. Use judgment — audit when risk signals appear (complex tasks, multiple rejections, scope questions) rather than at a fixed task count. Address findings before continuing. Update PROGRESS.md.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        |
| **Audit**    | Spawn Overwatch to audit all `review` tasks for **per-task** rule compliance, scope creep, and inefficiencies. This is a tactical check on individual task outputs — distinct from the Close retro which looks at epic-level patterns. If mid-dispatch audit already ran recently and covered the same tasks, the SA may skip or narrow the Audit scope to only tasks completed since the last audit. Address findings before Review. Update PROGRESS.md.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
| **Review**   | Spawn SDET for each task with status `review`. Handle rejections (task → `backlog` with notes). **Architecture scan:** after all tasks pass SDET review, scan the integrated changes against the C4 model — verify implementation matches the intended architecture, no unintended patterns were introduced, and cross-service contracts are honoured. **If violations found:** create fix tasks, dispatch, and re-review — do not revert. Update PROGRESS.md.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
| **Smoke**    | Spawn SDET to run the container smoke test against Docker containers (not local dev). Validates image builds, container startup, DB migration, inter-service networking, health endpoints, and basic UI (page loads, navigation, CORS, new pages). If smoke fails, create fix tasks and re-smoke. Do not proceed to Validate until smoke passes. Update PROGRESS.md.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| **Validate** | Spawn RA for epic completion gate (e2e suite). Spawn SDET for CI gate + quality parity audit (verify all UI apps have e2e, coverage thresholds, and gate commands). Update PROGRESS.md.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| **Close**    | Update architecture model, create ADRs. **PROGRESS.md consistency gate (mandatory before PR):** verify all tasks show final status (`done` or `rejected`), all phases are logged with timestamps, and the epic section ends with a clear completion entry. **Archive completed files:** move all task files (`TASK-*.md`), bug files (`BUG-*.md`), and plan files (`EP-*-plan.md`) for the current epic from `docs/tasks/` to `docs/tasks/done/`. **Archive epic requirements:** move the epic's requirement file (`ep-*.md`) from `docs/requirements/` to `docs/requirements/implemented/`. **Archive PROGRESS.md:** append the completed epic's sessions to `docs/tasks/done/PROGRESS-ARCHIVE.md`, then reset PROGRESS.md to a clean state. **Retrospective:** spawn Overwatch in retrospective mode to analyze the completed epic's archived task/bug files in `docs/tasks/done/` and the epic's sessions in `docs/tasks/done/PROGRESS-ARCHIVE.md`. Overwatch produces a structured report with metrics (task count, bug count, rejection count, e2e pass rate), findings (systemic patterns, time sinks, what went well), and recommendations (workflow improvements for future epics). The retro is advisory — the SA reviews the report and applies any immediate workflow improvements, but may proceed to PR even if the retro is thin. The retro report is saved as `docs/tasks/done/RETRO-EEE.md` (where EEE is the epic number). Note: Overwatch participated in the Audit and mid-dispatch phases of this epic, so its self-assessment of those phases should be read with that context — the SA is the final judge of retro findings. **Then** request user approval to commit/push/PR. Update PROGRESS.md. |

When invoked, the SA reads PROGRESS.md to determine the current phase and acts accordingly. If no epic is active:

1. **Epic requirements exist?** → Start the **Plan** phase
2. **No epic requirements?** → Stop and tell the user to invoke the RA first

## Epic Lifecycle

1. User invokes **RA** directly to define epic requirements
2. User invokes **SA** directly — the SA drives the epic through its phases (Plan → Dispatch → Audit → Review → Smoke → Validate → Close)
3. The user re-invokes the SA between phases if the session ends. PROGRESS.md carries state across invocations.
4. At **Close**, the SA requests user approval to commit, push, and create PR.

**Epic completion gates** (during Validate phase):

- **Docker pre-flight**: Required before either gate (see § Docker Pre-Flight).
- **RA gate**: Validates the completed epic satisfies requirements end-to-end. Runs the full e2e suite. Updates requirements to mark as `Implemented`.
- **CI gate**: SDET runs the full CI pipeline (lint → type-check → build → all test suites). Both gates must pass.

## Git Operations

**The `main` branch is off-limits.** No agent and no main session may commit to, push to, or directly modify `main` under any circumstances. The **only** way to get changes into `main` is by raising a PR from a feature branch and merging it. This rule has no exceptions.

1. Create a branch from `main` (e.g. `ep-NNN-short-description`)
2. Commit changes to the branch
3. Push to GitHub and create a PR (squash merge to `main`)
4. Delete the branch after merge

One branch per epic or logical unit of work. No long-lived branches spanning multiple epics. If an epic is too large for a single branch, the RA should split it into smaller epics before the SA begins the Plan phase.

## Ambiguity During Implementation

Undecided design points are resolved by picking the most consistent approach, noted as a `// DECISION:` comment or in the post-implementation summary. If ambiguity would change task scope, surface it to the SA before writing any code. The SA reviews `// DECISION:` comments during Close — any with cross-task or cross-epic implications are promoted to ADRs (see SA agent file § ADR Lifecycle).

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
