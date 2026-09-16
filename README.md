# Dotfiles

My dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Supported platforms and tools

These configs run on any Unix-like system. I use them on macOS and Linux. Where a setting differs per OS, I check the OS name at runtime or keep a separate package for that platform.

## Installation

Clone the repository, then symlink one package at a time.

```bash
gh repo clone Shikachuu/dotfiles
cd dotfiles
stow -v -R -t $HOME <package>
```

## Packages

Stow packages:

- `ai` (Claude Code config)
- `bash`
- `ghostty`
- `git`
- `mise`
- `nvim`
- `television`

Everything else is run directly, not stowed:

- `macos` holds a `Brewfile` and `setup.sh`, which writes macOS `defaults`.
- `lima` holds Lima VM definitions for Docker and k3s.

## License

Mozilla Public License 2.0. See [LICENSE](LICENSE).
