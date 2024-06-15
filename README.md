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

- `bash`
- `git`
- `nvim`
- `kitty`
- `linux` (for Linux specific configurations)
- `macos` (for macOS specific configurations)

## License

This project is licensed under the Mozilla Public License 2.0 - see the [LICENSE](LICENSE) file for details.
