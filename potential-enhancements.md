# Potential Enhancements

Improvements identified by comparing the agent stack template against a battle-tested deployment (Journey for Jasmine — 9 epics, 160+ tasks, 12 ADRs, 12+ bugs resolved). Ranked by criticality.

---

## 1. Agent file references in SA spawn prompts

**Priority:** Critical

**Current state:** `sa.md` tells the SA to include "Read `.claude/agent-stack.md`" in spawn prompts but does not instruct agents to read their own agent file.

**Enhancement:** Update `sa.md`'s "Spawning Agents" section to include an explicit instruction for each spawned agent to read its own agent file:

```
1. "Read `.claude/agent-stack.md` for workflow rules."
2. "Read your agent file (`agents/{role}.md`) for your role instructions."
3. The agent's role tag
4. The specific task
5. Relevant context
```

Update `agent-stack.md`'s "Agent identification (mandatory)" section to mention agent files.

**Files affected:** `agent-stack.md`, `agents/sa.md`

---

## 2. Specialized developer agent files per tech stack

**Priority:** Critical

**Current state:** A single generic `agents/developer.md` serves all developer roles. Specialization depends entirely on the SA's spawn prompt quality. The CLAUDE.md template has placeholder rows for developer roles but no mechanism to generate specialized agent files.

**Enhancement:** When the project's tech stack is defined, the generic `developer.md` should be replaced with self-contained specialized agent files tailored to each developer role.

**Approach:**
- **Setup script creates minimal specialized files** — the setup script asks the user for developer roles (name, role tag, primary directories) and generates a file per role (e.g., `agents/dotnet-developer.md`, `agents/webapp-developer.md`)
- **SA enriches them during Plan** — as the tech stack becomes clearer through C4 and tenets, the SA updates the agent files with specific frameworks, test commands, and conventions
- **Self-contained files** — each specialized file is complete on its own. Shared rules (TDD workflow, escalation, Work Log format) already live in `agent-stack.md`, so duplication is minimal (10-15 lines of boilerplate per file)

Each specialized file includes:
- Role identity and tag
- Assigned directories (hard boundaries)
- Tech stack and frameworks
- Relevant test and submission gate commands
- Domain-specific conventions

**Files affected:** `agents/developer.md` (becomes a base for generation), `setup.sh`, `setup.ps1`, `templates/CLAUDE.md`

---

## 3. Epic-prefixed task and bug numbering

**Priority:** High

**Current state:** Tasks use `TASK-NNN-short-description.md`. With multiple epics, flat numbering creates ambiguity — `TASK-015` gives no indication of which epic it belongs to.

**Enhancement:** Change the convention to `TASK-EEE-NNN-short-description.md` (e.g., `TASK-004-015-remove-azure-maps.md`). Apply the same pattern to bugs: `BUG-EEE-NNN-short-description.md`.

**Bug numbering rule:** Bugs default to epic-prefixed. If a bug is discovered during the Validate phase or ad-hoc testing and doesn't tie to a single epic, use `BUG-000-NNN-description.md` (epic zero = cross-cutting). The `Source task` field in the bug template captures the originating context.

**Files affected:** `agent-stack.md`, `templates/TASK-TEMPLATE.md`, `templates/BUG-TEMPLATE.md`, `agents/sa.md`

---

## 4. Split C4 into L1-L4 individual files

**Priority:** High

**Current state:** A single `templates/C4.md` contains all three levels (L1-L3) in one file. The template states "L4 is the code itself" and does not document it.

**Enhancement:** Replace the single file with four individual level files:
- `templates/C4-L1-context.md` — system context, actors, external systems
- `templates/C4-L2-containers.md` — containers, technologies, relationships
- `templates/C4-L3-components.md` — component diagrams per container
- `templates/C4-L4-code.md` — code conventions and patterns (serves as a developer agent reference for understanding codebase structure, repository patterns, handler conventions, etc.)

Drop the root `C4.md` index file. Each level file stands on its own.

**Benefits:** Agents read only the level they need. The SA updates only the level that changed. Smaller files reduce context window waste.

**Files affected:** `templates/C4.md` (replaced by 4 files), `agents/sa.md`, `agent-stack.md`, `templates/CLAUDE.md`

---

## 5. Add optional DevOps role and operations doc templates

**Priority:** High

**Current state:** The template has no infrastructure-specific role and no operations documentation. Projects deploying to cloud infrastructure must invent these from scratch.

