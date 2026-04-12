#!/usr/bin/env bash
# Claude Code status line — four-line display with agent tracking
#
# Line 1: git/repo info (user@host, branch, dirty state, ahead/behind)
# Line 2: Claude session info (model, context usage, tokens, rate limit)
# Line 3: system info (time, cpu, memory, disk)
# Line 4: active agent status (from .claude/agent-status.json)
#
# Installation:
#   1. Copy this file to ~/.claude/statusline.sh
#   2. chmod +x ~/.claude/statusline.sh
#   3. Add to ~/.claude/settings.json:
#      { "env": { "CLAUDE_CODE_STATUS_LINE": "bash ~/.claude/statusline.sh" } }
#   4. Allow the script in your project's .claude/settings.json or settings.local.json:
#      "Bash(bash ~/.claude/statusline.sh)"      (in the permissions.allow array)
#      "Bash(bash /home/YOU/.claude/statusline.sh)"  (absolute path alternative)

input=$(cat)

# Parse JSON with python3 (jq not guaranteed to be installed)
_parsed=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
def g(*path):
    cur = d
    for k in path:
        if isinstance(cur, dict) and k in cur:
            cur = cur[k]
        else:
            return ""
    return "" if cur is None else str(cur)
print(g("workspace", "current_dir") or g("cwd"))
print(g("model", "display_name"))
print(g("context_window", "used_percentage"))
print(g("session_name"))
print(g("context_window", "total_input_tokens"))
print(g("context_window", "total_output_tokens"))
print(g("rate_limits", "five_hour", "used_percentage"))
')
cwd=$(printf '%s' "$_parsed" | sed -n '1p')
model=$(printf '%s' "$_parsed" | sed -n '2p')
used_pct=$(printf '%s' "$_parsed" | sed -n '3p')
session_name=$(printf '%s' "$_parsed" | sed -n '4p')
total_in=$(printf '%s' "$_parsed" | sed -n '5p')
total_out=$(printf '%s' "$_parsed" | sed -n '6p')
five_hour_pct=$(printf '%s' "$_parsed" | sed -n '7p')

