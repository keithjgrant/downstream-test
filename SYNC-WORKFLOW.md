# Upstream Sync Workflow

This repository uses a branch-based strategy to maintain a public upstream fork while keeping certain files private in downstream.

## Repository Structure

- **downstream-test** (this repo): Private repository with all files
- **upstream-test**: Public repository with private files excluded

## Branch Strategy

- `main`: Primary development branch (contains all files, including private ones)
- `upstream-public`: Filtered branch that mirrors main but excludes private files

## Private Files (Excluded from Upstream)

- `private-asset.txt` - Proprietary configuration
- Any future branding assets, internal docs, or integration tests

## How It Works

1. All development happens on `main` branch in downstream
2. The `upstream-public` branch tracks `main` but with private files removed
3. When syncing, we rebase `upstream-public` onto `main`, which replays new commits while keeping private files deleted
4. The filtered branch is pushed to upstream repo

## Initial Setup (Already Done)

```fish
# Add upstream remote
git remote add upstream ~/src/upstream-test

# Create upstream-public branch
git checkout -b upstream-public
git rm private-asset.txt
git commit -m "Remove private assets for upstream release"

# Push to upstream
git push upstream upstream-public:main
```

## Syncing Changes to Upstream

### Automated (Recommended)

Simply run:

```fish
./sync-to-upstream.fish
```

### Manual Process

```fish
# 1. Checkout upstream-public branch
git checkout upstream-public

# 2. Rebase onto main (pulls in new changes)
git rebase main

# 3. If conflicts occur (likely with private files):
#    - Keep files deleted: git rm <file>
#    - Continue rebase: git rebase --continue

# 4. Push to upstream
git push upstream upstream-public:main --force-with-lease

# 5. Return to main
git checkout main
```

## Handling Mixed Commits

If a commit touches both public and private files:
- The commit is rebased onto `upstream-public`
- Git will detect conflict with deleted `private-asset.txt`
- Resolve by keeping it deleted: `git rm private-asset.txt`
- The public file changes are preserved

**Example:**
```
Commit on main:
  - Modified: normal-asset.txt ✓
  - Modified: private-asset.txt ✗

After rebase to upstream-public:
  - Modified: normal-asset.txt ✓
  (private-asset.txt stays deleted)
```

## Testing the Workflow

```fish
# 1. Make changes on main
git checkout main
echo "New content" >> normal-asset.txt
git add -A && git commit -m "Add feature"

# 2. Sync to upstream
./sync-to-upstream.fish

# 3. Verify upstream doesn't have private files
cd ~/src/upstream-test
ls -la  # Should only show normal-asset.txt
```

## Key Benefits

- ✅ Maintains clean history in both repos
- ✅ Handles mixed commits (touching both public and private files)
- ✅ Safe force-push with `--force-with-lease`
- ✅ Simple conflict resolution
- ✅ No dependency on external tools beyond git

## Troubleshooting

**Rebase conflicts:**
- Always keep private files deleted
- `git rm <private-file>` then `git rebase --continue`

**Push rejected:**
- Ensure upstream is configured: `git config receive.denyCurrentBranch updateInstead`
- Or push with `--force-with-lease` (safe version of force push)

**Lost changes:**
- All history is preserved in `main` branch
- `upstream-public` is just a filtered view
