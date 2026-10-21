#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
USER_NAME="$(id -un)"

PASEO_PORT=6767
PASEO_ENV="$HOME/.config/paseo/paseo.env"
PASEO_UNIT="$HOME/.config/systemd/user/paseo.service"

export MISE_GLOBAL_CONFIG_FILE="$DOTFILES_DIR/mise/.config/mise/config.toml"

log() { echo "==> $*"; }
warn() { echo "warning: $*" >&2; }
die() {
  echo "error: $*" >&2
  exit 1
}

has_systemd() { [[ -d /run/systemd/system ]]; }

preflight() {
  [[ $EUID -ne 0 ]] || die "run as a regular user with sudo access"

  # shellcheck disable=SC1091
  . /etc/os-release
  [[ ${ID:-} == fedora ]] || die "Fedora only, found ${ID:-unknown}"
  ((VERSION_ID >= 44)) || die "Fedora 44 or newer required, found $VERSION_ID (neovim 0.12)"

  case "$(uname -m)" in
  x86_64 | aarch64) ;;
  *) die "unsupported architecture $(uname -m)" ;;
  esac

  # sudo -v alone fails for NOPASSWD users who are also in a password-requiring group like wheel
  sudo -n true 2>/dev/null || sudo -v
}

install_packages() {
  local packages
  mapfile -t packages < <(grep -Ev '^[[:space:]]*(#|$)' "$SCRIPT_DIR/packages.txt")
  log "Installing ${#packages[@]} dnf packages"
  sudo dnf install -y "${packages[@]}"
}

add_repo() {
  local name=$1 key_url=$2 fingerprint=$3 baseurl=$4 title=$5
  local key="/etc/pki/rpm-gpg/RPM-GPG-KEY-$name" tmp actual

  tmp="$(mktemp -d)"
  curl -fsSL "$key_url" -o "$tmp/key"
  actual="$(gpg --show-keys --with-colons "$tmp/key" | awk -F: '$1 == "fpr" { print $10; exit }')"
  [[ $actual == "$fingerprint" ]] || die "$name signing key fingerprint is $actual, expected $fingerprint"

  sudo install -m 0644 "$tmp/key" "$key"
  sudo rpmkeys --import "$key"
  printf '[%s]\nname=%s\nbaseurl=%s\nenabled=1\ngpgcheck=1\ngpgkey=file://%s\n' \
    "$name" "$title" "$baseurl" "$key" | sudo tee "/etc/yum.repos.d/$name.repo" >/dev/null
  rm -rf "$tmp"
}

install_vendor_packages() {
  log "Adding vendor repos"
  add_repo mise https://mise.jdx.dev/gpg-key.pub 24853EC9F655CE80B48E6C3A8B81C9D17413A06D \
    https://mise.jdx.dev/rpm mise
  add_repo claude-code https://downloads.claude.ai/keys/claude-code.asc 31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE \
    https://downloads.claude.ai/claude-code/rpm/latest "Claude Code"
  # dnf expands $releasever and $basearch, not the shell
  # shellcheck disable=SC2016
  add_repo docker-ce https://download.docker.com/linux/fedora/gpg 060A61C51B558A7F742B77AAC52FEB6B621E9F35 \
    'https://download.docker.com/linux/fedora/$releasever/$basearch/stable' "Docker CE Stable"

  local pkg
  for pkg in podman-docker moby-engine; do
    ! rpm -q "$pkg" >/dev/null 2>&1 || sudo dnf remove -y "$pkg"
  done

  sudo dnf install -y mise claude-code \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

setup_docker() {
  log "Configuring docker"
  sudo usermod -aG docker "$USER_NAME"
  if has_systemd; then
    sudo systemctl enable --now docker
  else
    warn "no systemd, docker daemon not started"
  fi
}

install_mise_tools() {
  log "Installing mise tools from the lockfile"
  local token
  if token="$(gh auth token 2>/dev/null)"; then
    export MISE_GITHUB_TOKEN="$token"
  fi
  mise install --locked -y
}

setup_paseo() {
  log "Configuring the paseo service"
  local bin rendered changed=0
  bin="$(mise which paseo)"
  mkdir -p "$(dirname "$PASEO_ENV")" "$(dirname "$PASEO_UNIT")"

  if [[ ! -f $PASEO_ENV ]]; then
    (
      umask 077
      printf 'PASEO_LISTEN=0.0.0.0:%s\nPASEO_HOSTNAMES=true\nPASEO_PASSWORD=%s\n' \
        "$PASEO_PORT" "$(openssl rand -hex 24)" >"$PASEO_ENV"
    )
  fi

  rendered="$(sed "s|@PASEO_BIN@|$bin|" "$SCRIPT_DIR/paseo.service")"
  if [[ "$(cat "$PASEO_UNIT" 2>/dev/null || true)" != "$rendered" ]]; then
    printf '%s\n' "$rendered" >"$PASEO_UNIT"
    changed=1
  fi

  if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable paseo.service
    if ((changed)); then
      systemctl --user restart paseo.service
    else
      systemctl --user start paseo.service
    fi
    sudo loginctl enable-linger "$USER_NAME"
  else
    warn "no user systemd session, run: systemctl --user daemon-reload && systemctl --user enable --now paseo"
  fi

  if command -v firewall-cmd >/dev/null && sudo firewall-cmd --state >/dev/null 2>&1; then
    sudo firewall-cmd --permanent --add-port="$PASEO_PORT/tcp"
    sudo firewall-cmd --reload
  fi
}

verify() {
  log "Verifying tools"
  local bin missing=()
  for bin in nvim git jq rg bat fzf gh go gpg helm htop yq zoxide stow tree-sitter node npm aws fd bc dig ip \
    gcc make python3 xclip wl-copy mise claude docker; do
    command -v "$bin" >/dev/null || missing+=("$bin")
  done
  for bin in starship lazygit tv wt opencode kubectl tflint terraform-docs trivy tofu bun paseo; do
    mise which "$bin" >/dev/null 2>&1 || missing+=("$bin")
  done
  ((${#missing[@]} == 0)) || die "missing: ${missing[*]}"
}

next_steps() {
  cat <<EOF

Done. Remaining manual steps:
  - Move aside the Fedora ~/.bashrc and ~/.bash_profile, then:
      cd $DOTFILES_DIR && stow -v -R -t \$HOME ai bash git nvim television mise
  - Run nvim once to install plugins, mason packages and tree-sitter parsers
  - gh auth login
  - Run claude and opencode once as $USER_NAME to log in (the paseo daemon uses them)
  - Log out and back in for the docker group
  - Paseo password is in $PASEO_ENV, port $PASEO_PORT (plain HTTP, restrict it to a trusted network)
EOF
}

preflight
install_packages
install_vendor_packages
setup_docker
install_mise_tools
setup_paseo
verify
next_steps
