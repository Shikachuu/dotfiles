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

brew_bash_path=$(ls "$(brew --prefix)/bin/bash")

if ! grep -Fxq "$brew_bash_path" /etc/shells; then
  echo "$brew_bash_path" | sudo tee -a /etc/shells
  chsh -s "$(brew --prefix)/bin/bash"
fi

