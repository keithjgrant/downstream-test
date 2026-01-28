#!/usr/bin/env bash

# Sync downstream changes to upstream
# This script rebases the upstream-public branch onto main,
# ensuring private assets remain excluded

set -e  # Exit on error

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}==> Starting upstream sync...${NC}"

# Save current branch
ORIGINAL_BRANCH=$(git branch --show-current)

# Ensure we're on a clean working tree
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${RED}✗ Working directory is not clean. Commit or stash changes first.${NC}"
    exit 1
fi

echo -e "${YELLOW}==> Fetching latest changes...${NC}"
git fetch origin

echo -e "${YELLOW}==> Checking out upstream-public branch...${NC}"
git checkout upstream-public

echo -e "${YELLOW}==> Rebasing upstream-public onto main...${NC}"
if git rebase main; then
    echo -e "${GREEN}✓ Rebase successful${NC}"
else
    echo -e "${RED}✗ Rebase has conflicts. Resolve them manually:${NC}"
    echo "  1. Fix conflicts (ensure private-asset.txt stays deleted)"
    echo "  2. git add/rm conflicted files"
    echo "  3. git rebase --continue"
    echo "  4. Re-run this script"
    exit 1
fi

echo -e "${YELLOW}==> Pushing to upstream...${NC}"
if git push upstream upstream-public:main --force-with-lease; then
    echo -e "${GREEN}✓ Successfully synced to upstream!${NC}"
else
    echo -e "${RED}✗ Push failed. Check remote configuration.${NC}"
    exit 1
fi

echo -e "${YELLOW}==> Returning to original branch...${NC}"
git checkout "$ORIGINAL_BRANCH"

echo -e "${GREEN}==> Sync complete!${NC}"
echo ""
echo "Upstream status:"
git log upstream-public --oneline -3
