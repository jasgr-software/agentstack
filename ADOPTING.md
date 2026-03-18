# Adopting the Agent Stack in an Existing Project

This guide is for projects that already have a `CLAUDE.md` and established workflows. If you're starting a new project from scratch, see the [Getting started](README.md#getting-started-with-a-new-project) section in the README instead.

> **This path is untested.** The agent stack was developed and battle-tested on greenfield projects. Brownfield adoption hasn't been validated yet. **Try this on a separate branch first** so you can evaluate without risk to your existing setup.

## Before you start

Read through `.claude/agent-stack.md` (after running the setup script) to understand what the workflow expects. Some things may conflict with your existing conventions. The goal is to adopt what helps and skip what doesn't — not to rewrite your project to fit the stack.

## Step 1: Run the setup script

```bash
git checkout -b adopt-agent-stack       # Work on a branch

./setup.sh /path/to/your/project        # Bash
.\setup.ps1 C:\path\to\your\project    # PowerShell
```

The script will:
- Copy `.claude/agent-stack.md` and `agents/overwatch.md` (always)
- Create `docs/` directory structure and templates (only if they don't exist)
- **Skip your existing CLAUDE.md** (never overwrites)

## Step 2: Add the agent stack reference to your CLAUDE.md

Add this line near the top of your existing `CLAUDE.md`, before any agent-specific sections:

```markdown
All agents must read `.claude/agent-stack.md` before starting work.
The SA must include this instruction in every subagent spawn prompt:
*"Read `.claude/agent-stack.md` first for workflow rules."*
```

This is how agents discover the workflow rules. Without it, `.claude/agent-stack.md` just sits there unused.

## Step 3: Add an Agent Team table

The agent stack needs to know which roles exist and what they own. Add a section like this to your `CLAUDE.md`:

```markdown
## Agent Team

| Role | Model | Tech Stack | Assigned Directories | Role Tag |
|------|-------|------------|---------------------|----------|
| **Requirements Analyst (RA)** | Sonnet 4.6 | — | `docs/requirements/` | `[ra]` |
| **System Architect (SA)** | Opus 4.6 | — | `CLAUDE.md`, `docs/tasks/`, `docs/architecture/`, `docs/decisions/` | `[sa]` |
| **Your Developer Role** | Sonnet 4.6 | Your stack | Your directories | `[your-tag]` |
| **SDET / Validator** | Sonnet 4.6 | — | — | `[sdet]` |
| **Overwatch** | Sonnet 4.6 | — | Read-only | `[overwatch]` |
```

**Tips for mapping your existing setup:**
- If you already have agents or roles defined, map them to the closest agent stack role
- You don't need all roles immediately — start with SA + one developer + SDET
- The RA and Overwatch can be added later once the core workflow is working
- Directory assignments should reflect your existing project structure, not the template's

## Step 4: Add Submission Gate Commands

Add a section defining the specific commands agents must run before submitting work for review:

```markdown
### Submission Gate Commands

Before marking any task as `review`, the developer agent **must** pass:

1. **Lint + type-check**: `your lint command` and `your type-check command` — zero errors
2. **Relevant tests**: `your test command` for the changed code
3. **Targeted e2e** (only when `E2e-required: yes`): `your e2e command`
```

If you already have quality gates defined in your CLAUDE.md, keep them — just make sure the agent stack's submission gate section points to the right commands.

## Step 5: Decide what to adopt

You don't have to adopt everything. Here's what's independent vs. what depends on other pieces:

### Independent (adopt any of these individually)

| Feature | What to do | Value |
|---------|-----------|-------|
| **Role boundaries** | Add the Agent Team table | Prevents agents from stepping on each other |
| **Submission gates** | Add gate commands | Forces quality checks before review |
| **Escalation protocol** | Already in agent-stack.md | Prevents agents from spinning on failures |
| **Git discipline** | Already in agent-stack.md | Prevents direct commits to main |
| **Overwatch** | Already copied to `agents/` | On-demand process auditing |

### Requires the task pipeline

| Feature | What to do | Value |
|---------|-----------|-------|
| **Task files** | Start using `docs/tasks/TASK-NNN.md` format | SA can break down and track work |
| **PROGRESS.md** | Start using `docs/tasks/PROGRESS.md` | Session continuity for SA/RA/SDET |
| **SA phases** | Let the SA drive Plan → Dispatch → ... → Close | Autonomous epic execution |
| **Work Log breadcrumbs** | Developers log in task files | Session continuity for developers |

### Requires architecture docs

| Feature | What to do | Value |
|---------|-----------|-------|
| **C4 model** | Fill in `docs/architecture/C4.md` | SA consults during planning |
| **Tenets** | Fill in `docs/architecture/TENETS.md` | Agents use to break tie decisions |
| **ADRs** | SA creates in `docs/decisions/` | Architectural decisions are documented |

## Step 6: Test the workflow

Try a small, low-risk epic first:

1. Invoke the SA with a simple task: *"You are the System Architect. Begin every response with `[sa]`. Read `.claude/agent-stack.md` for workflow rules. Execute [a small feature or bugfix]."*
2. Watch how it interacts with your existing CLAUDE.md and project structure
3. Note any friction — places where the agent stack's conventions conflict with yours
4. Adjust either the agent stack file or your CLAUDE.md to resolve conflicts

## Common friction points

**"I already have agents defined differently."**
The agent stack's role names (RA, SA, Developer, SDET, Overwatch) are conventions, not requirements. If you have a "Backend Engineer" instead of ".NET Developer", that's fine — just use your naming in the Agent Team table and role tags.

**"I don't use epics."**
The SA phases assume epic-scoped work. If you work in smaller increments, you can still use the SA — just invoke it with a feature or task instead of an epic. The phases still apply, just at a smaller scale.

**"I don't want the RA."**
The RA is optional. If you manage requirements outside the stack (or don't use formal requirements), skip it. The SA can work directly from a description you provide. You'll lose the RA's epic-completion validation gate, but the SDET's CI gate still catches quality issues.

**"My CLAUDE.md is already large."**
The agent stack intentionally splits workflow rules into `.claude/agent-stack.md` to keep your CLAUDE.md focused on project-specific config. You shouldn't need to add more than ~30 lines to your existing CLAUDE.md (the reference line, agent team table, and gate commands).

**"I have existing docs in different locations."**
The `docs/` structure (`tasks/`, `architecture/`, `decisions/`, `requirements/`) is a convention. If your project uses different paths, update the references in your CLAUDE.md's Agent Team table (Assigned Directories column) and the SA will follow your structure.
