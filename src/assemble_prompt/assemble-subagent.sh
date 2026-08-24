#!/usr/bin/env bash
# assemble-subagent.sh — show what a CUSTOM subagent's body replaces, versus what
# the built-in general-purpose worker gets, from your own clone of the repo.
#
#   git clone https://github.com/Piebald-AI/claude-code-system-prompts
#   ./assemble-subagent.sh claude-code-system-prompts general-purpose > gp.md
#   ./assemble-subagent.sh claude-code-system-prompts explore         > explore.md
#   ./assemble-subagent.sh claude-code-system-prompts shared          > shared.md
#
# The picture is much simpler than the main-session case: a custom subagent's
# markdown body substitutes for ONE file (the built-in worker prompt). Everything
# else on the subagent side is either shared regardless, or conditional on how the
# worker was spawned (background / fork / worktree).

set -euo pipefail

REPO="${1:-.}"
MODE="${2:-general-purpose}"
DIR="$REPO/system-prompts"

[[ -d "$DIR" ]] || { echo "no system-prompts/ under $REPO" >&2; exit 1; }

# ---- what your custom body SUBSTITUTES FOR -------------------------------
# Pick the built-in whose slot your agent takes.
case "$MODE" in
  general-purpose)
    REPLACED=(
      agent-prompt-general-task-agent      # opening block, interpolated by the below
      agent-prompt-general-purpose         # the actual worker system prompt
      agent-prompt-general-purpose-agent   # description string shown in the Agent tool
    )
    ;;
  explore)
    REPLACED=( agent-prompt-explore )
    ;;
  plan)
    REPLACED=( agent-prompt-plan-mode-enhanced )
    ;;
  shared)
    REPLACED=()
    ;;
  *)
    echo "modes: general-purpose | explore | plan | shared" >&2; exit 1
    ;;
esac

# ---- what stays regardless of whose body is in the slot -------------------
SHARED=(
  system-prompt-agent-thread-notes              # cwd resets, absolute paths, no emoji, tool-call punctuation
  tool-description-agent-explicit-spawn-restriction
  tool-description-agent-simple-usage-notes
)

# ---- conditional on HOW the worker was spawned ---------------------------
CONDITIONAL=(
  system-prompt-background-session-instructions        # --bg / background workers
  system-prompt-background-worktree-isolation-guidance # EnterWorktree enforcement
  system-prompt-forked-agent-guidance                  # subagent_type: "fork"
  system-prompt-worker-instructions                    # coordinator-driven workers
  system-prompt-teammate-communication                 # agent teams
)

emit() {
  local header="$1"; shift
  local names=("$@")
  [[ ${#names[@]} -eq 0 ]] && return 0
  echo "<!-- ######## $header ######## -->"
  echo
  local total=0
  for name in "${names[@]}"; do
    local f="$DIR/$name.md"
    if [[ ! -f "$f" ]]; then
      echo "<!-- MISSING in this version: $name -->"; echo
      continue
    fi
    local chars; chars=$(wc -c < "$f")
    total=$((total + chars))
    echo "<!-- ==== $name (${chars}c) ==== -->"
    echo
    cat "$f"
    echo
  done
  echo "$header: ~${total} chars (~$((total / 4)) tks)" >&2
}

if [[ ${#REPLACED[@]} -gt 0 ]]; then
  emit "REPLACED by your custom subagent body" "${REPLACED[@]}"
fi
emit "SHARED — present either way" "${SHARED[@]}"
emit "CONDITIONAL — depends on spawn mode" "${CONDITIONAL[@]}"

cat >&2 <<'EOF'

Reading the output:
  * REPLACED   — your markdown body goes here instead. For general-purpose that's
                 ~700 tks total, against ~4700 tks on the main-session side.
  * SHARED     — you do not need to restate these; they arrive regardless.
  * CONDITIONAL— only injected for background/fork/worktree/team spawns. If your
                 agent only ever runs in the foreground, ignore them.

Which means: a custom subagent body needs to cover the task boundary, the report
contract back to the caller, and any domain method. It does NOT need permission
handling, terminal output conventions, or interactive tone — those either don't
apply or arrive via SHARED and the tools array.
EOF
