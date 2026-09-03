# =========================================================
# Git
# =========================================================

clean-branches() {
  echo "Cleaning up local branches..."
    
  # Check if we're in a git repository
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not in a git repository"
    return 1
  fi
    
  # Step 1: Switch to default branch (main or master)
  echo "Step 1: Switching to default branch..."
  local default_branch=""
    
  # Check if main exists
  if git show-ref --verify --quiet refs/heads/main; then
    default_branch="main"
  # Check if master exists
  elif git show-ref --verify --quiet refs/heads/master; then
    default_branch="master"
  else
    echo "Error: Could not find main or master branch"
    return 1
  fi
    
  echo "Switching to $default_branch..."
  git checkout "$default_branch"
    
  if [ $? -ne 0 ]; then
    echo "Error: Failed to switch to $default_branch"
    return 1
  fi
    
  # Step 2: Prune remote tracking branches
  echo "Step 2: Pruning remote tracking branches..."
  git remote prune origin
    
  # Step 3: Find and delete local branches
  echo "Step 3: Finding local branches to delete..."
    
  # Find local branches that don't have a corresponding remote branch
  local branches_to_delete=$(git for-each-ref --format='%(refname:short)' refs/heads/ | while read branch; do
    # Skip main, master, and develop branches
    if [[ "$branch" =~ ^(main|master|develop)$ ]]; then
      continue
    fi
        
    # Check if remote branch exists
    if ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      echo "$branch"
    fi
  done)
    
  if [[ -z "$branches_to_delete" ]]; then
    echo "No local branches to delete."
    return 0
  fi
    
  echo "Found branches to delete:"
  echo "$branches_to_delete" | sed 's/^/  - /'
    
  echo -n "Do you want to delete these branches? (y/N): "
  read -r response
    
  if [[ "$response" =~ ^[Yy]$ ]]; then
    echo "Deleting branches..."
    echo "$branches_to_delete" | while read branch; do
      if [[ -n "$branch" ]]; then
        echo "  Deleting: $branch"
        git branch -D "$branch"
      fi
    done
    echo "Branch cleanup completed!"
  else
    echo "Branch cleanup cancelled."
  fi
}

start-branch() {
  if [ -z "$1" ]; then
    echo "Usage: start-branch <branch-name>"
    echo "Creates a new git branch and runs 'nup' (npm run dependencies:update) in that branch"
    return 1
  fi
  
  local branch_name="$1"
  
  echo "Creating branch: $branch_name"
  git checkout -b "$branch_name"
  
  if [ $? -eq 0 ]; then
    echo "Successfully created and switched to branch: $branch_name"
    echo "Running nup (npm run dependencies:update)..."
    nup
  else
    echo "Failed to create branch: $branch_name"
    return 1
  fi
}