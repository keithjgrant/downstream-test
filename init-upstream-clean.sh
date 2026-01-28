#!/usr/bin/env bash

# Initialize upstream with clean history (no private files ever existed)
# This uses git-filter-repo to rewrite history ONCE during initial setup

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

echo -e "${YELLOW}==> Creating clean upstream history (one-time operation)...${NC}"
echo ""
echo -e "${RED}WARNING: This will rewrite git history!${NC}"
echo "This script should only be run ONCE during initial setup."
echo "After this, use sync-to-upstream.sh for ongoing syncs."
echo ""
read -p "Continue? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Save current branch
ORIGINAL_BRANCH=$(git branch --show-current)

# Create a temporary working directory
TEMP_DIR=$(mktemp -d)
echo -e "${YELLOW}==> Creating temporary clone in $TEMP_DIR...${NC}"

# Clone current repo to temp directory
git clone . "$TEMP_DIR"
cd "$TEMP_DIR"

echo -e "${YELLOW}==> Removing private files from all history...${NC}"

# Check if git-filter-repo is available
if ! command -v git-filter-repo &> /dev/null; then
    echo -e "${RED}✗ git-filter-repo is not installed.${NC}"
    echo "Install it with: pip install git-filter-repo"
    echo "Or: brew install git-filter-repo"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Build filter-repo arguments
FILTER_ARGS=()
for private_file in "${PRIVATE_FILES[@]}"; do
    FILTER_ARGS+=("--path" "$private_file" "--invert-paths")
done

# Run filter-repo
git-filter-repo "${FILTER_ARGS[@]}" --force

echo -e "${YELLOW}==> Filtered history created${NC}"
echo "Commits in filtered history:"
git log --oneline | head -10

echo ""
read -p "Does this history look correct? Push to upstream? (yes/no): " push_confirm

if [[ "$push_confirm" != "yes" ]]; then
    echo "Aborted. Temporary directory preserved at: $TEMP_DIR"
    echo "You can inspect it and manually push if desired."
    exit 1
fi

# Add upstream remote
echo -e "${YELLOW}==> Configuring upstream remote...${NC}"
git remote add upstream git@github.com:keithjgrant/upstream-test.git

# Force push to upstream
echo -e "${YELLOW}==> Force pushing clean history to upstream...${NC}"
git push upstream main:main --force

echo -e "${GREEN}✓ Clean upstream history created and pushed!${NC}"
echo ""
echo -e "${YELLOW}==> Updating local upstream-public branch...${NC}"

# Go back to original repo
cd -

# Delete and recreate upstream-public branch to match the filtered history
git branch -D upstream-public 2>/dev/null || true
git fetch upstream
git checkout -b upstream-public upstream/main

echo -e "${GREEN}==> Complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify upstream repo has clean history (no private files)"
echo "  2. Use sync-to-upstream.sh for all future syncs"
echo ""
echo "Cleaning up temporary directory..."
rm -rf "$TEMP_DIR"

# Return to original branch
git checkout "$ORIGINAL_BRANCH"

echo -e "${GREEN}✓ All done!${NC}"
