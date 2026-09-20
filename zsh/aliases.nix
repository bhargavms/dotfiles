{
  ".." = "cd ..";
  add = "git add .";
  push = "git push";
  pull = "git pull";
  m = "git switch main";
  zshconfig = "nvim ~/.dotfiles/home.nix";

  cleanGradleConfigCache = "rm -rf .gradle/configuration-cache";

  "codex-yolo" = "codex --yolo";
  "codex-gb" = "codex --config mcp_servers.growthbook.enabled=true";
  "codex-gb-yolo" = "codex --yolo --config mcp_servers.growthbook.enabled=true";

  gsyncm = "git pull origin master --rebase";
  fpush = "git push --force";
  g = "git";
  ga = "git add";
  gaa = "git add --all";
  gau = "git add --update";
  gst = "git status";
  gco = "git checkout";
  gcb = "git checkout -b";
  gcm = ''git checkout "$(git_main_branch)"'';
  gsw = "git switch";
  gswc = "git switch -c";
  gc = "git commit --verbose";
  gcmsg = "git commit -m";
  gca = "git commit --verbose --amend";
  gds = "git diff --staged";
  gl = "git pull";
  gb = "git branch";
  gba = "git branch -a";
  glog = "git log --oneline --decorate --graph";
  grb = "git rebase";
  grbi = "git rebase --interactive";
  gm = "git merge";
  gsta = "git stash push";
  gstp = "git stash pop";
  ggpull = ''git pull origin "$(git branch --show-current)"'';
  ggpush = ''git push origin "$(git branch --show-current)"'';
  gbr = "git branch -r";
  gcan = "git commit --amend --no-edit";
  gcannv = "git commit --amend --no-edit --no-verify";
  gclean = ''git branch --merged | grep -v '\*\|master\|main\|test\|dev\|qa\|prod' | xargs -n 1 git branch -d'';
  gd = "git diff";
  glol = "git log --graph --abbrev-commit --oneline --decorate";
  gp = "git push";
  gpf = "git push origin --force-with-lease";
  gpo = "git push origin";
  gpt = "git push --tag";
  gr = "git remote";
  gs = "git status";
  gsi = "git submodule update --init --depth 1 --jobs 4";
  gsu = "git submodule update --remote --jobs 4";
  gss = "git status -s";
  gtd = "git tag --delete";
}
