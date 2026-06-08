#!/usr/bin/env bash
# build-prompts.sh — extract the canonical fakoli-crew prompts into this repo's agents/.
# Run once (or when the upstream prompts change). Requires a fakoli-plugins checkout.
#
#   FAKOLI_PLUGINS=/path/to/fakoli-plugins ./scripts/build-prompts.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FAKOLI_PLUGINS="${FAKOLI_PLUGINS:-$HOME/ai-code/remote-cowork/fakoli-plugins}"
SRC="$FAKOLI_PLUGINS/plugins/fakoli-crew/agents"
REF_SRC="$FAKOLI_PLUGINS/plugins/fakoli-crew/skills/crew-ops/references"

if [ ! -d "$SRC" ]; then
  echo "ERROR: fakoli-crew agents not found at $SRC" >&2
  echo "Set FAKOLI_PLUGINS to your fakoli-plugins checkout." >&2
  exit 1
fi

echo "Extracting crew prompts -> agents/"
for name in guido critic scout smith welder herald keeper sentinel; do
  out="$REPO_DIR/agents/fakoli-$name"
  mkdir -p "$out"
  # Strip the leading YAML frontmatter (the first two '---' delimiter lines)
  # and keep the prompt body (which becomes the OpenClaw agent's AGENTS.md).
  awk 'c<2 && /^---[ \t]*$/ {c=c+1; next} c>=2 {print}' "$SRC/$name.md" > "$out/AGENTS.md"
  echo "  agents/fakoli-$name/AGENTS.md ($(wc -l < "$out/AGENTS.md") lines)"
done

# Bundle the shared crew-ops reference files (prompts read references/*.md at runtime).
if [ -d "$REF_SRC" ]; then
  mkdir -p "$REPO_DIR/agents/_references"
  cp -a "$REF_SRC/." "$REPO_DIR/agents/_references/" 2>/dev/null || true
  echo "  agents/_references/ ($(ls -1 "$REPO_DIR/agents/_references" 2>/dev/null | wc -l | tr -d ' ') files)"
fi

echo "Done. Review the generated prompts, then commit agents/."