**Enhancement:**
- Add `agents/devops.md` — a specialized developer agent for infrastructure work
- Add `templates/operations/inventory.md` — tracks deployed resources, SKUs, regions, FQDNs
- Add `templates/operations/runbook.md` — deployment procedures, rollback steps, troubleshooting
- Update `agents/sdet.md` — add ops doc verification rule for infrastructure tasks
- Update `agents/overwatch.md` — add ops doc consistency check
- Update `templates/CLAUDE.md` — add DevOps row to Agent Team table

**DevOps role boundaries:**
- Assigned directories: `infra/`, `.github/workflows/`, `Dockerfile*`, `docker-compose.yml` (project fills in specifics)
- Extra gate: must update ops docs when changing deployed resources
- Same submission gate and escalation protocol as other developers

**This is optional.** The setup script asks "Does your project have infrastructure?" and only adds the DevOps role and ops templates if yes.

**Files affected:** New `agents/devops.md`, new `templates/operations/`, `agents/sdet.md`, `agents/overwatch.md`, `templates/CLAUDE.md`, `setup.sh`, `setup.ps1`

---

## 6. Epic splitting guidance for the RA

**Priority:** Medium

**Current state:** Epics are flat files (`docs/requirements/ep-NNN-name.md`). There is no guidance on what to do when an epic grows too large for a single feature branch.

**Enhancement:** Add guidance to `agents/ra.md` and the epic lifecycle section of `agent-stack.md`: when an epic has too many acceptance criteria to complete in one feature branch, the RA should split it into smaller epics (e.g., `ep-005a-name`, `ep-005b-name` or sequential numbering). Each smaller epic should be independently completable in one branch.

**Files affected:** `agents/ra.md`, `agent-stack.md`

---

## 7. Human checklist template

**Priority:** Medium

**Current state:** All verification is agent-driven. There is no concept of verification steps that require a human (DNS propagation, cloud console checks, manual UI walkthroughs, external service delivery confirmation).

**Enhancement:** Add `templates/EP-HUMAN-CHECKLIST.md`. The SA creates one during Plan for epics involving infrastructure, deployment, or external service integration.

The checklist is the **user's responsibility** — it is not part of the agent validation pipeline. The SA creates it during Plan. The Close phase reminds the user to complete it before merging. The README should call out that some epics produce a human checklist the user must complete.

**Files affected:** New `templates/EP-HUMAN-CHECKLIST.md`, `agents/sa.md` (Plan and Close phases), `README.md`

---

## 8. Security findings in epic files

**Priority:** Medium

**Current state:** The SDET checks for security flaws per-task during Review, but there is no structured place to record project-level or epic-level security findings.

**Enhancement:** During the Validate phase, the SDET adds a "Security Findings" section directly to the epic file. Findings travel with the epic and get archived together when the epic completes. This covers OWASP-relevant items, auth/session security, input validation, and data exposure risks.

No separate template is needed — the epic file is the natural home for this.

**Future consideration:** A project-level `SECURITY-REVIEW.md` that aggregates unresolved findings across archived epics, maintained by the SDET.

**Files affected:** `agents/sdet.md`, `agent-stack.md` (Validate phase description)

---

## Future Considerations

The following items need further design decisions before implementation.

### Domain-specific hard submission gates

**Current state:** The submission gate is fixed: lint, type-check, tests, e2e (if required). Some domains need extra verification steps (e.g., data import against real sources, API contract validation).

**Current approach:** Domain-specific gates are expressed in the task's Definition of Done. The SA writes them in, the developer follows them, the SDET checks the Work Log for evidence.

**Future consideration:** A formal mechanism for additional hard submission gates that the SDET enforces beyond the standard pipeline — an `Extra-gate:` field in the task template with a command that must pass before the task can be marked as `review`.

### Architecture archive format

**Current state:** The SA updates C4 level files at Close. The previous state is overwritten. There is a Change Log table but no snapshot of the prior architecture.

**Future consideration:** Before updating C4 files, the SA archives the current state to `docs/architecture/archive/`. The format needs a decision:

- **(A) Single consolidated snapshot** — SA merges relevant changes into one `ep-NNN.md` file per epic. Simpler to maintain.
- **(B) Subdirectory per epic** — `archive/ep-NNN/C4-L2-containers.md`, etc., copying only files that changed. Preserves exact file structure but noisier.
