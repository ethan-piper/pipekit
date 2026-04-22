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
CHANGELOG="$PROJECT_ROOT/method/.sync-changelog.md"

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

# Clone to temp directory (or reuse one passed from a self-update re-exec)
if [ -n "${SYNC_METHOD_TEMP:-}" ] && [ -d "$SYNC_METHOD_TEMP" ]; then
  TEMP="$SYNC_METHOD_TEMP"
  unset SYNC_METHOD_TEMP
  trap "rm -rf $TEMP" EXIT
  echo "Reusing repo clone from self-update re-exec."
else
  TEMP=$(mktemp -d)
  trap "rm -rf $TEMP" EXIT

  echo "Fetching method repo..."
  git clone --depth 1 --branch "$REF" "$METHOD_REPO" "$TEMP" 2>/dev/null || {
    echo "ERROR: Failed to clone $METHOD_REPO at ref $REF"
    exit 1
  }
fi

# --- Self-update guard: if the upstream sync-method.sh differs from the one we're
# running, install the new version and re-exec with it. This makes single-invocation
# syncs always use the latest logic, even when new files or sync steps are added.
# The SYNC_METHOD_REEXEC flag prevents an infinite re-exec loop.
if [ -z "${SYNC_METHOD_REEXEC:-}" ] && [ -f "$TEMP/scripts/sync-method.sh" ]; then
  SELF_PATH=$(cd "$(dirname "$0")" 2>/dev/null && pwd -P)/$(basename "$0")
  if [ -f "$SELF_PATH" ] && ! cmp -s "$TEMP/scripts/sync-method.sh" "$SELF_PATH"; then
    echo ""
    echo "=== sync-method.sh self-update detected — installing and re-execing ==="
    cp "$TEMP/scripts/sync-method.sh" "$SELF_PATH"
    chmod +x "$SELF_PATH"
    export SYNC_METHOD_REEXEC=1
    export SYNC_METHOD_TEMP="$TEMP"
    trap - EXIT   # keep TEMP alive for the re-exec
    exec "$SELF_PATH" "$@"
  fi
fi

# --- Pre-sync: snapshot current state for changelog ---
SNAP=$(mktemp -d)
snapshot_dir() {
  local dir="$1"
  local label="$2"
  if [ -d "$dir" ]; then
    find "$dir" -type f -exec md5sum {} \; 2>/dev/null | sort > "$SNAP/$label.md5"
  else
    touch "$SNAP/$label.md5"
  fi
}

snapshot_dir "$PROJECT_ROOT/.claude/skills" "skills"
snapshot_dir "$PROJECT_ROOT/method" "method"

# Track changes
CHANGES=0

# Changelog arrays
NEW_SKILLS=""
UPDATED_SKILLS=""
REMOVED_SKILLS=""
UPDATED_FILES=""
NEW_FILES=""

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
sync_file "$TEMP/STARTUP.md" "$PROJECT_ROOT/method/STARTUP.md" "STARTUP.md"

# --- Sync Pipekit hook scripts (VBW lifecycle integration) ---
echo ""
echo "Hook scripts:"
mkdir -p "$PROJECT_ROOT/scripts"
sync_file "$TEMP/scripts/pipekit-post-archive.sh" "$PROJECT_ROOT/scripts/pipekit-post-archive.sh" "scripts/pipekit-post-archive.sh"
[ -f "$PROJECT_ROOT/scripts/pipekit-post-archive.sh" ] && chmod +x "$PROJECT_ROOT/scripts/pipekit-post-archive.sh"

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

  # Track new vs updated
  if [ ! -d "$dst" ]; then
    NEW_SKILLS="$NEW_SKILLS $skill"
  elif ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
    UPDATED_SKILLS="$UPDATED_SKILLS $skill"
  fi

  mkdir -p "$dst"

  if $DRY_RUN; then
    if [ -d "$dst" ]; then
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

