#!/bin/bash

# Script to automate git pull, conflict resolution, and push

# Define the repository path (modify if necessary)
REPO_PATH="/root/hyperlens"

# Change directory to the repository
cd $REPO_PATH || { echo "Repository path not found!"; exit 1; }

# Fetch the latest changes
echo "Fetching latest changes from remote..."
git fetch origin

# Check if there are any uncommitted changes
if [[ -n $(git status -s) ]]; then
    echo "Uncommitted changes found. Please commit or stash them before proceeding."
    exit 1
fi

# Perform the git pull with rebase to integrate remote changes
echo "Pulling the latest changes from remote and rebasing..."
git pull --rebase origin main

# Check if there are merge conflicts
if [[ $? -ne 0 ]]; then
    echo "Merge conflicts detected. Attempting to resolve..."

    # Automatically mark all conflicts as resolved (basic approach)
    git ls-files -u | cut -f 2 | sort -u | xargs git add

    # You can add further automated resolutions depending on specific file types
    # For example, for files with standard conflict markers (if they can be resolved in a particular way)
    # sed 's/<<<<<< HEAD/Resolved conflict/' > filename

    # Continue rebase after resolving conflicts
    git rebase --continue

    if [[ $? -ne 0 ]]; then
        echo "Rebase failed. Please resolve conflicts manually."
        exit 1
    fi
else
    echo "No conflicts found."
fi

# Push the changes back to the remote repository
echo "Pushing changes to remote repository..."
git push origin main

if [[ $? -eq 0 ]]; then
    echo "Changes pushed successfully!"
else
    echo "Failed to push changes."
    exit 1
fi
