#!/bin/bash

defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write com.apple.dock autohide -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
mkdir -p ~/Documents/Screenshots
defaults write com.apple.screencapture location ~/Documents/Screenshots
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticInlinePredictionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable hotkeys that captures the ctrl + space shortcut
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 60 "{ enabled = 0; }"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 61 "{ enabled = 0; }"
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 62 "{ enabled = 0; }"
defaults write com.apple.WindowManager GloballyEnabled -bool true

# Bind fill window to Control+Option+Enter
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "\033Window\033Fill" "^~\\U21a9"
# Bind center window to Control+Option+c
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "\033Window\033Center" "^~c"
# Bind arranging window left side to Control+Option+Left Arrow
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Left" "~^\\U2190"
# Bind arranging window right side to Control+Option+Right Arrow
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "\033Window\033Move & Resize\033Right" "~^\\U2192"

# WindowManager settings
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool true
defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool true

brew_bash_path=$(ls "$(brew --prefix)/bin/bash")

if ! grep -Fxq "$brew_bash_path" /etc/shells; then
  echo "$brew_bash_path" | sudo tee -a /etc/shells
  chsh -s "$(brew --prefix)/bin/bash"
fi

