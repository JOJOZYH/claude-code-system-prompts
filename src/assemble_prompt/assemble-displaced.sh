#!/usr/bin/env bash
# assemble-displaced.sh — concatenate the default main-session components that
# `--agent` replaces, from your own clone of the extraction repo.
#
#   git clone https://github.com/Piebald-AI/claude-code-system-prompts
#   ./assemble-displaced.sh claude-code-system-prompts > displaced.md
#
# Order below follows the harness's assembly order as far as it can be inferred.
# Treat it as close, not authoritative — a proxy capture is the only ground truth.

set -euo pipefail

REPO="${1:-.}"
DIR="$REPO/system-prompts"

[[ -d "$DIR" ]] || { echo "no system-prompts/ under $REPO" >&2; exit 1; }

# Components displaced when --agent supplies the system prompt.
# Comment out any you decide you don't need to replicate.
COMPONENTS=(
  # --- identity + harness ---
  system-prompt-harness-instructions
  system-prompt-system-section

  # --- doing tasks (scope + safety) ---
  system-prompt-doing-tasks-software-engineering-focus
  system-prompt-doing-tasks-no-unnecessary-additions
  system-prompt-doing-tasks-no-unnecessary-error-handling
  system-prompt-doing-tasks-no-compatibility-hacks
  system-prompt-doing-tasks-security
  system-prompt-doing-tasks-ambitious-tasks
  system-prompt-doing-tasks-help-and-feedback
  system-prompt-prefer-editing-existing-files

  # --- action safety ---
  system-prompt-executing-actions-with-care
  system-prompt-action-safety-and-truthful-reporting

  # --- tone / communication ---
  system-prompt-communication-style
  system-prompt-tone-and-style-code-references
  system-prompt-tone-and-style-concise-output-short
  system-prompt-emoji-avoidance
  system-prompt-tool-call-colon-avoidance

  # --- tool usage ---
  system-prompt-tool-usage-task-management
  system-prompt-tool-usage-subagent-guidance
  system-prompt-parallel-tool-call-note-part-of-tool-usage-policy

  # --- delegation (only if your agent spawns workers) ---
  system-prompt-subagent-delegation-restraint
  system-prompt-subagent-delegation-examples

  # --- conditional: only if auto-memory is configured ---
  # system-prompt-memory-instructions
  # system-prompt-memory-persistence-scope
)

total=0
missing=0

for name in "${COMPONENTS[@]}"; do
  f="$DIR/$name.md"
  if [[ ! -f "$f" ]]; then
    echo "<!-- MISSING in this version: $name -->" 
    echo
    missing=$((missing + 1))
    continue
  fi
  chars=$(wc -c < "$f")
  total=$((total + chars))
  echo "<!-- ==== $name (${chars}c) ==== -->"
  echo
  cat "$f"
  echo
done

{
  echo "assembled ${#COMPONENTS[@]} components, $missing missing, ~${total} chars" 
  echo "rough token estimate: $((total / 4))"
} >&2
