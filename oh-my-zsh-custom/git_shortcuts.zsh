alias gsyncm='git pull origin master --rebase'
alias fpush='ggpush -f'
alias gCleanB='git fetch -p ; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d'
alias gsquash='!bash -c '"'"'usage="Usage: git squash <Commit/Branch> <Message>";baseBranchParam=$0;if [ -z ${baseBranchParam+x} ];then echo "No base branch specified";echo $usage;exit 1;fi;git --no-pager show $baseBranchParam&>/dev/null;if [ $? -ne 0 ];then echo "No valid git object specified.";echo $usage;exit 1;fi;commitMsg=$1;if [ -z "$commitMsg" ];then echo "No commit message specified for squash commit.";echo $usage;exit 1;fi;currentBranch=$(git rev-parse --abbrev-ref HEAD);baseCommit=$(git merge-base $currentBranch $baseBranchParam);printf "Squashing the following commits:\n\n";printf "$(git --no-pager log --format='\"'%H %an - %s'\"' $baseCommit..$currentBranch)\n\n";git reset --soft $baseCommit&>/dev/null;git commit -m "$commitMsg" 1>/dev/null;if [ $? -ne 0 ];then echo "Squashed into new commit \"$commitMsg\"";exit 0;fi;exit 1'"'"' $1 $2'


# +-----+
# | git |
# +-----+

alias gbr='git branch -r'
alias gcan='git commit --amend --no-edit'
alias gcannv='git commit --amend --no-edit --no-verify'
alias gclean="git branch --merged | grep  -v '\\*\\|master\\|main\\|test\\|dev\\|qa\\|prod' | xargs -n 1 git branch -d"
alias gd='git diff'
alias glol='git log --graph --abbrev-commit --oneline --decorate'
alias gp='git push'
alias gpf='git push origin --force-with-lease'
alias gpo='git push origin'
alias gpt='git push --tag'
alias gr='git remote'
alias gs='git status'
alias gsi='git submodule update --init --depth 1 --jobs 4'
alias gsu='git submodule update --remote --jobs 4'
alias gss='git status -s'
alias gtd='git tag --delete'

# Functions

gpur(){
  git pull origin "$1" --rebase
}
