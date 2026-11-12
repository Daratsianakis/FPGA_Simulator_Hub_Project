#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

printf '%s\n' '=========================================' '  Simulator Hub GitHub Pages Publisher' '========================================='

for tool in python3 git gh; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "ERROR: Required tool not found: $tool" >&2
        exit 1
    fi
done

if ! gh auth status >/dev/null 2>&1; then
    echo 'GitHub CLI authentication is required.'
    gh auth login --web
    gh auth status >/dev/null
fi

echo '[1/6] Updating project manifest...'
python3 update_hub.py

if [ ! -f index.html ] || [ ! -f projects_data.js ]; then
    echo 'ERROR: Missing index.html or projects_data.js.' >&2
    exit 1
fi

echo '[2/6] Preparing local Git repository...'
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git init -b main
fi

branch=$(git symbolic-ref --quiet --short HEAD) || {
    echo 'ERROR: Git is in detached HEAD state. Switch to a branch before publishing.' >&2
    exit 1
}

git add --all
if ! git diff --cached --quiet; then
    git commit -m 'Publish Simulator Hub and update project manifest'
else
    echo 'No new changes to commit.'
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    echo 'ERROR: No Git commit exists to publish.' >&2
    exit 1
fi

echo '[3/6] Checking the GitHub repository...'
if ! git remote get-url origin >/dev/null 2>&1; then
    repo_name=$(basename "$PWD")
    echo "Creating GitHub repository: $repo_name"
    if ! gh repo create "$repo_name" --public --source=. --remote=origin; then
        echo 'ERROR: Could not create the repository. If it already exists, configure its origin remote explicitly.' >&2
        exit 1
    fi
fi

# Resolve the actual GitHub repository rather than guessing its owner or name.
repo_full_name=$(gh repo view --json nameWithOwner --jq '.nameWithOwner') || {
    echo 'ERROR: Unable to identify the GitHub repository for this folder.' >&2
    exit 1
}

echo "[4/6] Pushing branch $branch to $repo_full_name..."
git push -u origin "$branch"

echo '[5/6] Checking GitHub Pages...'
if gh api "repos/$repo_full_name/pages" >/dev/null 2>&1; then
    echo 'GitHub Pages is already configured.'
else
    echo "Enabling GitHub Pages from $branch at the repository root..."
    if ! gh api --method POST "repos/$repo_full_name/pages" \
        -H 'Accept: application/vnd.github+json' \
        -H 'X-GitHub-Api-Version: 2022-11-28' \
        -f "source[branch]=$branch" \
        -f 'source[path]=/' >/dev/null; then
        echo 'ERROR: GitHub Pages could not be enabled. Check repository Settings > Pages.' >&2
        exit 1
    fi
fi

echo '[6/6] Verifying GitHub Pages configuration...'
if ! pages_url=$(gh api "repos/$repo_full_name/pages" --jq '.html_url'); then
    echo 'ERROR: GitHub Pages configuration could not be verified.' >&2
    exit 1
fi

if [ -z "$pages_url" ] || [ "$pages_url" = 'null' ]; then
    echo 'ERROR: GitHub Pages did not return a site URL.' >&2
    exit 1
fi

printf '\n%s\n' '=========================================' 'Publishing push and Pages configuration succeeded.' "Repository: https://github.com/$repo_full_name" "GitHub Pages: $pages_url" 'Note: Initial site deployment may still be processing.' '========================================='
