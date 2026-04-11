#!/bin/bash
#
# sync-method.sh — Pull method repo content into a consuming project
#
# Usage:
#   ./scripts/sync-method.sh              # Sync from main
#   ./scripts/sync-method.sh v1.0         # Sync from a specific tag/branch
#   ./scripts/sync-method.sh --dry-run    # Show what would change
#
# What it syncs:
#   method/sop/        <- SOPs (Code Quality, Git, Linear, Skills, VBW)
#   method/templates/  <- Spec and review templates
#   method/method.md   <- The methodology overview
#   .claude/skills/    <- Portable skills (won't touch project-specific ones)
#
# What it does NOT touch:
#   method/decisions/       <- Project-specific ADRs
#   .claude/rules/          <- Project coding conventions
#   .claude/skills/{local}  <- Project-specific skills
#   .vbw-planning/          <- Project state
#   method.config.md        <- Project configuration

set -euo pipefail

METHOD_REPO="${METHOD_REPO:-https://github.com/ethan-piper/pipekit.git}"
REF="${1:-main}"
DRY_RUN=false
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true; shift ;;
  esac
done
REF="${1:-main}"

echo "=== Method Sync ==="
echo "Source: $METHOD_REPO @ $REF"
echo "Target: $PROJECT_ROOT"
echo ""

# Clone to temp directory
TEMP=$(mktemp -d)
trap "rm -rf $TEMP" EXIT

echo "Fetching method repo..."
git clone --depth 1 --branch "$REF" "$METHOD_REPO" "$TEMP" 2>/dev/null || {
  echo "ERROR: Failed to clone $METHOD_REPO at ref $REF"
  exit 1
}

# Track changes
CHANGES=0

sync_dir() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [ ! -d "$src" ]; then
    echo "  SKIP $label (source not found)"
    return
  fi

  mkdir -p "$dst"

  if $DRY_RUN; then
    local diff_count
    diff_count=$(diff -rq "$src" "$dst" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$diff_count" -gt 0 ]; then
      echo "  WOULD UPDATE $label ($diff_count files differ)"
      diff -rq "$src" "$dst" 2>/dev/null | head -10 | sed 's/^/    /'
      CHANGES=$((CHANGES + diff_count))
    else
      echo "  OK $label (no changes)"
    fi
  else
    rsync -av --delete "$src/" "$dst/" | tail -n +2 | head -20 | sed 's/^/    /'
    echo "  SYNCED $label"
    CHANGES=$((CHANGES + 1))
  fi
}

sync_file() {
  local src="$1"
  local dst="$2"
  local label="$3"

  if [ ! -f "$src" ]; then
    echo "  SKIP $label (source not found)"
    return
  fi

  if $DRY_RUN; then
    if [ -f "$dst" ] && diff -q "$src" "$dst" >/dev/null 2>&1; then
      echo "  OK $label (no changes)"
    else
      echo "  WOULD UPDATE $label"
      CHANGES=$((CHANGES + 1))
    fi
  else
    cp "$src" "$dst"
    echo "  SYNCED $label"
    CHANGES=$((CHANGES + 1))
  fi
}

# --- Sync method docs ---
echo ""
echo "Method docs:"
mkdir -p "$PROJECT_ROOT/method"
sync_dir "$TEMP/sop" "$PROJECT_ROOT/method/sop" "sop/"
sync_dir "$TEMP/templates" "$PROJECT_ROOT/method/templates" "templates/"
sync_file "$TEMP/method.md" "$PROJECT_ROOT/method/method.md" "method.md"
sync_file "$TEMP/GUIDE.md" "$PROJECT_ROOT/method/GUIDE.md" "GUIDE.md"
sync_file "$TEMP/METHOD_IMPROVEMENTS.md" "$PROJECT_ROOT/method/METHOD_IMPROVEMENTS.md" "METHOD_IMPROVEMENTS.md"
sync_file "$TEMP/STARTUP.md" "$PROJECT_ROOT/method/STARTUP.md" "STARTUP.md"

# --- Sync portable skills ---
echo ""
echo "Portable skills:"

# Get list of portable skills from method repo
PORTABLE_SKILLS=$(ls -d "$TEMP/skills/"*/ 2>/dev/null | xargs -I{} basename {})

for skill in $PORTABLE_SKILLS; do
  src="$TEMP/skills/$skill"
  dst="$PROJECT_ROOT/.claude/skills/$skill"

  if [ ! -d "$src" ]; then
    continue
  fi

  mkdir -p "$dst"

  if $DRY_RUN; then
    if [ -d "$dst" ]; then
      local diff_count
      diff_count=$(diff -rq "$src" "$dst" 2>/dev/null | wc -l | tr -d ' ')
      if [ "$diff_count" -gt 0 ]; then
        echo "  WOULD UPDATE skill: $skill"
        CHANGES=$((CHANGES + 1))
      else
        echo "  OK skill: $skill"
      fi
    else
      echo "  WOULD CREATE skill: $skill"
      CHANGES=$((CHANGES + 1))
    fi
  else
    rsync -av "$src/" "$dst/" >/dev/null 2>&1
    echo "  SYNCED skill: $skill"
    CHANGES=$((CHANGES + 1))
  fi
done

# --- Sync scripts ---
echo ""
echo "Scripts:"
sync_file "$TEMP/scripts/drift-check.sh" "$PROJECT_ROOT/scripts/drift-check.sh" "drift-check.sh"
# Make drift-check executable
if [ -f "$PROJECT_ROOT/scripts/drift-check.sh" ]; then
  chmod +x "$PROJECT_ROOT/scripts/drift-check.sh"
fi

# --- Check for method.config.md ---
echo ""
if [ ! -f "$PROJECT_ROOT/method.config.md" ]; then
  if $DRY_RUN; then
    echo "NOTE: method.config.md not found. Would copy template."
  else
    cp "$TEMP/method.config.template.md" "$PROJECT_ROOT/method.config.md"
    echo "CREATED method.config.md from template — fill in your project values!"
  fi
fi

# --- Summary ---
echo ""
echo "=== Sync Complete ==="
if $DRY_RUN; then
  echo "Dry run: $CHANGES items would change"
  echo "Remove --dry-run to apply"
else
  echo "Synced from: $METHOD_REPO @ $REF"
  echo ""
  echo "Next steps:"
  echo "  1. Edit method.config.md with your project's Linear workspace, state IDs, etc."
  echo "  2. Commit the synced files"
  echo "  3. Skills are ready to use"
fi