# --- Line 1: Git / repo info ---
git_line=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_name=$(basename "$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)")
    branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)

    # Dirty state
    dirty=""
    if ! git -C "$cwd" diff --quiet 2>/dev/null || ! git -C "$cwd" diff --cached --quiet 2>/dev/null; then
        dirty="*"
    fi

    # Untracked files
    if [ -n "$(git -C "$cwd" ls-files --others --exclude-standard 2>/dev/null)" ]; then
        dirty="${dirty}?"
    fi

    # Ahead/behind
    upstream=$(git -C "$cwd" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    ahead_behind=""
    if [ -n "$upstream" ]; then
        ahead=$(git -C "$cwd" rev-list --count "${upstream}..HEAD" 2>/dev/null)
        behind=$(git -C "$cwd" rev-list --count "HEAD..${upstream}" 2>/dev/null)
        [ "${ahead:-0}" -gt 0 ] && ahead_behind="${ahead_behind}+${ahead}"
        [ "${behind:-0}" -gt 0 ] && ahead_behind="${ahead_behind}-${behind}"
        [ -n "$ahead_behind" ] && ahead_behind=" ${ahead_behind}"
    fi

    # Shorten cwd: replace $HOME prefix with ~
    display_cwd="${cwd/#$HOME/\~}"

    user_host_git=$(printf "%s@%s" "$(whoami)" "$(hostname -s)")
    git_line=$(printf "\033[32m%s\033[0m:\033[90m%s\033[0m  \033[33m%s\033[0m  \033[36m%s%s\033[0m%s" \
        "$user_host_git" "$display_cwd" "$repo_name" "$branch" "$dirty" "$ahead_behind")
else
    display_cwd="${cwd/#$HOME/\~}"
    user_host_git=$(printf "%s@%s" "$(whoami)" "$(hostname -s)")
    git_line=$(printf "\033[32m%s\033[0m  \033[90m(no git repo)  %s\033[0m" \
        "$user_host_git" "$display_cwd")
fi

# --- Line 2: Claude info ---
rel_path="."
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    rel_path="${cwd#"$repo_root"}"
    rel_path="${rel_path#/}"
    [ -z "$rel_path" ] && rel_path="."
fi

ctx_info=""
if [ -n "$used_pct" ]; then
    ctx_info=$(printf " | ctx: %.0f%% used" "$used_pct")
fi

session_info=""
if [ -n "$session_name" ]; then
    session_info=" | \"${session_name}\""
fi

# Usage: cumulative session tokens (shown as Nk) + 5-hour rate limit when present
usage_info=""
if [ -n "$total_in" ] && [ "$total_in" != "0" ]; then
    in_k=$(awk "BEGIN {printf \"%.1fk\", $total_in/1000}")
    out_k=$(awk "BEGIN {printf \"%.1fk\", $total_out/1000}")
    usage_info=" | ${in_k}in ${out_k}out"
fi
if [ -n "$five_hour_pct" ]; then
    five_fmt=$(printf "%.0f" "$five_hour_pct")
    usage_info="${usage_info} | 5h:${five_fmt}%"
fi

claude_line=$(printf "\033[35m%s\033[0m  \033[90m%s\033[0m%s%s%s" \
    "$model" "$rel_path" "$ctx_info" "$session_info" "$usage_info")

# --- Line 3: System info ---
sys_time=$(date +"%H:%M")

# CPU usage: two /proc/stat samples 0.1s apart (Linux only — falls back gracefully)
cpu_pct="?"
if [ -f /proc/stat ]; then
    cpu_pct=$(awk '{for(i=2;i<=8;i++) t+=$i; print t, $5; exit}' /proc/stat)
    sleep 0.1
    cpu_pct=$(awk -v prev="$cpu_pct" '
    {
        for (i=2;i<=8;i++) t+=$i
        split(prev, p, " ")
        dt = t - p[1]
        di = $5 - p[2]
        if (dt > 0) printf "%d", (dt - di) * 100 / dt
        else print 0
        exit
    }' /proc/stat)
fi

# Memory (Linux)
mem_info=""
if [ -f /proc/meminfo ]; then
    mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    mem_used_kb=$(( mem_total_kb - mem_avail_kb ))
    mem_total_gb=$(awk "BEGIN {printf \"%.1f\", $mem_total_kb/1048576}")
    mem_used_gb=$(awk "BEGIN {printf \"%.1f\", $mem_used_kb/1048576}")
    mem_info="  mem:${mem_used_gb}/${mem_total_gb}G"
fi

# Disk
disk_pct=$(df / --output=pcent 2>/dev/null | tail -1 | tr -d ' %')
disk_info=""
[ -n "$disk_pct" ] && disk_info="  disk:${disk_pct}%"

sys_line=$(printf "%s  cpu:%s%%%s%s" "$sys_time" "$cpu_pct" "$mem_info" "$disk_info")

# --- Line 4: Agent status (multi-session, PID-based cleanup) ---
agent_line=""
agent_status_file=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
    agent_status_file="${repo_root}/.claude/agent-status.json"
fi

if [ -n "$agent_status_file" ] && [ -f "$agent_status_file" ]; then
    agent_line=$(python3 -c '
import json, sys, os
from datetime import datetime, timezone

try:
    with open(sys.argv[1]) as f:
        sessions = json.load(f)
except Exception:
    sessions = {}

# Prune dead sessions (PID no longer alive)
alive = {}
for sid, info in sessions.items():
    pid = info.get("pid")
    if pid and os.path.exists(f"/proc/{pid}"):
        alive[sid] = info

# Write back pruned file if we removed any
if len(alive) != len(sessions):
    try:
        with open(sys.argv[1], "w") as f:
            json.dump(alive, f, indent=2)
            f.write("\n")
    except Exception:
        pass

# Collect active agents
active = []
for sid, info in alive.items():
    if info.get("status") != "active":
        continue
    agent = info.get("agent", "?")
    model = info.get("model", "?")
    goal = info.get("goal", "")
    dispatched_by = info.get("dispatched_by", "")
    started = info.get("started", "")
    elapsed = ""
    if started:
        try:
            t = datetime.fromisoformat(started.replace("Z", "+00:00"))
            delta = datetime.now(timezone.utc) - t
            mins = int(delta.total_seconds() // 60)
            elapsed = "<1m" if mins < 1 else f"{mins}m"
        except Exception:
            pass
    prefix = f"{dispatched_by} -> " if dispatched_by else ""
    active.append(f"{prefix}{agent} ({model}) {goal} [{elapsed}]")

if not active:
    print("\033[90m-- no agents active --\033[0m", end="")
else:
    print("\033[33m" + "\033[0m | \033[33m".join(active) + "\033[0m", end="")
' "$agent_status_file" 2>/dev/null)

    [ -z "$agent_line" ] && agent_line=$(printf "\033[90m-- no agents active --\033[0m")
else
    agent_line=$(printf "\033[90m-- no agents active --\033[0m")
fi

# Output
printf "%s\n%s\n%s\n%s" "$git_line" "$claude_line" "$sys_line" "$agent_line"
