# Downstream → Upstream Sync Strategy

## The Problem

When maintaining a public upstream fork from a private downstream repository with certain files excluded, you face a critical choice:

### ❌ **Simple Branch Approach (Current POC)**
```bash
git checkout -b upstream-public
git rm private-asset.txt
git commit -m "Remove private files"
git push upstream upstream-public:main
```

**Problem:** Private files remain in git history!
- `git log -- private-asset.txt` shows all commits
- `git show <commit>:private-asset.txt` reveals content
- Anyone can access private data from old commits

### ✅ **Clean History Approach (Recommended)**

Use a **two-phase strategy**:

1. **Phase 1: Clean Initialization** - Rewrite history ONCE to remove private files
2. **Phase 2: Ongoing Sync** - Use branch strategy for future updates

## Implementation

### Phase 1: Clean Initialization (One-Time)

**Script:** `./init-upstream-clean.sh`

```bash
# What it does:
1. Creates temporary clone of your repo
2. Uses git-filter-repo to remove private files from ALL history
3. Force-pushes clean history to upstream
4. Sets up upstream-public tracking branch
```

**Result:** Upstream history is completely clean - private files never existed

### Phase 2: Ongoing Sync (Regular Updates)

**Script:** `./sync-to-upstream.sh`

```bash
# What it does:
1. Rebases upstream-public onto main
2. Auto-resolves conflicts (private files)
3. Pushes to upstream
```

**Result:** New commits sync cleanly without exposing private files

## Comparison

| Aspect | Simple Branch | Clean History |
|--------|--------------|---------------|
| **Private files in history** | ❌ Visible in old commits | ✅ Never existed |
| **Security** | ⚠️ Can be recovered | ✅ Truly private |
| **Initial setup** | Easy | Requires git-filter-repo |
| **Ongoing sync** | Same | Same |
| **Best for** | Internal/trusted repos | Public open source |

## Decision Guide

**Use Clean History approach if:**
- ✅ Upstream is **public** open source
- ✅ Private files contain **sensitive data**
- ✅ You care about **compliance/security**
- ✅ Repository is new or you can afford history rewrite

**Simple Branch approach OK if:**
- Upstream is **semi-private** (known contributors)
- Private files are just **branding/tests** (not sensitive)
- Repository has **existing forks** you can't break
- You understand the **historical exposure** trade-off

## For This POC

Since this is a test repository, **either approach works**. For the real `aap-ui` repository, I recommend:

**Use Clean History** because:
1. `ansible/ansible-ui` will be **public** on GitHub
2. Sets the right **security precedent**
3. One-time cost during initial setup
4. Protects against accidental **data exposure**

## Installation

**Requirements for clean initialization:**
```bash
# macOS
brew install git-filter-repo

# Python pip
pip install git-filter-repo
```

**Run once:**
```bash
./init-upstream-clean.sh
```

**Then for all future syncs:**
```bash
./sync-to-upstream.sh
```
