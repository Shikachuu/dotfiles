# Dotfiles

This repository contains my dotfiles. I use [GNU Stow](https://www.gnu.org/software/stow/) to manage them.

## Supported platforms and tools

My dotfiles basically runs on any Unix-like system. I use them on macOS and Linux.
For os specific configurations I either use the `uname` command or have separate packages files for each platform.

## Installation

To install some or all of my dotfiles, clone this repository and use GNU Stow to symlink the desired configuration files to your home directory.

```bash
gh repo clone Shikachuu/dotfiles
git submodule update --init --recursive
cd dotfiles
stow -v -R -t $HOME <package>
```

## Packages

- `ai` (Claude Code and OpenCode configurations)
- `bash`
- `git`
- `nvim`
- `ghostty`
- `television`
- `mise`
- `lima` (macOS only, not stowed)
- `macos` (macOS specific configuration, not stowed)
- `linux` (Fedora setup script, not stowed)

## Fedora

`linux/setup.sh` installs every tool the dotfiles use on Fedora 44 or newer: dnf packages from `linux/packages.txt`, Docker CE, Claude Code, and the mise tools that Fedora does not package. It also runs the Paseo daemon as a systemd user service. It does not stow anything or install Neovim plugins: after stowing, run `nvim` once to install plugins, mason packages and tree-sitter parsers.

```bash
linux/setup.sh
mv ~/.bashrc ~/.bashrc.fedora && mv ~/.bash_profile ~/.bash_profile.fedora
stow -v -R -t $HOME ai bash git nvim television mise
```

The mise config pins tools in `mise/.config/mise/mise.lock`. Refresh it with `mise lock --global --platform linux-x64,linux-arm64,macos-arm64`.

## Archify

Both setup scripts run `scripts/install-archify.sh`. It sparse-clones the [archify](https://github.com/tt-a1i/archify) skill at a pinned commit into `~/.local/share/archify` and symlinks it to `ai/.claude/skills/archify`, which git ignores. The skill needs only `node` from mise, with no npm install. The Claude settings set `ARCHIFY_UPDATE_CHECK_DISABLED=1`. To update, set `ARCHIFY_TAG` and `ARCHIFY_COMMIT` in the script to a new release (`git ls-remote --tags https://github.com/tt-a1i/archify` lists the peeled `^{}` commit of each tag) and rerun it.

## License

This project is licensed under the Mozilla Public License 2.0 - see the [LICENSE](LICENSE) file for details.
