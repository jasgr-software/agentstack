# CLAUDE.md

This is the **Agent Stack** template repository. It contains reusable multi-agent workflow files, not a software project.

## What this repo is

A collection of markdown templates and setup scripts that define a structured multi-agent workflow for Claude Code. Files are copied into target projects using `setup.sh` or `setup.ps1`.

## Repo structure

- `agent-stack.md` — the core workflow engine (upstream-managed, copied to `.claude/` in target projects)
- `agents/*.md` — agent role definitions: RA, SA, Developer, SDET, Overwatch (all upstream-managed)
- `templates/` — project-managed templates (CLAUDE.md, task/bug/ADR/C4/TENETS/SRS templates, PROGRESS.md)
- `examples/` — filled-in example showing what a configured project looks like
- `setup.sh` / `setup.ps1` — setup and upgrade scripts

## Rules for editing this repo

- Changes to `agent-stack.md` and `agents/overwatch.md` propagate to all projects on next upgrade — be careful with breaking changes
- Templates in `templates/` are only copied on first setup — changes won't affect existing projects
- The example in `examples/` is for documentation purposes only — it doesn't need to be functional
- Do not apply the agent stack workflow to this repo itself — it's a template repo, not a software project
