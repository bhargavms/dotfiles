''
  git_main_branch() {
    command git rev-parse --git-dir &>/dev/null || return
    local ref
    for ref in refs/{heads,remotes/{origin,upstream}}/{main,master,trunk}; do
      if command git show-ref -q --verify "$ref"; then
        echo "''${ref:t}"
        return
      fi
    done
    echo main
  }

  gpur() {
    git pull origin "$1" --rebase
  }

  gCleanB() {
    git fetch -p
    git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d
  }

  gsquash() {
    local usage="Usage: gsquash <commit-or-branch> <message>"
    local base="$1"
    local msg="$2"
    if [[ -z "$base" || -z "$msg" ]]; then
      echo "$usage"
      return 1
    fi
    if ! git --no-pager show "$base" &>/dev/null; then
      echo "No valid git object specified."
      echo "$usage"
      return 1
    fi
    local current base_commit
    current=$(git rev-parse --abbrev-ref HEAD)
    base_commit=$(git merge-base "$current" "$base")
    printf "Squashing the following commits:\n\n"
    git --no-pager log --format='%H %an - %s' "$base_commit".."$current"
    printf "\n"
    git reset --soft "$base_commit"
    git commit -m "$msg"
  }
''
