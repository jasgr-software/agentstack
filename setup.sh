#!/usr/bin/env bash
set -euo pipefail

# Agent Stack Setup & Upgrade
# Copies the multi-agent workflow files into a target project.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "Usage: $0 [--diff] <target-project-directory>"
  echo ""
  echo "Options:"
  echo "  --diff    Show what would change without copying anything (for upgrades)"
  echo ""
  echo "Upstream-managed files (always updated):"
  echo "  agent-stack.md        → <target>/.claude/agent-stack.md"
  echo "  agents/overwatch.md   → <target>/agents/overwatch.md"
  echo "  agents/ra.md          → <target>/agents/ra.md"
  echo "  agents/sa.md          → <target>/agents/sa.md"
  echo "  agents/developer.md   → <target>/agents/developer.md"
  echo "  agents/sdet.md        → <target>/agents/sdet.md"
  echo "  templates/TASK-TEMPLATE.md → <target>/docs/tasks/TASK-TEMPLATE.md"
  echo "  templates/BUG-TEMPLATE.md  → <target>/docs/tasks/BUG-TEMPLATE.md"
  echo ""
  echo "Project-managed files (only on first setup):"
  echo "  templates/CLAUDE.md   → <target>/CLAUDE.md"
  echo "  templates/PROGRESS.md → <target>/docs/tasks/PROGRESS.md"
  echo "  templates/C4.md       → <target>/docs/architecture/C4.md"
  echo "  templates/TENETS.md   → <target>/docs/architecture/TENETS.md"
  echo "  templates/SRS.md      → <target>/docs/requirements/SRS.md"
  echo "  templates/ADR-TEMPLATE.md → <target>/docs/decisions/ADR-TEMPLATE.md"
  exit 1
}

DIFF_ONLY=false
TARGET=""

for arg in "$@"; do
  case "$arg" in
    --diff) DIFF_ONLY=true ;;
    --help|-h) usage ;;
    *) TARGET="$arg" ;;
  esac
done

if [[ -z "$TARGET" ]]; then
  usage
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: '$TARGET' is not a directory."
  exit 1
fi

# Resolve to absolute path
TARGET="$(cd "$TARGET" && pwd)"

# Files that are always updated (upstream-managed)
UPSTREAM_FILES=(
  "agent-stack.md:.claude/agent-stack.md"
  "agents/overwatch.md:agents/overwatch.md"
  "agents/ra.md:agents/ra.md"
  "agents/sa.md:agents/sa.md"
  "agents/developer.md:agents/developer.md"
  "agents/sdet.md:agents/sdet.md"
  "templates/TASK-TEMPLATE.md:docs/tasks/TASK-TEMPLATE.md"
  "templates/BUG-TEMPLATE.md:docs/tasks/BUG-TEMPLATE.md"
)

# Files that are only copied on first setup (project-managed)
PROJECT_FILES=(
  "templates/CLAUDE.md:CLAUDE.md"
  "templates/PROGRESS.md:docs/tasks/PROGRESS.md"
  "templates/C4.md:docs/architecture/C4.md"
  "templates/TENETS.md:docs/architecture/TENETS.md"
  "templates/SRS.md:docs/requirements/SRS.md"
  "templates/ADR-TEMPLATE.md:docs/decisions/ADR-TEMPLATE.md"
)

if $DIFF_ONLY; then
  echo "Comparing agent stack files in: $TARGET"
  echo ""

  has_changes=false

  for mapping in "${UPSTREAM_FILES[@]}"; do
    src="${mapping%%:*}"
    dest="${mapping##*:}"
    target_file="$TARGET/$dest"

    if [[ ! -f "$target_file" ]]; then
      echo "--- $dest (new file, does not exist in project)"
      has_changes=true
    elif ! diff -q "$SCRIPT_DIR/$src" "$target_file" > /dev/null 2>&1; then
      echo "--- $dest"
      diff -u "$target_file" "$SCRIPT_DIR/$src" --label "project/$dest" --label "agentstack/$src" || true
      echo ""
      has_changes=true
    fi
  done

  if ! $has_changes; then
    echo "No changes. Your project is up to date."
  else
    echo ""
    echo "Run without --diff to apply these changes."
  fi

  exit 0
fi

echo "Setting up agent stack in: $TARGET"
echo ""

# Create directories
mkdir -p "$TARGET/.claude"
mkdir -p "$TARGET/agents"
mkdir -p "$TARGET/docs/tasks"
mkdir -p "$TARGET/docs/tasks/done"
mkdir -p "$TARGET/docs/architecture"
mkdir -p "$TARGET/docs/decisions"
mkdir -p "$TARGET/docs/requirements"
mkdir -p "$TARGET/docs/requirements/archive"

# Copy upstream-managed files (always updated)
for mapping in "${UPSTREAM_FILES[@]}"; do
  src="${mapping%%:*}"
  dest="${mapping##*:}"
  target_file="$TARGET/$dest"

  if [[ -f "$target_file" ]] && diff -q "$SCRIPT_DIR/$src" "$target_file" > /dev/null 2>&1; then
    echo "  = $dest (unchanged)"
  elif [[ -f "$target_file" ]]; then
    cp "$SCRIPT_DIR/$src" "$target_file"
    echo "  ~ $dest (updated)"
  else
    cp "$SCRIPT_DIR/$src" "$target_file"
    echo "  + $dest (new)"
  fi
done

# Copy project-managed files (only on first setup)
for mapping in "${PROJECT_FILES[@]}"; do
  src="${mapping%%:*}"
  dest="${mapping##*:}"
  target_file="$TARGET/$dest"

  if [[ -f "$target_file" ]]; then
    echo "  - $dest (already exists, skipped)"
  else
    cp "$SCRIPT_DIR/$src" "$target_file"
    echo "  + $dest (new)"
  fi
done

# Hint about CLAUDE.md reference
if [[ -f "$TARGET/CLAUDE.md" ]] && ! grep -q "agent-stack.md" "$TARGET/CLAUDE.md"; then
  echo ""
  echo "  Note: Your CLAUDE.md does not reference agent-stack.md."
  echo "  Add this line so agents discover the workflow rules:"
  echo ""
  echo "    All agents must read \`.claude/agent-stack.md\` before starting work."
fi

echo ""
echo "Done! Next steps:"
echo "  1. Edit CLAUDE.md — fill in product vision, agent team, and commands"
echo "  2. Edit docs/architecture/TENETS.md — define your architectural tenets"
echo "  3. Edit docs/architecture/C4.md — sketch your initial architecture"
echo "  4. Start working: invoke the RA to define requirements, then the SA to execute"
