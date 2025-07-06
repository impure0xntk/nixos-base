lib: basedir: lib.forEach [

"arr.marksman"
"asvetliakov.vscode-neovim"
"augustocdias.tasks-shell-input"
"coderabbit.coderabbit-vscode"
"donjayamanne.githistory"
"dorzey.vscode-sqlfluff"
"dotiful.dotfiles-syntax-highlighting"
"eriklynd.json-tools"
"github.copilot"
"github.copilot-chat"
"github.github-vscode-theme"
"jnoortheen.nix-ide"
"mads-hartmann.bash-ide-vscode"
"mhutchie.git-graph"
"redhat.vscode-yaml"
"visualstudioexptteam.intellicode-api-usage-examples"
"vscjava.vscode-java-dependency"

] (name: "${basedir}/${name}*")