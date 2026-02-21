#!/bin/bash

# Sync published notes from Obsidian vault to Quartz content directory
# Filters notes with `publish: true` in frontmatter
# Strips private fields (project, status) before copying

set -euo pipefail

VAULT_PATH="/Users/athumb/Library/CloudStorage/GoogleDrive-uumj222@gmail.com/내 드라이브/Obsidian/second-brain"
CONTENT_DIR="$(cd "$(dirname "$0")" && pwd)/content"

# Clean previous content (except index.md which is Quartz's landing page)
find "$CONTENT_DIR" -name "*.md" ! -name "index.md" -delete 2>/dev/null
find "$CONTENT_DIR" -type d -empty -delete 2>/dev/null

COPIED=0

# Find all .md files with publish: true
while IFS= read -r -d '' file; do
  # Check if frontmatter contains publish: true
  if head -50 "$file" | grep -q "^publish:\s*true"; then
    # Get relative path from vault
    rel_path="${file#"$VAULT_PATH"/}"
    dest="$CONTENT_DIR/$rel_path"
    dest_dir="$(dirname "$dest")"

    # Create destination directory
    mkdir -p "$dest_dir"

    # Copy and strip private frontmatter fields
    sed \
      -e '/^project:/d' \
      -e '/^status:/d' \
      -e 's/^publish: true$//' \
      "$file" > "$dest"

    COPIED=$((COPIED + 1))
    echo "  ✓ $rel_path"
  fi
done < <(find "$VAULT_PATH" -name "*.md" -not -path "*/.obsidian/*" -not -path "*/90-Templates/*" -print0)

echo ""
echo "Synced $COPIED published notes to content/"
