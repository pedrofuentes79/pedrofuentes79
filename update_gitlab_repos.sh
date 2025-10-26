#!/bin/bash

PROJECTS_DIR="$HOME/Projects"

IGNORE_LIST=("Owna-AI")

if [ -f "$HOME/.config/gitlab-sync/token" ]; then
  source "$HOME/.config/gitlab-sync/token"
else
  echo "Error: Token file not found at $HOME/.config/gitlab-sync/token" >&2
  exit 1
fi

if [ -z "$GITLAB_PRIVATE_TOKEN" ]; then
  echo "Error: GITLAB_PRIVATE_TOKEN is not set in the token file." >&2
  exit 1
fi

echo "Starting GitLab sync scan on $PROJECTS_DIR..."

# Find all .git directories, then get their parent directory
find "$PROJECTS_DIR" -maxdepth 2 -type d -name ".git" | while read git_dir; do
  repo_path=$(dirname "$git_dir")
  repo_name=$(basename "$repo_path")

  if [[ " ${IGNORE_LIST[@]} " =~ " ${repo_name} " ]]; then
    continue
  fi

  cd "$repo_path" || continue

  if git remote -v | grep -q "gitlab.com"; then
    echo " -> Local remote found. Skipping creation step."
    git push --all gitlab
    git push --tags gitlab
    continue
  fi

  API_URL="https://gitlab.com/api/v4/projects/${GITLAB_USERNAME}%2F${repo_name}"

  # --fail tells us if project exists
  PROJECT_DATA=$(curl --silent --fail --request GET \
    --header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
    "$API_URL")

  # curl returns 0 if successful (project exists), non-zero otherwise (project doesn't exist)
  if [ $? -eq 0 ]; then
    # --- Project Exists on GitLab (Case 1: "has already been taken" fix) ---
    echo " -> Project exists on GitLab. Retrieving remote URL..."

    SSH_URL=$(echo "$PROJECT_DATA" | jq -r .ssh_url_to_repo)

    if [ "$SSH_URL" != "null" ] && [ -n "$SSH_URL" ]; then
      echo "    -> Found existing URL: $SSH_URL"
      git remote add gitlab "$SSH_URL"
      echo "    -> Added 'gitlab' remote. Pushing changes..."
      git push --all gitlab
      git push --tags gitlab
    else
      echo "    -> ERROR: Could not retrieve SSH URL for existing project. Check GitLab settings."
    fi

  else
    # --- Project Does NOT Exist on GitLab (Case 2: New Repo Creation) ---
    echo " -> Project does not exist. Creating new private project..."

    RESPONSE=$(curl --silent --request POST \
      --header "PRIVATE-TOKEN: $GITLAB_PRIVATE_TOKEN" \
      --data "name=$repo_name&visibility=private" \
      "https://gitlab.com/api/v4/projects")

    SSH_URL=$(echo "$RESPONSE" | jq -r .ssh_url_to_repo)

    if [ "$SSH_URL" != "null" ] && [ -n "$SSH_URL" ]; then
      echo "    -> Success: Created at $SSH_URL"
      git remote add gitlab "$SSH_URL"
      echo "    -> Added 'gitlab' remote. Pushing changes..."
      git push --all gitlab
      git push --tags gitlab
    else
      echo "    -> CRITICAL ERROR: API call failed. Response message:"
      echo "$RESPONSE" | jq .message
    fi
  fi

  echo "--- End Processing ---"
done
