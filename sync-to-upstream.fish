#!/usr/bin/env fish

# Sync downstream changes to upstream
# This script rebases the upstream-public branch onto main,
# ensuring private assets remain excluded

set -l YELLOW '\033[1;33m'
set -l GREEN '\033[0;32m'
set -l RED '\033[0;31m'
set -l NC '\033[0m' # No Color

echo -e "$YELLOW==> Starting upstream sync...$NC"

# Save current branch
set -l ORIGINAL_BRANCH (git branch --show-current)

# Ensure we're on a clean working tree
if test -n (git status --porcelain)
    echo -e "$RED✗ Working directory is not clean. Commit or stash changes first.$NC"
    exit 1
end

echo -e "$YELLOW==> Fetching latest changes...$NC"
git fetch origin

echo -e "$YELLOW==> Checking out upstream-public branch...$NC"
git checkout upstream-public

echo -e "$YELLOW==> Rebasing upstream-public onto main...$NC"
if git rebase main
    echo -e "$GREEN✓ Rebase successful$NC"
else
    echo -e "$RED✗ Rebase has conflicts. Resolve them manually:$NC"
    echo "  1. Fix conflicts (ensure private-asset.txt stays deleted)"
    echo "  2. git add/rm conflicted files"
    echo "  3. git rebase --continue"
    echo "  4. Re-run this script"
    exit 1
end

echo -e "$YELLOW==> Pushing to upstream...$NC"
if git push upstream upstream-public:main --force-with-lease
    echo -e "$GREEN✓ Successfully synced to upstream!$NC"
else
    echo -e "$RED✗ Push failed. Check remote configuration.$NC"
    exit 1
end

echo -e "$YELLOW==> Returning to original branch...$NC"
git checkout $ORIGINAL_BRANCH

echo -e "$GREEN==> Sync complete!$NC"
echo ""
echo "Upstream status:"
git log upstream-public --oneline -3
