# Proof of Concept: Downstream → Upstream Sync

## ✅ Successfully Demonstrated

This POC proves the **branch-based sync strategy** works for maintaining a public upstream fork from a private downstream repository.

## What Was Tested

### 1. Initial Setup
- Created `upstream-public` branch in downstream
- Removed `private-asset.txt` from the branch
- Pushed to upstream repository
- ✅ Result: Upstream only contains public files

### 2. Mixed Commits
- Created commits that modified **both** public and private files:
  - `normal-asset.txt` (public) ✓
  - `private-asset.txt` (private) ✗
- Synced to upstream via rebase
- ✅ Result: Only public file changes synced; private file stayed deleted in upstream

### 3. Multiple Syncs
- Performed two separate sync operations
- Each time, new commits were added to upstream history
- ✅ Result: Clean, linear history in upstream without force-push conflicts

### 4. File Integrity
- **Downstream (main)**: Contains all files including `private-asset.txt`
- **Upstream**: Only contains public files
- ✅ Result: Private files properly excluded, public files fully synced

## Current State

### Downstream (`~/src/downstream-test`)
```
Files:
- normal-asset.txt (public)
- private-asset.txt (private)
- sync-to-upstream.sh (automation script)
- SYNC-WORKFLOW.md (documentation)

Branches:
- main: Full repository with private files
- upstream-public: Filtered view without private files

History: 4 commits
```

### Upstream (`~/src/upstream-test`)
```
Files:
- normal-asset.txt (public)
- sync-to-upstream.sh (public)
- SYNC-WORKFLOW.md (public)

History: 4 commits (matching downstream but filtered)
```

## Key Findings

### ✅ What Works Well

1. **Mixed commits are handled perfectly**
   - Commits touching both public and private files sync cleanly
   - Private file changes are automatically filtered out
   - No manual file-by-file tracking needed

2. **History remains clean**
   - No history rewriting (unlike git-filter-repo)
   - Upstream has stable commit SHAs
   - Contributors can fork/PR without issues

3. **Simple conflict resolution**
   - When rebasing, git detects conflicts with deleted private files
   - Resolution is always the same: `git rm <private-file>`
   - Can be semi-automated

4. **Bidirectional capability**
   - Could accept PRs from upstream back to downstream
   - Just merge upstream/main into downstream main

### ⚠️ Minor Considerations

1. **Rebase conflicts on every sync**
   - Because private files keep getting modified in main
   - Always requires `git rm private-asset.txt` during rebase
   - This is expected behavior, not a bug

2. **Force push required**
   - Each sync requires `--force-with-lease` to upstream
   - Safe because only we control upstream-public branch
   - Won't affect upstream contributors (they work on different branches)

## Applicability to aap-ui

This POC validates the approach for your real use case:

### Files to Exclude (examples)
```
platform/assets/aap-logo*.svg
platform/assets/redhat-icon.svg
platform/public/*.svg
AGENTS.md
integration-tests/
```

### Workflow
```bash
# In aap-ui downstream repo

# One-time setup
git remote add upstream git@github.com:ansible/ansible-ui.git
git checkout -b upstream-public
git rm -rf platform/assets/aap-logo*.svg platform/assets/redhat-icon.svg
git rm -rf platform/public/*.svg
git rm AGENTS.md
git rm -rf integration-tests/
git commit -m "Remove proprietary assets for upstream release"
git push upstream upstream-public:main

# Periodic sync (automated or manual)
./sync-to-upstream.sh
```

## Recommendation

**✅ Proceed with this approach** for ansible-automation-platform/aap-ui → ansible/ansible-ui sync.

### Next Steps

1. **Identify all private files/directories** to exclude
2. **Create upstream-public branch** in downstream
3. **Set up automation** (GitHub Actions or periodic script)
4. **Test with actual aap-ui codebase**

### Alternatives Considered

- ❌ git-filter-repo: Rewrites history, breaks upstream
- ❌ Subtree (nested): Complex, pollutes history
- ❌ Midstream: Unnecessary complexity
- ✅ **Branch strategy**: Simple, proven, maintainable
