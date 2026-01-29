#!/usr/bin/env bash

# Initialize upstream with clean history using orphan branch
# This creates a new independent history without rewriting existing commits
# After this, sync-to-upstream.sh will work normally

set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================
# CONFIGURATION: Match sync-to-upstream.sh
# ============================================
PRIVATE_FILES=(
    "private-asset.txt"
    "POC-SUMMARY.md"
)

echo -e "${YELLOW}==> Creating clean upstream history (orphan branch approach)...${NC}"
echo ""
echo -e "${YELLOW}Note: This creates a fresh start for upstream without rewriting main's history${NC}"
echo "After this, sync-to-upstream.sh will work for ongoing syncs."
echo ""
read -p "Continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Save current branch
ORIGINAL_BRANCH=$(git branch --show-current)

# Delete existing upstream-public if it exists
echo -e "${YELLOW}==> Removing old upstream-public branch if exists...${NC}"
git branch -D upstream-public 2>/dev/null || true

# Create orphan branch (no history)
echo -e "${YELLOW}==> Creating orphan branch...${NC}"
git checkout --orphan upstream-public

# Remove private files from the working directory
echo -e "${YELLOW}==> Removing private files...${NC}"
for private_file in "${PRIVATE_FILES[@]}"; do
    git rm --cached "$private_file" 2>/dev/null || true
    rm -f "$private_file" 2>/dev/null || true
    echo "  Removed: $private_file"
done

# Commit the clean state
echo -e "${YELLOW}==> Creating initial commit...${NC}"
git commit -m "Initial upstream release (private files excluded)"

echo -e "${GREEN}✓ Orphan branch created${NC}"
echo ""
echo "Current files in upstream-public:"
ls -1

echo ""
read -p "Does this look correct? Push to upstream? (yes/no): " push_confirm

if [[ "$push_confirm" != "yes" ]]; then
    echo "Aborted. Branch 'upstream-public' created locally but not pushed."
    echo "You can push manually with: git push upstream upstream-public:main --force"
    git checkout "$ORIGINAL_BRANCH"
    exit 1
fi

# Push to upstream (force required for initial push)
echo -e "${YELLOW}==> Force pushing to upstream...${NC}"
git push upstream upstream-public:main --force

echo -e "${GREEN}✓ Clean upstream history created and pushed!${NC}"
echo ""
echo -e "${YELLOW}Important: This creates a completely new history in upstream.${NC}"
echo "From now on, use sync-to-upstream.sh to sync new commits."
echo ""
echo "How it works going forward:"
echo "  1. Make commits on 'main' (with private files)"
echo "  2. Run './sync-to-upstream.sh' to sync"
echo "  3. Script rebases upstream-public onto main, auto-removing private files"

# Return to original branch
git checkout "$ORIGINAL_BRANCH"

echo -e "${GREEN}✓ All done!${NC}"