# Check for skills that exist locally but not in the method repo (removed/renamed)
if [ -d "$PROJECT_ROOT/.claude/skills" ]; then
  for existing_skill_dir in "$PROJECT_ROOT/.claude/skills"/*/; do
    existing_skill=$(basename "$existing_skill_dir")
    if [ ! -d "$TEMP/skills/$existing_skill" ]; then
      # Could be project-specific or a removed portable skill
      # Only flag it if it has no project-specific marker
      if [ -f "$existing_skill_dir/skill.md" ]; then
        # Check if this was a portable skill (existed in a previous sync)
        if grep -q "^  SYNCED skill: $existing_skill" "$PROJECT_ROOT/method/.sync-changelog.md" 2>/dev/null || \
           echo "$PORTABLE_SKILLS" | grep -qv "$existing_skill"; then
          REMOVED_SKILLS="$REMOVED_SKILLS $existing_skill"
        fi
      fi
    fi
  done
fi

# --- Sync scripts ---
echo ""
echo "Scripts:"
sync_file "$TEMP/scripts/drift-check.sh" "$PROJECT_ROOT/scripts/drift-check.sh" "drift-check.sh"
# Also update the sync script itself
sync_file "$TEMP/scripts/sync-method.sh" "$PROJECT_ROOT/scripts/sync-method.sh" "sync-method.sh"
# Make scripts executable
for script in drift-check.sh sync-method.sh; do
  if [ -f "$PROJECT_ROOT/scripts/$script" ]; then
    chmod +x "$PROJECT_ROOT/scripts/$script"
  fi
done

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

# --- Post-sync: generate changelog ---
if ! $DRY_RUN; then
  # Compare method files
  for f in method.md GUIDE.md STARTUP.md; do
    dst="$PROJECT_ROOT/method/$f"
    if [ -f "$dst" ]; then
      old_hash=$(grep "$dst" "$SNAP/method.md5" 2>/dev/null | awk '{print $1}' || true)
      new_hash=$(md5sum "$dst" 2>/dev/null | awk '{print $1}')
      if [ "$old_hash" != "$new_hash" ]; then
        UPDATED_FILES="$UPDATED_FILES $f"
      fi
    fi
  done

  # Write changelog
  SYNC_DATE=$(date '+%Y-%m-%d %H:%M')
  cat > "$CHANGELOG" << CHLOG
# Sync Changelog

**Synced:** $SYNC_DATE
**Source:** $METHOD_REPO @ $REF

## Skills

CHLOG

  if [ -n "$NEW_SKILLS" ]; then
    echo "### New" >> "$CHANGELOG"
    for s in $NEW_SKILLS; do
      desc=""
      if [ -f "$PROJECT_ROOT/.claude/skills/$s/skill.md" ]; then
        desc=$(grep '^description:' "$PROJECT_ROOT/.claude/skills/$s/skill.md" 2>/dev/null | head -1 | sed 's/^description: *//')
      fi
      echo "- \`/$s\` — $desc" >> "$CHANGELOG"
    done
    echo "" >> "$CHANGELOG"
  fi

  if [ -n "$UPDATED_SKILLS" ]; then
    echo "### Updated" >> "$CHANGELOG"
    for s in $UPDATED_SKILLS; do
      echo "- \`/$s\`" >> "$CHANGELOG"
    done
    echo "" >> "$CHANGELOG"
  fi

  if [ -n "$REMOVED_SKILLS" ]; then
    echo "### Possibly Removed/Renamed" >> "$CHANGELOG"
    for s in $REMOVED_SKILLS; do
      echo "- \`/$s\` — exists locally but not in method repo (may be renamed or project-specific)" >> "$CHANGELOG"
    done
    echo "" >> "$CHANGELOG"
  fi

  if [ -z "$NEW_SKILLS" ] && [ -z "$UPDATED_SKILLS" ] && [ -z "$REMOVED_SKILLS" ]; then
    echo "No skill changes." >> "$CHANGELOG"
    echo "" >> "$CHANGELOG"
  fi

  echo "## Method Docs" >> "$CHANGELOG"
  if [ -n "$UPDATED_FILES" ]; then
    for f in $UPDATED_FILES; do
      echo "- \`$f\` — updated" >> "$CHANGELOG"
    done
  else
    echo "No doc changes." >> "$CHANGELOG"
  fi
  echo "" >> "$CHANGELOG"

  echo "## Config" >> "$CHANGELOG"
  # Check if template has fields not in project config
  if [ -f "$PROJECT_ROOT/method.config.md" ] && [ -f "$TEMP/method.config.template.md" ]; then
    new_fields=$(diff <(grep '^\| \*\*' "$PROJECT_ROOT/method.config.md" 2>/dev/null | sort) \
                      <(grep '^\| \*\*' "$TEMP/method.config.template.md" 2>/dev/null | sort) \
                      2>/dev/null | grep '^>' | sed 's/^> //' || true)
    if [ -n "$new_fields" ]; then
      echo "New fields in template (may need adding to method.config.md):" >> "$CHANGELOG"
      echo "$new_fields" | while read -r line; do
        echo "- $line" >> "$CHANGELOG"
      done
    else
      echo "No new config fields." >> "$CHANGELOG"
    fi
  else
    echo "No config comparison available." >> "$CHANGELOG"
  fi
  echo "" >> "$CHANGELOG"
  echo "---" >> "$CHANGELOG"
  echo "_Read by \`/pipekit-update\` for reconciliation. Safe to delete after review._" >> "$CHANGELOG"

  echo ""
  echo "Changelog written to: method/.sync-changelog.md"
fi

# Clean up snapshot
rm -rf "$SNAP"

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
  echo "  1. Review method/.sync-changelog.md for what changed"
  echo "  2. Run /pipekit-update reconciliation (restart Claude Code first)"
  echo "  3. Commit the synced files"
fi
